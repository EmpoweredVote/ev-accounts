/**
 * verify-stance-research.ts — deterministic verification gate for /research-stances.
 *
 * Reads a batch directory's `stances.csv` + `evidence.csv`, fetches each cited
 * URL through the tiered fetch ladder (HTTP → Wayback; src/lib/verificationFetch.ts),
 * and checks every snippet appears verbatim on the page (after normalization) with
 * the politician's name within 500 characters. No LLM in the loop. See
 * .claude/skills/research-stances/README.md and
 * docs/superpowers/specs/2026-04-30-stance-research-verification-design.md.
 *
 *   Dry-run (default): decides every scored row's action bucket — auto-push,
 *     unchanged, review, or re-research — via stancePublishPolicy.decidePublish,
 *     printing the bucket counts and, for re-research rows, the failed-source
 *     URLs to feed a re-research pass.
 *   --apply: pushes auto-push rows through the season-aware writeVerifiedStance
 *     (inform.politician_answers + inform.politician_context) plus
 *     inform.politician_context_evidence, and writes review / below-threshold
 *     rows to inform.stance_research_review.
 *
 *   REVIEW-ALL IS THE DEFAULT. Without --auto-push, a row that passes every check
 *     goes to the review queue with reason `review-all-mode` instead of being
 *     written (ruling 2026-09-22, "nothing auto-publishes"). Until a chair-fit
 *     classifier exists (Plan 2), a person approves every stance, and those
 *     approvals are the labeled set Plan 2 needs. --auto-push is a deliberate
 *     per-run flag; no env var turns it on.
 *
 * Usage:
 *   npx tsx scripts/verify-stance-research.ts --dir data/stance-research/<batch> \
 *     [--threshold 2] [--batch-id <id>] [--apply] [--auto-push] [--re-researched] [--editor-id <uuid>]
 * Requires <dir>/gate-findings.json from scripts/stance-gate.ts, and <dir>/topics.json
 * from scripts/build-stance-topic-bundle.ts: every scored row's ladder revision must
 * still be the open season's pin, or the run exits 2 before any write.
 * Exit: 0 ok, 1 --apply finished with row errors, 2 usage / unreadable / refused batch.
 *
 * Idempotent: re-running the same batch is safe. Stance writes are season-aware
 * upserts, each in its own transaction with its snippets; snippets are
 * insert-if-absent. Review-queue rows are upserted per (batch, politician-or-name,
 * topic), and a re-run refreshes only rows still UNDECIDED (pending /
 * unresolved_politician) — a row a person already resolved or rejected is left
 * alone, never reset to pending. A re-research pass REPLACES that (politician, topic) pair's rows
 * in research.csv / evidence.csv — it never appends a second row for a pair (two
 * rows for one pair are refused: stance-gate flags `duplicate-row`, and this script
 * exits 2 before any write) — and then re-runs scripts/stance-gate.ts (which
 * regenerates stances.csv and gate-findings.json together). Appending straight to
 * stances.csv instead would fail the row-count check against gate-findings.json below.
 */
import 'dotenv/config';
import { readFileSync, existsSync, writeFileSync, rmSync } from 'node:fs';
import { join, basename } from 'node:path';
import type { PoolClient } from 'pg';
import { pool } from '../src/lib/db.js';
import { parseStancesCsv, parseEvidenceCsv } from '../src/lib/stanceResearchCsv.js';
import {
  verifyEvidence,
  createPageFetcher,
  normTopic,
  stanceKey,
  type StanceRow,
  type EvidenceRow,
  type PoliticianNames,
  type VerifiedRow,
} from '../src/lib/researchVerifier.js';
import { createVerificationFetchSession } from '../src/lib/verificationFetch.js';
import {
  buildEvidenceRowsForInsert,
  buildReviewRowForInsert,
  accumulateEvidence,
  upsertReviewRow,
  writeVerifiedStance,
} from '../src/lib/researchEvidenceService.js';
import { OPEN_SEASON_ANSWER_SQL } from '../src/lib/seasonService.js';
import { decidePublish, type Decision } from './lib/stancePublishPolicy.js';
import { GATE_CHECK_IDS, type GateFinding } from './lib/stanceGate.js';

