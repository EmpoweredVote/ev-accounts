import { describe, it, expect } from 'vitest';
import {
  seedEdited,
  changedFields,
  validateProposal,
  buildProposalPayload,
  type CurrentTopicContent,
} from './proposeRevision';

const CURRENT: CurrentTopicContent = {
  topicKey: 'taxes',
  title: 'Taxation and Public Spending',
  shortTitle: 'Taxes',
  questionText: 'How should government balance taxes and spending?',
  revision: 1,
  version: 1,
  ladder: [1, 2, 3, 4, 5].map((v) => ({ value: v, text: `rung ${v}` })),
};

describe('seedEdited', () => {
  it('mirrors the current content, ordered by chair value', () => {
    const e = seedEdited(CURRENT);
    expect(e.title).toBe(CURRENT.title);
    expect(e.rungs).toEqual(['rung 1', 'rung 2', 'rung 3', 'rung 4', 'rung 5']);
  });

  it('fills a missing rung with an empty string instead of shifting positions', () => {
    const gappy = { ...CURRENT, ladder: CURRENT.ladder.filter((r) => r.value !== 3) };
    expect(seedEdited(gappy).rungs).toEqual(['rung 1', 'rung 2', '', 'rung 4', 'rung 5']);
  });
});

describe('changedFields', () => {
  it('ignores whitespace-only differences (matches the diff renderer)', () => {
    const e = seedEdited(CURRENT);
    e.title = '  Taxation   and Public Spending ';
    const c = changedFields(CURRENT, e);
    expect(c.title).toBe(false);
    expect(c.anyChanged).toBe(false);
  });

  it('flags a reworded rung and the ladder as changed', () => {
    const e = seedEdited(CURRENT);
    e.rungs[3] = 'Cut taxes broadly, including the main rates most people pay';
    const c = changedFields(CURRENT, e);
    expect(c.rungs).toEqual([false, false, false, true, false]);
    expect(c.ladderChanged).toBe(true);
  });
});

describe('validateProposal', () => {
  it('refuses an unedited proposal', () => {
    const e = seedEdited(CURRENT);
    e.rationale = 'r';
    e.publicNote = 'n';
    expect(validateProposal(CURRENT, e)[0]).toMatch(/Nothing has changed/);
  });

  it('requires rationale and public note', () => {
    const e = seedEdited(CURRENT);
    e.rungs[0] = 'reworded';
    const problems = validateProposal(CURRENT, e);
    expect(problems.some((p) => p.includes('rationale'))).toBe(true);
    expect(problems.some((p) => p.includes('public note'))).toBe(true);
  });

  it('accepts a complete edit', () => {
    const e = seedEdited(CURRENT);
    e.rungs[0] = 'reworded';
    e.rationale = 'why';
    e.publicNote = 'what changed';
    expect(validateProposal(CURRENT, e)).toEqual([]);
  });
});

describe('buildProposalPayload', () => {
  it('attaches the identity rung map only when the ladder changed', () => {
    const e = seedEdited(CURRENT);
    e.questionText = 'A different question?';
    expect(buildProposalPayload(CURRENT, e).rung_map).toBeNull();

    e.rungs[2] = 'a reworded middle chair';
    expect(buildProposalPayload(CURRENT, e).rung_map).toEqual({ 1: 1, 2: 2, 3: 3, 4: 4, 5: 5 });
  });

  it('nulls an empty short title and review ref, and numbers the stances 1..5', () => {
    const e = seedEdited(CURRENT);
    e.shortTitle = '  ';
    e.rungs[0] = 'reworded';
    const p = buildProposalPayload(CURRENT, e);
    expect(p.short_title).toBeNull();
    expect(p.review_ref).toBeNull();
    expect(p.stances.map((s) => s.value)).toEqual([1, 2, 3, 4, 5]);
    expect(p.stances[0].text).toBe('reworded');
  });
});
