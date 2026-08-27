/**
 * workos-import-users.ts — Phase 1 of the Supabase Auth → WorkOS AuthKit
 * migration (decision 0002): import the export file into a WorkOS environment.
 *
 * Creates each user via POST /user_management/users with:
 *   - password_hash + password_hash_type: 'bcrypt'  (no forced resets)
 *   - external_id: the Supabase auth.users UUID — the ONE join key between
 *     WorkOS identity and internal data (see src/lib/tokenIdentity.ts and
 *     PRIVACY-ARCHITECTURE property A). Do not omit it.
 *   - email_verified carried over, so migrated users are not re-challenged.
 *
 * Idempotent: users whose email already exists in the WorkOS environment are
 * skipped, so re-running after a partial failure (and the Phase 4 delta
 * import) is safe.
 *
 * Safety: refuses a live (sk_live_) API key unless --allow-live is passed —
 * Phase 1 targets the STAGING environment only. The API key comes from the
 * environment, never from a file in this repo.
 *
 * Usage:
 *   WORKOS_API_KEY=sk_test_... npx tsx backend/scripts/workos-import-users.ts \
 *     --in /path/to/users.workos-export.json [--dry-run] [--allow-live]
 */

import { readFileSync } from 'fs';

const API_BASE = process.env.WORKOS_API_BASE ?? 'https://api.workos.com';
const inFlag = process.argv.indexOf('--in');
const IN = inFlag !== -1 ? process.argv[inFlag + 1] : null;
const DRY_RUN = process.argv.includes('--dry-run');
const ALLOW_LIVE = process.argv.includes('--allow-live');

const apiKey = process.env.WORKOS_API_KEY;
if (!IN) {
  console.error('Usage: --in <export file> is required.');
  process.exit(1);
}
if (!apiKey) {
  console.error('WORKOS_API_KEY is not set. Set it in the shell environment only —');
  console.error('never in a committed file (keys belong in the Render dashboard).');
  process.exit(1);
}
if (!ALLOW_LIVE && !apiKey.startsWith('sk_test_')) {
  console.error('Refusing non-staging API key: Phase 1 imports into STAGING only.');
  console.error('Pass --allow-live only for the Phase 4 final delta import.');
  process.exit(1);
}

interface ExportedUser {
  id: string;
  email: string;
  password_hash: string | null;
  email_verified: boolean;
  first_name: string | null;
  last_name: string | null;
}

const maskEmail = (e: string) => e.replace(/^(.).*(@.*)$/, '$1***$2');

async function workos(path: string, init?: RequestInit): Promise<Response> {
  for (let attempt = 0; ; attempt++) {
    const res = await fetch(`${API_BASE}${path}`, {
      ...init,
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        ...init?.headers,
      },
    });
    if (res.status === 429 && attempt < 5) {
      const retryAfter = Number(res.headers.get('retry-after') ?? '2');
      await new Promise((r) => setTimeout(r, Math.max(retryAfter, 1) * 1000));
      continue;
    }
    return res;
  }
}

async function existsByEmail(email: string): Promise<boolean> {
  const res = await workos(`/user_management/users?email=${encodeURIComponent(email)}`);
  if (!res.ok) throw new Error(`lookup failed (${res.status}): ${await res.text()}`);
  const body = (await res.json()) as { data: unknown[] };
  return body.data.length > 0;
}

async function createUser(u: ExportedUser): Promise<void> {
  const payload: Record<string, unknown> = {
    email: u.email,
    email_verified: u.email_verified,
    external_id: u.id,
  };
  if (u.password_hash) {
    payload.password_hash = u.password_hash;
    payload.password_hash_type = 'bcrypt';
  }
  if (u.first_name) payload.first_name = u.first_name;
  if (u.last_name) payload.last_name = u.last_name;

  const res = await workos('/user_management/users', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  if (!res.ok) throw new Error(`create failed (${res.status}): ${await res.text()}`);
}

async function main() {
  const { users } = JSON.parse(readFileSync(IN!, 'utf8')) as { users: ExportedUser[] };
  console.log(`${users.length} users in ${IN}${DRY_RUN ? ' (dry run)' : ''}`);

  let created = 0;
  let skipped = 0;
  const failed: string[] = [];

  for (const u of users) {
    const label = maskEmail(u.email);
    try {
      if (await existsByEmail(u.email)) {
        skipped++;
        console.log(`skip   ${label} — already in WorkOS`);
        continue;
      }
      if (DRY_RUN) {
        created++;
        console.log(`would  ${label} — create (external_id=${u.id})`);
        continue;
      }
      await createUser(u);
      created++;
      console.log(`create ${label}`);
      await new Promise((r) => setTimeout(r, 150)); // stay well under rate limits
    } catch (err) {
      failed.push(label);
      console.error(`FAIL   ${label}: ${err instanceof Error ? err.message : err}`);
    }
  }

  console.log('');
  console.log(`created: ${created}  skipped: ${skipped}  failed: ${failed.length}`);
  if (failed.length > 0) {
    console.error('Some users failed — fix and re-run (existing users are skipped).');
    process.exit(1);
  }
  if (!DRY_RUN) {
    console.log('Verify the count in the WorkOS dashboard, then DELETE the export file.');
  }
}

main().catch((err) => {
  console.error('Import failed:', err);
  process.exit(1);
});
