/**
 * stage5CoderSummary.ts — the summary written inside the coding step (STAGE5.md 7b, "Written by the coder").
 *
 * A position summary is normally written by a second agent that re-reads everything the coder just read. With
 * `coder-inputs.ts --with-summary` the coder writes it in the same pass, as `summary` on each seated or doesnt-fit
 * entry. Trial 2026-11-22/23 (gun policy): Nevada placements were the same in two plain and two merged runs (17 of
 * 17 each), the blind check on the 24 own-words seats agreed with the codes on 23 with the merged brief (plain
 * brief: 22), and the Opus cost of coding plus writing fell from $3.10 to $1.79 for 17 people.
 *
 * The rules the coder is given are the summary writer's own, cut from its template, so there is one copy of them.
 * The coder's summary is only a draft: it goes through the same lint and checker as any other, and it is used only
 * while the person's code is still the one the coder gave.
 */
import { SummaryDraftSchema, type SummaryDraft } from './stage5Summary.js';
import type { Stage5Code } from './stage5Code.js';

const RULES_START = 'A summary is one short paragraph';
const RULES_END = '## People';
export const SUMMARY_JOB_HEADING = '## Second job: a summary voters will read, for each person you coded seated or doesnt-fit';

/** The "second job" section of a coder brief, built from the summary writer's template. Throws if the template has moved. */
export function summaryJobSection(writerTemplate: string, sides: string | null): string {
  const a = writerTemplate.indexOf(RULES_START); const b = writerTemplate.indexOf(RULES_END);
  if (a < 0 || b < a) throw new Error(`summaryJobSection: the writer template no longer holds "${RULES_START}" before "${RULES_END}"`);
  const rules = writerTemplate.slice(a, b).trim()
    .replaceAll('{{SIDES}}', sides ?? 'none ruled for this topic')
    .replace("The bill text is listed under each person's findings.", "The bill's text is the `operative_text` in its instrument file, and its subject lines in the findings file's `bills` table where there is one.")
    .replace(/^## /gm, '### ')
    .replace("Use only `cites` ids that appear in that person's findings below.", "Use only `cites` ids that are that person's finding ids in the findings file.");
  const left = rules.match(/\{\{\w+\}\}/g);
  if (left) throw new Error(`summaryJobSection: writer template slots this section cannot fill: ${[...new Set(left)].join(', ')}`);
  return `${SUMMARY_JOB_HEADING}

Finish a person's code first. Then, if the outcome is \`seated\` or \`doesnt-fit\` and the person has at least one
finding, write a short, cited summary of what the person has said or done on the topic, and put it in that person's
entry as \`summary\`. Write none for \`no-stance\`. The summary is a separate text from \`reasoning\`: it never uses the
rungs' words, and it follows the rules below. In a collapsed findings file a vote line carries its census gate
(\`none\` = not gated) and a sponsorship line its role; those are what the rules call the finding's \`act\` and
\`gated:\` mark. You may cite any of the person's findings, not only the ones in \`finding_ids\`.

${rules}

### The summary's shape in your output

Add this to the person's entry:

\`\`\`json
"summary": { "sentences": [
  { "text": "Opening line in plain words, no brackets.", "lead": true },
  { "parts": [
      { "text": "In the House, he voted to end the license requirement to carry a handgun,", "cites": ["<finding id>"] },
      { "text": "to honor carry licenses from more states", "cites": ["<finding id>"] }
  ] },
  { "text": "A sentence about one act, no brackets.", "cites": ["<finding id>", "<finding id>"] }
] }
\`\`\`
`;
}

/** Put the section before the brief's rulings (so the rulings stay last), or at the end when it has no such heading. */
export function withSummaryJob(brief: string, section: string): string {
  const i = brief.indexOf('## Rulings and notes for this batch');
  return i < 0 ? `${brief.trimEnd()}\n\n${section}` : `${brief.slice(0, i)}${section}\n${brief.slice(i)}`;
}

/** A coder's summary as stored beside the codes: the draft, and the code it was written for. */
export interface CoderSummary { politician_id: string; topic_key: string; outcome: string; value: number | null; batch: string; sentences: SummaryDraft['sentences'] }

/** Split a coder entry into the code entry and its summary. A malformed `summary` is dropped with a reason, never kept. */
export function takeSummary(entry: Record<string, unknown>): { entry: Record<string, unknown>; sentences: SummaryDraft['sentences'] | null; problem: string | null } {
  const { summary, ...rest } = entry;
  if (summary === undefined || summary === null) return { entry: rest, sentences: null, problem: null };
  const got = SummaryDraftSchema.shape.sentences.safeParse((summary as { sentences?: unknown }).sentences);
  if (!got.success || got.data.length === 0) return { entry: rest, sentences: null, problem: 'the summary is not a list of sentences in the writer\'s shape; it was not kept' };
  return { entry: rest, sentences: got.data, problem: null };
}

/** The stored record for a passing code, or null when the outcome gets no summary. */
export function coderSummary(code: Pick<Stage5Code, 'politician_id' | 'topic_key' | 'outcome' | 'value'>, sentences: SummaryDraft['sentences'], batch: string): CoderSummary | null {
  if (code.outcome !== 'seated' && code.outcome !== 'doesnt-fit') return null;
  return { politician_id: code.politician_id, topic_key: code.topic_key, outcome: code.outcome, value: code.value ?? null, batch, sentences };
}

/**
 * The draft to use for a person, or null with the reason. A coder's summary describes the code the coder gave; once a
 * review or a re-code has changed the outcome or the seat, it is stale and the separate writer takes over.
 */
export function usableCoderDraft(stored: CoderSummary | undefined, code: Pick<Stage5Code, 'outcome' | 'value'>): { draft: SummaryDraft | null; why: string } {
  if (!stored) return { draft: null, why: 'no coder summary on file' };
  if (stored.outcome !== code.outcome || (stored.value ?? null) !== (code.value ?? null)) {
    return { draft: null, why: `written for ${stored.outcome}${stored.value ? ` ${stored.value}` : ''}; the code is now ${code.outcome}${code.value ? ` ${code.value}` : ''}` };
  }
  return { draft: { politician_id: stored.politician_id, topic_key: stored.topic_key, sentences: stored.sentences }, why: '' };
}
