/**
 * workos-export-users.ts — Phase 1 of the Supabase Auth → WorkOS AuthKit
 * migration (decision 0002): export auth.users for the WorkOS shadow import.
 *
 * Follows workos.com/docs/migrate/supabase: id, email, encrypted_password
 * (bcrypt), email_confirmed_at → email_verified, name from
 * raw_user_meta_data, and providers joined from auth.identities.
 *
 * Connection rules (DEPLOY.md): DIRECT Postgres connection only —
 * db.<ref>.supabase.co:5432. The pooler is refused. Note the direct host is
 * IPv6-only unless the project has the IPv4 add-on; run this from a host with
 * IPv6 connectivity. Exception: --allow-session-pooler accepts the SESSION
 * pooler (pooler.supabase.com, port 5432 — never the transaction pooler on
 * 6543). The DEPLOY.md pooler ban exists because multi-statement migrations
 * fail there; this script is one read-only SELECT, so the failure mode does
 * not apply. Pass the flag only with founder approval (given 2026-08-27 for
 * the IPv6-blocked machine).
 *
 * The output file contains PASSWORD HASHES. It must never be committed
 * (.gitignore covers *.workos-export*.json), never leave the operator's
 * machine except to the WorkOS import, and should be deleted after import.
 *
 * Usage:
 *   ACCOUNTS_DB=postgresql://postgres:<pwd>@db.<ref>.supabase.co:5432/postgres \
 *     npx tsx backend/scripts/workos-export-users.ts --out /path/to/users.workos-export.json \
 *     [--allow-providers=email]
 *
 * Exits 1 (and writes nothing) if any identity provider falls outside the
 * allowlist — that is the decision-record STOP-AND-ASK gate.
 */

import 'dotenv/config';
import { Client } from 'pg';
import { writeFileSync, chmodSync } from 'fs';

const outFlag = process.argv.indexOf('--out');
const OUT = outFlag !== -1 ? process.argv[outFlag + 1] : null;
const providersArg = process.argv.find((a) => a.startsWith('--allow-providers='));
const ALLOWED_PROVIDERS = new Set(
  (providersArg ? providersArg.split('=')[1] : 'email').split(',').map((p) => p.trim())
);

if (!OUT || !OUT.endsWith('.workos-export.json')) {
  console.error('Usage: --out <path ending in .workos-export.json> is required.');
  console.error('The suffix keeps the file inside the .gitignore rule for export files.');
  process.exit(1);
}

const url = process.env.ACCOUNTS_DB;
if (!url) {
  console.error('ACCOUNTS_DB is not set (direct connection string).');
  process.exit(1);
}
const ALLOW_SESSION_POOLER = process.argv.includes('--allow-session-pooler');
const host = new URL(url).hostname;
const port = new URL(url).port || '5432';
const isDirect = /^db\.[a-z0-9]+\.supabase\.co$/.test(host) && port === '5432';
const isSessionPooler = /\.pooler\.supabase\.com$/.test(host) && port === '5432';
if (!isDirect && !(ALLOW_SESSION_POOLER && isSessionPooler)) {
  console.error(`Refusing to run: ${host}:${port} is not a direct connection.`);
  console.error('Use db.<ref>.supabase.co:5432 — never the pooler (DEPLOY.md).');
  console.error('Session pooler (port 5432) is allowed only with --allow-session-pooler.');
  process.exit(1);
}
if (!isDirect) {
  console.warn(`NOTE: using the SESSION pooler (${host}:${port}) under --allow-session-pooler.`);
}

interface ExportedUser {
  id: string;
  email: string;
  password_hash: string | null;
  email_verified: boolean;
  first_name: string | null;
  last_name: string | null;
  created_at: string;
  providers: string[];
}

function splitName(meta: Record<string, unknown> | null): {
  first_name: string | null;
  last_name: string | null;
} {
  const m = meta ?? {};
  const first = typeof m.first_name === 'string' ? m.first_name : null;
  const last = typeof m.last_name === 'string' ? m.last_name : null;
  if (first || last) return { first_name: first, last_name: last };
  const full = typeof m.full_name === 'string' ? m.full_name : typeof m.name === 'string' ? m.name : null;
  if (!full) return { first_name: null, last_name: null };
  const space = full.indexOf(' ');
  if (space === -1) return { first_name: full, last_name: null };
  return { first_name: full.slice(0, space), last_name: full.slice(space + 1) };
}

async function main() {
  // ssl: rejectUnauthorized false required for Supabase's self-signed cert chain
  // (matches src/lib/db.ts).
  const client = new Client({ connectionString: url, ssl: { rejectUnauthorized: false } });
  await client.connect();
  try {
    const { rows } = await client.query(`
      SELECT u.id, u.email, u.encrypted_password, u.created_at,
             u.email_confirmed_at IS NOT NULL AS email_verified,
             u.raw_user_meta_data,
             u.is_anonymous, u.deleted_at,
             COALESCE(array_agg(i.provider) FILTER (WHERE i.provider IS NOT NULL), '{}') AS providers
      FROM auth.users u
      LEFT JOIN auth.identities i ON i.user_id = u.id
      GROUP BY u.id
      ORDER BY u.created_at
    `);

    const skipped = rows.filter((r) => r.is_anonymous || r.deleted_at !== null || r.email === null);
    const eligible = rows.filter((r) => !skipped.includes(r));

    // STOP-AND-ASK gate: any provider outside the allowlist aborts the export.
    const seenProviders = new Set<string>(eligible.flatMap((r) => r.providers as string[]));
    const unexpected = [...seenProviders].filter((p) => !ALLOWED_PROVIDERS.has(p));
    if (unexpected.length > 0) {
      console.error(`GATE FAILED — unexpected providers found: ${unexpected.join(', ')}`);
      console.error(`Allowlist was: ${[...ALLOWED_PROVIDERS].join(', ')}. Nothing was written.`);
      console.error('Per decision 0002: stop and confirm how these providers migrate.');
      process.exit(1);
    }

    const users: ExportedUser[] = eligible.map((r) => ({
      id: r.id,
      email: r.email,
      password_hash: r.encrypted_password || null,
      email_verified: r.email_verified,
      ...splitName(r.raw_user_meta_data),
      created_at: r.created_at.toISOString(),
      providers: r.providers,
    }));

    const nonBcrypt = users.filter(
      (u) => u.password_hash !== null && !/^\$2[aby]\$/.test(u.password_hash)
    );
    if (nonBcrypt.length > 0) {
      console.error(`GATE FAILED — ${nonBcrypt.length} password hash(es) are not bcrypt.`);
      process.exit(1);
    }

    writeFileSync(OUT!, JSON.stringify({ exported_at: new Date().toISOString(), total: users.length, users }, null, 2));
    chmodSync(OUT!, 0o600);

    console.log(`Exported ${users.length} users to ${OUT}`);
    console.log(`Providers seen: ${[...seenProviders].join(', ') || '(none)'}`);
    console.log(`With password hash: ${users.filter((u) => u.password_hash).length}`);
    console.log(`Email unverified: ${users.filter((u) => !u.email_verified).length}`);
    if (skipped.length > 0) {
      console.log(`Skipped (anonymous/deleted/no email): ${skipped.length}`);
    }
    console.log('');
    console.log('CHECK NOW: compare the total above with the Supabase dashboard user');
    console.log('count. If they differ, STOP — do not import (decision 0002 gate).');
    console.log('This file holds password hashes: do not commit it; delete after import.');
  } finally {
    await client.end();
  }
}

main().catch((err) => {
  console.error('Export failed:', err);
  process.exit(1);
});
