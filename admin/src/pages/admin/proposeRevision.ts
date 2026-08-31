import { hasChanged } from '../../lib/wordDiff';

/**
 * Pure logic behind the revision editor (ProposeRevisionPage). Kept out of the
 * component so the payload rules are unit-testable (the app has no component
 * tests by construction — vitest runs node, .ts only).
 */

export type ChangeClass = 'editorial' | 'clarifying' | 'substantive';

export interface CurrentTopicContent {
  topicKey: string;
  title: string;
  shortTitle: string | null;
  questionText: string;
  revision: number;
  version: number;
  ladder: { value: number; text: string }[];
}

export interface EditedContent {
  title: string;
  shortTitle: string;
  questionText: string;
  /** Exactly five texts, index 0 = chair 1. */
  rungs: string[];
  changeClass: ChangeClass;
  rationale: string;
  publicNote: string;
  reviewRef: string;
}

export interface ProposalPayload {
  topic_key: string;
  change_class: ChangeClass;
  title: string;
  short_title: string | null;
  question_text: string;
  stances: { value: number; text: string }[];
  rationale: string;
  public_note: string;
  review_ref: string | null;
  rung_map: Record<string, number> | null;
}

export function seedEdited(current: CurrentTopicContent): EditedContent {
  const rungs = [1, 2, 3, 4, 5].map(
    (v) => current.ladder.find((r) => r.value === v)?.text ?? '',
  );
  return {
    title: current.title,
    shortTitle: current.shortTitle ?? '',
    questionText: current.questionText,
    rungs,
    changeClass: 'clarifying',
    rationale: '',
    publicNote: '',
    reviewRef: '',
  };
}

/** Whitespace-insensitive change test per field, matching the diff renderer. */
export function changedFields(current: CurrentTopicContent, e: EditedContent): {
  title: boolean;
  shortTitle: boolean;
  questionText: boolean;
  rungs: boolean[];
  ladderChanged: boolean;
  anyChanged: boolean;
} {
  const rungs = [1, 2, 3, 4, 5].map((v, i) =>
    hasChanged(current.ladder.find((r) => r.value === v)?.text ?? '', e.rungs[i] ?? ''),
  );
  const ladderChanged = rungs.some(Boolean);
  const title = hasChanged(current.title, e.title);
  const shortTitle = hasChanged(current.shortTitle ?? '', e.shortTitle);
  const questionText = hasChanged(current.questionText, e.questionText);
  return {
    title,
    shortTitle,
    questionText,
    rungs,
    ladderChanged,
    anyChanged: title || shortTitle || questionText || ladderChanged,
  };
}

/** Blocking problems, in the order they should be shown. Empty = submittable. */
export function validateProposal(current: CurrentTopicContent, e: EditedContent): string[] {
  const problems: string[] = [];
  const c = changedFields(current, e);
  if (!c.anyChanged) problems.push('Nothing has changed yet — edit at least one field.');
  if (!e.title.trim()) problems.push('The title cannot be empty.');
  if (!e.questionText.trim()) problems.push('The question cannot be empty.');
  e.rungs.forEach((r, i) => {
    if (!r.trim()) problems.push(`Option ${i + 1} cannot be empty.`);
  });
  if (!e.rationale.trim()) problems.push('A rationale is required — it is what the reviewer reads.');
  if (!e.publicNote.trim()) {
    problems.push('A public note is required — revisions are a transparency surface (ADR 0004 §9).');
  }
  return problems;
}

/**
 * The POST body. The rung map is ALWAYS the identity when the ladder changed
 * and null when it did not: this editor rewords chairs in place. Moving,
 * merging, or removing a chair is refused at publish (answer re-pointing is
 * not built), so the editor does not offer it.
 */
export function buildProposalPayload(
  current: CurrentTopicContent,
  e: EditedContent,
): ProposalPayload {
  const { ladderChanged } = changedFields(current, e);
  return {
    topic_key: current.topicKey,
    change_class: e.changeClass,
    title: e.title.trim(),
    short_title: e.shortTitle.trim() === '' ? null : e.shortTitle.trim(),
    question_text: e.questionText.trim(),
    stances: e.rungs.map((text, i) => ({ value: i + 1, text: text.trim() })),
    rationale: e.rationale.trim(),
    public_note: e.publicNote.trim(),
    review_ref: e.reviewRef.trim() === '' ? null : e.reviewRef.trim(),
    rung_map: ladderChanged ? { 1: 1, 2: 2, 3: 3, 4: 4, 5: 5 } : null,
  };
}
