'use strict';

const crypto = require('node:crypto');
const fs = require('node:fs/promises');
const path = require('node:path');
const mysql = require('mysql2/promise');

const envPath = path.join(__dirname, '.env');
const tempEnvPath = path.join(__dirname, '.env.setup-tmp');
const appPassword = crypto.randomBytes(32).toString('hex');
const jwtSecret = crypto.randomBytes(32).toString('hex');

async function main() {
  if (!process.env.MYSQL_ROOT_PASSWORD) {
    throw new Error('Missing MySQL root password in the current process');
  }

  try {
    await fs.access(envPath);
    throw new Error('backend-mysql/.env already exists; refusing to overwrite it');
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
  }

  const envContents = [
    'HOST=127.0.0.1',
    'PORT=3000',
    'DB_HOST=127.0.0.1',
    'DB_PORT=3306',
    'DB_NAME=felipe6_local',
    'DB_USER=felipe6_app',
    `DB_PASSWORD=${appPassword}`,
    `JWT_SECRET=${jwtSecret}`,
    'CORS_ORIGINS=http://localhost:5000',
    '',
  ].join('\n');

  let rootConnection;
  let appConnection;
  try {
    await fs.writeFile(tempEnvPath, envContents, { flag: 'wx' });
    rootConnection = await mysql.createConnection({
      host: '127.0.0.1',
      port: 3306,
      user: 'root',
      password: process.env.MYSQL_ROOT_PASSWORD,
    });

    const [schemas] = await rootConnection.execute(
      `SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA
       WHERE SCHEMA_NAME = 'felipe6_local'`,
    );
    if (schemas.length === 0) {
      throw new Error('Database felipe6_local does not exist; execute schema.sql first');
    }

    const [tables] = await rootConnection.execute(
      `SELECT COUNT(*) AS table_count FROM INFORMATION_SCHEMA.TABLES
       WHERE TABLE_SCHEMA = 'felipe6_local'`,
    );
    if (tables[0].table_count === 0) {
      throw new Error('Database felipe6_local has no tables; execute schema.sql first');
    }

    await rootConnection.query(
      `CREATE USER IF NOT EXISTS 'felipe6_app'@'127.0.0.1'
       IDENTIFIED BY '${appPassword}'`,
    );
    await rootConnection.query(
      `ALTER USER 'felipe6_app'@'127.0.0.1'
       IDENTIFIED BY '${appPassword}'`,
    );
    await rootConnection.query(
      `GRANT SELECT, INSERT, UPDATE, DELETE ON felipe6_local.*
       TO 'felipe6_app'@'127.0.0.1'`,
    );

    appConnection = await mysql.createConnection({
      host: '127.0.0.1',
      port: 3306,
      user: 'felipe6_app',
      password: appPassword,
      database: 'felipe6_local',
    });
    const [rows] = await appConnection.execute('SELECT 1 AS connected');
    if (rows[0].connected !== 1) throw new Error('Database account verification failed');

    await fs.rename(tempEnvPath, envPath);
    console.log(`MySQL connection verified; ${tables[0].table_count} tables found.`);
    console.log('Generated backend-mysql/.env and rotated the felipe6_app password.');
  } catch (error) {
    await fs.rm(tempEnvPath, { force: true });
    throw error;
  } finally {
    await appConnection?.end();
    await rootConnection?.end();
  }
}

main().catch((error) => {
  console.error(`Local setup failed: ${error.message}`);
  process.exitCode = 1;
});