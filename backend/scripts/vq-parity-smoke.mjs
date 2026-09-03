#!/usr/bin/env node
/**
 * Validation Quests (VQ) — engine fold-in parity smoke test.
 *
 * Engine consolidation, Phase 2. Proves the 33 VQ endpoints folded into the engine
 * respond identically to the still-running standalone `empowered-validation-quests`
 * service. The engine serves the same paths under a `/vq` prefix (the cutover alias),
 * so the engine URL is the old path prefixed with `/vq`:
 *     old:    https://empowered-validation-quests.onrender.com/api/quests/123
 *     engine: https://ev-accounts-api.onrender.com/vq/api/quests/123
 *
 * Safe against production: every request is UNAUTHENTICATED. 31 of the 33 endpoints are
 * gated (requireAuth / requireStaff / requireConnected / requireAiApiKey) and reject with
 * 401 before the handler runs — so every POST/PATCH is a no-op. The 2 public reads are a
 * health check and a bogus-id quest lookup.
 *
 * Usage:
 *   node scripts/vq-parity-smoke.mjs --old <oldBase>                # baseline
 *   node scripts/vq-parity-smoke.mjs --old <oldBase> --engine <eng> # diff (33/33)
 *   Defaults: --old https://empowered-validation-quests.onrender.com
 *   --json | --timeout <ms>
 */

const A = {
  PUBLIC: 'public',
  AUTH: 'requireAuth(+tier)',
  STAFF: 'requireAuth+requireStaff',
  APIKEY: 'requireAiApiKey (x-api-key)',
};

// path: VQ-native (old-host) path. Engine path = '/vq' + path.
const ENDPOINTS = [
  { method: 'GET', path: '/api/health', auth: A.PUBLIC },

  { method: 'POST', path: '/api/quests', auth: A.AUTH, body: {} },
  { method: 'GET', path: '/api/quests/smoke-nonexistent', auth: A.PUBLIC, note: 'bogus id' },
  { method: 'GET', path: '/api/quests/smoke-nonexistent/transparency', auth: A.AUTH },

  { method: 'POST', path: '/api/submissions', auth: A.AUTH, body: {} },
  { method: 'POST', path: '/api/submissions/ai', auth: A.APIKEY, body: {} },

  { method: 'GET', path: '/api/feed', auth: A.AUTH },
  { method: 'POST', path: '/api/feed/initialize', auth: A.AUTH, body: {} },
  { method: 'GET', path: '/api/feed/bounty', auth: A.AUTH },

  { method: 'GET', path: '/api/history', auth: A.AUTH },
  { method: 'GET', path: '/api/history/users/smoke-user', auth: A.AUTH },

  { method: 'POST', path: '/api/contests', auth: A.AUTH, body: {} },

  { method: 'GET', path: '/api/notifications', auth: A.AUTH },
  { method: 'PATCH', path: '/api/notifications/read', auth: A.AUTH, body: {} },
  { method: 'GET', path: '/api/notifications/preferences', auth: A.AUTH },
  { method: 'PATCH', path: '/api/notifications/preferences', auth: A.AUTH, body: {} },

  { method: 'GET', path: '/api/profile', auth: A.AUTH },

  { method: 'GET', path: '/api/admin/jurisdictions', auth: A.STAFF },
  { method: 'GET', path: '/api/admin/quests', auth: A.STAFF },
  { method: 'PATCH', path: '/api/admin/quests/1/pin', auth: A.STAFF, body: {} },
  { method: 'PATCH', path: '/api/admin/quests/1/unpin', auth: A.STAFF, body: {} },
  { method: 'POST', path: '/api/admin/quests', auth: A.STAFF, body: {} },
  { method: 'GET', path: '/api/admin/quests/1/submissions', auth: A.STAFF },
  { method: 'POST', path: '/api/admin/users/smoke-user/age-waiver', auth: A.STAFF, body: {} },
  { method: 'POST', path: '/api/admin/users/smoke-user/suspend', auth: A.STAFF, body: {} },
  { method: 'POST', path: '/api/admin/users/smoke-user/unsuspend', auth: A.STAFF, body: {} },
  { method: 'GET', path: '/api/admin/ai-agents', auth: A.STAFF },
  { method: 'PATCH', path: '/api/admin/quests/1/priority', auth: A.STAFF, body: {} },
  { method: 'GET', path: '/api/admin/quests/promotions', auth: A.STAFF },
  { method: 'POST', path: '/api/admin/quests/1/revert', auth: A.STAFF, body: {} },
  { method: 'POST', path: '/api/admin/quests/bulk', auth: A.STAFF, body: {} },
  { method: 'POST', path: '/api/admin/quests/1/override', auth: A.STAFF, body: {} },
  { method: 'POST', path: '/api/admin/contests/1/resolve', auth: A.STAFF, body: {} },
];

