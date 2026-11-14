/**
 * datasetQuery.ts — answer LegiScan API calls from bulk datasets already on disk.
 *
 * Set LEGISCAN_DATASETS=<dir> and `legiscanQuery` (client.ts) reads the datasets instead of calling
 * the API: no query is spent and the monthly counter is not touched. <dir> holds one folder per
 * dataset, named <ST>-<session_id>, each laid out as LegiScan's zip unpacks:
 *   <ST>-<session_id>/<ST>/<session folder>/{bill,vote,people}/<…>.json
 * LEGISCAN_DATASET_STATES=TN,WA (optional) limits the folders read.
 *
 * Why (gun-policy Stage 5, Tennessee, 2026-11-14): the key reached its November cap, and the runner
 * ruled "Use on-file roll calls". The bulk files carry the same bill, roll-call and person objects
 * as getBill, getRollCall and getPerson, so the Stage 5 roll-call match, evidence lines and verifier
 * read them unchanged. A dataset is a snapshot: a vote taken after it was pulled is not there.
 *
 * Answers getSessionList, getMasterListRaw, getBill, getRollCall and getSessionPeople. Any other
 * operation throws, never falling back to the API.
 */
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

/* eslint-disable @typescript-eslint/no-explicit-any */
type Json = any;

interface Session {
  state: string;
  dir: string;
  meta: Json;
  /** bill_id → bill file, built on first use. */
  bills?: Map<number, string>;
}

const roots = new Map<string, Session[]>();

const readJson = (p: string): Json => JSON.parse(readFileSync(p, 'utf8'));

export function datasetSessions(root: string, states = process.env.LEGISCAN_DATASET_STATES): Session[] {
  const key = `${root}|${states ?? ''}`;
  const hit = roots.get(key);
  if (hit) return hit;
  const only = states ? new Set(states.split(',').map((s) => s.trim().toUpperCase()).filter(Boolean)) : null;
  const out: Session[] = [];
  for (const d of readdirSync(root).sort()) {
    const m = /^([A-Z]{2})-(\d+)$/.exec(d);
    if (!m || (only && !only.has(m[1]))) continue;
    const stDir = join(root, d, m[1]);
    if (!existsSync(stDir)) continue;
    for (const s of readdirSync(stDir).sort()) {
      const dir = join(stDir, s);
      const billDir = join(dir, 'bill');
      if (!existsSync(billDir)) continue;
      const first = readdirSync(billDir).find((f) => f.endsWith('.json'));
      if (!first) continue;
      const meta = readJson(join(billDir, first)).bill?.session;
      if (!meta || Number(meta.session_id) !== Number(m[2])) continue;
      out.push({ state: m[1], dir, meta: { ...meta, state_abbr: m[1] } });
    }
  }
  roots.set(key, out);
  return out;
}

function billIndex(s: Session): Map<number, string> {
  if (!s.bills) {
    s.bills = new Map();
    const billDir = join(s.dir, 'bill');
    for (const f of readdirSync(billDir)) {
      if (!f.endsWith('.json')) continue;
      const p = join(billDir, f);
      s.bills.set(Number(readJson(p).bill.bill_id), p);
    }
  }
  return s.bills;
}

function sessionById(all: Session[], id: string): Session {
  const s = all.find((x) => String(x.meta.session_id) === String(id));
  if (!s) throw new Error(`LegiScan session ${id}: no dataset on disk`);
  return s;
}

export function datasetQuery(root: string, op: string, params: Record<string, string> = {}): Json {
  const all = datasetSessions(root);
  switch (op) {
    case 'getSessionList': {
      const st = String(params.state ?? '').toUpperCase();
      return { status: 'OK', sessions: all.filter((s) => s.state === st).map((s) => s.meta) };
    }
    case 'getMasterListRaw': {
      const s = sessionById(all, params.id);
      const masterlist: Json = { session: s.meta };
      let i = 0;
      for (const p of billIndex(s).values()) {
        const b = readJson(p).bill;
        masterlist[String(i++)] = { bill_id: b.bill_id, number: b.bill_number, change_hash: b.change_hash, url: b.url, status_date: b.status_date, status: b.status, last_action_date: b.history?.at?.(-1)?.date ?? '', last_action: b.history?.at?.(-1)?.action ?? '', title: b.title, description: b.description };
      }
      return { status: 'OK', masterlist };
    }
    case 'getBill': {
      const id = Number(params.id);
      for (const s of all) {
        const p = billIndex(s).get(id);
        if (p) return { status: 'OK', ...readJson(p) };
      }
      throw new Error(`LegiScan bill ${params.id}: not in the datasets on disk`);
    }
    case 'getRollCall': {
      for (const s of all) {
        const p = join(s.dir, 'vote', `${Number(params.id)}.json`);
        if (existsSync(p)) return { status: 'OK', ...readJson(p) };
      }
      throw new Error(`LegiScan roll call ${params.id}: not in the datasets on disk`);
    }
    case 'getSessionPeople': {
      const s = sessionById(all, params.id);
      const peopleDir = join(s.dir, 'people');
      const people = existsSync(peopleDir)
        ? readdirSync(peopleDir).filter((f) => f.endsWith('.json')).sort().map((f) => readJson(join(peopleDir, f)).person)
        : [];
      return { status: 'OK', sessionpeople: { session: s.meta, people } };
    }
    default:
      throw new Error(`LegiScan ${op}: not answered from the datasets on disk (LEGISCAN_DATASETS is set)`);
  }
}
