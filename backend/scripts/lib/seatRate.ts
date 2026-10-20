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

export type BlankClass = 'source-gap' | 'gate' | 'wording' | 'no-lever';
export type RecordKind = 'vote-yes' | 'vote-no' | 'sponsor' | 'author' | 'own-words' | 'none';
type Query = (sql: string, params?: unknown[]) => Promise<{ rows: any[] }>;

export const LEVELS: Level[] = ['federal', 'state', 'local', 'judicial', 'school'];
const BLANK_CLASSES: BlankClass[] = ['source-gap', 'gate', 'wording', 'no-lever'];
const RECORD_KINDS: RecordKind[] = ['vote-yes', 'vote-no', 'sponsor', 'author', 'own-words', 'none'];
const AFFIRMATIVE_KINDS: RecordKind[] = ['vote-yes', 'sponsor', 'author'];

export interface ResearchRow {
  politician_id: string;
  office_id: string;
  level: Level;
  value: number | null;
  blank_reason?: string;
  blank_class?: BlankClass;
  record_kind: RecordKind;
  gate?: string;
}

const REASON_CLASS: Record<string, BlankClass> = {
  'no-evidence': 'source-gap',
  'near-unanimous': 'gate', 'multi-subject': 'gate', 'study-directive': 'gate', 'pre-seating': 'gate',
  'direction-only': 'wording', 'adjacent-chairs': 'wording', 'compound-partial': 'wording',
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
    const row: ResearchRow = { politician_id, office_id, level: level as Level, value, record_kind: record_kind as RecordKind };
    if (blank_reason) row.blank_reason = blank_reason;
    if (blank_class) row.blank_class = blank_class as BlankClass;
    if (gate) row.gate = gate;
    out.push(row);
  }
  return out;
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
  byClass: { 'source-gap': 0, gate: 0, wording: 0, 'no-lever': 0, unclassified: 0 },
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

export function formatReport(r: SeatRateReport): string {
  if (r.total.rows === 0) return 'no rows';
  const hasAff = r.total.affirmative !== undefined;
  const head = ['level', 'rows', 'seated', 'rate', 'blank', 'source-gap', 'gate', 'wording', 'no-lever', 'unclassified'];
  if (hasAff) head.push('aff rows', 'aff seated', 'aff rate');
  const line = (name: string, b: Bucket) => {
    const c = [name, b.rows, b.seated, pct(b.seated, b.rows), b.blank, b.byClass['source-gap'], b.byClass.gate,
      b.byClass.wording, b.byClass['no-lever'], b.byClass.unclassified];
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
  return `${out.join('\n')}\n\nrungs held (total): ${rungs}`;
}

// ---- database ----------------------------------------------------------------------------------

/**
 * One row per answer. Level comes from the district of ONE current office per politician
 * (office_current_holder is politician-rooted here, so it can fan out): the office named on the
 * topic's review row wins when that politician holds it, otherwise the lowest office id. Read-only.
 * Answers whose office level is unknown (null from levelForDistrict) are skipped and reported via
 * `onSkip`, never scored.
 */
export async function loadDbRows(
  q: Query, topicKey: string, seasonId: string, onSkip?: (politicianId: string) => void,
): Promise<ResearchRow[]> {
  // @zero-scope: counts-blanks — this report asks whether a politician is SEATED, so a 0 is a blank to count.
  const { rows } = await q(
    `-- @ladder-text: frozen-ok — reads only inform.compass_topics.topic_key (to find the topic id); the word title below is essentials.offices.title, the office name.
     SELECT DISTINCT ON (pa.politician_id)
            pa.politician_id::text AS politician_id, o.id::text AS office_id, pa.value::float8 AS value,
            d.district_type, d.is_judicial, d.label AS district_label,
            ARRAY[o.title, c.name] AS office_labels, rv.proposed_blank_reason
       FROM inform.politician_answers pa
       JOIN inform.compass_topics t ON t.id = pa.topic_id
       JOIN essentials.office_current_holder och ON och.politician_id = pa.politician_id
       JOIN essentials.offices o ON o.id = och.office_id
       LEFT JOIN essentials.districts d ON d.id = o.district_id
       LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
       LEFT JOIN LATERAL (
              SELECT r.office_id, r.proposed_blank_reason FROM inform.stance_research_review r
               WHERE r.politician_id = pa.politician_id AND r.topic_id = pa.topic_id AND r.season_id = pa.season_id
               ORDER BY r.created_at DESC LIMIT 1) rv ON true
      WHERE t.topic_key = $1 AND pa.season_id = $2
      ORDER BY pa.politician_id, (o.id = rv.office_id) DESC, o.id`,
    [topicKey, seasonId],
  );
  const out: ResearchRow[] = [];
  for (const r of rows) {
    const level = levelForDistrict(r.district_type ?? null, r.is_judicial ?? null, r.district_label ?? null, r.office_labels ?? []);
    if (!level) { onSkip?.(r.politician_id); continue; }
    const value = r.value === null ? null : Number(r.value);
    const row: ResearchRow = { politician_id: r.politician_id, office_id: r.office_id, level, value, record_kind: 'none' };
    if (r.proposed_blank_reason) {
      row.blank_reason = r.proposed_blank_reason;
      const cls = blankClassForReason(r.proposed_blank_reason);
      if (cls) row.blank_class = cls;
    }
    out.push(row);
  }
  return out;
}