// ---------------------------------------------------------------- args
function flag(name: string): boolean {
  return process.argv.includes(name);
}
function opt(name: string, def?: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i !== -1 && i + 1 < process.argv.length ? process.argv[i + 1] : def;
}

const DIR = opt('--dir');
if (!DIR) {
  console.error('ERROR: --dir <batch directory> is required');
  process.exit(2);
}
// R2: a refused run (any exit-2 path below) must not leave a PREVIOUS run's report sitting in the
// batch directory — someone reading publish-report.json after a refusal would otherwise see a
// stale, unrelated result and mistake it for this run's outcome. Removed right after --dir is
// known, before any other validation can exit; prints only when there was something to remove.
const stalePublishReportPath = join(DIR, 'publish-report.json');
if (existsSync(stalePublishReportPath)) {
  rmSync(stalePublishReportPath, { force: true });
  console.log('removed stale publish-report.json');
}
// Default 1 verified source (cheap mode — avoids a re-research wave). Override
// with --threshold or the RESEARCH_STANCES_THRESHOLD env var.
const rawThreshold = opt('--threshold', process.env.RESEARCH_STANCES_THRESHOLD ?? '1');
const THRESHOLD = Number(rawThreshold);
if (!Number.isInteger(THRESHOLD) || THRESHOLD < 1) {
  // An unvalidated NaN/0 threshold is not a strict setting — `verifiedSourceCount < THRESHOLD`
  // is false for every row, so a bad --threshold silently AUTO-PUSHES rows no page verified.
  console.error(`ERROR: --threshold (or RESEARCH_STANCES_THRESHOLD) must be an integer >= 1, got ${JSON.stringify(rawThreshold)}`);
  process.exit(2);
}
const BATCH_ID = opt('--batch-id', basename(DIR.replace(/\/+$/, '')))!;
const APPLY = flag('--apply');
// Review-all unless the operator opts in, per run (ruling 2026-09-22). Deliberately argv-only:
// an env var would let a scheduled run inherit unattended publishing nobody chose for it.
const AUTO_PUSH = flag('--auto-push');
// Stamps re_research_attempted on queued rows that are actually below-threshold re-research
// attempts — not on every queued row (R7; see the queued-rows loop below).
const RE_RESEARCHED = flag('--re-researched');

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const EDITOR_ID = opt('--editor-id', process.env.EV_EDITOR_ID) ?? null;
if (EDITOR_ID && !UUID_RE.test(EDITOR_ID)) {
  // Catches `--editor-id --apply` (opt() greedily takes the next argv token as the value, so
  // EDITOR_ID becomes the literal string "--apply") before it can reach a query as a bad param.
  console.error(`ERROR: --editor-id must be a uuid, got ${JSON.stringify(EDITOR_ID)}`);
  process.exit(2);
}
if (APPLY && !EDITOR_ID) {
  console.error('ERROR: --apply needs --editor-id <admin user uuid> (or EV_EDITOR_ID) — a stance nobody authored is a row nobody can be asked about');
  process.exit(2);
}
const gatePath = join(DIR, 'gate-findings.json');
if (!existsSync(gatePath)) {
  console.error(`ERROR: ${gatePath} not found — run scripts/stance-gate.ts --dir ${DIR} first`);
  process.exit(2);
}
const topicsPath = join(DIR, 'topics.json');
if (!existsSync(topicsPath)) {
  console.error(`ERROR: ${topicsPath} not found — it records the ladder revisions this batch was researched against; rebuild it with scripts/build-stance-topic-bundle.ts`);
  process.exit(2);
}

// ---------------------------------------------------------------- load CSVs
const stancesPath = join(DIR, 'stances.csv');
const evidencePath = join(DIR, 'evidence.csv');
if (!existsSync(stancesPath)) {
  console.error(`ERROR: ${stancesPath} not found`);
  process.exit(2);
}
let allStances: StanceRow[];
try {
  allStances = parseStancesCsv(readFileSync(stancesPath, 'utf8'));
} catch (err) {
  const msg = err instanceof Error ? err.message : String(err);
  console.error(`ERROR: ${stancesPath} is not valid CSV: ${msg}`);
  process.exit(2);
}
let evidenceRows: EvidenceRow[] = [];
if (existsSync(evidencePath)) {
  try {
    evidenceRows = parseEvidenceCsv(readFileSync(evidencePath, 'utf8'));
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error(`ERROR: ${evidencePath} is not valid CSV: ${msg}`);
    process.exit(2);
  }
}

