/**
 * coderPrompt — the complete input for one tool-less stance coder (spec §1.3, ruling Q1).
 * Everything the coder may use is IN this text: codebook, annex, the served ladder, the seat, and
 * the snapshot passages. Nothing from the collector's own reading (research.csv) is passed. Source
 * order is shuffled per slot so the three coders do not share a primacy bias.
 */
import { createHash } from 'node:crypto';
import { CODEBOOK_VERSION } from './coderLabel.js';
import type { SnapshotRecord } from './snapshotSources.js';

export interface SeatContext {
  politician_id: string;
  full_name: string;
  level: string | null;
  mode: 'seated' | 'candidate';
  office_id: string;
  office_title: string;
  jurisdiction_names: string[];
  term_start: string | null;
  start_precision: string | null;
  term_end: string | null;
  election_date: string | null;
  /** The seat's state (USPS, e.g. 'AZ'), from offices.representing_state. Absent → no earlier-chamber route. */
  state_usps?: string | null;
  /**
   * Codebook V5 option B (ruling 2026-09-27): the person's CLOSED terms in a state-legislature seat of
   * the same state — the other chamber, or an earlier district. A record dated in one of them counts
   * for this seat; CONFIRM checks the page against that term's chamber. Empty/absent → such a record
   * reads `prior-service-unverified` (fail closed).
   */
  prior_terms?: PriorTerm[];
}
export interface PriorTerm {
  office_title: string;
  /** The chamber served in (essentials.legislative_service). Given → it decides the chamber check. */
  chamber?: 'upper' | 'lower';
  state_usps: string;
  term_start: string | null;
  start_precision: string | null;
  term_end: string | null;
}
export interface PromptTopic {
  topic_id: string;
  topic_key: string;
  served_revision_id: string;
  question_text: string;
  stances: { value: number; text: string }[];
  annexMd: string | null;
  /** CA_0302 (ruling 2026-10-06, option B): levels at which this topic is asked on own words only. */
  own_words_levels?: string[];
}

/** mulberry32 — small, deterministic, good enough for ordering. */
function rng(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
export function shuffleSeeded<T>(xs: readonly T[], seed: number): T[] {
  const out = [...xs];
  const r = rng(seed);
  for (let i = out.length - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [out[i], out[j]] = [out[j], out[i]]; }
  return out;
}
export const seedFor = (batchId: string, slot: number): number =>
  createHash('sha256').update(`${batchId}#${slot}`).digest().readUInt32BE(0);

const KIND_NOTE: Record<SnapshotRecord['source_kind'], string> = {
  'public-record': 'public-record',
  'own-site': "own-site (the person's own site or account)",
  news: 'news (excerpt only)',
  pointer: 'pointer (NOT evidence — you may not rest a chair on it; use it only to name a needs_source)',
  transcript: 'transcript',
};

export function buildCoderPrompt(i: {
  codebookMd: string; seat: SeatContext; topics: PromptTopic[]; snapshots: SnapshotRecord[];
  slot: 1 | 2 | 3; seed: number; labelPath: string;
}): string {
  const codable = shuffleSeeded(i.snapshots.filter((s) => s.ok && s.snapshot_text), i.seed);
  const s = i.seat;
  const topics = i.topics.map((t) => [
    `### topic_key: ${t.topic_key}`,
    `topic_id: ${t.topic_id}  served_revision_id: ${t.served_revision_id}`,
    `Question: ${t.question_text}`,
    ...(s.level && t.own_words_levels?.includes(s.level)
      ? [`Evidence basis at this seat's level (${s.level}): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").`]
      : []),
    ...[...t.stances].sort((a, b) => a.value - b.value).map((r) => `  ${r.value}. ${r.text}`),
    '',
    t.annexMd ? `#### Annex\n\n${t.annexMd}` : '#### Annex\n\n(no annex for this topic yet — apply the codebook alone)',
  ].join('\n')).join('\n\n');
  const sources = codable.map((x) => [
    `---`,
    `snapshot_id: ${x.snapshot_id}`,
    `source_kind: ${KIND_NOTE[x.source_kind]}`,
    `url: ${x.url}`,
    '',
    x.snapshot_text,
  ].join('\n')).join('\n\n');
  return [
    `You are stance coder ${i.slot}. You code evidence against the codebook below. You do not search,`,
    'fetch or verify anything: every source you may use is in this message, and code checks your',
    'labels afterwards. If the evidence a row needs is named but not included here, put it in',
    'needs_source instead of guessing.',
    '',
    `Use only the Write tool, exactly once, to write ${i.labelPath}. Write JSON only, matching`,
    `codebook Part E, with "codebook_version": "${CODEBOOK_VERSION}" and "coder_slot": ${i.slot}. One row per`,
    'topic below. Every quoted string you write must be copied exactly from a source below.',
    '',
    '## Codebook',
    '',
    i.codebookMd,
    '',
    '## The person',
    '',
    `politician_id: ${s.politician_id}  office_id: ${s.office_id}`,
    `${s.full_name} — ${s.office_title}, ${s.jurisdiction_names.join(' / ') || 'jurisdiction unknown'} (${s.mode}, level: ${s.level ?? 'unknown'})`,
    s.mode === 'seated'
      ? `Current term: ${s.term_start ?? 'unknown'} (precision: ${s.start_precision ?? 'unknown'}) to ${s.term_end ?? 'present'}`
      : `Candidate in the election of ${s.election_date ?? 'unknown date'}`,
    ...((s.prior_terms?.length ?? 0) > 0
      ? [`Earlier terms in this legislature: ${s.prior_terms!.map((t) => `${t.office_title} ${t.term_start ?? 'unknown'} (precision: ${t.start_precision ?? 'unknown'}) to ${t.term_end ?? 'unknown'}`).join('; ')}`]
      : []),
    '',
    '## Topics (served ladder text — code against these words only)',
    '',
    topics,
    '',
    '## Sources',
    '',
    sources || '(no codable sources — every row is BLANK no-evidence, with needs_source where you can name one)',
  ].join('\n');
}
