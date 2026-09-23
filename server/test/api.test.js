const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const { Pool } = require('pg');
const fs = require('node:fs');
const path = require('node:path');
const { createApp } = require('../index');

const DATABASE_URL = process.env.DATABASE_URL;
if (!DATABASE_URL) throw new Error('DATABASE_URL is required for API tests.');

const pool = new Pool({ connectionString: DATABASE_URL });
const config = {
  access: 'a'.repeat(64),
  refresh: 'b'.repeat(64),
  allowSelfRegistration: true,
  allowedOrigins: [],
};
const app = createApp({ pool, config });

async function seedSchema() {
  const schema = fs.readFileSync(
    path.join(__dirname, '..', 'migrations', '001_initial.sql'),
    'utf8',
  );
  await pool.query(schema);
  await pool.query('TRUNCATE refresh_tokens, attempts, users, subscriptions, organization_licenses, billing_events, audit_logs, schools, organizations CASCADE');
  await pool.query(
    `INSERT INTO subscription_plans(code,name,description,interval,price_cents,currency,learner_limit,active)
     VALUES('school_small','Small School','Up to 100 learners','annual',30000,'USD',100,TRUE)
     ON CONFLICT (code) DO UPDATE SET active=TRUE`,
  );
}

test.before(seedSchema);
test.after(async () => pool.end());

test('health checks database readiness', async () => {
  const response = await request(app).get('/health');
  assert.equal(response.status, 200);
  assert.equal(response.body.database, 'ready');
});

test('learner can register, login, refresh and sync only their own attempts', async () => {
  const register = await request(app)
    .post('/v1/auth/register')
    .send({
      username: 'learner.one',
      password: 'StrongPass123!',
      displayName: 'Learner One',
      grade: 'Grade 6',
    });

  assert.equal(register.status, 201);
  assert.equal(register.body.user.role, 'learner');
  assert.ok(register.body.accessToken);
  assert.ok(register.body.refreshToken);

  const session = register.body;
  const login = await request(app)
    .post('/v1/auth/login')
    .send({ username: 'learner.one', password: 'StrongPass123!' });
  assert.equal(login.status, 200);
  assert.equal(login.body.user.learnerId, session.user.learnerId);

  const refresh = await request(app)
    .post('/v1/auth/refresh')
    .send({ refreshToken: session.refreshToken });
  assert.equal(refresh.status, 200);
  assert.ok(refresh.body.accessToken);

  const attempt = {
    client_id: 'client_attempt_001',
    learner_id: session.user.learnerId,
    question_id: 'fractions-q1',
    topic_id: 'fractions',
    correct: true,
    timestamp: new Date().toISOString(),
    attempt_type: 'practice',
    selected_answer: '3/5',
    duration_ms: 2300,
    difficulty: 1,
  };

  const sync = await request(app)
    .post('/v1/sync/attempts')
    .set('Authorization', 'Bearer ' + session.accessToken)
    .send({ attempts: [attempt] });

  assert.equal(sync.status, 200);
  assert.equal(sync.body.accepted, 1);
  assert.equal(sync.body.duplicates, 0);

  const duplicate = await request(app)
    .post('/v1/sync/attempts')
    .set('Authorization', 'Bearer ' + session.accessToken)
    .send({ attempts: [attempt] });

  assert.equal(duplicate.status, 200);
  assert.equal(duplicate.body.accepted, 0);
  assert.equal(duplicate.body.duplicates, 1);

  const progress = await request(app)
    .get('/v1/learners/' + session.user.learnerId + '/progress')
    .set('Authorization', 'Bearer ' + session.accessToken);

  assert.equal(progress.status, 200);
  assert.equal(progress.body.topics[0].topic_id, 'fractions');
  assert.equal(progress.body.topics[0].attempted, 1);

  const second = await request(app)
    .post('/v1/auth/register')
    .send({
      username: 'learner.two',
      password: 'StrongPass456!',
      displayName: 'Learner Two',
      grade: 'Grade 6',
    });
  assert.equal(second.status, 201);

  const crossScope = await request(app)
    .post('/v1/sync/attempts')
    .set('Authorization', 'Bearer ' + session.accessToken)
    .send({
      attempts: [{ ...attempt, client_id: 'client_attempt_002', learner_id: second.body.user.learnerId }],
    });

  assert.equal(crossScope.status, 403);
  assert.equal(crossScope.body.error, 'learner_scope_violation');
});

test('protected endpoints reject missing credentials', async () => {
  const response = await request(app)
    .post('/v1/sync/attempts')
    .send({ attempts: [] });
  assert.equal(response.status, 401);
  assert.equal(response.body.error, 'authentication_required');
});


test('admin billing endpoints expose plans and organization billing state', async () => {
  const organizationId = 'org_test_001';
  const schoolId = 'school_test_001';

  await pool.query(
    `INSERT INTO organizations(id,name,type,billing_email)
     VALUES($1,'Pilot Organisation','school_group','billing@example.test')`,
    [organizationId],
  );
  await pool.query(
    `INSERT INTO schools(id,code,name,organization_id)
     VALUES($1,'PILOT','Pilot School',$2)`,
    [schoolId, organizationId],
  );

  const passwordHash = await require('bcryptjs').hash('AdminPass123!', 12);
  const adminId = 'admin_test_001';
  await pool.query(
    `INSERT INTO users(id,username,password_hash,display_name,role,school_id,organization_id)
     VALUES($1,'pilot.admin',$2,'Pilot Admin','admin',$3,$4)`,
    [adminId, passwordHash, schoolId, organizationId],
  );

  const login = await request(app)
    .post('/v1/auth/login')
    .send({ username: 'pilot.admin', password: 'AdminPass123!' });
  assert.equal(login.status, 200);

  const plans = await request(app)
    .get('/v1/admin/billing/plans')
    .set('Authorization', 'Bearer ' + login.body.accessToken);
  assert.equal(plans.status, 200);
  assert.equal(plans.body.plans[0].code, 'school_small');

  const billing = await request(app)
    .post('/v1/admin/billing/subscription')
    .set('Authorization', 'Bearer ' + login.body.accessToken)
    .send({ planCode: 'school_small' });
  assert.equal(billing.status, 201);
  assert.equal(billing.body.status, 'active');

  const state = await request(app)
    .get('/v1/admin/billing/organization')
    .set('Authorization', 'Bearer ' + login.body.accessToken);
  assert.equal(state.status, 200);
  assert.equal(state.body.organization.plan_code, 'school_small');
  assert.equal(state.body.organization.subscription_status, 'active');
});
