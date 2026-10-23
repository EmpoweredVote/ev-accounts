/**
 * stage5Code.ts — Stage 5 step 4: one person's code on one topic, judged from saved findings only.
 *
 * Three outcomes (design §5 step 4): `seated` on a rung with reasoning; `no-stance` — nothing on the topic
 * after a full search; `doesnt-fit` — on-topic evidence that no rung holds, with an open note in the coder's
 * own words and any of the starter tags (or none). The older blank classes stay as detail under the last
 * two: `source-gap` is no stance found; `gate`, `wording`, `no-lever`, `off-question` and `nay-only` are
 * doesn't fit. `checkCode` is the mechanical check a code passes before it counts: every cited finding is on
 * file, a local record never seats alone (RULINGS.md "Stage 5 rulings"), and `evidence_basis` says what the
 * cited findings are. Pure.
 */
import { z } from 'zod';
import { BLANK_CLASSES, type BlankClass } from './seatRate.js';
import type { Finding, PersonFindings } from './sourceStore.js';

export const STARTER_TAGS = ['between-rungs', 'related-question', 'unnamed-position', 'direction-only', 'other-level-lever'] as const;
export type StarterTag = (typeof STARTER_TAGS)[number];

export const Stage5CodeSchema = z.object({
  politician_id: z.string().uuid(),
  topic_key: z.string().min(1),
  season: z.number().int(),
  season_id: z.string().min(1),
  revision_id: z.string().min(1),
  outcome: z.enum(['seated', 'no-stance', 'doesnt-fit']),
  value: z.number().min(1).max(5).refine((v) => Number.isInteger(v * 2), 'value must be whole or a half').optional(),
  reasoning: z.string().min(1),
  blank_class: z.enum(BLANK_CLASSES as [BlankClass, ...BlankClass[]]).optional(),
  open_note: z.string().optional(),
  tags: z.array(z.enum(STARTER_TAGS)).default([]),
  finding_ids: z.array(z.string()).default([]),
  evidence_basis: z.enum(['record', 'own-words', 'joint']).optional(),
  codebook: z.string().min(1),
  coded_by: z.string().min(1),
  coded_at: z.string().min(1),
});
export type Stage5Code = z.infer<typeof Stage5CodeSchema>;

/** What the cited findings are: all records, all own words, or both. */
export function basisOf(cited: Finding[]): 'record' | 'own-words' | 'joint' {
  const kinds = new Set(cited.map((f) => f.kind));
  return kinds.size > 1 ? 'joint' : kinds.has('own-words') ? 'own-words' : 'record';
}

/** Problems with one code, in plain words; an empty list means it passes. */
export function checkCode(code: Stage5Code, pf: PersonFindings): string[] {
  const out: string[] = [];
  const parsed = Stage5CodeSchema.safeParse(code);
  if (!parsed.success) return parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`);
  if (pf.politician_id !== code.politician_id) out.push('the findings file is for another person');

  const byId = new Map(pf.findings.map((f) => [f.id, f]));
  const cited: Finding[] = [];
  for (const id of code.finding_ids) {
    const f = byId.get(id);
    if (!f) out.push(`finding ${id.slice(0, 12)}… is not in the findings file`);
    else if (!f.topic_keys.includes(code.topic_key)) out.push(`finding ${id.slice(0, 12)}… is not on ${code.topic_key}`);
    else cited.push(f);
  }

  if (code.outcome === 'seated') {
    if (code.value === undefined) out.push('a seat needs a value');
    if (cited.some((f) => f.local_record) && !cited.some((f) => f.kind === 'own-words')) {
      out.push('a local record never seats alone: it supports their own words, so cite their own words too');
    }
  } else if (code.value !== undefined) {
    out.push(`a ${code.outcome} code carries no value`);
  }

  if (code.outcome === 'seated' || code.outcome === 'doesnt-fit') {
    if (!code.finding_ids.length) out.push(`a ${code.outcome} code needs at least one finding`);
    if (cited.length && code.evidence_basis !== basisOf(cited)) out.push(`evidence_basis should be ${basisOf(cited)} for the findings cited`);
  }

  if (code.outcome === 'doesnt-fit') {
    if (!code.open_note?.trim()) out.push('doesnt-fit needs an open note in the coder\'s own words');
    if (code.blank_class === 'source-gap') out.push('source-gap means no stance found, not doesnt-fit');
  } else if (code.tags.length) {
    out.push('tags belong on doesnt-fit codes only');
  }

  if (code.outcome === 'no-stance') {
    if (!pf.searches.some((s) => s.topic_key === code.topic_key && s.season === code.season)) out.push('no-stance needs a search for this topic and season: no search is on file');
    if (pf.findings.some((f) => f.topic_keys.includes(code.topic_key))) out.push('no-stance, but on-topic findings on file: code them (seated or doesnt-fit)');
    if (code.finding_ids.length) out.push('no-stance cites no findings');
    if (code.blank_class && code.blank_class !== 'source-gap') out.push(`no-stance is source-gap, not ${code.blank_class}`);
  }
  return out;
}