// value=null rows are an explicit "insufficient evidence" signal: skip verification,
// drop in normal mode (never pushed, never queued).
const nullRows = allStances.filter((s) => s.value === null);
const stanceRows = allStances.filter((s) => s.value !== null);

// ---------------------------------------------------------------- load gate findings (D3)
// gate-findings.json and stances.csv are written together by stance-gate.ts, from the same
// research.csv. A row-count mismatch means gate-findings.json describes a different batch
// than the one being verified here — a verdict from that is a blind detector, not a clean one.
// A severity or check_id the gate never writes is refused, not trusted: a hand-edited
// "severity": "critical" would otherwise not count as high, and an unknown check_id would be
// carried into decidePublish as if the gate had meant it.
const CHECK_IDS: ReadonlySet<string> = new Set(GATE_CHECK_IDS);
function isFindingShape(f: unknown): f is GateFinding {
  if (typeof f !== 'object' || f === null) return false;
  const r = f as Record<string, unknown>;
  return typeof r.full_name === 'string' && typeof r.topic_key === 'string'
    && typeof r.check_id === 'string' && CHECK_IDS.has(r.check_id)
    && (r.severity === 'high' || r.severity === 'medium');
}

let gateFileRaw: unknown;
try {
  gateFileRaw = JSON.parse(readFileSync(gatePath, 'utf8'));
} catch (err) {
  const msg = err instanceof Error ? err.message : String(err);
  console.error(`ERROR: ${gatePath} is not valid JSON: ${msg}`);
  process.exit(2);
}
// M5: a malformed-but-parseable file (a non-object top level, a missing .summary, or a finding
// missing a required field) used to reach a property access on `undefined`/`null` further down
// and crash with an uncaught TypeError (exit 1) instead of the deliberate "usage/unreadable"
// exit 2 this script uses everywhere else. Validate the whole shape up front instead.
if (typeof gateFileRaw !== 'object' || gateFileRaw === null || Array.isArray(gateFileRaw)) {
  console.error(`ERROR: ${gatePath} is not valid JSON: expected a top-level object`);
  process.exit(2);
}
const gateFileCandidate = gateFileRaw as { findings?: unknown; summary?: unknown };
if (!Array.isArray(gateFileCandidate.findings) || !gateFileCandidate.findings.every(isFindingShape)) {
  console.error(`ERROR: ${gatePath} is not valid JSON: .findings must be an array of findings with string full_name/topic_key, severity high|medium, and a check_id stance-gate emits`);
  process.exit(2);
}
const findings = gateFileCandidate.findings as GateFinding[];
const summary = gateFileCandidate.summary as { rows?: unknown } | undefined;
if (!summary || typeof summary.rows !== 'number') {
  console.error(`ERROR: ${gatePath} is not valid JSON: .summary.rows must be a number`);
  process.exit(2);
}
if (summary.rows !== allStances.length) {
  console.error(
    `ERROR: gate-findings.json covers ${summary.rows} rows but stances.csv has ${allStances.length} — re-run scripts/stance-gate.ts`,
  );
  process.exit(2);
}
// Keyed through the gate's own normalizer (stanceKey): findings carry research.csv's spelling,
// stances.csv carries the bundle's canonical one, and the two must meet.
const gateByKey = new Map<string, GateFinding[]>();
for (const f of findings) {
  const k = stanceKey(f.full_name, f.topic_key);
  gateByKey.set(k, [...(gateByKey.get(k) ?? []), f]);
}

