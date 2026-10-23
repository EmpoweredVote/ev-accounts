/**
 * stage5Write.ts — Stage 5 step 7: turn checked codes into the rows the draft season stores.
 *
 * `planBatch` takes one batch of codes, the people's saved findings and the quote checks, and returns:
 *   - `outcomes` — one inform.topic_research_outcomes row per code: the "we researched" marker (spec §8).
 *   - `passages` — one inform.own_words_passages row per shown passage: a doesnt-fit code's cited own words,
 *     and its cited local records described in plain words (the finding's note). Only a passage whose newest
 *     quote check, for this person and topic, passed. A passage that names a party is refused even then.
 *   - `researchCsv` — seats and blanks for the existing pipeline (stance-gate.ts → verify-stance-research.ts
 *     --season draft), so stanceGate, decidePublish and the pre-write audit still run. An own-words seat is
 *     `statement` evidence, so it keeps the `statement-evidence` hold (RULINGS.md "Stage 5 rulings").
 *   - `refused` — codes not written at all, and passages kept off the page, each with the reason.
 *   - `notInCsv` — blanks whose Stage 5 detail maps to no single codebook V6 reason: their outcome row is
 *     written, but the research.csv row is left for the runner to add by hand.
 *
 * Rows carry `topic_key`; the CLI (topic-stage5-write.ts) resolves topic ids and writes in one transaction.
 * Pure.
 */
import { stringify } from 'csv-stringify/sync';
import type { BlankReason } from '../../src/lib/blankReasons.js';
import { checkCode, type Stage5Code } from './stage5Code.js';
import { namesParty, type QuoteCheck } from './stage5QuoteCheck.js';
import type { SeasonTarget } from './seasonTarget.js';
import type { Finding, PersonFindings } from './sourceStore.js';

export type OutcomeRow = {
  politician_id: string;
  topic_key: string;
  season_id: string;
  outcome: Stage5Code['outcome'];
  researched_on: string;
  checked_by: string[];
};

export type PassageRow = {
  politician_id: string;
  topic_key: string;
  season_id: string;
  finding_id: string;
  kind: 'own-words' | 'local-record';
  passage: string;
  source_url: string;
  source_date: string | null;
  source_date_precision: Finding['date_precision'];
  quote_check: 'passed';
  quote_checked_at: string;
  quote_checker: string;
};

export type Refusal = { politician_id: string; reason: string };

export type BatchPlan = {
  outcomes: OutcomeRow[];
  passages: PassageRow[];
  researchCsv: string;
  refused: Refusal[];
  notInCsv: Refusal[];
};

/** Stage 5 writes only to the draft season (Global Constraints). */
export function assertDraftSeason(t: SeasonTarget): void {
  if (t.status !== 'draft') {
    throw new Error(`season ${t.number} is ${t.status}: topic:stage5-write writes to the draft season only (--season draft)`);
  }
}

/** The codebook V6 blank reason for a Stage 5 blank, or null when no single reason fits. */
export function blankReasonFor(code: Stage5Code): BlankReason | null {
  if (code.outcome === 'no-stance') return 'no-evidence';
  if (code.outcome !== 'doesnt-fit') return null;
  if (code.tags.includes('direction-only') || code.blank_class === 'nay-only') return 'direction-only';
  if (code.blank_class === 'no-lever' || code.tags.includes('other-level-lever')) return 'scope-unavailable';
  if (code.tags.includes('between-rungs')) return 'adjacent-chairs';
  return null;
}

const day = (iso: string) => iso.slice(0, 10);
const isDate = (s: string) => /^\d{4}-\d{2}-\d{2}$/.test(s);

/** The newest check for this finding, person and topic. A later run overrides an earlier one. */
function newestCheck(checks: QuoteCheck[], f: Finding, code: Stage5Code): QuoteCheck | undefined {
  return checks
    .filter((c) => c.finding_id === f.id && c.politician_id === code.politician_id && c.topic_key === code.topic_key)
    .sort((a, b) => a.at.localeCompare(b.at))
    .at(-1);
}

