/**
 * stage5QuoteCheck.ts — Stage 5 safeguard G5: the quote check that guards every shown quote.
 *
 * A second agent (never the searcher or the coder) fetches each source page fresh and confirms four things
 * about a passage before it may be shown as "own words, not a position on the scale" (design §8):
 * it is on the page word for word, it is the person's own words (codebook V1), it is on the topic, and it
 * names no political party or party colour (ruled 2026-10-22: a quote that names a party is never shown, and quotes are never
 * edited). `verdict = 'passed'` only when all four hold; the schema refuses anything else, so a passed check
 * cannot be written by mistake. The agent's brief is templates/stage5-quote-check-prompt.md; its output is
 * `<research>/stage5/quote-checks.jsonl`, one check per line. Pure.
 */
import { createHash } from 'node:crypto';
import { z } from 'zod';

/** Party names in English text, any case. The quote check's floor: the checker also judges `names_party` itself. */
export const PARTY_RE = /\b(republicans?|democrats?|democratic party|libertarians?|GOP\w*|DNC|RNC|DFL|green party|independent party|independence party|working families( party)?|constitution party|reform party|conservative party|tea party)\b/i;
// Case-sensitive forms: "Democratic" as a name ("Democratic lawmakers") and "Dem"/"Dems", but not "a democratic process".
const PARTY_NAME_CASED = /\b(Democratic|Dems?)\b/;
// Party colours used as labels for people or places ("red states", "a blue district"); ruled out with the names.
const PARTY_COLOUR = /\b(red|blue)[- ](states?|count(y|ies)|districts?|cit(y|ies)|areas?|voters?|wave)\b/i;

/** True when the text names a political party, or uses a party colour as a label. Fails safe: a false hit costs one quote. */
export function namesParty(text: string): boolean {
  return PARTY_RE.test(text) || PARTY_NAME_CASED.test(text) || PARTY_COLOUR.test(text);
}

/** The sha256 of the exact text a check covered: the passage for own words, the note for a local record. */
export function shownSha256(text: string): string {
  return createHash('sha256').update(text, 'utf8').digest('hex');
}

/** Collapse whitespace; curly → straight quotes and apostrophes; en/em dash → hyphen. Nothing else. */
export function normaliseForMatch(s: string): string {
  return s
    .replace(/[“”„‟″«»]/g, '"')
    .replace(/[‘’‚‛′]/g, "'")
    .replace(/[–—]/g, '-')
    .replace(/\s+/g, ' ')
    .trim();
}

/** True when the passage is on the page, word for word, up to whitespace, quote marks and dashes. */
export function passageOnPage(passage: string, pageText: string): boolean {
  const p = normaliseForMatch(passage);
  return p.length > 0 && normaliseForMatch(pageText).includes(p);
}

export const QuoteCheckSchema = z
  .object({
    finding_id: z.string().min(1),
    politician_id: z.string().uuid(),
    topic_key: z.string().min(1),
    verdict: z.enum(['passed', 'failed']),
    on_page: z.boolean(),
    own_words: z.boolean(),
    on_topic: z.boolean(),
    names_party: z.boolean(),
    /** sha256 of the exact text checked (shownSha256), so text changed after the check has no check. */
    shown_sha256: z.string().regex(/^[0-9a-f]{64}$/),
    /** Local records only: the plain-words note says only what the page shows, with no adjectives about the person. */
    fair_summary: z.boolean().optional(),
    reason: z.string().min(1),
    checker: z.string().min(1),
    at: z.string().min(1),
  })
  .refine((c) => c.verdict !== 'passed' || (c.on_page && c.own_words && c.on_topic && !c.names_party && c.fair_summary !== false), {
    message: 'passed needs on_page, own_words and on_topic true, names_party false, and fair_summary not false',
    path: ['verdict'],
  });
export type QuoteCheck = z.infer<typeof QuoteCheckSchema>;

/** Read quote-checks.jsonl. A bad line throws with its line number. */
export function readQuoteChecks(jsonl: string): QuoteCheck[] {
  const out: QuoteCheck[] = [];
  jsonl.split('\n').forEach((line, i) => {
    if (!line.trim()) return;
    const r = QuoteCheckSchema.safeParse(JSON.parse(line));
    if (!r.success) throw new Error(`quote-checks line ${i + 1}: ${r.error.issues.map((x) => `${x.path.join('.')}: ${x.message}`).join('; ')}`);
    out.push(r.data);
  });
  return out;
}