// ---------------------------------------------------------------- load the bundle's ladders (I7)
// topics.json is the exact question set the researcher scored against: each topic's pinned
// topic_revision_id at the moment build-stance-topic-bundle.ts ran. Checked against the open
// season's CURRENT pin below.
let bundleTopicsRaw: unknown;
try {
  bundleTopicsRaw = JSON.parse(readFileSync(topicsPath, 'utf8'));
} catch (err) {
  const msg = err instanceof Error ? err.message : String(err);
  console.error(`ERROR: ${topicsPath} is not valid JSON: ${msg}`);
  process.exit(2);
}
const isBundleTopic = (t: unknown): t is { topic_key: string; topic_revision_id: string } =>
  typeof t === 'object' && t !== null
  && typeof (t as Record<string, unknown>).topic_key === 'string'
  && typeof (t as Record<string, unknown>).topic_revision_id === 'string';
if (!Array.isArray(bundleTopicsRaw) || bundleTopicsRaw.length === 0 || !bundleTopicsRaw.every(isBundleTopic)) {
  console.error(`ERROR: ${topicsPath} is not valid JSON: expected a non-empty array of topics with string topic_key/topic_revision_id`);
  process.exit(2);
}
const bundleRevisionByKey = new Map(
  (bundleTopicsRaw as { topic_key: string; topic_revision_id: string }[])
    .map((t) => [normTopic(t.topic_key), t.topic_revision_id]),
);

// ---------------------------------------------------------------- editor pre-flight (M4)
// A uuid that names nobody fails the editor_id FK on the FIRST stance write — after every page
// has been fetched, and (before transactions) after the answer row. Refuse it before anything.
if (APPLY) {
  const { rows: editor } = await pool.query(`SELECT 1 FROM public.users WHERE id = $1`, [EDITOR_ID]);
  if (editor.length === 0) {
    console.error(`ERROR: --editor-id ${EDITOR_ID} is not a user in public.users — refusing to write stances nobody can be asked about`);
    await pool.end();
    process.exit(2);
  }
}

// ---------------------------------------------------------------- resolve politicians + topics
// D1: resolve by the bundle's politician_id first. full_name is not unique here — duplicate
// discovery stubs and namesakes are real (e.g. three "Rachael Himsel" records existed until
// 2026-09-22) — so a name-only join can silently write a stance onto the wrong person.
const csvNames = [...new Set(stanceRows.map((s) => s.full_name))];
const idsByName = new Map<string, Set<string>>();
for (const s of stanceRows) {
  if (!s.politician_id) continue;
  const set = idsByName.get(s.full_name) ?? new Set<string>();
  set.add(s.politician_id);
  idsByName.set(s.full_name, set);
}
const idsToLookUp = [...new Set([...idsByName.values()].flatMap((set) => [...set]))];
// Compare as text so a malformed id in the CSV cannot throw a uuid cast error.
const { rows: idRows } = idsToLookUp.length
  ? await pool.query<{ id: string; full_name: string }>(
      `SELECT id::text AS id, full_name FROM essentials.politicians WHERE id::text = ANY($1::text[])`,
      [idsToLookUp],
    )
  : { rows: [] };
const polById = new Map(idRows.map((p) => [p.id, p]));

const namesNeedingFallback = csvNames.filter((n) => (idsByName.get(n)?.size ?? 0) === 0);
const { rows: nameRows } = namesNeedingFallback.length
  ? await pool.query<{ id: string; full_name: string }>(
      `SELECT id::text AS id, full_name FROM essentials.politicians
       WHERE lower(full_name) = ANY(SELECT lower(n) FROM unnest($1::text[]) AS n)`,
      [namesNeedingFallback],
    )
  : { rows: [] };
const nameMatchesByLower = new Map<string, { id: string; full_name: string }[]>();
for (const p of nameRows) {
  const k = p.full_name.toLowerCase();
  nameMatchesByLower.set(k, [...(nameMatchesByLower.get(k) ?? []), p]);
}

const lastToken = (name: string) => name.trim().split(/\s+/).filter(Boolean).slice(-1)[0] ?? name;

