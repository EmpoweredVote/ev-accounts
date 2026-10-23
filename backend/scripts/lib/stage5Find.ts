/**
 * stage5Find.ts — Stage 5 step 3: who to search next, and how a collector's file enters the store.
 *
 * Every person on the roster gets one own-words search per topic per season (design §5 step 3, §10 budget
 * rule), including people a vote on file already places. `nextBatch` lists the next people in one unit
 * (federal, or one state's state or local officials) who have no search entry yet for this topic and
 * season, with people who already have findings on file first. Officials who are leaving get the cheap
 * pass only (pre-fill), so they are left out. Re-running after a stop simply lists who is still owed.
 *
 * `importFindFile` validates one collector file (templates/BRIEF-stage5-find.md), computes finding ids,
 * stamps provenance and appends the search entry, even when nothing was found. A file that carries a rung
 * or value is refused: searching and coding are separate passes, and the searcher never decides the rung.
 */
import { existsSync, readFileSync } from 'node:fs';
import { z } from 'zod';
import {
  FindingSchema, PersonFindingsSchema, ProvenanceSchema, findingId, searchedFor, storePaths,
  type Finding, type PersonFindings,
} from './sourceStore.js';
import type { RosterRow } from './stage5Roster.js';
import type { Level } from '../../src/lib/topicApplicability.js';

export type Unit = { level: Level; state?: string };

const PARTY_RE = /\b(republicans?|democrats?|democratic party|libertarians?|GOP|DNC|RNC|green party|independent party)\b/i;

/** `federal`, `state:in`, `local:in` → a unit. */
export function parseUnit(s: string): Unit {
  if (s === 'federal') return { level: 'federal' };
  const m = /^(state|local|school|judicial):([a-z]{2})$/i.exec(s);
  if (!m) throw new Error(`bad unit "${s}": use federal, state:xx, local:xx, school:xx or judicial:xx`);
  return { level: m[1].toLowerCase() as Level, state: m[2].toUpperCase() };
}

function loadFindings(store: string, politicianId: string): PersonFindings | undefined {
  const f = storePaths(store).findings(politicianId);
  return existsSync(f) ? PersonFindingsSchema.parse(JSON.parse(readFileSync(f, 'utf8'))) : undefined;
}

export function nextBatch(roster: RosterRow[], store: string, topicKey: string, season: number, unit: Unit, size: number): RosterRow[] {
  const owed: { row: RosterRow; onFile: boolean }[] = [];
  for (const row of roster) {
    if (row.level !== unit.level) continue;
    if (unit.state && row.state !== unit.state) continue;
    if (row.leaving === 'yes') continue;
    const pf = loadFindings(store, row.politician_id);
    if (pf && searchedFor(pf, topicKey, season)) continue;
    owed.push({ row, onFile: !!pf?.findings.some((f) => f.topic_keys.includes(topicKey)) });
  }
  // Stable: people with findings on file first, otherwise roster order.
  return owed.sort((a, b) => Number(b.onFile) - Number(a.onFile)).slice(0, size).map((o) => o.row);
}

// What a collector writes. `.strict()` refuses extra keys, so a value or rung cannot slip in.
const CollectedFindingSchema = z.object({
  kind: z.enum(['record', 'own-words']),
  url: z.string().min(1),
  date: z.string(),
  date_precision: z.enum(['day', 'month', 'year', 'unknown']),
  passage: z.string().optional(),
  instrument_id: z.string().optional(),
  act: z.enum(['yea', 'nay', 'abstain', 'sponsor', 'author', 'signed', 'vetoed', 'other']).optional(),
  motion: z.string().optional(),
  local_record: z.boolean().optional(),
  note: z.string().min(1),
  subjects: z.array(z.string().min(1)),
  method: ProvenanceSchema.shape.method.optional(),
  saved_copy: ProvenanceSchema.shape.saved_copy,
}).strict();

const CollectorFileSchema = z.object({
  politician_id: z.string().uuid(),
  searched: z.object({ subjects: z.array(z.string().min(1)).min(1), places: z.array(z.string().min(1)).min(1) }).strict(),
  findings: z.array(CollectedFindingSchema),
}).strict();

export function importFindFile(
  json: unknown, topicKey: string, season: number, by: { by: string; at: string },
  expect?: { fileId: string; onRoster: Set<string> },
): PersonFindings {
  const pid = (json as { politician_id?: string })?.politician_id ?? '(no politician_id)';
  // A collector that kept a template id, or mixed up two people, would file one person's words under another.
  if (expect && pid !== expect.fileId) throw new Error(`${pid}: the file name says ${expect.fileId}; a collector file must be <politician_id>.json`);
  if (expect && !expect.onRoster.has(pid)) throw new Error(`${pid}: not on the roster for this topic`);
  const parsed = CollectorFileSchema.safeParse(json);
  if (!parsed.success) {
    throw new Error(`${pid}: ${parsed.error.issues.map((i) => `${i.path.join('.') || '(root)'}: ${i.message}`).join('; ')}`);
  }
  const file = parsed.data;
  // Antipartisan rule: our own text never names a party. A verbatim passage is the person's words and is kept
  // as found; whether it may be shown is the quote check's call.
  const ours = [...file.searched.places, ...file.searched.subjects, ...file.findings.flatMap((f) => [f.note, ...f.subjects])];
  const hit = ours.find((t) => PARTY_RE.test(t.replace(/https?:\/\/\S+/g, "")));
  if (hit) throw new Error(`${pid}: a party name in our own text ("${hit.slice(0, 80)}"); write notes, subjects and places without parties`);
  const findings: Finding[] = file.findings.map((c, i) => {
    const { method, saved_copy, ...rest } = c;
    const base = {
      ...rest, topic_keys: [topicKey],
      provenance: { fetched_by: by.by, fetched_at: by.at, method: method ?? 'webfetch', ...(saved_copy ? { saved_copy } : {}) },
    };
    const r = FindingSchema.safeParse({ id: findingId(base), ...base });
    if (!r.success) throw new Error(`${pid}: finding ${i}: ${r.error.issues.map((x) => `${x.path.join('.')}: ${x.message}`).join('; ')}`);
    return r.data;
  });
  return PersonFindingsSchema.parse({
    politician_id: file.politician_id,
    findings,
    searches: [{ topic_key: topicKey, season, subjects: file.searched.subjects, places: file.searched.places, found: findings.length, at: by.at, by: by.by }],
  });
}
