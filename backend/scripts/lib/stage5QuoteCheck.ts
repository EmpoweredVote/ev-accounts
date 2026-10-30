/**
 * stage5QuoteCheck.ts — Stage 5 safeguard G5: the quote check that guards every shown quote.
 *
 * A second agent (never the searcher or the coder) fetches each source page fresh and confirms four things
 * about a passage before it may be shown as "own words, not a position on the scale" (design §8):
 * it is on the page word for word, it is the person's own words (codebook V1), it is on the topic, and a party
 * is not its point (ruled 2026-10-29, RULINGS.md "Party labels never reach a reader": a passage that only mentions
 * a party passes with each label bracketed out in `shown_text`; one whose point is to back or oppose a party
 * fails). `verdict = 'passed'` only when all four hold; the schema refuses anything else, so a passed check
 * cannot be written by mistake. The agent's brief is templates/stage5-quote-check-prompt.md; its output is
 * `<research>/stage5/quote-checks.jsonl`, one check per line. Pure.
 */
import { createHash } from 'node:crypto';
import { z } from 'zod';

/** The party-label detector lives in src/lib/partyLabels.ts, shared with the evidence writer and the stance gate. */
export { namesParty, bracketEditProblem, BRACKET_WORDS } from '../../src/lib/partyLabels.js';

/** The sha256 of the exact text voters see: shown_text when a label is bracketed out, else the passage; the note for a local record. */
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
    /** True when backing or opposing a party is the passage's point: it fails. A mere mention is bracketed out instead. */
    names_party: z.boolean(),
    /**
     * Own words only: the passage with each party label replaced by a bracket from BRACKET_WORDS. Left out when the
     * passage has no label. The writer checks it mechanically (bracketEditProblem) before storing it.
     */
    shown_text: z.string().min(1).optional(),
    /** sha256 of the exact text voters see (shownSha256 of shown_text, else of the passage; of the note for a local record). */
    shown_sha256: z.string().regex(/^[0-9a-f]{64}$/),
    /** Local records only: the plain-words note says only what the page shows, with no adjectives about the person. */
    fair_summary: z.boolean().optional(),
    reason: z.string().min(1),
    checker: z.string().min(1),
    /** ISO timestamp with a zone; compared as a time, never as text. */
    at: z.string().datetime({ offset: true }),
  })
  .refine((c) => c.verdict !== 'passed' || (c.on_page && c.own_words && c.on_topic && !c.names_party && c.fair_summary !== false), {
    message: 'passed needs on_page, own_words and on_topic true, names_party false, and fair_summary not false',
    path: ['verdict'],
  });
export type QuoteCheck = z.infer<typeof QuoteCheckSchema>;

const ENTITIES: Record<string, string> = {
  nbsp: ' ', amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", ldquo: '\u201C', rdquo: '\u201D',
  lsquo: '\u2018', rsquo: '\u2019', ndash: '\u2013', mdash: '\u2014', hellip: '\u2026',
};

/** A fetched page as text: scripts, styles and tags dropped, entities decoded. For passageOnPage. */
export function pageText(html: string): string {
  return html
    .replace(/<(script|style|noscript)\b[\s\S]*?<\/\1>/gi, ' ')
    .replace(/<[^>]*>/g, ' ')
    .replace(/&(#x[0-9a-f]+|#\d+|[a-z]+);/gi, (m, e: string) => {
      if (e[0] === '#') return String.fromCodePoint(e[1] === 'x' || e[1] === 'X' ? parseInt(e.slice(2), 16) : parseInt(e.slice(1), 10));
      return ENTITIES[e.toLowerCase()] ?? m;
    });
}

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