const politicianNames: PoliticianNames = {};
const idByName = new Map<string, string | null>(); // csv name -> politician_id (or null if unmatched)
for (const name of csvNames) {
  const ids = idsByName.get(name);
  let resolved: { id: string; full_name: string } | null = null;
  if (ids && ids.size === 1) {
    const [id] = ids;
    const p = polById.get(id);
    if (p) {
      resolved = p;
    } else {
      console.warn(`WARN: ${name} carries politician_id ${id}, which is not in essentials.politicians — unresolved`);
    }
  } else if (ids && ids.size > 1) {
    console.warn(`WARN: ${name} carries ${ids.size} distinct politician_ids in this batch (${[...ids].join(', ')}) — unresolved`);
  } else {
    const matches = nameMatchesByLower.get(name.toLowerCase()) ?? [];
    if (matches.length === 1) {
      resolved = matches[0];
    } else if (matches.length > 1) {
      console.warn(`WARN: ${name} matches ${matches.length} politicians by name — unresolved (carries no politician_id to disambiguate)`);
    }
  }
  const canonical = resolved?.full_name ?? name;
  politicianNames[name] = { fullName: canonical, lastName: lastToken(canonical) };
  idByName.set(name, resolved?.id ?? null);
}

// 🔴 The open season's question set — not is_live. A stance can only be written to a
// question the open season asks; is_live and the season's set disagreed on 2026-09-22.
const { rows: topicRows } = await pool.query<{ topic_id: string; topic_key: string; topic_revision_id: string }>(
  `SELECT t.id AS topic_id, t.topic_key, sq.topic_revision_id::text AS topic_revision_id
     FROM inform.season_questions sq
     JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
     JOIN inform.compass_topics t ON t.id = sq.topic_id`,
);
const topicIdByKey = new Map(topicRows.map((t) => [normTopic(t.topic_key), t.topic_id]));
const openRevisionByKey = new Map(topicRows.map((t) => [normTopic(t.topic_key), t.topic_revision_id]));
if (topicRows.length === 0) {
  console.error('ERROR: no open season (or it asks no questions) — nothing can be verified against a pin or written; open a season first');
  await pool.end();
  process.exit(2);
}

// ---------------------------------------------------------------- the ladder must still be the pin (I7)
// A value is an answer to one ladder's wording. If the open season re-pinned a topic (or dropped
// it) after the bundle was built, the researcher scored against a sentence the stored answer
// would not be an answer to. Checked for every scored row's topic that the bundle holds (a topic
// the bundle lacks is already a gate-high `topic-not-in-season`), before any fetch or write.
const ladderChanged = [...new Set(stanceRows.map((s) => normTopic(s.topic_key)))]
  .filter((k) => bundleRevisionByKey.has(k) && bundleRevisionByKey.get(k) !== openRevisionByKey.get(k))
  .sort();
if (ladderChanged.length) {
  console.error(`ERROR: the ladder changed since the bundle was built — rebuild the bundle and re-research these topics: ${ladderChanged
    .map((k) => `${k} (bundle ${bundleRevisionByKey.get(k)}, open season ${openRevisionByKey.get(k) ?? 'no longer asks it'})`).join('; ')}`);
  await pool.end();
  process.exit(2);
}

// ---------------------------------------------------------------- one row per pair (C1)
// Two rows proposing a value for one (politician, topic) pair verify each other's snippets and
// both reach decidePublish. stance-gate flags them `duplicate-row` (high); this is the verifier's
// own refusal, so a stale or hand-edited gate-findings.json cannot let one through. Keyed by the
// resolved (politician_id, topic_id) where there is one — two spellings of one person are one
// person — else by the normalized name + topic. Checked over every scored row (the same set
// `decided` is built from below) before any page is fetched, and before any write.
const pairKey = (s: StanceRow): string => {
  const pid = idByName.get(s.full_name) ?? null;
  if (!pid) return `name:${stanceKey(s.full_name, s.topic_key)}`;
  return `id:${pid}\u0000${topicIdByKey.get(normTopic(s.topic_key)) ?? `key:${normTopic(s.topic_key)}`}`;
};
const rowsByPair = new Map<string, StanceRow[]>();
for (const s of stanceRows) rowsByPair.set(pairKey(s), [...(rowsByPair.get(pairKey(s)) ?? []), s]);
const duplicatePairs = [...rowsByPair.values()].filter((rs) => rs.length > 1);
if (duplicatePairs.length) {
  console.error('ERROR: more than one scored row for one (politician, topic) pair — refusing to decide or write any of them. '
    + 'A re-research pass must REPLACE the pair\'s rows in research.csv/evidence.csv, never append; fix and re-run stance-gate.ts: '
    + duplicatePairs.map((rs) => `${rs.map((s) => `${s.full_name}/${s.topic_key}=${s.value}`).join(' + ')}`).join('; '));
  await pool.end();
  process.exit(2);
}

