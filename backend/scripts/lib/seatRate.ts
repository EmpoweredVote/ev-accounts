/**
 * seatRate.ts — how many politicians a compass topic seats, per level, and why the rest are blank.
 *
 * Why: the season-topic-prep skill needs one number to compare before and after a wording change,
 * a gate change or a new source: "of the politicians this topic reaches, how many hold a rung?"
 * A blank is `value = 0` (CLAUDE.md "A blank is value = 0"); this report COUNTS blanks as blanks,
 * because it asks about seating, not about position. Half values (2.5) are seated write-ins.
 *
 * Pure apart from the query it is handed: no db.js import (that module validates env at import
 * time), no writes. `loadDbRows` runs one parameterised SELECT.
 */
import { levelForDistrict, type Level } from '../../src/lib/topicApplicability.js';

/**
 * Why a blank is blank. `off-question`: the person's real record (or own words) is on a question this
 * ladder no longer asks, so neither more collection nor a rung change on this question seats it; many such
 * rows are a question-scope matter for the runner. `nay-only`: the only on-question record is a No vote
 * (or a pause or keep vote no rung states), which shows a side for ever (codebook V4.1), so it is not a
 * wording loss. Both are filled by hand: no stored blank reason maps to them.
 */
export type BlankClass = 'source-gap' | 'gate' | 'wording' | 'no-lever' | 'off-question' | 'nay-only';
export type RecordKind = 'vote-yes' | 'vote-no' | 'sponsor' | 'author' | 'own-words' | 'none';
type Query = (sql: string, params?: unknown[]) => Promise<{ rows: any[] }>;

export const LEVELS: Level[] = ['federal', 'state', 'local', 'judicial', 'school'];
export const BLANK_CLASSES: BlankClass[] = ['source-gap', 'gate', 'wording', 'no-lever', 'off-question', 'nay-only'];
const RECORD_KINDS: RecordKind[] = ['vote-yes', 'vote-no', 'sponsor', 'author', 'own-words', 'none'];
const AFFIRMATIVE_KINDS: RecordKind[] = ['vote-yes', 'sponsor', 'author'];
/** The gate values rows.tsv may carry (SKILL.md "rows.tsv columns"; gates from lib/gatePrescreen.ts and the pilots). */
export const GATES = ['multi-subject', 'consent', 'higher-law-duty', 'near-unanimous', 'off-version-sponsor', 'pre-seating', 'study-directive'] as const;

export interface ResearchRow {
  politician_id: string;
  office_id: string;
  level: Level;
  value: number | null;
  blank_reason?: string;
  blank_class?: BlankClass;
  record_kind: RecordKind;
  gate?: string;
  /** First 300 characters of this season's politician_context.reasoning (database rows only; never in rows.tsv). */
  reasoning?: string;
  /** The same for the earliest season's context row, which holds the original evidence of a repair-blanked row. */
  first_reasoning?: string;
}

/** A database answer loadDbRows could not score, reported apart instead of being lost (Stage 0a step 2). */
export interface SkippedRow {
  politician_id: string;
  why: 'no-office' | 'unknown-level';
  value: number | null;
  blank_reason?: string;
}

// `direction-only` is deliberately NOT mapped: a No vote's direction-only can never be fixed by wording
// (class `nay-only`), while a Yea that shows a side but no rung can. Only the runner, reading the record,
// can tell them apart, so the starter rows.tsv leaves it unclassified.
const REASON_CLASS: Record<string, BlankClass> = {
  'no-evidence': 'source-gap',
  'near-unanimous': 'gate', 'multi-subject': 'gate', 'study-directive': 'gate', 'pre-seating': 'gate',
  'adjacent-chairs': 'wording', 'compound-partial': 'wording',
  'record-vs-statement-conflict': 'wording',
  'scope-unavailable': 'no-lever',
};

/** The class a stored blank reason belongs to, or null when the reason is not one we know. */
export function blankClassForReason(reason: string): BlankClass | null {
  return Object.prototype.hasOwnProperty.call(REASON_CLASS, reason) ? REASON_CLASS[reason] : null;
}

