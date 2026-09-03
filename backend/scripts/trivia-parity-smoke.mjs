#!/usr/bin/env node
/**
 * Civic Trivia Championships (CTC) — engine fold-in parity smoke test.
 *
 * Engine consolidation, Phase 1. Proves the 49 CTC endpoints folded into the engine
 * respond identically to the still-running standalone `civic-trivia-backend` service.
 *
 * ── What it does ──────────────────────────────────────────────────────────────
 * One row per CTC endpoint (method, CTC-native path, auth mode, representative
 * request, expected status). It hits each on the OLD host and on the ENGINE and
 * diffs the status codes. The engine serves the same paths under a `/ctc` prefix
 * (the temporary cutover alias), so the engine URL is simply OLD_PATH prefixed
 * with `/ctc`:
 *     old:    https://civic-trivia-backend.onrender.com/api/game/collections
 *     engine: https://ev-accounts-api.onrender.com/ctc/api/game/collections
 *     old:    https://civic-trivia-backend.onrender.com/health/live
 *     engine: https://ev-accounts-api.onrender.com/ctc/health/live
 *
 * ── Why it is safe to run against production ──────────────────────────────────
 * Every request is sent UNAUTHENTICATED. 40 of the 49 endpoints (all of profile,
 * feedback and admin) are gated by requireAuth/requireAdmin at the router level, so
 * an unauthenticated call — including every POST/DELETE/PATCH — is rejected with 401
 * BEFORE the handler runs. No writes happen. The 9 public endpoints are reads, one
 * bogus-id read, one invalid-body POST (rejected), and one anonymous POST /session
 * that creates a throwaway, self-expiring game session identical to what any
 * anonymous player creates — no persistent data, no XP for anonymous.
 *
 * Parity here means "the endpoint exists at the right path and enforces the same
 * gate / returns the same status for the same request". The handler bodies are the
 * same code ported byte-for-byte, and authenticated end-to-end behaviour is proven
 * separately by the CTC frontend during the 2-week parallel run.
 *
 * ── Usage ─────────────────────────────────────────────────────────────────────
 *   node scripts/trivia-parity-smoke.mjs --old <oldBase>                # baseline only
 *   node scripts/trivia-parity-smoke.mjs --engine <engineBase>          # engine only
 *   node scripts/trivia-parity-smoke.mjs --old <oldBase> --engine <eng> # diff (49/49)
 *
 *   Defaults: --old  https://civic-trivia-backend.onrender.com
 *   (no engine default — the engine URL is supplied once the fold-in is deployed.)
 *
 *   --json   emit machine-readable JSON instead of the table
 *   --timeout <ms>   per-request timeout (default 20000)
 */

const AUTH = {
  PUBLIC: 'public', // no auth
  OPTIONAL: 'optionalAuth', // works signed-in or anonymous
  AUTH: 'requireAuth', // 401 without a token
  ADMIN: 'requireAuth+requireAdmin', // 401 without a token
  SUPERADMIN: 'requireAuth+requireSuperAdmin', // 401 without a token
};

