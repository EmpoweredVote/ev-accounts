/**
 * stage5Write.ts — Stage 5 step 7: turn checked codes into the rows the draft season stores.
 *
 * `planBatch` takes one batch of codes, the people's saved findings and the quote checks, and returns:
 *   - `outcomes` — one inform.topic_research_outcomes row per code: the "we researched" marker (spec §8).
 *   - `passages` — one inform.own_words_passages row per shown passage: a doesnt-fit code's cited own words,
 *     and its cited local records described in plain words (the finding's note). Only a passage whose newest
 *     quote check, for this person and topic, passed. A party label never reaches a voter (RULINGS.md "Party
 *     labels never reach a reader"): own words carry it bracketed out in `shown_text`, which must change
 *     nothing but the labels (bracketEditProblem); a note or shown text that still has one is refused.
 *   - `researchCsv` — seats and blanks for the existing pipeline (stance-gate.ts → verify-stance-research.ts
 *     --season draft), so stanceGate, decidePublish and the pre-write audit still run. An own-words seat is
 *     `statement` evidence, so it keeps the `statement-evidence` hold (RULINGS.md "Stage 5 rulings").
 *   - `refused` — codes not written at all (`kind: 'code'`), and passages kept off the page (`kind: 'passage'`).
 *     A local record is shown only beside at least one shown own-words passage (spec §8), and only when its
 *     check also confirmed the plain-words note is a fair summary. Every check must cover the exact text
 *     stored (`shown_sha256`), so text changed after its check has no check.
 *   - `notInCsv` — blanks whose Stage 5 detail maps to no single codebook V6 reason: their outcome row is
 *     written, but the research.csv row is left for the runner to add by hand.
 *
 * Rows carry `topic_key`; the CLI (topic-stage5-write.ts) resolves topic ids and writes in one transaction.
 * Pure.
 */
import { stringify } from 'csv-stringify/sync';
import type { BlankReason } from '../../src/lib/blankReasons.js';
import { checkCode, type Stage5Code } from './stage5Code.js';
import { bracketEditProblem, namesParty, pageText, passageOnPage, shownSha256, type QuoteCheck } from './stage5QuoteCheck.js';
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
  /** Own words: the exact words, never edited. Local record: the plain-words note. */
  passage: string;
  /** Own words with each party label bracketed out (CA_0337); null when the passage has none. Voters see this. */
  shown_text: string | null;
  source_url: string;
  source_date: string | null;
  source_date_precision: Finding['date_precision'];
  quote_check: 'passed';
  quote_checked_at: string;
  quote_checker: string;
};

/** `code`: the whole code was not written. `passage`: one passage kept off the page; the outcome is still written. */
export type Refusal = { politician_id: string; kind: 'code' | 'passage'; reason: string };

