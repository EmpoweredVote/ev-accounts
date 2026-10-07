/**
 * seasonTarget.ts — which season a stance-research step works against (`--season <id|open|draft>`).
 *
 * Default `open`: every script behaves exactly as before. `draft` pre-stages research for the one
 * draft season (Season 3 before it opens). A uuid names a season directly. A CLOSED season is always
 * refused — its answers are immutable (ADR 0005).
 *
 * Pure apart from the query it is handed, so the cases are testable with a fake. No db.js import:
 * that module validates env at import time.
 */
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

export interface SeasonTarget {
  id: string;
  number: number;
  name: string;
  status: 'open' | 'draft';
}
type Query = (sql: string, params?: unknown[]) => Promise<{ rows: any[] }>;

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export class SeasonTargetError extends Error {}

/** `--season` and the older `--season-id` both name a season; the value defaults to `open`. */
export function seasonSpecFromArgv(argv: string[]): string {
  for (const flag of ['--season', '--season-id']) {
    const i = argv.indexOf(flag);
    if (i !== -1) {
      const v = argv[i + 1];
      if (!v || v.startsWith('--')) throw new SeasonTargetError(`${flag} needs a value: open | draft | <season uuid>`);
      return v;
    }
  }
  return 'open';
}

export async function resolveSeasonTarget(spec: string, query: Query): Promise<SeasonTarget> {
  const sel = 'SELECT id::text AS id, number, name, status FROM inform.seasons';
  let rows: any[];
  if (spec === 'open' || spec === 'draft') {
    ({ rows } = await query(`${sel} WHERE status = $1 ORDER BY number`, [spec]));
    if (rows.length === 0) {
      throw new SeasonTargetError(spec === 'open'
        ? 'no open season — nothing can be researched against a pin or written; open a season first, or pass --season draft'
        : 'no draft season — there is nothing to pre-stage; pass --season open, or --season <uuid>');
    }
    if (rows.length > 1) {
      throw new SeasonTargetError(`${rows.length} ${spec} seasons (${rows.map((r) => `${r.number}`).join(', ')}) — `
        + 'name one with --season <uuid>');
    }
  } else if (UUID_RE.test(spec)) {
    ({ rows } = await query(`${sel} WHERE id = $1`, [spec.toLowerCase()]));
    if (rows.length === 0) throw new SeasonTargetError(`no season ${spec}`);
  } else {
    throw new SeasonTargetError(`--season ${JSON.stringify(spec)}: expected open | draft | <season uuid>`);
  }
  const r = rows[0];
  if (r.status !== 'open' && r.status !== 'draft') {
    throw new SeasonTargetError(`season ${r.number} is ${r.status}; its answers are immutable — only an open or draft season can be researched`);
  }
  return { id: r.id, number: Number(r.number), name: r.name, status: r.status };
}

/**
 * The bundle records the season it was built for ONLY when that season is not the open one, so an
 * open-season bundle stays byte-identical to what this script has always written. A later step
 * (verify, code, queue) must then be pointed at the same season: a draft bundle checked against the
 * open season would drift-check one season's pins against another's.
 */
export const SEASON_FILE = 'season.json';

export function writeBundleSeason(dir: string, t: SeasonTarget): void {
  if (t.status === 'open') return;
  writeFileSync(join(dir, SEASON_FILE), JSON.stringify({ id: t.id, number: t.number, name: t.name, status: t.status }, null, 2));
}

/** Throws when the batch dir's recorded season is not `t`. An open target with no file is the legacy case and passes. */
export function assertBundleSeason(dir: string, t: SeasonTarget): void {
  const p = join(dir, SEASON_FILE);
  if (!existsSync(p)) {
    if (t.status === 'draft') {
      throw new SeasonTargetError(`${dir} has no ${SEASON_FILE} — its bundle was built for the open season, not for draft season ${t.number}. `
        + 'Rebuild it with build-stance-topic-bundle.ts --season draft');
    }
    return;
  }
  const rec = JSON.parse(readFileSync(p, 'utf8')) as { id: string; number: number };
  if (rec.id !== t.id) {
    throw new SeasonTargetError(`${dir} was built for season ${rec.number} (${rec.id}) but this run targets season ${t.number} (${t.id}) — `
      + 'pass the same --season to every step, or rebuild the bundle');
  }
}

/**
 * The no-database check the coder/queue steps can run on a bare `--season-id <uuid>`: when the batch
 * dir records a season (a non-open bundle), the id must be that season. A batch dir with no
 * season.json is an open-season bundle; it cannot be checked here and passes.
 */
export function assertSeasonIdMatchesBundle(dir: string, seasonId: string): void {
  const p = join(dir, SEASON_FILE);
  if (!existsSync(p)) return;
  const rec = JSON.parse(readFileSync(p, 'utf8')) as { id: string; number: number };
  if (rec.id.toLowerCase() !== seasonId.toLowerCase()) {
    throw new SeasonTargetError(`${dir} was built for season ${rec.number} (${rec.id}), not ${seasonId} — `
      + 'pass that season, or rebuild the bundle');
  }
}

/**
 * `--season-id <uuid>` (as before) or `--season <open|draft|uuid>` → the season id. `--season-id`
 * wins when both are given only if they agree. Returns null when neither flag is present.
 * `--season open|draft` needs the database (resolved through `query`); a uuid does not.
 */
export async function seasonIdFromArgs(argv: string[], dir: string, query: Query): Promise<string | null> {
  const val = (f: string) => { const i = argv.indexOf(f); return i !== -1 ? argv[i + 1] : undefined; };
  const byId = val('--season-id');
  const bySpec = val('--season');
  if (byId === undefined && bySpec === undefined) return null;
  let id = byId;
  if (bySpec !== undefined) {
    const t = await resolveSeasonTarget(bySpec, query);
    assertBundleSeason(dir, t);
    if (id !== undefined && id.toLowerCase() !== t.id.toLowerCase()) {
      throw new SeasonTargetError(`--season-id ${id} and --season ${bySpec} name different seasons`);
    }
    id = t.id;
  } else if (id !== undefined) {
    if (!UUID_RE.test(id)) throw new SeasonTargetError(`--season-id ${JSON.stringify(id)} is not a uuid`);
    assertSeasonIdMatchesBundle(dir, id);
  }
  return id ?? null;
}