// ---------------------------------------------------------------- verify
// Tiered fetch ladder (HTTP → Wayback). No LLM in the loop.
const fetchSession = createVerificationFetchSession();
const fetcher = createPageFetcher(fetchSession.fetch);
const { pushable, needsReResearch } = await verifyEvidence({
  stanceRows,
  evidenceRows,
  fetcher,
  threshold: THRESHOLD,
  politicianNames,
});
await fetchSession.close();

const failedUrls = (row: VerifiedRow) => row.failedSources.map((s) => s.url);

// Existing OPEN-season values — the thing a write would replace.
const existing = new Map<string, number>();
for (const pid of new Set([...idByName.values()].filter((v): v is string => Boolean(v)))) {
  const { rows } = await pool.query<{ topic_id: string; value: string }>(OPEN_SEASON_ANSWER_SQL, [pid]);
  for (const r of rows) existing.set(`${pid} ${r.topic_id}`, Number(r.value));
}

type Decided = { row: VerifiedRow; pid: string | null; tid: string | null; decision: Decision };
const decided: Decided[] = [...pushable, ...needsReResearch].map((row) => {
  const pid = idByName.get(row.stance.full_name) ?? null;
  const tid = topicIdByKey.get(normTopic(row.stance.topic_key)) ?? null;
  const ex = pid && tid ? existing.get(`${pid} ${tid}`) : undefined;
  const decision = decidePublish({
    proposedValue: row.stance.value as number,
    verifiedSourceCount: row.verifiedSources.length,
    threshold: THRESHOLD,
    gateFindings: gateByKey.get(stanceKey(row.stance.full_name, row.stance.topic_key)) ?? [],
    politicianResolved: Boolean(pid),
    existingOpenSeasonValue: ex === undefined ? null : ex,
    autoPushEnabled: AUTO_PUSH,
  });
  return { row, pid, tid, decision };
});
const bucket = (a: Decision['action']) => decided.filter((d) => d.decision.action === a);
const reasonsOf = (d: Decided): string[] => ('reasons' in d.decision ? [...d.decision.reasons] : []);

// Review rows and below-threshold rows go to the human queue. Gate-high rows are NOT written:
// the research itself is defective — send those pairs back to the researcher and re-run.
const queued = decided.filter((d) => d.decision.action === 'review'
  || (d.decision.action === 're-research' && reasonsOf(d).includes('below-threshold')));
const queuedSet = new Set(queued);
// Ruling 2026-09-22 (I4): an unresolved politician's row IS saved (status unresolved_politician,
// full_name_raw kept), but the admin queue lists only `pending` rows — so nobody will see it
// there. Say so, in the console and in publish-report.json, instead of implying it is queued.
const notInAdminQueue = queued.filter((d) => !d.pid);

writeFileSync(join(DIR, 'publish-report.json'), JSON.stringify(decided.map((d) => ({
  full_name: d.row.stance.full_name, topic_key: d.row.stance.topic_key, value: d.row.stance.value,
  action: d.decision.action, reasons: reasonsOf(d),
  verified_sources: d.row.verifiedSources.map((s) => s.url), failed_urls: failedUrls(d.row),
  // Only on rows that go to inform.stance_research_review: true = a `pending` row the admin
  // review queue lists; false = saved as unresolved_politician, which that queue does not list.
  ...(queuedSet.has(d) ? { admin_queue_visible: Boolean(d.pid) } : {}),
})), null, 2));

console.log(`\n=== verify-stance-research — batch "${BATCH_ID}" (threshold ${THRESHOLD}) ===`);
console.log(AUTO_PUSH
  ? 'mode: --auto-push — rows that pass every check are written without a person'
  : 'mode: review-all (default) — every stance goes to a person; pass --auto-push to publish clean rows unattended');
