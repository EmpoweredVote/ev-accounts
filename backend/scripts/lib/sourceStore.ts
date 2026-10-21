/**
 * sourceStore.ts — schemas, paths and merge rules for the season-topic-prep source store.
 *
 * Every stage of topic prep saves what it finds (instruments and their votes, sources per person,
 * portals per jurisdiction, dead ends) so the next stage or the next runner never repeats the
 * search. The store is plain JSON under `backend/data/source-store/` and is committed with each
 * stage's PR. Files are pretty-printed with keys in schema order and a trailing newline so diffs
 * stay small. Re-running a stage merges into what is there instead of overwriting it.
 *
 * Pure filesystem helpers: no db.js import, no network.
 */
import { appendFileSync, existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { z } from 'zod';

// ---------- shared pieces ----------

/** Steward scope form: `federal`, `state:wa`, `county:53033`, `place:5363000`. */
export const ScopeSchema = z.string().regex(/^(federal|state:[a-z]{2}|county:\d{5}|place:\d{7})$/, 'bad scope');

/** Jurisdiction prefix, instrument, year: `WA-ESSB-5044-2021`. */
export const InstrumentIdSchema = z
  .string()
  .regex(/^[A-Za-z0-9]+(?:-[A-Za-z0-9]+)+-\d{4}$/, 'bad instrument id');

export const ProvenanceSchema = z.object({
  fetched_by: z.string().min(1),
  fetched_at: z.string().min(1), // ISO timestamp
  method: z.enum(['webfetch', 'curl', 'browser', 'ocr', 'api', 'hand-saved', 'unrecorded']),
  saved_copy: z.object({ path: z.string().min(1), sha256: z.string().regex(/^[0-9a-f]{64}$/i) }).optional(),
});
export type Provenance = z.infer<typeof ProvenanceSchema>;

// ---------- instruments ----------

export const VoteSchema = z.object({
  date: z.string(),
  body: z.string(),
  motion: z.string(),
  kind: z.enum(['action-item', 'consent', 'en-bloc', 'roll-call']),
  yes: z.number(),
  no: z.number(),
  absent: z.number().optional(),
  body_size: z.number().optional(),
  /** Plain-words caveat about the tally or the member list (for example a count that was inferred). */
  note: z.string().optional(),
  members: z.array(
    z.object({
      name: z.string(),
      politician_id: z.string().optional(),
      vote: z.enum(['yea', 'nay', 'absent', 'abstain']),
    }),
  ),
});
export type Vote = z.infer<typeof VoteSchema>;

export const InstrumentSchema = z.object({
  id: InstrumentIdSchema,
  scope: ScopeSchema,
  title: z.string(),
  urls: z.array(z.string()),
  version: z.enum(['as-filed', 'enrolled', 'adopted', 'other']),
  operative_text: z.string().optional(),
  single_subject: z.array(
    z.object({
      season: z.number(),
      codebook: z.string(),
      topic_list_hash: z.string(),
      verdict: z.enum(['single', 'multi']),
      other_topics: z.array(z.string()),
    }),
  ),
  higher_law_duty: z.string().optional(),
  votes: z.array(VoteSchema),
  provenance: ProvenanceSchema,
});
export type Instrument = z.infer<typeof InstrumentSchema>;

// ---------- people ----------

export const PersonSourcesSchema = z.object({
  politician_id: z.string().uuid(), // becomes a file name, so it must not contain / or ..
  sources: z.array(
    z.object({
      url: z.string(),
      kind: z.enum(['record', 'own-words']),
      topic_keys: z.array(z.string()),
      useful: z.boolean(),
      note: z.string().optional(),
      provenance: ProvenanceSchema,
    }),
  ),
  terms: z.array(
    z.object({
      office: z.string(),
      start: z.string().optional(),
      end: z.string().optional(),
      precision: z.enum(['day', 'month', 'year', 'unknown']),
      source: z.string(),
    }),
  ),
});
export type PersonSources = z.infer<typeof PersonSourcesSchema>;

// ---------- jurisdictions ----------

export const JurisdictionSchema = z.object({
  scope: ScopeSchema,
  portals: z.array(
    z.object({
      name: z.string(),
      url: z.string(),
      status: z.enum(['works', 'blocked', 'needs-browser']),
      how: z.string().optional(),
      checked_at: z.string(),
      provenance: ProvenanceSchema,
    }),
  ),
  rosters: z.array(z.object({ url: z.string(), note: z.string().optional() })),
  higher_law_duties: z.array(z.object({ topic_key: z.string(), duty: z.string(), citation: z.string() })),
});
export type Jurisdiction = z.infer<typeof JurisdictionSchema>;

// ---------- dead ends ----------

export const DeadEndSchema = z.object({
  at: z.string(),
  scope: ScopeSchema.optional(),
  politician_id: z.string().optional(),
  topic_key: z.string().optional(),
  query_or_url: z.string(),
  result: z.enum(['nothing', 'blocked', 'paywalled', 'robots']),
  by: z.string(),
});
export type DeadEnd = z.infer<typeof DeadEndSchema>;

// ---------- paths ----------

/** `state:wa` → `state-wa`; `federal` stays `federal`. */
export function scopeDir(scope: string): string {
  return scope.replace(/:/g, '-');
}

export function storePaths(root: string) {
  return {
    instrument: (scope: string, id: string) => join(root, 'instruments', scopeDir(scope), `${id}.json`),
    person: (politicianId: string) => join(root, 'people', `${politicianId}.json`),
    jurisdiction: (scope: string) => join(root, 'jurisdictions', `${scopeDir(scope)}.json`),
    deadEnds: join(root, 'dead-ends.jsonl'),
  };
}

// ---------- file io ----------

function writeJson(file: string, value: unknown): void {
  mkdirSync(dirname(file), { recursive: true });
  writeFileSync(file, JSON.stringify(value, null, 2) + '\n');
}

function readJson(file: string): unknown | undefined {
  if (!existsSync(file)) return undefined;
  return JSON.parse(readFileSync(file, 'utf8'));
}

// ---------- merge helpers ----------

/** Union two lists by key; on a key clash, `pick` chooses the winner (default: keep the existing one). */
function unionBy<T>(a: T[], b: T[], key: (x: T) => string, pick?: (old: T, next: T) => T): T[] {
  const out = new Map<string, T>();
  for (const x of a) out.set(key(x), x);
  for (const x of b) {
    const k = key(x);
    const old = out.get(k);
    out.set(k, old === undefined ? x : pick ? pick(old, x) : old);
  }
  return [...out.values()];
}

const time = (iso: string): number => {
  const t = Date.parse(iso);
  return Number.isNaN(t) ? 0 : t;
};

export function mergeInstrument(old: Instrument, next: Instrument): Instrument {
  const newer = time(next.provenance.fetched_at) >= time(old.provenance.fetched_at) ? next : old;
  const older = newer === next ? old : next;
  // Newer object wins every field it has; fields only the older one has are kept.
  const base: Instrument = { ...older, ...stripUndefined(newer) };
  return InstrumentSchema.parse({
    ...base,
    urls: unionBy(older.urls, newer.urls, (u) => u, (o) => o),
    votes: unionBy(old.votes, next.votes, (v) => `${v.date}|${v.body}|${v.motion}`, (o, n) => (newer === next ? n : o)),
    single_subject: unionBy(
      old.single_subject,
      next.single_subject,
      (s) => `${s.season}|${s.codebook}|${s.topic_list_hash}`,
      (o, n) => (newer === next ? n : o),
    ),
  });
}

function stripUndefined<T extends object>(o: T): Partial<T> {
  return Object.fromEntries(Object.entries(o).filter(([, v]) => v !== undefined)) as Partial<T>;
}

export function mergePerson(old: PersonSources, next: PersonSources): PersonSources {
  return PersonSourcesSchema.parse({
    politician_id: old.politician_id,
    sources: unionBy(old.sources, next.sources, (s) => s.url, (o, n) =>
      time(n.provenance.fetched_at) >= time(o.provenance.fetched_at) ? n : o,
    ),
    terms: unionBy(old.terms, next.terms, (t) => `${t.office}|${t.start ?? ''}`, (_o, n) => n),
  });
}

export function mergeJurisdiction(old: Jurisdiction, next: Jurisdiction): Jurisdiction {
  return JurisdictionSchema.parse({
    scope: old.scope,
    portals: unionBy(old.portals, next.portals, (p) => p.url, (o, n) => (time(n.checked_at) >= time(o.checked_at) ? n : o)),
    rosters: unionBy(old.rosters, next.rosters, (r) => r.url, (_o, n) => n),
    higher_law_duties: unionBy(old.higher_law_duties, next.higher_law_duties, (d) => `${d.topic_key}|${d.duty}`, (_o, n) => n),
  });
}

// ---------- upserts ----------

function upsert<T>(file: string, schema: z.ZodType<T>, value: T, merge: (o: T, n: T) => T): 'created' | 'merged' {
  const fresh = schema.parse(value);
  const existing = readJson(file);
  if (existing === undefined) {
    writeJson(file, fresh);
    return 'created';
  }
  writeJson(file, merge(schema.parse(existing), fresh));
  return 'merged';
}

export function upsertInstrument(root: string, inst: Instrument): 'created' | 'merged' {
  return upsert(storePaths(root).instrument(inst.scope, inst.id), InstrumentSchema, inst, mergeInstrument);
}

export function upsertPerson(root: string, p: PersonSources): 'created' | 'merged' {
  return upsert(storePaths(root).person(p.politician_id), PersonSourcesSchema, p, mergePerson);
}

export function upsertJurisdiction(root: string, j: Jurisdiction): 'created' | 'merged' {
  return upsert(storePaths(root).jurisdiction(j.scope), JurisdictionSchema, j, mergeJurisdiction);
}

export function appendDeadEnd(root: string, d: DeadEnd): void {
  const file = storePaths(root).deadEnds;
  mkdirSync(dirname(file), { recursive: true });
  appendFileSync(file, JSON.stringify(DeadEndSchema.parse(d)) + '\n');
}

// ---------- validation ----------

function walkJson(dir: string): string[] {
  if (!existsSync(dir)) return [];
  const out: string[] = [];
  for (const name of readdirSync(dir).sort()) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) out.push(...walkJson(p));
    else if (name.endsWith('.json')) out.push(p);
  }
  return out;
}

