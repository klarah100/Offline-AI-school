require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');
const { randomUUID, createHash } = require('node:crypto');
const { z } = require('zod');

const ACCESS_TTL = '15m';
const REFRESH_TTL = '30d';
const ISSUER = 'offlineai-school';
const AUDIENCE = 'offlineai-school-client';

const loginSchema = z.object({
  username: z.string().trim().min(3).max(120),
  password: z.string().min(10).max(200),
});

const registerSchema = loginSchema.extend({
  displayName: z.string().trim().min(1).max(120),
  grade: z.string().trim().min(1).max(50),
  schoolCode: z.string().trim().min(2).max(50).optional(),
});

const refreshSchema = z.object({
  refreshToken: z.string().min(20),
});

const syncItemSchema = z.object({
  client_id: z.string().trim().min(8).max(120),
  learner_id: z.string().trim().min(8).max(120),
  question_id: z.string().trim().min(1).max(200),
  topic_id: z.string().trim().min(1).max(200),
  correct: z.boolean(),
  timestamp: z.string().datetime({ offset: true }),
  attempt_type: z.enum(['diagnostic', 'practice']).default('practice'),
  selected_answer: z.string().max(500).nullable().optional(),
  duration_ms: z.number().int().min(0).max(86400000).nullable().optional(),
  difficulty: z.number().int().min(1).max(3).default(1),
});

const syncSchema = z.object({
  attempts: z.array(syncItemSchema).min(1).max(100),
});

const createUserSchema = z.object({
  username: z.string().trim().min(3).max(120),
  password: z.string().min(10).max(200),
  displayName: z.string().trim().min(1).max(120),
  role: z.enum(['learner', 'teacher']),
  schoolId: z.string().uuid(),
  grade: z.string().trim().max(50).optional(),
  learnerId: z.string().trim().min(8).max(120).optional(),
});

function publicUser(row) {
  return {
    id: row.id,
    username: row.username,
    displayName: row.display_name,
    role: row.role,
    schoolId: row.school_id,
    learnerId: row.learner_id,
    grade: row.grade,
  };
}

async function audit(pool, userId, action, metadata = {}) {
  await pool.query(
    'INSERT INTO audit_logs(user_id, action, metadata) VALUES($1,$2,$3)',
    [userId || null, action, JSON.stringify(metadata)],
  );
}

function hashToken(token) {
  return createHash('sha256').update(token).digest('hex');
}

function createTokens(user, secrets) {
  const accessToken = jwt.sign(
    {
      sub: user.id,
      role: user.role,
      schoolId: user.school_id || null,
      learnerId: user.learner_id || null,
    },
    secrets.access,
    { expiresIn: ACCESS_TTL, issuer: ISSUER, audience: AUDIENCE },
  );
  const refreshToken = jwt.sign(
    { sub: user.id, type: 'refresh' },
    secrets.refresh,
    { expiresIn: REFRESH_TTL, issuer: ISSUER, audience: AUDIENCE },
  );
  return { accessToken, refreshToken };
}

async function storeRefreshToken(pool, userId, refreshToken) {
  const decoded = jwt.decode(refreshToken);
  const expiresAt = new Date(decoded.exp * 1000);
  await pool.query(
    'INSERT INTO refresh_tokens(id,user_id,token_hash,expires_at) VALUES($1,$2,$3,$4)',
    [randomUUID(), userId, hashToken(refreshToken), expiresAt],
  );
}

function configFromEnv() {
  const access = process.env.JWT_ACCESS_SECRET;
  const refresh = process.env.JWT_REFRESH_SECRET;
  if (!access || access.length < 32 || !refresh || refresh.length < 32) {
    throw new Error('JWT_ACCESS_SECRET and JWT_REFRESH_SECRET must each be at least 32 characters.');
  }

  return {
    access,
    refresh,
    allowSelfRegistration: process.env.ALLOW_SELF_REGISTRATION === 'true',
    allowedOrigins: (process.env.ALLOWED_ORIGINS || '')
      .split(',')
      .map((value) => value.trim())
      .filter(Boolean),
  };
}