console.log(`stance rows: ${allStances.length} (${stanceRows.length} scored, ${nullRows.length} value=null skipped) | evidence rows: ${evidenceRows.length}`);
console.log(`AUTO-PUSH: ${bucket('auto-push').length}  UNCHANGED: ${bucket('unchanged').length}  REVIEW: ${bucket('review').length}  RE-RESEARCH: ${bucket('re-research').length}`);
for (const d of decided) {
  const s = d.row.stance;
  console.log(`  ${d.decision.action.toUpperCase().padEnd(11)} ${s.full_name}\t${s.topic_key}\tvalue=${s.value}\tverified=${d.row.verifiedSources.length}`
    + (reasonsOf(d).length ? `\t[${reasonsOf(d).join(', ')}]` : '')
    + (d.decision.action === 're-research' ? `\texclude-urls=${failedUrls(d.row).join(',') || '(none)'}` : ''));
}
if (nullRows.length) {
  console.log('\n--- value=null (skipped; not pushed, not queued) ---');
  for (const s of nullRows) console.log(`  SKIP\t${s.full_name}\t${s.topic_key}`);
}
if (notInAdminQueue.length) {
  console.log('\n--- NOT IN THE ADMIN QUEUE — politician not resolved; rebuild the bundle with this person (--politician <uuid>:<level>) and re-run: ---');
  for (const d of notInAdminQueue) console.log(`  UNRESOLVED\t${d.row.stance.full_name}\t${d.row.stance.topic_key}\tvalue=${d.row.stance.value}`);
}
console.log(`\nwrote ${join(DIR, 'publish-report.json')}`);