// path: CTC-native (old-host) path. Engine path = '/ctc' + path.
// body: sent as JSON on non-GET where useful. :params use a smoke placeholder; for
// the auth-gated routes the value never matters (401 fires first).
const ENDPOINTS = [
  // health (mount /health — NOT under /api)
  { method: 'GET', path: '/health/live', auth: AUTH.PUBLIC },
  { method: 'GET', path: '/health', auth: AUTH.PUBLIC },
  { method: 'GET', path: '/health/collections', auth: AUTH.PUBLIC },

  // game (mount /api/game)
  { method: 'GET', path: '/api/game/collections', auth: AUTH.PUBLIC },
  { method: 'GET', path: '/api/game/questions', auth: AUTH.PUBLIC },
  { method: 'POST', path: '/api/game/session', auth: AUTH.OPTIONAL, body: {}, note: 'anonymous ephemeral session' },
  { method: 'POST', path: '/api/game/answer', auth: AUTH.PUBLIC, body: {}, note: 'invalid body → rejected, non-mutating' },
  { method: 'GET', path: '/api/game/results/smoke-nonexistent-session', auth: AUTH.PUBLIC, note: 'bogus id → not found' },

  // profile (mount /api/users/profile, router.use(requireAuth))
  { method: 'GET', path: '/api/users/profile/identity', auth: AUTH.AUTH },
  { method: 'GET', path: '/api/users/profile/admin-status', auth: AUTH.AUTH },
  { method: 'GET', path: '/api/users/profile', auth: AUTH.AUTH },
  { method: 'PATCH', path: '/api/users/profile/settings', auth: AUTH.AUTH, body: {} },
  { method: 'GET', path: '/api/users/profile/xp/history', auth: AUTH.AUTH },

  // feedback (mount /api/feedback, per-route requireAuth)
  { method: 'POST', path: '/api/feedback/flag', auth: AUTH.AUTH, body: {} },
  { method: 'DELETE', path: '/api/feedback/flag/smoke-qid', auth: AUTH.AUTH },
  { method: 'PATCH', path: '/api/feedback/flags/batch', auth: AUTH.AUTH, body: {} },

  // leaderboard (mount /api/leaderboard) — public
  { method: 'GET', path: '/api/leaderboard', auth: AUTH.PUBLIC },

  // admin (mount /api/admin, router.use(requireAuth, requireAdmin))
  { method: 'GET', path: '/api/admin/questions', auth: AUTH.ADMIN },
  { method: 'POST', path: '/api/admin/questions/1/renew', auth: AUTH.ADMIN, body: {} },
  { method: 'POST', path: '/api/admin/questions/1/archive', auth: AUTH.ADMIN, body: {} },
  { method: 'POST', path: '/api/admin/questions/by-external-id/smoke/archive', auth: AUTH.ADMIN, body: {} },
  { method: 'POST', path: '/api/admin/questions/1/restore', auth: AUTH.ADMIN, body: {} },
  { method: 'PUT', path: '/api/admin/questions/1', auth: AUTH.ADMIN, body: {} },
  { method: 'GET', path: '/api/admin/questions/explore', auth: AUTH.ADMIN },
  { method: 'GET', path: '/api/admin/questions/1/detail', auth: AUTH.ADMIN },
  { method: 'GET', path: '/api/admin/collections', auth: AUTH.ADMIN },
  { method: 'GET', path: '/api/admin/collections/health', auth: AUTH.ADMIN },
  { method: 'GET', path: '/api/admin/flags', auth: AUTH.ADMIN },
  { method: 'GET', path: '/api/admin/flags/1/detail', auth: AUTH.ADMIN },
  { method: 'PATCH', path: '/api/admin/flags/1/archive', auth: AUTH.ADMIN, body: {} },
  { method: 'POST', path: '/api/admin/flags/1/dismiss', auth: AUTH.ADMIN, body: {} },
  { method: 'PATCH', path: '/api/admin/flags/1/restore', auth: AUTH.ADMIN, body: {} },
  { method: 'GET', path: '/api/admin/duplicates', auth: AUTH.ADMIN },
  { method: 'POST', path: '/api/admin/duplicates/resolve', auth: AUTH.ADMIN, body: {} },
  { method: 'POST', path: '/api/admin/duplicates/auto-resolve', auth: AUTH.ADMIN, body: {} },
  { method: 'POST', path: '/api/admin/duplicates/undo', auth: AUTH.ADMIN, body: {} },
  { method: 'GET', path: '/api/admin/duplicates/summary', auth: AUTH.ADMIN },
  { method: 'GET', path: '/api/admin/election-races/classified', auth: AUTH.ADMIN },
  { method: 'GET', path: '/api/admin/election-races', auth: AUTH.ADMIN },
  { method: 'POST', path: '/api/admin/election-races', auth: AUTH.ADMIN, body: {} },
  { method: 'POST', path: '/api/admin/election-races/1/generate', auth: AUTH.ADMIN, body: {} },
  { method: 'GET', path: '/api/admin/election-races/1/question-count', auth: AUTH.ADMIN },
  { method: 'POST', path: '/api/admin/election-races/1/enter-result', auth: AUTH.ADMIN, body: {} },
  { method: 'POST', path: '/api/admin/election-races/1/regenerate', auth: AUTH.ADMIN, body: {} },
  { method: 'PUT', path: '/api/admin/election-races/1', auth: AUTH.ADMIN, body: {} },
  { method: 'DELETE', path: '/api/admin/election-races/1', auth: AUTH.ADMIN },
  { method: 'GET', path: '/api/admin/admins', auth: AUTH.SUPERADMIN },
  { method: 'POST', path: '/api/admin/admins', auth: AUTH.SUPERADMIN, body: {} },
  { method: 'DELETE', path: '/api/admin/admins/smoke-user', auth: AUTH.SUPERADMIN },
];

