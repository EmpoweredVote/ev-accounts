/**
 * coder-io.ts — file helpers shared by `coder-inputs.ts` and `split-codes.ts`: the coder config, the source
 * store's findings and instruments, and the roster. No database, no network.
 */
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { PersonFindingsSchema, type PersonFindings } from '../lib/sourceStore.js';
import type { RosterRow } from '../lib/stage5CoderInputs.js';
import type { InstrumentText } from '../lib/stage5Ingest.js';

export const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');
export const STORE = join(REPO, 'backend/data/source-store');

/** One per topic run (`stage5/coder-config.json`); the coder never writes these fields. */
export interface CoderConfig {
  topic_key: string;
  season: number;
  season_id: string;
  revision_id: string;
  codebook: string;
  /** The date written into the brief's title. */
  date: string;
  /** From `topic:ladder-lint --season draft`: a `Question: "…"` line and `N. text` rung lines. */
  ladder_text: string;
  evidence_basis_by_level: string;
}

export function readConfig(path: string): CoderConfig {
  const c = JSON.parse(readFileSync(path, 'utf8')) as Partial<CoderConfig>;
  for (const k of ['topic_key', 'season', 'season_id', 'revision_id', 'codebook', 'date', 'ladder_text', 'evidence_basis_by_level'] as const) {
    if (c[k] === undefined || c[k] === '') throw new Error(`${path}: ${k} is missing`);
  }
  return c as CoderConfig;
}

export function readPersonFindings(store: string, pid: string): PersonFindings | undefined {
  const p = join(store, 'findings', `${pid}.json`);
  if (!existsSync(p)) return undefined;
  return PersonFindingsSchema.parse(JSON.parse(readFileSync(p, 'utf8')));
}

export function findingsFileSize(store: string, pid: string): number {
  const p = join(store, 'findings', `${pid}.json`);
  return existsSync(p) ? readFileSync(p, 'utf8').length : 0;
}

/** Instrument id → its file, relative to `<store>/instruments` (`state-ga/GA-HB-1324-2025.json`). */
export function instrumentIndex(store: string): Map<string, string> {
  const out = new Map<string, string>();
  const root = join(store, 'instruments');
  for (const d of readdirSync(root, { withFileTypes: true })) {
    if (!d.isDirectory()) continue;
    for (const f of readdirSync(join(root, d.name))) if (f.endsWith('.json')) out.set(f.slice(0, -5), `${d.name}/${f}`);
  }
  return out;
}

/** Title and operative text of the instruments named, read once each. */
export function instrumentTexts(store: string, index: Map<string, string>, ids: Iterable<string>): Map<string, InstrumentText> {
  const out = new Map<string, InstrumentText>();
  for (const id of ids) {
    const rel = index.get(id);
    if (!rel || out.has(id)) continue;
    const j = JSON.parse(readFileSync(join(store, 'instruments', rel), 'utf8')) as InstrumentText;
    out.set(id, { title: j.title, operative_text: j.operative_text });
  }
  return out;
}

/** Roster rows by politician id; the first file that lists a person wins (as the Georgia scripts did). */
export function readRosters(paths: string[]): Map<string, RosterRow> {
  const out = new Map<string, RosterRow>();
  for (const p of paths) {
    const [head, ...lines] = readFileSync(p, 'utf8').split('\n').filter((l) => l.trim());
    const cols = head.split('\t');
    for (const l of lines) {
      const v = l.split('\t');
      const r = Object.fromEntries(cols.map((c, i) => [c, v[i] ?? ''])) as unknown as RosterRow;
      if (r.politician_id && !out.has(r.politician_id)) out.set(r.politician_id, r);
    }
  }
  return out;
}

/** `--flag value` pairs and positional arguments; a repeated flag keeps every value. */
export function parseArgs(argv: string[]): { pos: string[]; flags: Map<string, string[]> } {
  const pos: string[] = [];
  const flags = new Map<string, string[]>();
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const v = argv[i + 1] !== undefined && !argv[i + 1].startsWith('--') ? argv[++i] : 'true';
      flags.set(a.slice(2), [...(flags.get(a.slice(2)) ?? []), v]);
    } else pos.push(a);
  }
  return { pos, flags };
}