// ---- rows.tsv ----------------------------------------------------------------------------------

const COLUMNS = ['politician_id', 'office_id', 'level', 'value', 'blank_reason', 'blank_class', 'record_kind', 'gate'];

export function parseRowsTsv(text: string, file: string): ResearchRow[] {
  const lines = text.split(/\r?\n/);
  const fail = (line: number, col: string, msg: string): never => {
    throw new Error(`${file}: line ${line}, column ${col}: ${msg}`);
  };
  const header = (lines[0] ?? '').split('\t');
  if (header.join('\t') !== COLUMNS.join('\t')) {
    fail(1, 'header', `expected columns ${COLUMNS.join(', ')}; got ${JSON.stringify(lines[0] ?? '')}`);
  }
  const out: ResearchRow[] = [];
  for (let i = 1; i < lines.length; i++) {
    if (lines[i].trim() === '') continue;
    const n = i + 1;
    const cells = lines[i].split('\t');
    if (cells.length !== COLUMNS.length) fail(n, 'row', `expected ${COLUMNS.length} cells, got ${cells.length}`);
    const [politician_id, office_id, level, rawValue, blank_reason, blank_class, record_kind, gate] = cells.map((c) => c.trim());
    if (!politician_id) fail(n, 'politician_id', 'empty');
    if (!office_id) fail(n, 'office_id', 'empty');
    if (!LEVELS.includes(level as Level)) fail(n, 'level', `${JSON.stringify(level)} is not one of ${LEVELS.join(', ')}`);
    let value: number | null = null;
    if (rawValue !== '') {
      value = Number(rawValue);
      if (!Number.isFinite(value) || value < 0 || value > 5) fail(n, 'value', `${JSON.stringify(rawValue)} is not empty or a number from 0 to 5`);
    }
    if (blank_class !== '' && !BLANK_CLASSES.includes(blank_class as BlankClass)) {
      fail(n, 'blank_class', `${JSON.stringify(blank_class)} is not one of ${BLANK_CLASSES.join(', ')}`);
    }
    if (!RECORD_KINDS.includes(record_kind as RecordKind)) {
      fail(n, 'record_kind', `${JSON.stringify(record_kind)} is not one of ${RECORD_KINDS.join(', ')}`);
    }
    if (gate !== '' && !(GATES as readonly string[]).includes(gate)) {
      fail(n, 'gate', `${JSON.stringify(gate)} is not one of ${GATES.join(', ')}`);
    }
    const row: ResearchRow = { politician_id, office_id, level: level as Level, value, record_kind: record_kind as RecordKind };
    if (blank_reason) row.blank_reason = blank_reason;
    if (blank_class) row.blank_class = blank_class as BlankClass;
    if (gate) row.gate = gate;
    out.push(row);
  }
  return out;
}

/**
 * A starter rows.tsv for Stage 0a (`topic:seat-rate --rows-out`): the header and one row per database
 * answer, with its level, value and stored blank reason. blank_class comes from the reason
 * (blankClassForReason) when the row has none; record_kind is `none` and gate is empty, because the
 * database knows neither. The runner then classifies each blank by hand. Tabs and newlines inside a
 * cell are turned into spaces so the file always parses back.
 */
export function formatRowsTsv(rows: ResearchRow[]): string {
  const cell = (v: string | number | null | undefined) => (v == null ? '' : String(v).replace(/[\t\r\n]+/g, ' '));
  const lines = rows.map((r) => {
    const cls = r.blank_class ?? (r.blank_reason ? blankClassForReason(r.blank_reason) : null);
    return [r.politician_id, r.office_id, r.level, r.value, r.blank_reason, cls, 'none', ''].map(cell).join('\t');
  });
  return [COLUMNS.join('\t'), ...lines].join('\n') + '\n';
}

const sidecarCell = (v: string | number | null | undefined) => (v == null ? '' : String(v).replace(/[\t\r\n]+/g, ' '));