function createApp({ pool, config = configFromEnv() }) {
  const app = express();

  app.disable('x-powered-by');
  app.set('trust proxy', process.env.TRUST_PROXY === 'true');

  app.use(helmet());
  app.use(cors({
    origin(origin, callback) {
      if (!origin || config.allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(new Error('Origin not allowed'));
    },
  }));
  app.use(express.json({ limit: '256kb' }));

  const generalLimiter = rateLimit({
    windowMs: 60 * 1000,
    limit: 120,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
  });
  const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 20,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
  });

  app.use(generalLimiter);

  async function authenticate(req, res, next) {
    const header = req.get('authorization') || '';
    if (!header.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'authentication_required' });
    }

    try {
      req.user = jwt.verify(header.slice(7), config.access, {
        issuer: ISSUER,
        audience: AUDIENCE,
      });
      return next();
    } catch {
      return res.status(401).json({ error: 'invalid_or_expired_token' });
    }
  }

  function requireRoles(...roles) {
    return (req, res, next) => {
      if (!roles.includes(req.user.role)) {
        return res.status(403).json({ error: 'forbidden' });
      }
      return next();
    };
  }

  async function issueSession(user) {
    const tokens = createTokens(user, config);
    await storeRefreshToken(pool, user.id, tokens.refreshToken);
    return { ...tokens, user: publicUser(user) };
  }

  app.get('/health', async (_req, res, next) => {
    try {
      await pool.query('SELECT 1');
      res.json({ ok: true, service: 'offlineai-school-api', database: 'ready' });
    } catch (error) {
      next(error);
    }
  });

  app.post('/v1/auth/register', authLimiter, async (req, res, next) => {
    try {
      if (!config.allowSelfRegistration) {
        return res.status(403).json({ error: 'self_registration_disabled' });
      }

      const input = registerSchema.parse(req.body);
      const existing = await pool.query('SELECT 1 FROM users WHERE username = $1', [input.username]);
      if (existing.rowCount) return res.status(409).json({ error: 'username_taken' });

      let schoolId = null;
      if (input.schoolCode) {
        const school = await pool.query('SELECT id FROM schools WHERE code = $1', [input.schoolCode]);
        if (school.rowCount === 0) return res.status(400).json({ error: 'unknown_school' });
        schoolId = school.rows[0].id;
      }

      const user = {
        id: randomUUID(),
        username: input.username,
        display_name: input.displayName,
        role: 'learner',
        school_id: schoolId,
        learner_id: `learner_${randomUUID().replaceAll('-', '')}`,
        grade: input.grade,
      };

      const passwordHash = await bcrypt.hash(input.password, 12);
      await pool.query(
        `INSERT INTO users(id,username,password_hash,display_name,role,school_id,learner_id,grade)
         VALUES($1,$2,$3,$4,$5,$6,$7,$8)`,
        [user.id, user.username, passwordHash, user.display_name, user.role, user.school_id, user.learner_id, user.grade],
      );

      const session = await issueSession(user);
      await audit(pool, user.id, 'learner_registered', { schoolId });
      res.status(201).json(session);
    } catch (error) {
      next(error);
    }
  });

  app.post('/v1/auth/login', authLimiter, async (req, res, next) => {
    try {
      const input = loginSchema.parse(req.body);
      const result = await pool.query('SELECT * FROM users WHERE username = $1', [input.username]);
      const user = result.rows[0];
      if (!user || !(await bcrypt.compare(input.password, user.password_hash))) {
        return res.status(401).json({ error: 'invalid_credentials' });
      }
      const session = await issueSession(user);
      await audit(pool, user.id, 'user_login', { role: user.role });
      res.json(session);
    } catch (error) {
      next(error);
    }
  });

  app.post('/v1/auth/refresh', authLimiter, async (req, res, next) => {
    try {
      const input = refreshSchema.parse(req.body);
      const decoded = jwt.verify(input.refreshToken, config.refresh, {
        issuer: ISSUER,
        audience: AUDIENCE,
      });
      if (decoded.type !== 'refresh') return res.status(401).json({ error: 'invalid_refresh_token' });

      const tokenRow = await pool.query(
        'SELECT * FROM refresh_tokens WHERE token_hash = $1 AND revoked_at IS NULL AND expires_at > NOW()',
        [hashToken(input.refreshToken)],
      );
      if (tokenRow.rowCount === 0) return res.status(401).json({ error: 'refresh_token_revoked' });

      const userResult = await pool.query('SELECT * FROM users WHERE id = $1', [decoded.sub]);
      if (userResult.rowCount === 0) return res.status(401).json({ error: 'user_not_found' });

      await pool.query('UPDATE refresh_tokens SET revoked_at = NOW() WHERE id = $1', [tokenRow.rows[0].id]);
      const nextSession = await issueSession(userResult.rows[0]);
      await audit(pool, userResult.rows[0].id, 'token_refresh');
      res.json(nextSession);
    } catch (error) {
      if (error instanceof jwt.JsonWebTokenError || error instanceof jwt.TokenExpiredError) {
        return res.status(401).json({ error: 'invalid_refresh_token' });
      }
      next(error);
    }
  });

  app.post('/v1/auth/logout', authenticate, async (req, res, next) => {
    try {
      const input = refreshSchema.parse(req.body);
      await pool.query(
        'UPDATE refresh_tokens SET revoked_at = NOW() WHERE user_id = $1 AND token_hash = $2',
        [req.user.sub, hashToken(input.refreshToken)],
      );
      await audit(pool, req.user.sub, 'user_logout');
      res.status(204).end();
    } catch (error) {
      next(error);
    }
  });

  app.get('/v1/auth/me', authenticate, async (req, res, next) => {
    try {
      const result = await pool.query('SELECT * FROM users WHERE id = $1', [req.user.sub]);
      if (result.rowCount === 0) return res.status(401).json({ error: 'user_not_found' });
      res.json({ user: publicUser(result.rows[0]) });
    } catch (error) {
      next(error);
    }
  });


  app.delete('/v1/auth/me/data', authenticate, requireRoles('learner'), async (req, res, next) => {
    try {
      const client = await pool.connect();
      try {
        await client.query('BEGIN');
        await audit(pool, req.user.sub, 'learner_data_deletion_requested');
        await client.query('DELETE FROM refresh_tokens WHERE user_id = $1', [req.user.sub]);
        if (req.user.learnerId) {
          await client.query('DELETE FROM attempts WHERE learner_id = $1', [req.user.learnerId]);
        }
        await client.query('DELETE FROM users WHERE id = $1', [req.user.sub]);
        await client.query('COMMIT');
        return res.status(204).end();
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      } finally {
        client.release();
      }
    } catch (error) {
      next(error);
    }
  });

  app.post('/v1/admin/users', authenticate, requireRoles('admin'), async (req, res, next) => {
    try {
      const input = createUserSchema.parse(req.body);
      if (req.user.schoolId && req.user.schoolId !== input.schoolId) {
        return res.status(403).json({ error: 'school_scope_violation' });
      }
      const existing = await pool.query('SELECT 1 FROM users WHERE username = $1', [input.username]);
      if (existing.rowCount) return res.status(409).json({ error: 'username_taken' });

      const school = await pool.query('SELECT id FROM schools WHERE id = $1', [input.schoolId]);
      if (school.rowCount === 0) return res.status(400).json({ error: 'unknown_school' });

      const learnerId = input.role === 'learner'
        ? (input.learnerId || `learner_${randomUUID().replaceAll('-', '')}`)
        : null;
      const user = {
        id: randomUUID(),
        username: input.username,
        display_name: input.displayName,
        role: input.role,
        school_id: input.schoolId,
        learner_id: learnerId,
        grade: input.grade || null,
      };
      const passwordHash = await bcrypt.hash(input.password, 12);

      await pool.query(
        `INSERT INTO users(id,username,password_hash,display_name,role,school_id,learner_id,grade)
         VALUES($1,$2,$3,$4,$5,$6,$7,$8)`,
        [user.id,user.username,passwordHash,user.display_name,user.role,user.school_id,user.learner_id,user.grade],
      );

      await audit(pool, req.user.sub, 'admin_user_provisioned', { role: input.role, schoolId: input.schoolId });
      res.status(201).json({ user: publicUser(user) });
    } catch (error) {
      next(error);
    }
  });

  app.post('/v1/sync/attempts', authenticate, requireRoles('learner'), async (req, res, next) => {
    try {
      const input = syncSchema.parse(req.body);
      if (!req.user.learnerId) return res.status(403).json({ error: 'learner_identity_missing' });

      for (const attempt of input.attempts) {
        if (attempt.learner_id !== req.user.learnerId) {
          return res.status(403).json({ error: 'learner_scope_violation' });
        }
      }

      const client = await pool.connect();
      try {
        await client.query('BEGIN');
        let accepted = 0;
        for (const attempt of input.attempts) {
          const result = await client.query(
            `INSERT INTO attempts(
               client_id,learner_id,question_id,topic_id,correct,timestamp,
               attempt_type,selected_answer,duration_ms,difficulty
             ) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
             ON CONFLICT(client_id) DO NOTHING`,
            [
              attempt.client_id,
              attempt.learner_id,
              attempt.question_id,
              attempt.topic_id,
              attempt.correct,
              new Date(attempt.timestamp),
              attempt.attempt_type,
              attempt.selected_answer ?? null,
              attempt.duration_ms ?? null,
              attempt.difficulty,
            ],
          );
          accepted += result.rowCount || 0;
        }
        await client.query('COMMIT');
        await audit(pool, req.user.sub, 'attempts_synced', { accepted, duplicates: input.attempts.length - accepted });
        res.json({ accepted, duplicates: input.attempts.length - accepted });
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      } finally {
        client.release();
      }
    } catch (error) {
      next(error);
    }
  });


  app.get('/v1/teacher/learners/progress', authenticate, requireRoles('teacher', 'admin'), async (req, res, next) => {
    try {
      if (!req.user.schoolId) return res.status(403).json({ error: 'school_scope_missing' });
      const result = await pool.query(
        `SELECT
           u.learner_id,
           u.display_name,
           u.grade,
           COUNT(a.id)::int AS attempts,
           COALESCE(SUM(CASE WHEN a.correct THEN 1 ELSE 0 END),0)::int AS correct,
           CASE
             WHEN COUNT(a.id) = 0 THEN 0
             ELSE ROUND(AVG(CASE WHEN a.correct THEN 1.0 ELSE 0.0 END)::numeric, 4)
           END AS accuracy
         FROM users u
         LEFT JOIN attempts a
           ON a.learner_id = u.learner_id
          AND a.attempt_type = 'practice'
         WHERE u.school_id = $1
           AND u.role = 'learner'
         GROUP BY u.learner_id, u.display_name, u.grade
         ORDER BY u.display_name`,
        [req.user.schoolId],
      );
      await audit(pool, req.user.sub, 'teacher_progress_viewed', { learnerCount: result.rows.length });
      res.json({ learners: result.rows });
    } catch (error) {
      next(error);
    }
  });

  app.get('/v1/learners/:id/progress', authenticate, async (req, res, next) => {
    try {
      const learnerId = req.params.id;
      const learner = await pool.query(
        'SELECT id, school_id, learner_id, role, display_name, grade FROM users WHERE learner_id = $1',
        [learnerId],
      );
      if (learner.rowCount === 0) return res.status(404).json({ error: 'learner_not_found' });

      const target = learner.rows[0];
      const canViewOwn = req.user.role === 'learner' && req.user.learnerId === learnerId;
      const canViewSchool = ['teacher', 'admin'].includes(req.user.role)
        && req.user.schoolId
        && req.user.schoolId === target.school_id;
      if (!canViewOwn && !canViewSchool) {
        return res.status(403).json({ error: 'learner_scope_violation' });
      }

      const topics = await pool.query(
        `SELECT topic_id,
                COUNT(*)::int AS attempted,
                COALESCE(SUM(CASE WHEN correct THEN 1 ELSE 0 END),0)::int AS correct,
                ROUND(AVG(CASE WHEN correct THEN 1.0 ELSE 0.0 END)::numeric, 4) AS accuracy
         FROM attempts
         WHERE learner_id = $1 AND attempt_type = 'practice'
         GROUP BY topic_id
         ORDER BY topic_id`,
        [learnerId],
      );

      res.json({
        learner: {
          learnerId,
          displayName: target.display_name,
          grade: target.grade,
        },
        topics: topics.rows,
      });
    } catch (error) {
      next(error);
    }
  });

  app.use((error, _req, res, _next) => {
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        error: 'validation_error',
        details: error.issues.map((issue) => ({ path: issue.path, message: issue.message })),
      });
    }
    if (error.message === 'Origin not allowed') {
      return res.status(403).json({ error: 'origin_not_allowed' });
    }
    console.error(error);
    return res.status(500).json({ error: 'internal_server_error' });
  });

  return app;
}

async function start() {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const config = configFromEnv();
  const app = createApp({ pool, config });
  const port = Number(process.env.PORT || 8080);
  const server = app.listen(port, () => {
    console.log(`OfflineAI School API listening on ${port}`);
  });

  const shutdown = async (signal) => {
    console.log(`Received ${signal}; shutting down gracefully.`);
    server.close(async () => {
      await pool.end();
      process.exit(0);
    });
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

if (require.main === module) {
  start().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}

module.exports = { createApp, configFromEnv, hashToken };