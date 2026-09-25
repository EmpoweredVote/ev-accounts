/**
 * coderLabel — the contract for labels/coder-N.json (codebook Part E) and its validator.
 * Codebook: docs/codebook/stance-and-quote-codebook.md. Spec §1.4: a label that fails here makes
 * that coder MISSING for the row — which makes the row not unanimous, which sends it to a person.
 * Pure: no DB, no network. Verbatim checks use the verifier's own normalisation.
 */
import { normalizeText } from '../../src/lib/researchVerifier.js';

/** 🔴 Must equal the codebook's **Version:** line — coderLabel.test.ts pins it. */
export const CODEBOOK_VERSION = '0.2';

export const V1_ATTRIBUTION = ['own-words', 'own-act', 'third-party-characterization', 'namesake-unclear'] as const;
export const V2_RELEVANCE = ['on-question', 'adjacent', 'off'] as const;
export const V3_CLASS = ['record', 'statement-answer', 'statement-other', 'not-evidence'] as const;
export const V4_SHAPE = ['chair-shaped', 'direction-only', 'multi-subject', 'procedural', 'study-directive', 'near-unanimous', 'rhetorical', 'off-axis'] as const;
export const V5_TIME = ['in-term', 'pre-seating', 'superseded-by-later', 'undated'] as const;
export const BLANK_REASONS = ['no-evidence', 'direction-only', 'adjacent-chairs', 'compound-partial', 'record-vs-statement-conflict', 'scope-unavailable'] as const;
export const V7_TIER = ['lever', 'direction', 'none'] as const;
export const V7_FLAGS = ['lever-named', 'lever-unclear'] as const;
export const V8_CODES = ['not-forward', 'is-attack', 'off-question', 'misleading-verbatim', 'source-not-an-answer', 'deid-dishonest', 'non-differentiating-goal'] as const;
/** V8 codes that do not gate (PRINCIPLES.md: flag for a human, no blanket gate). */
const NON_GATING_V8 = new Set<string>(['non-differentiating-goal']);

export interface Passage {
  snapshot_id: string;
  v1_attribution: typeof V1_ATTRIBUTION[number];
  v2_relevance: typeof V2_RELEVANCE[number];
  v3_class: typeof V3_CLASS[number];
  v4_shape: typeof V4_SHAPE[number];
  v5_time: typeof V5_TIME[number];
  date: string | null;
  instrument: string | null;
  provision_quote: string | null;
  note?: string;
}
export interface QuoteLabel {
  snapshot_id: string;
  text: string;
  v7_tier: typeof V7_TIER[number];
  v7_flag: typeof V7_FLAGS[number] | null;
  v8_quotable: boolean;
  v8_codes: string[];
}
export interface CoderRow {
  politician_id: string;
  office_id: string;
  topic_id: string;
  served_revision_id: string;
  passages: Passage[];
  v6_value: number | null;
  v6_blank_reason: typeof BLANK_REASONS[number] | null;
  rests_on: string[];
  reasoning: string;
  needs_source: string[];
  quotes: QuoteLabel[];
}
export interface CoderLabelFile { codebook_version: string; coder_slot: number; rows: CoderRow[] }
export interface ValidatedRow { key: string; row: CoderRow | null; errors: string[] }
export interface ValidationResult { fileErrors: string[]; rows: ValidatedRow[] }

export const rowKey = (r: { politician_id: string; office_id: string; topic_id: string }): string =>
  `${r.politician_id}|${r.office_id}|${r.topic_id}`;

/** Codebook Part 0.3: a passage can support a chair only if V1–V5 all allow it. */
export function passageAllowsChair(p: Passage): boolean {
  return (p.v1_attribution === 'own-words' || p.v1_attribution === 'own-act')
    && p.v2_relevance === 'on-question'
    && p.v3_class !== 'not-evidence'
    && p.v4_shape === 'chair-shaped'
    && p.v5_time === 'in-term';
}

export const verbatimIn = (snapshotText: string, span: string): boolean => {
  const s = normalizeText(span);
  return s.length > 0 && normalizeText(snapshotText).includes(s);
};

const isObj = (x: unknown): x is Record<string, unknown> => typeof x === 'object' && x !== null && !Array.isArray(x);
const isStrArr = (x: unknown): x is string[] => Array.isArray(x) && x.every((v) => typeof v === 'string');
function enumErr(where: string, field: string, v: unknown, allowed: readonly string[]): string | null {
  return typeof v === 'string' && allowed.includes(v) ? null : `${where}: ${field} ${String(v)} not allowed`;
}

/**
 * A passage date is YYYY, YYYY-MM or YYYY-MM-DD with a real month and day, or null. Anything else
 * ("March 2010", "unknown") would make the CONFIRM date checks compare strings and fail open.
 */
export function isCoderDate(v: unknown): boolean {
  if (typeof v !== 'string') return false;
  const m = /^(\d{4})(?:-(\d{2})(?:-(\d{2}))?)?$/.exec(v);
  if (!m) return false;
  if (m[2] === undefined) return true;
  const month = Number(m[2]);
  if (month < 1 || month > 12) return false;
  if (m[3] === undefined) return true;
  const day = Number(m[3]);
  const daysInMonth = new Date(Date.UTC(Number(m[1]), month, 0)).getUTCDate();
  return day >= 1 && day <= daysInMonth;
}

