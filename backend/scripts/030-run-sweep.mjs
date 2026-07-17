#!/usr/bin/env node
/**
 * 030-run-sweep.mjs — one-line Render sweep session.
 *
 * Creates a one-off Render Job running the FEC completeness sweep, then polls its status
 * and live-tails its logs until it finishes. No dependencies (uses Node's global fetch),
 * runs LOCALLY (it drives Render's API from your machine — it does NOT run on Render).
 *
 * Reads RENDER_API_KEY from backend/.env (located relative to this file, so cwd doesn't
 * matter). Bypasses the Cloudflare POST block because it talks to api.render.com, not
 * your own domain.
 *
 * Usage (from anywhere):
 *   node backend/scripts/030-run-sweep.mjs [pairs] [maxMinutes]
 *     pairs       max (source,cycle) pairs this session   (default 50)
 *     maxMinutes  wall-clock budget, hard-stops mid-pair  (default 55)
 *
 *   node backend/scripts/030-run-sweep.mjs --audit         # run the truncation audit instead
 *   node backend/scripts/030-run-sweep.mjs --backfill      # run the agg backfill instead
 *   node backend/scripts/030-run-sweep.mjs --cmd "npx tsx scripts/foo.ts"   # arbitrary command
 *   node backend/scripts/030-run-sweep.mjs --dry [args]    # show what it WOULD run + test auth, create nothing
 *
 * Examples:
 *   node backend/scripts/030-run-sweep.mjs            # 50 pairs, 55-min cap
 *   node backend/scripts/030-run-sweep.mjs 200 240    # 200 pairs, 4-hour cap
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const SERVICE = 'srv-d6h1pahr0fns739kfjfg';
const OWNER = 'tea-d69tn76mcj7s738vmt10';
const API = 'https://api.render.com/v1';
const POLL_MS = 12_000;
const HEARTBEAT_MS = 60_000;

const scriptDir = path.dirname(fileURLToPath(import.meta.url));   // .../backend/scripts
const ENV_PATH = path.join(scriptDir, '..', '.env');             // .../backend/.env

function readKey() {
  let txt;
  try { txt = fs.readFileSync(ENV_PATH, 'utf8'); }
  catch { throw new Error(`cannot read ${ENV_PATH} — run from the ev-accounts checkout`); }
  const line = txt.split(/\r?\n/).find((l) => l.startsWith('RENDER_API_KEY='));
  if (!line) throw new Error(`RENDER_API_KEY not found in ${ENV_PATH}`);
  return line.slice('RENDER_API_KEY='.length).replace(/^["']|["']$/g, '').trim();
}

function buildStartCommand(argv) {
  const cmdIdx = argv.indexOf('--cmd');
  if (cmdIdx >= 0) return argv[cmdIdx + 1] ?? '';
  if (argv.includes('--audit')) return 'npx tsx scripts/030-find-truncated-fec-pairs.ts';
  if (argv.includes('--backfill')) return 'npx tsx scripts/030-backfill-summary-agg.ts 100000 25';
  const pos = argv.filter((a) => !a.startsWith('--'));
  const pairs = pos[0] ?? '50';
  const maxMin = pos[1] ?? '55';
  return `npx tsx scripts/030-completeness-sweep.ts ${pairs} ${maxMin}`;
}

const KEY = readKey();
const H = { Authorization: `Bearer ${KEY}`, 'Content-Type': 'application/json' };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const iso = (d) => new Date(d).toISOString();
const nowIso = () => new Date().toISOString();

async function api(method, url, body) {
  const res = await fetch(url, { method, headers: H, body: body ? JSON.stringify(body) : undefined });
  const text = await res.text();
  let json; try { json = JSON.parse(text); } catch { json = { raw: text }; }
  if (!res.ok) throw new Error(`${method} ${url} -> ${res.status}: ${text.slice(0, 200)}`);
  return json;
}

async function main() {
  const argv = process.argv.slice(2);
  const dry = argv.includes('--dry');
  const startCommand = buildStartCommand(argv.filter((a) => a !== '--dry'));

  if (dry) {
    console.log(`[dry] key loaded from ${ENV_PATH} (len ${KEY.length})`);
    console.log(`[dry] would create job with startCommand:\n        ${startCommand}`);
    const svc = await api('GET', `${API}/services/${SERVICE}`);
    console.log(`[dry] auth OK — service "${svc.name}" (${svc.type}), rootDir=${JSON.stringify(svc.rootDir)}`);
    console.log('[dry] no job created.');
    return;
  }

  console.log(`▶ creating one-off Render job\n    ${startCommand}`);
  const job = await api('POST', `${API}/services/${SERVICE}/jobs`, { startCommand });
  console.log(`  job id : ${job.id}`);
  console.log(`  started: ${job.createdAt}\n  ── live logs ─────────────────────────────`);

  const startTime = iso(job.createdAt);
  const seen = new Set();
  const terminal = new Set(['succeeded', 'failed', 'canceled']);
  let status = job.status;
  let lastOutput = Date.now();
  const t0 = Date.now();

  while (!terminal.has(status)) {
    await sleep(POLL_MS);

    // Tail new log lines
    try {
      const { logs = [] } = await api('GET',
        `${API}/logs?ownerId=${OWNER}&resource=${job.id}&startTime=${startTime}&endTime=${nowIso()}&limit=300`);
      logs.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
      for (const l of logs) {
        const k = `${l.timestamp}|${l.message}`;
        if (seen.has(k)) continue;
        seen.add(k);
        const m = (l.message || '').replace(/\s+$/, '');
        if (m && !/Fetching committee/.test(m)) { console.log(m); lastOutput = Date.now(); }
      }
    } catch { /* transient log-api hiccup; keep polling */ }

    // Status
    try { status = (await api('GET', `${API}/services/${SERVICE}/jobs/${job.id}`)).status; } catch { /* keep polling */ }

    // Heartbeat during long silent fetches (mega-pairs emit no per-page logs)
    if (!terminal.has(status) && Date.now() - lastOutput > HEARTBEAT_MS) {
      console.log(`    … running (${((Date.now() - t0) / 60000).toFixed(1)}m, status=${status})`);
      lastOutput = Date.now();
    }
  }

  console.log(`  ──────────────────────────────────────────\n■ job ${job.id} finished: ${status}`);
  process.exit(status === 'succeeded' ? 0 : 1);
}

main().catch((e) => { console.error('ERROR:', e.message); process.exit(1); });
