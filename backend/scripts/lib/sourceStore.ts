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
import { createHash } from 'node:crypto';
import { appendFileSync, existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { z } from 'zod';

// ---------- shared pieces ----------

/**
 * Steward scope form: `federal`, `state:wa`, `county:53033`, `place:5363000`, plus `school:5103840` for a
 * school district (the 7-digit district geoid essentials.districts holds: state FIPS + 5-digit district
 * code). A district is not a place, and its geoid can equal a real place's, so it has its own prefix.
 */
export const ScopeSchema = z.string().regex(/^(federal|state:[a-z]{2}|county:\d{5}|place:\d{7}|school:\d{7})$/, 'bad scope');

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
      vote: z.enum(['yea', 'nay', 'absent', 'abstain', 'recused']),
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
  /**
   * Who filed it, as printed on the official bill page. A sponsorship is a record (codebook E1), so co-authors
   * are kept here rather than appended to operative_text. `version` is the version they are on (as filed, a
   * substitute); politician_id only once the identity step has confirmed the person.
   */
  sponsors: z
    .array(
      z.object({
        name: z.string().min(1),
        politician_id: z.string().optional(),
        role: z.enum(['prime', 'co', 'author', 'patron']),
        version: z.string().optional(),
      }),
    )
    .optional(),
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
  // String() of an object gives '[object Object]', which tells the next researcher nothing about
  // what was blocked. Format { target, reason } records as text before appending.
  query_or_url: z.string().min(1).refine((s) => !s.includes('[object Object]'), {
    message: 'query_or_url is a stringified object ([object Object]); write the query or URL as text',
  }),
  result: z.enum(['nothing', 'blocked', 'paywalled', 'robots']),
  by: z.string(),
});
export type DeadEnd = z.infer<typeof DeadEndSchema>;

// ---------- findings (Stage 5) ----------

/**
 * What one Stage 5 search found for one person (design §7): the exact passage of their own words, or their
 * act on a record, with the date, a plain note and subject tags in plain words (not rung numbers, so a
 * reworded or split topic can be re-coded from them). `id` is `findingId`, so the same passage or act is
 * stored once however often it is found. `local_record` marks a local ordinance or resolution, which may
 * support a local official's own words but never seats alone (RULINGS.md "Stage 5 rulings").
 */
export const FindingSchema = z
  .object({
    id: z.string().min(1),
    kind: z.enum(['record', 'own-words']),
    url: z.string().min(1),
    date: z.string(),
    date_precision: z.enum(['day', 'month', 'year', 'unknown']),
    passage: z.string().min(1).optional(),
    instrument_id: InstrumentIdSchema.optional(),
    act: z.enum(['yea', 'nay', 'abstain', 'sponsor', 'author', 'signed', 'vetoed', 'other']).optional(),
    /** For a vote: the motion, as the instrument's vote records it (two votes on one day differ here). */
    motion: z.string().min(1).optional(),
    local_record: z.boolean().optional(),
    note: z.string().min(1),
    subjects: z.array(z.string().min(1)).min(1),
    topic_keys: z.array(z.string().min(1)),
    provenance: ProvenanceSchema,
  })
  .refine((f) => f.kind !== 'own-words' || !!f.passage, { message: 'own-words needs the exact passage', path: ['passage'] })
  .refine((f) => f.kind !== 'record' || !!f.act, { message: 'a record needs the act', path: ['act'] });
export type Finding = z.infer<typeof FindingSchema>;

/** One search for one person on one topic in one season, kept even when it found nothing. */
export const SearchSchema = z.object({
  topic_key: z.string().min(1),
  season: z.number().int(),
  subjects: z.array(z.string().min(1)),
  places: z.array(z.string().min(1)),
  found: z.number().int().min(0),
  at: z.string(),
  by: z.string().min(1),
});
export type Search = z.infer<typeof SearchSchema>;

