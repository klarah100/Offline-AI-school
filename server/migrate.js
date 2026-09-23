require('dotenv').config();
const { Pool } = require('pg');
const fs = require('node:fs');
const path = require('node:path');

async function main() {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  try {
    const schema = fs.readFileSync(path.join(__dirname, 'migrations', '001_initial.sql'), 'utf8');
    await pool.query(schema);
    console.log('Database schema is ready.');
  } finally {
    await pool.end();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