function validateRow(raw: unknown, snapshotText: ReadonlyMap<string, string>): ValidatedRow {
  const errors: string[] = [];
  if (!isObj(raw)) return { key: '?', row: null, errors: ['row: not an object'] };
  for (const k of ['politician_id', 'office_id', 'topic_id', 'served_revision_id', 'reasoning'] as const) {
    if (typeof raw[k] !== 'string' || (raw[k] as string).length === 0) errors.push(`row: ${k} missing`);
  }
  const key = errors.length ? '?' : rowKey(raw as unknown as CoderRow);
  const passages = Array.isArray(raw.passages) ? raw.passages : [];
  if (!Array.isArray(raw.passages)) errors.push('row: passages not an array');
  const byId = new Map<string, Passage>();
  for (const p of passages) {
    if (!isObj(p) || typeof p.snapshot_id !== 'string') { errors.push('passage: not an object with snapshot_id'); continue; }
    const where = `passage ${p.snapshot_id}`;
    const text = snapshotText.get(p.snapshot_id);
    if (text === undefined) errors.push(`passage: unknown snapshot ${p.snapshot_id}`);
    for (const [f, allowed] of [['v1_attribution', V1_ATTRIBUTION], ['v2_relevance', V2_RELEVANCE], ['v3_class', V3_CLASS], ['v4_shape', V4_SHAPE], ['v5_time', V5_TIME]] as const) {
      const e = enumErr(where, f, p[f], allowed);
      if (e) errors.push(e);
    }
    if (p.date !== null && !isCoderDate(p.date)) errors.push(`${where}: date ${String(p.date)} not YYYY, YYYY-MM or YYYY-MM-DD`);
    if (p.provision_quote !== null && p.provision_quote !== undefined) {
      if (typeof p.provision_quote !== 'string') errors.push(`${where}: provision_quote not a string`);
      else if (text !== undefined && !verbatimIn(text, p.provision_quote)) errors.push(`${where}: provision_quote not verbatim in snapshot`);
    }
    byId.set(p.snapshot_id, p as unknown as Passage);
  }
  const value = raw.v6_value;
  const reason = raw.v6_blank_reason;
  if (value === null || value === undefined) {
    if (reason === null || reason === undefined) errors.push('v6: value is null but no blank reason');
    else { const e = enumErr('v6', 'blank_reason', reason, BLANK_REASONS); if (e) errors.push(e); }
  } else {
    if (reason !== null && reason !== undefined) errors.push('v6: value and blank reason both set');
    if (typeof value !== 'number' || !Number.isInteger(value) || value < 1 || value > 5) errors.push(`v6: value ${String(value)} not an integer 1..5`);
  }
  const restsOn = isStrArr(raw.rests_on) ? raw.rests_on : [];
  if (!isStrArr(raw.rests_on)) errors.push('rests_on: not a string array');
  if (typeof value === 'number') {
    if (restsOn.length === 0) errors.push('rests_on: empty for a numeric chair');
    for (const id of restsOn) {
      const p = byId.get(id);
      if (!p) errors.push(`rests_on: ${id} is not a coded passage`);
      else if (!passageAllowsChair(p)) errors.push(`rests_on: ${id} does not allow a chair (V1-V5)`);
    }
  }
  if (!isStrArr(raw.needs_source)) errors.push('needs_source: not a string array');
  const quotes = Array.isArray(raw.quotes) ? raw.quotes : [];
  if (!Array.isArray(raw.quotes)) errors.push('quotes: not an array');
  for (const q of quotes) {
    if (!isObj(q) || typeof q.snapshot_id !== 'string' || typeof q.text !== 'string') { errors.push('quote: not an object with snapshot_id and text'); continue; }
    const text = snapshotText.get(q.snapshot_id);
    if (text === undefined) errors.push(`quote: unknown snapshot ${q.snapshot_id}`);
    else if (!verbatimIn(text, q.text)) errors.push('quote: text not verbatim in snapshot');
    const e = enumErr('quote', 'v7_tier', q.v7_tier, V7_TIER);
    if (e) errors.push(e);
    if (q.v7_flag !== null && q.v7_flag !== undefined) { const f = enumErr('quote', 'v7_flag', q.v7_flag, V7_FLAGS); if (f) errors.push(f); }
    const codes = isStrArr(q.v8_codes) ? q.v8_codes : [];
    if (!isStrArr(q.v8_codes)) errors.push('quote: v8_codes not a string array');
    for (const c of codes) if (!(V8_CODES as readonly string[]).includes(c)) errors.push(`quote: v8 code ${c} not allowed`);
    if (typeof q.v8_quotable !== 'boolean') errors.push('quote: v8_quotable not a boolean');
    else if (q.v8_quotable && codes.some((c) => !NON_GATING_V8.has(c))) errors.push('quote: v8_quotable true but gating codes present');
  }
  return { key, row: errors.length ? null : (raw as unknown as CoderRow), errors };
}

export function validateCoderLabelFile(
  raw: unknown,
  ctx: { snapshotText: ReadonlyMap<string, string>; expectedSlot: number },
): ValidationResult {
  if (!isObj(raw) || !Array.isArray(raw.rows)) return { fileErrors: ['not an object with a rows array'], rows: [] };
  const fileErrors: string[] = [];
  if (raw.codebook_version !== CODEBOOK_VERSION) fileErrors.push(`codebook_version ${String(raw.codebook_version)} != ${CODEBOOK_VERSION}`);
  if (raw.coder_slot !== ctx.expectedSlot) fileErrors.push(`coder_slot ${String(raw.coder_slot)} != ${ctx.expectedSlot}`);
  return { fileErrors, rows: raw.rows.map((r) => validateRow(r, ctx.snapshotText)) };
}