function parseArgs(argv) {
  const args = { old: 'https://civic-trivia-backend.onrender.com', engine: null, json: false, timeout: 20000 };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--old') args.old = argv[++i];
    else if (a === '--engine') args.engine = argv[++i];
    else if (a === '--json') args.json = true;
    else if (a === '--timeout') args.timeout = parseInt(argv[++i], 10);
    else if (a === '--help' || a === '-h') { printHelp(); process.exit(0); }
  }
  return args;
}

function printHelp() {
  console.log(`Usage:
  node scripts/trivia-parity-smoke.mjs --old <oldBase> [--engine <engineBase>] [--json] [--timeout ms]

  --old     old civic-trivia-backend base (default https://civic-trivia-backend.onrender.com)
  --engine  merged engine base (its paths are served under /ctc). Omit to capture a baseline.
  --json    machine-readable output
  --timeout per-request timeout ms (default 20000)`);
}

const stripSlash = (u) => (u || '').replace(/\/+$/, '');

async function hit(base, prefix, ep, timeoutMs) {
  const url = stripSlash(base) + prefix + ep.path;
  const controller = new AbortController();
  const t = setTimeout(() => controller.abort(), timeoutMs);
  const init = {
    method: ep.method,
    headers: { Accept: 'application/json' },
    signal: controller.signal,
  };
  if (ep.body !== undefined && ep.method !== 'GET' && ep.method !== 'DELETE') {
    init.headers['Content-Type'] = 'application/json';
    init.body = JSON.stringify(ep.body);
  }
  try {
    const res = await fetch(url, init);
    return { status: res.status, url };
  } catch (err) {
    return { status: err.name === 'AbortError' ? 'TIMEOUT' : `ERR:${err.code || err.name}`, url };
  } finally {
    clearTimeout(t);
  }
}

async function main() {
  const args = parseArgs(process.argv);
  const doOld = !!args.old;
  const doEngine = !!args.engine;
  const rows = [];

  for (const ep of ENDPOINTS) {
    const oldRes = doOld ? await hit(args.old, '', ep, args.timeout) : null;
    const engRes = doEngine ? await hit(args.engine, '/ctc', ep, args.timeout) : null;
    let verdict = '—';
    if (doOld && doEngine) {
      verdict = String(oldRes.status) === String(engRes.status) ? 'PASS' : 'FAIL';
    }
    rows.push({
      method: ep.method,
      path: ep.path,
      auth: ep.auth,
      note: ep.note || '',
      old: oldRes ? oldRes.status : null,
      engine: engRes ? engRes.status : null,
      verdict,
    });
  }

  if (args.json) {
    console.log(JSON.stringify({ old: args.old, engine: args.engine, rows }, null, 2));
    return;
  }

  // table
  const mw = Math.max(...rows.map((r) => r.method.length), 6);
  const pw = Math.max(...rows.map((r) => r.path.length), 4);
  const aw = Math.max(...rows.map((r) => r.auth.length), 4);
  const head =
    'METHOD'.padEnd(mw) + '  ' + 'PATH'.padEnd(pw) + '  ' + 'AUTH'.padEnd(aw) +
    (doOld ? '  OLD' : '') + (doEngine ? '  ENGINE' : '') + (doOld && doEngine ? '  VERDICT' : '');
  console.log(head);
  console.log('-'.repeat(head.length));
  for (const r of rows) {
    let line = r.method.padEnd(mw) + '  ' + r.path.padEnd(pw) + '  ' + r.auth.padEnd(aw);
    if (doOld) line += '  ' + String(r.old).padStart(3);
    if (doEngine) line += '  ' + String(r.engine).padStart(6);
    if (doOld && doEngine) line += '  ' + (r.verdict === 'PASS' ? 'PASS' : `>>> ${r.verdict}`);
    console.log(line);
  }

  console.log('');
  if (doOld && doEngine) {
    const pass = rows.filter((r) => r.verdict === 'PASS').length;
    console.log(`Parity: ${pass}/${rows.length} endpoints match between old host and engine.`);
    const fails = rows.filter((r) => r.verdict !== 'PASS');
    if (fails.length) {
      console.log(`\nMismatches (${fails.length}):`);
      for (const r of fails) console.log(`  ${r.method} ${r.path}  old=${r.old} engine=${r.engine}`);
      process.exitCode = 1;
    } else {
      console.log('ALL GREEN — 49/49.');
    }
  } else {
    const which = doEngine ? 'engine' : 'old host';
    console.log(`Captured ${rows.length} endpoint statuses from the ${which}. Supply both --old and --engine to diff.`);
  }
}

main().catch((e) => { console.error(e); process.exit(2); });