function shownKind(f: Finding): PassageRow['kind'] | null {
  if (f.kind === 'own-words') return 'own-words';
  return f.local_record ? 'local-record' : null;
}

export function planBatch(
  codes: Stage5Code[],
  findingsByPerson: Map<string, PersonFindings>,
  checks: QuoteCheck[],
  opts: { seasonId: string; names: Map<string, string> },
): BatchPlan {
  const outcomes: OutcomeRow[] = [];
  const passages: PassageRow[] = [];
  const refused: Refusal[] = [];
  const notInCsv: Refusal[] = [];
  const csvRows: { full_name: string; topic_key: string; value: number; reasoning: string; evidence_type: string; blank_reason: string; urls: string[] }[] = [];
  const seen = new Set<string>();

  for (const code of codes) {
    const pid = code.politician_id;
    const refuse = (reason: string) => refused.push({ politician_id: pid, reason });
    if (code.season_id !== opts.seasonId) { refuse(`coded for season ${code.season_id}, not the draft season ${opts.seasonId}`); continue; }
    const key = `${pid} ${code.topic_key}`;
    if (seen.has(key)) { refuse(`more than one code for ${code.topic_key}; keep one`); continue; }
    const pf = findingsByPerson.get(pid);
    if (!pf) { refuse('no findings file on record for this person'); continue; }
    const problems = checkCode(code, pf);
    if (problems.length) { refuse(problems.join('; ')); continue; }
    const name = opts.names.get(pid);
    if (!name) { refuse('not on the roster (no name for research.csv)'); continue; }
    seen.add(key);

    const byId = new Map(pf.findings.map((f) => [f.id, f]));
    const cited = code.finding_ids.map((id) => byId.get(id)!);
    const searches = pf.searches.filter((s) => s.topic_key === code.topic_key && s.season === code.season);
    const lastSearch = searches.map((s) => s.at).sort().at(-1);
    const researchedOn = day(lastSearch ?? code.coded_at);

    const checkers = new Set<string>();
    if (code.outcome === 'doesnt-fit') {
      for (const f of cited) {
        const kind = shownKind(f);
        if (!kind) continue;
        const shown = kind === 'own-words' ? f.passage! : f.note;
        const c = newestCheck(checks, f, code);
        const label = `finding ${f.id.slice(0, 12)}…`;
        if (!c) { refuse(`${label}: no quote check on file; kept off the page`); continue; }
        if (c.verdict !== 'passed') { refuse(`${label}: quote check failed (${c.reason}); kept off the page`); continue; }
        if (namesParty(shown) || (f.passage && namesParty(f.passage))) { refuse(`${label}: names a party; never shown, never edited`); continue; }
        checkers.add(c.checker);
        passages.push({
          politician_id: pid, topic_key: code.topic_key, season_id: code.season_id, finding_id: f.id, kind,
          passage: shown, source_url: f.url, source_date: isDate(f.date) ? f.date : null,
          source_date_precision: f.date_precision, quote_check: 'passed', quote_checked_at: c.at, quote_checker: c.checker,
        });
      }
    }

    outcomes.push({
      politician_id: pid, topic_key: code.topic_key, season_id: code.season_id, outcome: code.outcome,
      researched_on: researchedOn, checked_by: [code.coded_by, ...checkers],
    });

    const citedUrls = [...new Set(cited.map((f) => f.url))];
    if (code.outcome === 'seated') {
      const record = cited.some((f) => f.kind === 'record' && !f.local_record);
      csvRows.push({ full_name: name, topic_key: code.topic_key, value: code.value!, reasoning: code.reasoning, evidence_type: record ? 'record' : 'statement', blank_reason: '', urls: citedUrls });
    } else {
      const reason = blankReasonFor(code);
      if (!reason) {
        notInCsv.push({ politician_id: pid, reason: `blank_class ${code.blank_class ?? '(none)'} with tags [${code.tags.join(', ')}] maps to no single codebook V6 reason; add the research.csv row by hand` });
        continue;
      }
      // A blank's sources are every page the coder examined: the cited findings, then the searched pages.
      const examined = [...new Set([...citedUrls, ...searches.flatMap((s) => s.places).filter((p) => /^https?:\/\//.test(p))])];
      csvRows.push({ full_name: name, topic_key: code.topic_key, value: 0, reasoning: code.reasoning, evidence_type: 'blank', blank_reason: reason, urls: examined });
    }
  }

  const width = Math.max(1, ...csvRows.map((r) => r.urls.length));
  const urlCols = Array.from({ length: width }, (_, i) => `source_url_${i + 1}`);
  const researchCsv = stringify(
    csvRows.map((r) => [r.full_name, r.topic_key, String(r.value), r.reasoning, r.evidence_type, r.blank_reason, ...urlCols.map((_, i) => r.urls[i] ?? '')]),
    { header: true, columns: ['full_name', 'topic_key', 'value', 'reasoning', 'evidence_type', 'blank_reason', ...urlCols] },
  );
  return { outcomes, passages, researchCsv, refused, notInCsv };
}

type Query = (sql: string, params?: unknown[]) => Promise<{ rows: any[] }>;

/**
 * Write one planned batch in one transaction: each outcome (upsert, so a re-run in the draft season replaces
 * it), then each person-topic's passages replaced whole, so a passage whose newest check failed leaves the page.
 * Every topic must be one the target season asks. The caller has checked the season is the draft one.
 */
export async function applyBatch(q: Query, plan: BatchPlan, seasonId: string): Promise<{ outcomes: number; passages: number }> {
  const off = [...plan.outcomes, ...plan.passages].find((r) => r.season_id !== seasonId);
  if (off) throw new Error(`a row is for season ${off.season_id}, not ${seasonId}`);
  const keys = [...new Set(plan.outcomes.map((o) => o.topic_key))];
  await q('BEGIN');
  try {
    const { rows } = await q(
      `SELECT t.id::text AS id, t.topic_key,
              EXISTS (SELECT 1 FROM inform.season_questions sq WHERE sq.season_id = $2 AND sq.topic_id = t.id) AS asked
         FROM inform.compass_topics t
        WHERE t.topic_key = ANY($1::text[])`,
      [keys, seasonId],
    );
    const topicId = new Map<string, string>();
    for (const r of rows) if (r.asked) topicId.set(r.topic_key, r.id);
    const missing = keys.find((k) => !topicId.has(k));
    if (missing) throw new Error(`the draft season does not ask ${missing}; nothing written`);

    for (const o of plan.outcomes) {
      await q(
        `INSERT INTO inform.topic_research_outcomes (politician_id, topic_id, season_id, outcome, researched_on, checked_by)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (politician_id, topic_id, season_id)
         DO UPDATE SET outcome = EXCLUDED.outcome, researched_on = EXCLUDED.researched_on, checked_by = EXCLUDED.checked_by`,
        [o.politician_id, topicId.get(o.topic_key), o.season_id, o.outcome, o.researched_on, o.checked_by],
      );
      await q(
        'DELETE FROM inform.own_words_passages WHERE politician_id = $1 AND topic_id = $2 AND season_id = $3',
        [o.politician_id, topicId.get(o.topic_key), o.season_id],
      );
    }
    for (const p of plan.passages) {
      await q(
        `INSERT INTO inform.own_words_passages
           (politician_id, topic_id, season_id, finding_id, kind, passage, source_url, source_date, source_date_precision,
            quote_check, quote_checked_at, quote_checker)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
        [p.politician_id, topicId.get(p.topic_key), p.season_id, p.finding_id, p.kind, p.passage, p.source_url,
          p.source_date, p.source_date_precision, p.quote_check, p.quote_checked_at, p.quote_checker],
      );
    }
    await q('COMMIT');
  } catch (err) {
    await q('ROLLBACK');
    throw err;
  }
  return { outcomes: plan.outcomes.length, passages: plan.passages.length };
}