export const PersonFindingsSchema = z.object({
  politician_id: z.string().uuid(), // becomes a file name, so it must not contain / or ..
  findings: z.array(FindingSchema),
  searches: z.array(SearchSchema),
});
export type PersonFindings = z.infer<typeof PersonFindingsSchema>;

/** SHA-256 of kind, url and what was found there (the passage, or the instrument, act, date and motion). */
export function findingId(f: Pick<Finding, 'kind' | 'url' | 'passage' | 'instrument_id' | 'act' | 'date' | 'motion'>): string {
  const what = f.kind === 'own-words' ? (f.passage ?? '') : `${f.instrument_id ?? ''}|${f.act ?? ''}|${f.date}|${f.motion ?? ''}`;
  return createHash('sha256').update(`${f.kind}\n${f.url}\n${what}`).digest('hex');
}

/** True when this person was searched for this topic in this season. */
export function searchedFor(pf: PersonFindings, topicKey: string, season: number): boolean {
  return pf.searches.some((s) => s.topic_key === topicKey && s.season === season);
}

// ---------- paths ----------

/** `state:wa` → `state-wa`, `school:5103840` → `school-5103840`; `federal` stays `federal`. */
export function scopeDir(scope: string): string {
  return scope.replace(/:/g, '-');
}

export function storePaths(root: string) {
  return {
    instrument: (scope: string, id: string) => join(root, 'instruments', scopeDir(scope), `${id}.json`),
    person: (politicianId: string) => join(root, 'people', `${politicianId}.json`),
    jurisdiction: (scope: string) => join(root, 'jurisdictions', `${scopeDir(scope)}.json`),
    findings: (politicianId: string) => join(root, 'findings', `${politicianId}.json`),
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
    sponsors: old.sponsors || next.sponsors
      ? unionBy(old.sponsors ?? [], next.sponsors ?? [], (x) => `${x.name}|${x.role}|${x.version ?? ''}`, (o, n) => (newer === next ? n : o))
      : undefined,
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

// `prev`, not `old`: the occupancy guard reads `o*.politician_id` as an essentials.offices alias.
export function mergePerson(prev: PersonSources, next: PersonSources): PersonSources {
  return PersonSourcesSchema.parse({
    politician_id: prev.politician_id,
    sources: unionBy(prev.sources, next.sources, (s) => s.url, (o, n) =>
      time(n.provenance.fetched_at) >= time(o.provenance.fetched_at) ? n : o,
    ),
    terms: unionBy(prev.terms, next.terms, (t) => `${t.office}|${t.start ?? ''}`, (_o, n) => n),
  });
}

export function mergeFindings(prev: PersonFindings, next: PersonFindings): PersonFindings {
  return PersonFindingsSchema.parse({
    politician_id: prev.politician_id,
    findings: unionBy(prev.findings, next.findings, (f) => f.id, (o, n) =>
      time(n.provenance.fetched_at) >= time(o.provenance.fetched_at) ? n : o,
    ),
    searches: unionBy(prev.searches, next.searches, (x) => `${x.topic_key}|${x.season}|${x.at}`, (o) => o),
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

export function upsertFindings(root: string, pf: PersonFindings): 'created' | 'merged' {
  return upsert(storePaths(root).findings(pf.politician_id), PersonFindingsSchema, pf, mergeFindings);
}

export function appendDeadEnd(root: string, d: DeadEnd): void {
  const file = storePaths(root).deadEnds;
  mkdirSync(dirname(file), { recursive: true });
  appendFileSync(file, JSON.stringify(DeadEndSchema.parse(d)) + '\n');
}

// ---------- topic list hash ----------

/**
 * The `topic_list_hash` every single-subject verdict carries: SHA-256 (hex) of the season's served topic
 * keys, de-duplicated, sorted, one per line, with a trailing newline. Two verdicts with the same hash
 * were judged against the same list. `npm run source-store --prefix backend -- topic-list-hash --season
 * <open|draft|uuid>` prints it for a season. (The voting-rights census computed it the same way by hand:
 * Season 3, 60 topics, a7b0076a….)
 */
export function topicListHash(topicKeys: string[]): string {
  const list = [...new Set(topicKeys)].sort();
  return createHash('sha256').update(list.map((k) => `${k}\n`).join('')).digest('hex');
}

// ---------- merging a staging store ----------

/**
 * Merge a staging store (a dry run, or a run that could not commit, writes one with `--root`) into the
 * repo store, by the same rules as the upserts. Dead ends already present (same fields apart from `at`)
 * are not appended again. Validate both first: a broken staging file throws before anything is written
 * for it.
 */
export function mergeStore(fromRoot: string, toRoot: string): { instruments: number; people: number; jurisdictions: number; findings: number; deadEnds: number } {
  const n = { instruments: 0, people: 0, jurisdictions: 0, findings: 0, deadEnds: 0 };
  const load = (f: string) => JSON.parse(readFileSync(f, 'utf8'));
  for (const f of walkJson(join(fromRoot, 'instruments'))) { upsertInstrument(toRoot, InstrumentSchema.parse(load(f))); n.instruments++; }
  for (const f of walkJson(join(fromRoot, 'people'))) { upsertPerson(toRoot, PersonSourcesSchema.parse(load(f))); n.people++; }
  for (const f of walkJson(join(fromRoot, 'jurisdictions'))) { upsertJurisdiction(toRoot, JurisdictionSchema.parse(load(f))); n.jurisdictions++; }
  for (const f of walkJson(join(fromRoot, 'findings'))) { upsertFindings(toRoot, PersonFindingsSchema.parse(load(f))); n.findings++; }
  const from = storePaths(fromRoot).deadEnds;
  if (existsSync(from)) {
    const keyOf = (d: Record<string, unknown>) => {
      const { at: _at, ...rest } = d;
      return JSON.stringify(Object.keys(rest).sort().map((k) => [k, rest[k]]));
    };
    const to = storePaths(toRoot).deadEnds;
    const have = new Set(
      existsSync(to) ? readFileSync(to, 'utf8').split('\n').filter((l) => l.trim()).map((l) => keyOf(JSON.parse(l))) : [],
    );
    for (const line of readFileSync(from, 'utf8').split('\n')) {
      if (!line.trim()) continue;
      const d = DeadEndSchema.parse(JSON.parse(line));
      const k = keyOf(d);
      if (have.has(k)) continue;
      appendDeadEnd(toRoot, d);
      have.add(k);
      n.deadEnds++;
    }
  }
  return n;
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
  for (const f of walkJson(join(root, 'findings'))) checkFile(f, PersonFindingsSchema, problems, root);
  const dead = storePaths(root).deadEnds;
  if (existsSync(dead)) {
    // A dead end stored twice (same fields, any `at`) is a re-run that appended again, not a new
    // finding. Key on every field but `at`, in sorted order, so field order does not hide a repeat.
    const seen = new Map<string, number>();
    readFileSync(dead, 'utf8').split('\n').forEach((line, i) => {
      if (!line.trim()) return;
      try {
        const parsed = JSON.parse(line);
        const r = DeadEndSchema.safeParse(parsed);
        if (!r.success) problems.push({ file: `dead-ends.jsonl:${i + 1}`, error: r.error.issues.map((x) => x.message).join('; ') });
        const { at: _at, ...rest } = parsed;
        const key = JSON.stringify(Object.keys(rest).sort().map((k) => [k, rest[k]]));
        const first = seen.get(key);
        if (first) problems.push({ file: `dead-ends.jsonl:${i + 1}`, error: `duplicate of line ${first} (only "at" differs, if anything)` });
        else seen.set(key, i + 1);
      } catch (e) {
        problems.push({ file: `dead-ends.jsonl:${i + 1}`, error: `invalid JSON: ${(e as Error).message}` });
      }
    });
  }
  return problems;
}