function checkFile(file: string, schema: z.ZodType, problems: { file: string; error: string }[], root: string) {
  const rel = relative(root, file);
  try {
    const r = schema.safeParse(JSON.parse(readFileSync(file, 'utf8')));
    if (!r.success) problems.push({ file: rel, error: r.error.issues.map((i) => `${i.path.join('.') || '(root)'}: ${i.message}`).join('; ') });
  } catch (e) {
    problems.push({ file: rel, error: `invalid JSON: ${(e as Error).message}` });
  }
}

/** Check every file in the store against its schema. Returns one entry per problem file (or line). */
export function validateStore(root: string): { file: string; error: string }[] {
  const problems: { file: string; error: string }[] = [];
  for (const f of walkJson(join(root, 'instruments'))) checkFile(f, InstrumentSchema, problems, root);
  for (const f of walkJson(join(root, 'people'))) checkFile(f, PersonSourcesSchema, problems, root);
  for (const f of walkJson(join(root, 'jurisdictions'))) checkFile(f, JurisdictionSchema, problems, root);
  const dead = storePaths(root).deadEnds;
  if (existsSync(dead)) {
    readFileSync(dead, 'utf8').split('\n').forEach((line, i) => {
      if (!line.trim()) return;
      try {
        const r = DeadEndSchema.safeParse(JSON.parse(line));
        if (!r.success) problems.push({ file: `dead-ends.jsonl:${i + 1}`, error: r.error.issues.map((x) => x.message).join('; ') });
      } catch (e) {
        problems.push({ file: `dead-ends.jsonl:${i + 1}`, error: `invalid JSON: ${(e as Error).message}` });
      }
    });
  }
  return problems;
}