function parseArgs(argv) {
  const a = { old: 'https://empowered-validation-quests.onrender.com', engine: null, json: false, timeout: 20000 };
  for (let i = 2; i < argv.length; i++) {
    const x = argv[i];
    if (x === '--old') a.old = argv[++i];
    else if (x === '--engine') a.engine = argv[++i];
    else if (x === '--json') a.json = true;
    else if (x === '--timeout') a.timeout = parseInt(argv[++i], 10);
  }
  return a;
}
const stripSlash = (u) => (u || '').replace(/\/+$/, '');

async function hit(base, prefix, ep, timeoutMs) {
  const url = stripSlash(base) + prefix + ep.path;
  const c = new AbortController();
  const t = setTimeout(() => c.abort(), timeoutMs);
  const init = { method: ep.method, headers: { Accept: 'application/json' }, signal: c.signal };
  if (ep.body !== undefined && ep.method !== 'GET' && ep.method !== 'DELETE') {
    init.headers['Content-Type'] = 'application/json';
    init.body = JSON.stringify(ep.body);
  }
  try {
    const r = await fetch(url, init);
    return r.status;
  } catch (e) {
    return e.name === 'AbortError' ? 'TIMEOUT' : `ERR:${e.code || e.name}`;
  } finally {
    clearTimeout(t);
  }
}

async function main() {
  const args = parseArgs(process.argv);
  const doEng = !!args.engine;
  const rows = [];
  for (const ep of ENDPOINTS) {
    const o = await hit(args.old, '', ep, args.timeout);
    const e = doEng ? await hit(args.engine, '/vq', ep, args.timeout) : null;
    rows.push({ ...ep, old: o, engine: e, verdict: doEng ? (String(o) === String(e) ? 'PASS' : 'FAIL') : '—' });
  }
  if (args.json) { console.log(JSON.stringify(rows, null, 2)); return; }
  const pw = Math.max(...rows.map((r) => r.path.length), 4);
  const aw = Math.max(...rows.map((r) => r.auth.length), 4);
  console.log('METHOD'.padEnd(6) + '  ' + 'PATH'.padEnd(pw) + '  ' + 'AUTH'.padEnd(aw) + '  OLD' + (doEng ? '  ENGINE  VERDICT' : ''));
  console.log('-'.repeat(pw + aw + (doEng ? 30 : 15)));
  for (const r of rows) {
    let l = r.method.padEnd(6) + '  ' + r.path.padEnd(pw) + '  ' + r.auth.padEnd(aw) + '  ' + String(r.old).padStart(3);
    if (doEng) l += '  ' + String(r.engine).padStart(6) + '  ' + (r.verdict === 'PASS' ? 'PASS' : '>>> FAIL');
    console.log(l);
  }
  console.log('');
  if (doEng) {
    const pass = rows.filter((r) => r.verdict === 'PASS').length;
    console.log(`Parity: ${pass}/${rows.length} endpoints match between old host and engine.`);
    const fails = rows.filter((r) => r.verdict !== 'PASS');
    if (fails.length) { console.log(`\nMismatches (${fails.length}):`); for (const r of fails) console.log(`  ${r.method} ${r.path}  old=${r.old} engine=${r.engine}`); process.exitCode = 1; }
    else console.log(`ALL GREEN — ${rows.length}/${rows.length}.`);
  } else {
    console.log(`Captured ${rows.length} endpoint statuses from the old host. Add --engine to diff.`);
  }
}
main().catch((e) => { console.error(e); process.exit(2); });