export type BatchPlan = {
  outcomes: OutcomeRow[];
  passages: PassageRow[];
  researchCsv: string;
  refused: Refusal[];
  notInCsv: { politician_id: string; reason: string }[];
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

/**
 * The newest check for this finding, person and topic, made since the code was. A later run overrides an
 * earlier one, and a check from before the code (an earlier run) never carries over. Compared as times.
 */
function newestCheck(checks: QuoteCheck[], f: Finding, code: Stage5Code): QuoteCheck | undefined {
  const since = Date.parse(code.coded_at);
  return checks
    .filter((c) => c.finding_id === f.id && c.politician_id === code.politician_id && c.topic_key === code.topic_key)
    .filter((c) => !(Date.parse(c.at) < since))
    .sort((a, b) => Date.parse(a.at) - Date.parse(b.at))
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
  const notInCsv: { politician_id: string; reason: string }[] = [];
  const csvRows: { full_name: string; topic_key: string; value: number; reasoning: string; evidence_type: string; blank_reason: string; urls: string[] }[] = [];
  const seen = new Set<string>();

  for (const code of codes) {
    const pid = code.politician_id;
    const refuse = (reason: string) => refused.push({ politician_id: pid, kind: 'code', reason });
    const keepOff = (reason: string) => refused.push({ politician_id: pid, kind: 'passage', reason });
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
      const shownHere: { row: PassageRow; checker: string }[] = [];
      for (const f of cited) {
        const kind = shownKind(f);
        if (!kind) continue;
        const stored = kind === 'own-words' ? f.passage! : f.note;
        const c = newestCheck(checks, f, code);
        const label = `finding ${f.id.slice(0, 12)}…`;
        if (!c) { keepOff(`${label}: no quote check since this code was made; kept off the page`); continue; }
        if (c.verdict !== 'passed') { keepOff(`${label}: quote check failed (${c.reason}); kept off the page`); continue; }
        const shownText = c.shown_text ?? null;
        if (shownText !== null && kind !== 'own-words') { keepOff(`${label}: only own words carry a bracketed shown text; a local record's note is ours and names no party`); continue; }
        // What voters see: the bracketed text when the check wrote one, else the stored words.
        const seen = shownText ?? stored;
        if (c.shown_sha256 !== shownSha256(seen)) { keepOff(`${label}: text changed since its quote check; check it again`); continue; }
        if (kind === 'local-record' && c.fair_summary !== true) { keepOff(`${label}: a local record needs its check to confirm the note is a fair summary`); continue; }
        if (shownText !== null) {
          const problem = bracketEditProblem(stored, shownText);
          if (problem) { keepOff(`${label}: shown text is not a clean bracket edit (${problem}); check it again`); continue; }
        }
        if (namesParty(seen)) { keepOff(`${label}: a party label would reach voters; bracket it out in shown_text, or leave it off`); continue; }
        shownHere.push({
          checker: c.checker,
          row: {
            politician_id: pid, topic_key: code.topic_key, season_id: code.season_id, finding_id: f.id, kind,
            passage: stored, shown_text: shownText, source_url: f.url, source_date: isDate(f.date) ? f.date : null,
            source_date_precision: f.date_precision, quote_check: 'passed', quote_checked_at: c.at, quote_checker: c.checker,
          },
        });
      }
      // A local record supports their own words; it is never shown alone (spec §8).
      const ownWordsShown = shownHere.some((x) => x.row.kind === 'own-words');
      for (const x of shownHere) {
        if (!ownWordsShown) { keepOff(`finding ${x.row.finding_id.slice(0, 12)}…: a local record is never shown alone, and none of their own words passed`); continue; }
        checkers.add(x.checker);
        passages.push(x.row);
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
    // The season was checked before the dry run; check again inside the write, holding it while we write.
    const { rows: seasonRows } = await q('SELECT status FROM inform.seasons WHERE id = $1 FOR SHARE', [seasonId]);
    if (seasonRows[0]?.status !== 'draft') throw new Error(`season ${seasonId} is no longer a draft (${seasonRows[0]?.status ?? 'missing'}); nothing written`);
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

    for (const row of plan.outcomes) {
      await q(
        `INSERT INTO inform.topic_research_outcomes (politician_id, topic_id, season_id, outcome, researched_on, checked_by)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (politician_id, topic_id, season_id)
         DO UPDATE SET outcome = EXCLUDED.outcome, researched_on = EXCLUDED.researched_on, checked_by = EXCLUDED.checked_by`,
        [row.politician_id, topicId.get(row.topic_key), row.season_id, row.outcome, row.researched_on, row.checked_by],
      );
      await q(
        'DELETE FROM inform.own_words_passages WHERE politician_id = $1 AND topic_id = $2 AND season_id = $3',
        [row.politician_id, topicId.get(row.topic_key), row.season_id],
      );
    }
    for (const p of plan.passages) {
      // CA_0337's column is named only when the row carries a bracketed text, so a batch without one writes the
      // same SQL as before that migration.
      const bracketed = p.shown_text !== null ? { col: ', shown_text', val: ', $13' } : { col: '', val: '' };
      await q(
        `INSERT INTO inform.own_words_passages
           (politician_id, topic_id, season_id, finding_id, kind, passage, source_url, source_date, source_date_precision,
            quote_check, quote_checked_at, quote_checker${bracketed.col})
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12${bracketed.val})`,
        [p.politician_id, topicId.get(p.topic_key), p.season_id, p.finding_id, p.kind, p.passage, p.source_url,
          p.source_date, p.source_date_precision, p.quote_check, p.quote_checked_at, p.quote_checker,
          ...(p.shown_text !== null ? [p.shown_text] : [])],
      );
    }
    await q('COMMIT');
  } catch (err) {
    await q('ROLLBACK');
    throw err;
  }
  return { outcomes: plan.outcomes.length, passages: plan.passages.length };
}

/**
 * Why `--apply` must not run, or null. A refused code is never written, so its person's earlier outcome and
 * passages would stay live from the last write; the codes are fixed first. Refused passages do not block:
 * they stay off the page because the person's passages are replaced whole.
 */
export function applyBlocker(plan: BatchPlan): string | null {
  const n = plan.refused.filter((r) => r.kind === 'code').length;
  return n ? `${n} code(s) refused: fix them and dry-run again before --apply (an earlier write for those people would stay live)` : null;
}

/**
 * Re-fetch each own-words passage's page and keep it only when `passageOnPage` finds it there: a mechanical
 * check beside the quote-check agent's word. A page that cannot be fetched keeps the agent's verdict and is
 * listed in `unchecked`. A local record left with none of the person's own words is dropped, as in planBatch.
 */
export async function refusePassagesNotOnPage(
  plan: BatchPlan,
  fetchText: (url: string) => Promise<string>,
): Promise<BatchPlan & { unchecked: { politician_id: string; reason: string }[] }> {
  const pages = new Map<string, Promise<string>>();
  const page = (url: string) => {
    if (!pages.has(url)) pages.set(url, fetchText(url).then(pageText));
    return pages.get(url)!;
  };
  const refused = [...plan.refused];
  const unchecked: { politician_id: string; reason: string }[] = [];
  const kept: PassageRow[] = [];
  for (const p of plan.passages) {
    if (p.kind !== 'own-words') { kept.push(p); continue; }
    const label = `finding ${p.finding_id.slice(0, 12)}…`;
    let text: string;
    try {
      text = await page(p.source_url);
    } catch (err) {
      unchecked.push({ politician_id: p.politician_id, reason: `${label}: could not re-fetch ${p.source_url} (${err instanceof Error ? err.message : String(err)}); kept on the quote check alone` });
      kept.push(p);
      continue;
    }
    if (passageOnPage(p.passage, text)) kept.push(p);
    else refused.push({ politician_id: p.politician_id, kind: 'passage', reason: `${label}: not on the page when re-fetched; kept off the page` });
  }
  const withOwnWords = new Set(kept.filter((p) => p.kind === 'own-words').map((p) => `${p.politician_id} ${p.topic_key}`));
  const passages = kept.filter((p) => {
    if (p.kind === 'own-words' || withOwnWords.has(`${p.politician_id} ${p.topic_key}`)) return true;
    refused.push({ politician_id: p.politician_id, kind: 'passage', reason: `finding ${p.finding_id.slice(0, 12)}…: a local record is never shown alone, and none of their own words passed` });
    return false;
  });
  return { ...plan, passages, refused, unchecked };
}
