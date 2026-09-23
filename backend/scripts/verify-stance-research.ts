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
 * Requires <dir>/gate-findings.json from scripts/stance-gate.ts.
 *
 * Idempotent: re-running the same batch is safe — all writes are upserts /
 * replace-by-key. A re-research pass adds rows to research.csv / evidence.csv and
 * re-runs scripts/stance-gate.ts (which regenerates stances.csv and
 * gate-findings.json together) — appending straight to stances.csv instead would
 * fail the row-count check against gate-findings.json below.
 */
import 'dotenv/config';
import { readFileSync, existsSync, writeFileSync } from 'node:fs';
import { join, basename } from 'node:path';
import { pool } from '../src/lib/db.js';
import { parseStancesCsv, parseEvidenceCsv } from '../src/lib/stanceResearchCsv.js';
import {
  verifyEvidence,
  createPageFetcher,
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
import type { GateFinding } from './lib/stanceGate.js';

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
const RE_RESEARCHED = flag('--re-researched'); // stamp review rows as re_research_attempted

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
function isFindingShape(f: unknown): f is GateFinding {
  if (typeof f !== 'object' || f === null) return false;
  const r = f as Record<string, unknown>;
  return typeof r.full_name === 'string' && typeof r.topic_key === 'string'
    && typeof r.check_id === 'string' && typeof r.severity === 'string';
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
  console.error(`ERROR: ${gatePath} is not valid JSON: .findings must be an array of findings with string full_name/topic_key/check_id/severity`);
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
const gateByKey = new Map<string, GateFinding[]>();
for (const f of findings) {
  const k = `${f.full_name.toLowerCase()} ${f.topic_key}`;
  gateByKey.set(k, [...(gateByKey.get(k) ?? []), f]);
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
const { rows: topicRows } = await pool.query<{ topic_id: string; topic_key: string }>(
  `SELECT t.id AS topic_id, t.topic_key
     FROM inform.season_questions sq
     JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
     JOIN inform.compass_topics t ON t.id = sq.topic_id`,
);
const topicIdByKey = new Map(topicRows.map((t) => [t.topic_key, t.topic_id]));

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
  const tid = topicIdByKey.get(row.stance.topic_key) ?? null;
  const ex = pid && tid ? existing.get(`${pid} ${tid}`) : undefined;
  const decision = decidePublish({
    proposedValue: row.stance.value as number,
    verifiedSourceCount: row.verifiedSources.length,
    threshold: THRESHOLD,
    gateFindings: gateByKey.get(`${row.stance.full_name.toLowerCase()} ${row.stance.topic_key}`) ?? [],
    politicianResolved: Boolean(pid),
    existingOpenSeasonValue: ex === undefined ? null : ex,
    autoPushEnabled: AUTO_PUSH,
  });
  return { row, pid, tid, decision };
});
const bucket = (a: Decision['action']) => decided.filter((d) => d.decision.action === a);
const reasonsOf = (d: Decided): string[] => ('reasons' in d.decision ? [...d.decision.reasons] : []);

writeFileSync(join(DIR, 'publish-report.json'), JSON.stringify(decided.map((d) => ({
  full_name: d.row.stance.full_name, topic_key: d.row.stance.topic_key, value: d.row.stance.value,
  action: d.decision.action, reasons: reasonsOf(d),
  verified_sources: d.row.verifiedSources.map((s) => s.url), failed_urls: failedUrls(d.row),
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
console.log(`\nwrote ${join(DIR, 'publish-report.json')}`);

// ---------------------------------------------------------------- apply
if (!APPLY) {
  console.log('\n(dry-run — pass --apply to write answers/context/evidence and review-queue rows)');
  await pool.end();
  process.exit(0);
}

console.log('\n=== --apply: writing to database ===');
let pushed = 0;
let evidenceWritten = 0;
let reviewed = 0;
const errors: string[] = [];
const pushedPoliticianIds = new Set<string>();

for (const d of bucket('auto-push')) {
  const { row, pid, tid } = d;
  if (!pid || !tid) {
    errors.push(`PUSH ${row.stance.full_name}/${row.stance.topic_key}: ${!pid ? 'no politician_id' : 'topic_key not in the open season'} — skipped`);
    continue;
  }
  try {
    await writeVerifiedStance({
      politicianId: pid, topicId: tid, value: row.stance.value as number,
      reasoning: row.stance.reasoning, sources: row.verifiedSources.map((s) => s.url), editorId: EDITOR_ID,
    });
    const evRows = buildEvidenceRowsForInsert({ row, politicianId: pid, topicId: tid, batchId: BATCH_ID });
    await accumulateEvidence(evRows);
    pushed++; evidenceWritten += evRows.length; pushedPoliticianIds.add(pid);
    console.log(`  PUSHED ${row.stance.full_name}/${row.stance.topic_key} value=${row.stance.value} (${evRows.length} snippets)`);
  } catch (e: any) {
    errors.push(`PUSH ${row.stance.full_name}/${row.stance.topic_key}: ${e.message}`);
  }
}

// Review rows and below-threshold rows go to the human queue. Gate-high rows are NOT written:
// the research itself is defective — fix research.csv / evidence.csv and re-run.
const queued = decided.filter((d) => d.decision.action === 'review'
  || (d.decision.action === 're-research' && reasonsOf(d).includes('below-threshold')));
for (const { row, pid, tid } of queued) {
  try {
    await upsertReviewRow(buildReviewRowForInsert({
      row, politicianId: pid, topicId: pid ? tid : null, batchId: BATCH_ID,
      threshold: THRESHOLD, reResearchAttempted: RE_RESEARCHED,
    }));
    reviewed++;
    console.log(`  REVIEW ${row.stance.full_name}/${row.stance.topic_key}`);
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
  `\nSUMMARY: pushed=${pushed} (snippets=${evidenceWritten}) reviewed=${reviewed} stamped=${pushedPoliticianIds.size} errors=${errors.length}`,
);
if (errors.length) {
  errors.forEach((e) => console.log('  ' + e));
  process.exitCode = 1;
}
await pool.end();
