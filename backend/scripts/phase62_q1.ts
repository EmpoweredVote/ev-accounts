import { Client } from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
  const client = new Client({ connectionString: process.env.DATABASE_URL });
  await client.connect();

  const migs = await client.query("SELECT version FROM supabase_migrations.schema_migrations ORDER BY version::integer DESC LIMIT 30");
  console.log('MIGRATIONS:');
  migs.rows.forEach((r: any) => process.stdout.write(r.version + ' '));
  console.log('');

  const m171 = await client.query("SELECT version FROM supabase_migrations.schema_migrations WHERE version='171'");
  const m182 = await client.query("SELECT version FROM supabase_migrations.schema_migrations WHERE version='182'");
  console.log('171 applied:', m171.rows.length > 0);
  console.log('182 applied:', m182.rows.length > 0);

  await client.end();
}
main().catch(e => { console.error(e.message); process.exit(1); });
