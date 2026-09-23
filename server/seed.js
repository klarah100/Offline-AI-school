require('dotenv').config();
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const { randomUUID } = require('node:crypto');

async function main() {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  try {
    const username = process.env.SEED_ADMIN_USERNAME;
    const password = process.env.SEED_ADMIN_PASSWORD;
    const name = process.env.SEED_ADMIN_NAME || 'OfflineAI Administrator';
    const schoolCode = process.env.SEED_SCHOOL_CODE;
    const schoolName = process.env.SEED_SCHOOL_NAME;
    const organizationId = process.env.SEED_ORGANIZATION_ID || randomUUID();
    const organizationName = process.env.SEED_ORGANIZATION_NAME || schoolName || 'OfflineAI School Organisation';
    const organizationType = process.env.SEED_ORGANIZATION_TYPE || 'school_group';
    const billingEmail = process.env.SEED_BILLING_EMAIL || null;

    if (!username || !password || !schoolCode || !schoolName) {
      throw new Error('Set SEED_ADMIN_USERNAME, SEED_ADMIN_PASSWORD, SEED_ADMIN_NAME, SEED_SCHOOL_CODE and SEED_SCHOOL_NAME.');
    }

    const passwordHash = await bcrypt.hash(password, 12);

    await pool.query(
      `INSERT INTO organizations(id, name, type, billing_email)
       VALUES($1,$2,$3,$4)
       ON CONFLICT(id) DO UPDATE SET
         name=EXCLUDED.name,
         type=EXCLUDED.type,
         billing_email=EXCLUDED.billing_email`,
      [organizationId, organizationName, organizationType, billingEmail],
    );

    const schoolId = randomUUID();
    const existingSchool = await pool.query('SELECT id FROM schools WHERE code = $1', [schoolCode]);
    const finalSchoolId = existingSchool.rows[0]?.id || schoolId;

    await pool.query(
      `INSERT INTO schools(id, code, name, organization_id)
       VALUES($1,$2,$3,$4)
       ON CONFLICT(code) DO UPDATE SET
         name=EXCLUDED.name,
         organization_id=EXCLUDED.organization_id`,
      [finalSchoolId, schoolCode, schoolName, organizationId],
    );

    const userId = randomUUID();
    await pool.query(
      `INSERT INTO users(id, username, password_hash, display_name, role, school_id, organization_id)
       VALUES($1,$2,$3,$4,'admin',$5,$6)
       ON CONFLICT(username) DO UPDATE SET
         password_hash=EXCLUDED.password_hash,
         display_name=EXCLUDED.display_name,
         school_id=EXCLUDED.school_id,
         organization_id=EXCLUDED.organization_id,
         role='admin'`,
      [userId, username, passwordHash, name, finalSchoolId, organizationId],
    );

    console.log('Organisation, school and admin seed completed.');
  } finally {
    await pool.end();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