/**
 * The reasons sidecar `--rows-out` writes beside rows.tsv (`<name>.reasons.tsv`): politician_id, value,
 * stored blank reason, and the first 300 characters of this season's and the earliest season's context
 * reasoning. Repair migrations blank rows without a review row, so for many topics this prose is the only
 * place the blank's reason lives. It names people and instruments: forbidden to drafters, like rows.tsv.
 */
export function formatReasonsTsv(rows: ResearchRow[]): string {
  const head = ['politician_id', 'value', 'blank_reason', 'reasoning', 'first_reasoning'];
  const lines = rows.map((r) => [r.politician_id, r.value, r.blank_reason, r.reasoning, r.first_reasoning].map(sidecarCell).join('\t'));
  return [head.join('\t'), ...lines].join('\n') + '\n';
}

/**
 * The skipped sidecar `--rows-out` writes beside rows.tsv (`<name>.skipped.tsv`): answers with no current
 * office (candidates, former holders the compass still shows) or an unknown level. They cannot go in
 * rows.tsv, which needs an office and a level, so the diagnosis reports them apart.
 */
export function formatSkippedTsv(rows: SkippedRow[]): string {
  const head = ['politician_id', 'why', 'value', 'blank_reason'];
  const lines = rows.map((r) => [r.politician_id, r.why, r.value, r.blank_reason].map(sidecarCell).join('\t'));
  return [head.join('\t'), ...lines].join('\n') + '\n';
}

/** `/x/stage0a/rows.tsv` → `/x/stage0a/rows.<kind>.tsv`. */
export function sidecarPath(rowsOut: string, kind: 'reasons' | 'skipped'): string {
  return rowsOut.replace(/(\.tsv)?$/, `.${kind}.tsv`);
}

// ---- summary -----------------------------------------------------------------------------------

type Bucket = {
  rows: number; seated: number; blank: number;
  byClass: Record<BlankClass | 'unclassified', number>;
  perRung: Record<'1' | '2' | '3' | '4' | '5' | 'between', number>;
  affirmative?: { rows: number; seated: number; rate: number | null };
};
export type SeatRateReport = { byLevel: Record<Level, Bucket>; total: Bucket };
type SummaryRow = { level: Level; value: number | null; blank_class?: BlankClass; record_kind?: RecordKind; gate?: string };

const emptyBucket = (): Bucket => ({
  rows: 0, seated: 0, blank: 0,
  byClass: { 'source-gap': 0, gate: 0, wording: 0, 'no-lever': 0, 'off-question': 0, 'nay-only': 0, unclassified: 0 },
  perRung: { '1': 0, '2': 0, '3': 0, '4': 0, '5': 0, between: 0 },
});

function addTo(b: Bucket, r: SummaryRow): void {
  b.rows++;
  const seated = r.value !== null && r.value > 0;
  if (seated) {
    b.seated++;
    const v = r.value as number;
    b.perRung[Number.isInteger(v) && v >= 1 && v <= 5 ? (String(v) as '1') : 'between']++;
  } else {
    b.blank++;
    b.byClass[r.blank_class ?? 'unclassified']++;
  }
  if (r.record_kind !== undefined) {
    b.affirmative ??= { rows: 0, seated: 0, rate: null };
    if (AFFIRMATIVE_KINDS.includes(r.record_kind) && !r.gate) {
      b.affirmative.rows++;
      if (seated) b.affirmative.seated++;
    }
  }
}

export function summarise(rows: SummaryRow[]): SeatRateReport {
  const report: SeatRateReport = {
    byLevel: Object.fromEntries(LEVELS.map((l) => [l, emptyBucket()])) as Record<Level, Bucket>,
    total: emptyBucket(),
  };
  for (const r of rows) {
    addTo(report.byLevel[r.level], r);
    addTo(report.total, r);
  }
  for (const b of [...Object.values(report.byLevel), report.total]) {
    if (b.affirmative) b.affirmative.rate = b.affirmative.rows ? b.affirmative.seated / b.affirmative.rows : null;
  }
  return report;
}