// ---------------------------------------------------------------- apply
if (!APPLY) {
  console.log('\n(dry-run — pass --apply to write answers/context/evidence and review-queue rows)');
  await pool.end();
  // ⚠ Do NOT process.exit() here. This runs after the fetch session above (createVerificationFetchSession /
  // createPageFetcher), and Node's fetch keeps pooled sockets alive for a moment after the last
  // request — exiting hard while they are closing can trip a libuv assertion on some platforms
  // that replaces our exit code with a wrong one (`UV_HANDLE_CLOSING`, src/win/async.c). That is
  // exactly what verify-quotes.mjs (backend/scripts/verify-quotes.mjs) hit for real on a live wave.
  // A gate whose exit code can be overwritten at teardown is not a gate, so set exitCode and let
  // the loop drain naturally, with an unref'd backstop so a wedged socket still cannot hang CI.
  process.exitCode = 0;
  setTimeout(() => process.exit(process.exitCode ?? 0), 5000).unref();
} else {
  console.log('\n=== --apply: writing to database ===');
  let pushed = 0;
  let snippetsAttempted = 0;
  let snippetsInserted = 0;
  let reviewed = 0;
  let leftDecided = 0;
  const errors: string[] = [];
  const pushedPoliticianIds = new Set<string>();

  for (const d of bucket('auto-push')) {
    const { row, pid, tid } = d;
    if (!pid || !tid) {
      errors.push(`PUSH ${row.stance.full_name}/${row.stance.topic_key}: ${!pid ? 'no politician_id' : 'topic_key not in the open season'} — skipped`);
      continue;
    }
    // I6: the answer, its context and its snippets commit together or not at all. Before this, a
    // failure after the answer write left a value with no reasoning, and nothing re-ran it.
    const evRows = buildEvidenceRowsForInsert({ row, politicianId: pid, topicId: tid, batchId: BATCH_ID });
    // R3: pool.connect() runs INSIDE the try — a connect failure (pool exhausted, a network blip) is
    // then a per-row error like any other; the review loop and SUMMARY below still run for the rest
    // of the batch. Before this, `c` was assigned before the try, so a rejected connect() threw
    // straight out of the for-loop body, uncaught, and killed the whole --apply run after however
    // many rows had already pushed.
    let c: PoolClient | undefined;
    try {
      c = await pool.connect();
      await c.query('BEGIN');
      await writeVerifiedStance({
        politicianId: pid, topicId: tid, value: row.stance.value as number,
        reasoning: row.stance.reasoning, sources: row.verifiedSources.map((s) => s.url), editorId: EDITOR_ID,
      }, c);
      const inserted = await accumulateEvidence(evRows, c);
      await c.query('COMMIT');
      pushed++; snippetsAttempted += evRows.length; snippetsInserted += inserted; pushedPoliticianIds.add(pid);
      console.log(`  PUSHED ${row.stance.full_name}/${row.stance.topic_key} value=${row.stance.value} (snippets inserted ${inserted} of ${evRows.length})`);
    } catch (e: any) {
      await c?.query('ROLLBACK').catch(() => undefined);
      errors.push(`PUSH ${row.stance.full_name}/${row.stance.topic_key}: ${e.message}`
        + (c ? ' — rolled back, nothing written for this row' : ' — could not open a connection, nothing written for this row'));
    } finally {
      c?.release();
    }
  }

  for (const d of queued) {
    const { row, pid, tid } = d;
    try {
      // R7: --re-researched stamps a queued row only when it is actually a re-research attempt
      // (a below-threshold row) — NOT every queued row. Under review-all (the default) most queued
      // rows are ordinary review rows (review-all-mode, value-change, statement-evidence, …), never
      // re-researched at all; stamping all of them re_research_attempted=true misled the reviewer UI
      // into showing "Re-research attempted" on a row nobody had re-researched.
      const reResearchAttempted = RE_RESEARCHED && reasonsOf(d).includes('below-threshold');
      const wrote = await upsertReviewRow(buildReviewRowForInsert({
        row, politicianId: pid, topicId: pid ? tid : null, batchId: BATCH_ID,
        threshold: THRESHOLD, reResearchAttempted,
      }));
      if (!wrote) {
        // I1: this batch's row for the pair was already resolved or rejected by a person.
        leftDecided++;
        console.log(`  LEFT ALONE ${row.stance.full_name}/${row.stance.topic_key} — already decided in the review queue`);
        continue;
      }
      reviewed++;
      console.log(`  REVIEW ${row.stance.full_name}/${row.stance.topic_key}${pid ? '' : ' (unresolved_politician — NOT in the admin queue)'}`);
      // No citations are written for a queued row (ruling 2026-09-22, R1): accumulateEvidence
      // attaches a snippet to the pair's newest published context row, and citations render with
      // no batch filter — so a snippet for a PROPOSED value would show under whatever stance is
      // displayed right now, before anyone approves. The review row already stores every snippet
      // with its verdict (buildReviewRowForInsert, above) — resolveResearchReview writes the
      // machine-verified ones on approval.
    } catch (e: any) {
      errors.push(`REVIEW ${row.stance.full_name}/${row.stance.topic_key}: ${e.message}`);
    }
  }

  if (pushedPoliticianIds.size) {
    await pool.query(
      `UPDATE essentials.politicians SET last_stances_researched_at = NOW() WHERE id = ANY($1::uuid[])`,
      [[...pushedPoliticianIds]],
    );
  }

  console.log(
    `\nSUMMARY: pushed=${pushed} (snippets inserted=${snippetsInserted} of ${snippetsAttempted} attempted) `
    + `reviewed=${reviewed} left-alone(already decided)=${leftDecided} not-in-admin-queue=${notInAdminQueue.length} `
    + `stamped=${pushedPoliticianIds.size} errors=${errors.length}`,
  );
  if (snippetsInserted < snippetsAttempted) {
    console.log(`  ${snippetsAttempted - snippetsInserted} snippet(s) were not inserted: the unique index on `
      + 'politician_context_evidence (politician_id, topic_id, source_url, snippet_index) has no season column, '
      + 'so a snippet already stored for that pair (from an earlier batch or season) was dropped as already present.');
  }
  if (notInAdminQueue.length) {
    console.log(`  ${notInAdminQueue.length} row(s) saved as unresolved_politician are NOT in the admin queue — see the list above; rebuild the bundle with those people and re-run.`);
  }
  if (errors.length) {
    errors.forEach((e) => console.log('  ' + e));
    process.exitCode = 1;
  }
  await pool.end();
}
