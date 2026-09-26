/**
 * goldLabels — the file a person's blind gold decisions are recorded in before they are written to
 * inform.stance_gold_labels (spec 2026-09-25 §4.3; CA_0292). One entry = one human decision on one
 * (politician, office, topic): the BLIND answer (given before any coder output or proposed code was
 * seen) and the FINAL answer (after adjudication; equal to the blind one when nothing changed).
 * The gold file lives outside the repo (it must never reach a coder prompt); this parser only
 * validates it. Fail closed: any malformed entry stops the write.
 */
export const BLANK_REASONS = ['no-evidence', 'direction-only', 'adjacent-chairs', 'compound-partial', 'record-vs-statement-conflict', 'scope-unavailable'] as const;
export type BlankReason = (typeof BLANK_REASONS)[number];
export const GOLD_MODES = ['blind', 'standard', 'audit'] as const;

export interface GoldAnswer { value: number | null; blank_reason: BlankReason | null }
export interface GoldEntry {
  item: string;
  batch: string;
  politician_id: string;
  office_id: string;
  topic_key: string;
  mode: (typeof GOLD_MODES)[number];
  blind: GoldAnswer & { submitted_at: string | null };
  final: GoldAnswer;
  codebook_version: string;
  reviewer_id: string;
  excluded_from_cert: boolean;
  note: string;
}

const KEYS = ['item', 'batch', 'politician_id', 'office_id', 'topic_key', 'mode', 'blind', 'final', 'codebook_version', 'reviewer_id', 'excluded_from_cert', 'note'];
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const isObj = (v: unknown): v is Record<string, unknown> => typeof v === 'object' && v !== null && !Array.isArray(v);

function answerErrors(at: string, a: unknown): string[] {
  if (!isObj(a)) return [`${at} must be an object`];
  const e: string[] = [];
  const v = a.value; const b = a.blank_reason;
  if (v !== null && !(Number.isInteger(v) && (v as number) >= 1 && (v as number) <= 5)) e.push(`${at} value ${String(v)} must be 1-5 or null`);
  if (b !== null && !(BLANK_REASONS as readonly unknown[]).includes(b)) e.push(`${at} blank_reason "${String(b)}" is not one of ${BLANK_REASONS.join(' | ')}`);
  if ((v === null) === (b === null)) e.push(`${at} needs a chair XOR a blank reason`);
  return e;
}

export function parseGoldFile(raw: unknown): { ok: true; entries: GoldEntry[] } | { ok: false; errors: string[] } {
  if (!isObj(raw) || !Array.isArray(raw.entries)) return { ok: false, errors: ['not an object with an entries array'] };
  const errors: string[] = [];
  const seen = new Set<string>();
  for (const [n, e] of raw.entries.entries()) {
    if (!isObj(e)) { errors.push(`entries[${n}] must be an object`); continue; }
    const at = typeof e.item === 'string' && e.item ? e.item : `entries[${n}]`;
    for (const k of Object.keys(e)) if (!KEYS.includes(k)) errors.push(`${at}: unknown key "${k}"`);
    if (seen.has(at)) errors.push(`duplicate item "${at}"`);
    seen.add(at);
    for (const k of ['politician_id', 'office_id', 'reviewer_id']) if (typeof e[k] !== 'string' || !UUID.test(e[k] as string)) errors.push(`${at}: ${k} is not a uuid`);
    for (const k of ['batch', 'topic_key', 'codebook_version', 'note']) if (typeof e[k] !== 'string' || !(e[k] as string).trim()) errors.push(`${at}: ${k} must be a non-empty string`);
    if (!(GOLD_MODES as readonly unknown[]).includes(e.mode)) errors.push(`${at}: mode "${String(e.mode)}" is not one of ${GOLD_MODES.join(' | ')}`);
    if (typeof e.excluded_from_cert !== 'boolean') errors.push(`${at}: excluded_from_cert must be true or false`);
    errors.push(...answerErrors(`${at}: blind`, e.blind), ...answerErrors(`${at}: final`, e.final));
    const sub = isObj(e.blind) ? e.blind.submitted_at : null;
    if (e.mode === 'blind' && (typeof sub !== 'string' || Number.isNaN(Date.parse(sub)))) errors.push(`${at}: blind mode needs blind.submitted_at (an ISO time)`);
  }
  return errors.length ? { ok: false, errors } : { ok: true, entries: raw.entries as GoldEntry[] };
}