const pct = (n: number, d: number) => (d ? `${((100 * n) / d).toFixed(1)}%` : '-');

/** Below this many affirmative records the affirmative rate says little; the overall rate is the headline. */
export const MIN_AFFIRMATIVE_FOR_HEADLINE = 10;

export function formatReport(r: SeatRateReport): string {
  if (r.total.rows === 0) return 'no rows';
  const hasAff = r.total.affirmative !== undefined;
  const head = ['level', 'rows', 'seated', 'rate', 'blank', 'source-gap', 'gate', 'wording', 'no-lever', 'off-question', 'nay-only', 'unclassified'];
  if (hasAff) head.push('aff rows', 'aff seated', 'aff rate');
  const line = (name: string, b: Bucket) => {
    const c = [name, b.rows, b.seated, pct(b.seated, b.rows), b.blank, b.byClass['source-gap'], b.byClass.gate,
      b.byClass.wording, b.byClass['no-lever'], b.byClass['off-question'], b.byClass['nay-only'], b.byClass.unclassified];
    if (hasAff) {
      const a = b.affirmative;
      c.push(a?.rows ?? 0, a?.seated ?? 0, a?.rate == null ? '-' : pct(a.seated, a.rows));
    }
    return c.map(String);
  };
  const table = [head, ...LEVELS.filter((l) => r.byLevel[l].rows > 0).map((l) => line(l, r.byLevel[l])), line('total', r.total)];
  const w = head.map((_, i) => Math.max(...table.map((row) => row[i].length)));
  const out = table.map((row) => row.map((c, i) => (i === 0 ? c.padEnd(w[i]) : c.padStart(w[i]))).join('  '));
  const rungs = Object.entries(r.total.perRung).map(([k, v]) => `${k}=${v}`).join(' ');
  const aff = r.total.affirmative;
  const note = aff && aff.rows < MIN_AFFIRMATIVE_FOR_HEADLINE
    ? `\nnote: only ${aff.rows} affirmative record(s); report the overall rate (${pct(r.total.seated, r.total.rows)}) as the headline and say why`
    : '';
  return `${out.join('\n')}\n\nrungs held (total): ${rungs}${note}`;
}

// ---- database ----------------------------------------------------------------------------------

/**
 * One row per answer. Level comes from the district of ONE current office per politician
 * (office_current_holder is politician-rooted here, so it can fan out): the office named on the
 * topic's review row wins when that politician holds it, otherwise the lowest office id. Read-only.
 * Answers are never lost silently: one whose politician holds no current office (a candidate, a former
 * holder) or whose office level is unknown (null from levelForDistrict) is not scored, and is reported
 * through `onSkip(politicianId, why)`. Review rows that were rejected or superseded are ignored when
 * picking the blank reason.
 */
export async function loadDbRows(
  q: Query, topicKey: string, seasonId: string,
  onSkip?: (politicianId: string, why: 'no-office' | 'unknown-level', row?: SkippedRow) => void,
): Promise<ResearchRow[]> {
  // @zero-scope: counts-blanks — this report asks whether a politician is SEATED, so a 0 is a blank to count.
  const { rows } = await q(
    `-- @ladder-text: frozen-ok — reads only inform.compass_topics.topic_key (to find the topic id); the word title below is essentials.offices.title, the office name.
     SELECT DISTINCT ON (pa.politician_id)
            pa.politician_id::text AS politician_id, o.id::text AS office_id, pa.value::float8 AS value,
            d.district_type, d.is_judicial, d.label AS district_label,
            ARRAY[o.title, c.name] AS office_labels, rv.proposed_blank_reason,
            left(cx.reasoning, 300) AS reasoning, left(cx1.reasoning, 300) AS first_reasoning
       FROM inform.politician_answers pa
       JOIN inform.compass_topics t ON t.id = pa.topic_id
       LEFT JOIN essentials.office_current_holder och ON och.politician_id = pa.politician_id
       LEFT JOIN essentials.offices o ON o.id = och.office_id
       LEFT JOIN essentials.districts d ON d.id = o.district_id
       LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
       LEFT JOIN LATERAL (
              SELECT r.office_id, r.proposed_blank_reason FROM inform.stance_research_review r
               WHERE r.politician_id = pa.politician_id AND r.topic_id = pa.topic_id AND r.season_id = pa.season_id
                 AND r.status NOT IN ('rejected', 'superseded')
               ORDER BY r.created_at DESC LIMIT 1) rv ON true
       LEFT JOIN inform.politician_context cx
              ON cx.politician_id = pa.politician_id AND cx.topic_id = pa.topic_id AND cx.season_id = pa.season_id
       LEFT JOIN LATERAL (
              SELECT c1.reasoning FROM inform.politician_context c1 JOIN inform.seasons s1 ON s1.id = c1.season_id
               WHERE c1.politician_id = pa.politician_id AND c1.topic_id = pa.topic_id
               ORDER BY s1.number LIMIT 1) cx1 ON true
      WHERE t.topic_key = $1 AND pa.season_id = $2
      ORDER BY pa.politician_id, (o.id = rv.office_id) DESC, o.id`,
    [topicKey, seasonId],
  );
  const out: ResearchRow[] = [];
  for (const r of rows) {
    const value = r.value === null ? null : Number(r.value);
    const skip = (why: 'no-office' | 'unknown-level') => {
      const s: SkippedRow = { politician_id: r.politician_id, why, value };
      if (r.proposed_blank_reason) s.blank_reason = r.proposed_blank_reason;
      onSkip?.(r.politician_id, why, s);
    };
    if (!r.office_id) { skip('no-office'); continue; }
    const level = levelForDistrict(r.district_type ?? null, r.is_judicial ?? null, r.district_label ?? null, r.office_labels ?? []);
    if (!level) { skip('unknown-level'); continue; }
    const row: ResearchRow = { politician_id: r.politician_id, office_id: r.office_id, level, value, record_kind: 'none' };
    if (r.proposed_blank_reason) {
      row.blank_reason = r.proposed_blank_reason;
      const cls = blankClassForReason(r.proposed_blank_reason);
      if (cls) row.blank_class = cls;
    }
    if (r.reasoning) row.reasoning = r.reasoning;
    if (r.first_reasoning) row.first_reasoning = r.first_reasoning;
    out.push(row);
  }
  return out;
}

/** True when `inform.compass_topics` has this key, so an unknown key is not mistaken for "no rows". */
export async function topicExists(q: Query, topicKey: string): Promise<boolean> {
  const { rows } = await q('SELECT 1 FROM inform.compass_topics WHERE topic_key = $1', [topicKey]);
  return rows.length > 0;
}

/**
 * JOIN research onto the database rows (ruling, spec §9 item 1): the database rows stay the base;
 * a rows.tsv row with the same politician_id supplies blank_class, record_kind and gate. A database
 * row with no tsv match keeps none of them. tsv rows matching no database row are counted, not scored.
 */
export function mergeResearch(dbRows: ResearchRow[], tsvRows: ResearchRow[]): { rows: ResearchRow[]; researchOnly: number } {
  const byPol = new Map<string, ResearchRow>();
  for (const t of tsvRows) if (!byPol.has(t.politician_id)) byPol.set(t.politician_id, t);
  const seen = new Set<string>();
  const rows = dbRows.map((d) => {
    const t = byPol.get(d.politician_id);
    if (!t) return d;
    seen.add(d.politician_id);
    const m: ResearchRow = { ...d, record_kind: t.record_kind };
    const cls = t.blank_class ?? d.blank_class;
    if (cls) m.blank_class = cls; else delete m.blank_class;
    if (t.gate) m.gate = t.gate;
    return m;
  });
  return { rows, researchOnly: [...byPol.keys()].filter((id) => !seen.has(id)).length };
}
