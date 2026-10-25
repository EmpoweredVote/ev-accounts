import { describe, it, expect } from 'vitest';
import { presentQuestion } from './servePresentation.js';
import type { Question } from './sessionService.js';

const base: Question = {
  id: 'akron-oh_0002', text: 'How many members?', options: ['9', '11', '13', '15'],
  correctAnswer: 2, explanation: '', difficulty: 'easy', topic: 't', topicCategory: 'c',
};

/** Deterministic rng for tests: always returns `v`. */
const rng = (v: number) => () => v;

describe('presentQuestion — numeric with a scale', () => {
  const scaled: Question = {
    ...base,
    options: ['9', '11', '13', '15'],
    correctAnswer: 2,
    optionsScale: ['7', '9', '11', '13', '15', '17', '19'],
  };

  it('serves a window from the scale, answer included, ascending', () => {
    const r = presentQuestion(scaled, rng(0)); // roll 1
    expect(r.options).toEqual(['7', '9', '11', '13']);
    expect(r.options[r.correctAnswer]).toBe('13');
  });

  it('reaches position A on the top roll', () => {
    const r = presentQuestion(scaled, rng(0.99)); // roll 4
    expect(r.correctAnswer).toBe(0);
    expect(r.options[r.correctAnswer]).toBe('13');
  });

  it('never loses the answer across many rolls', () => {
    for (let i = 0; i < 200; i++) {
      const r = presentQuestion(scaled, Math.random);
      expect(r.options[r.correctAnswer]).toBe('13');
      expect(r.options).toHaveLength(4);
    }
  });

  it('falls back to stored options when the scale is malformed', () => {
    const bad = { ...scaled, optionsScale: ['7', '9', '11'] };
    const r = presentQuestion(bad, rng(0));
    expect(r.options).toEqual(['9', '11', '13', '15']);
    expect(r.correctAnswer).toBe(2);
  });

  it('falls back to stored options when the scale is well-formed but misaligned with the real answer', () => {
    // Well-formed (length 7, ascending, one unit) but SCALE_ANSWER_INDEX (3) holds '15',
    // not '13' -- the row's real answer. A backfill bug or a scale copied from a sibling
    // row would produce exactly this: internally consistent, but wrong.
    const misaligned = { ...scaled, optionsScale: ['7', '9', '11', '15', '13', '17', '19'] };
    const r = presentQuestion(misaligned, rng(0));
    expect(r.options).toEqual(['9', '11', '13', '15']);
    expect(r.correctAnswer).toBe(2);
    expect(r.options[r.correctAnswer]).toBe('13');
  });

  it('never serves optionsScale to the caller, even on a successful roll', () => {
    const r = presentQuestion(scaled, rng(0));
    expect(r).not.toHaveProperty('optionsScale');
  });
});

describe('presentQuestion — prose', () => {
  const prose: Question = {
    ...base, options: ['Alpha', 'Beta', 'Gamma', 'Delta'], correctAnswer: 1, optionsScale: null,
  };

  it('keeps the answer attached to its own text after shuffling', () => {
    for (let i = 0; i < 200; i++) {
      const r = presentQuestion(prose, Math.random);
      expect(r.options[r.correctAnswer]).toBe('Beta');
      expect([...r.options].sort()).toEqual([...prose.options].sort());
    }
  });

  it('actually varies position across sessions', () => {
    const seen = new Set<number>();
    for (let i = 0; i < 200; i++) seen.add(presentQuestion(prose, Math.random).correctAnswer);
    expect(seen.size).toBeGreaterThan(1);
  });

  it('leaves a fixed-position option set untouched', () => {
    const fixed: Question = {
      ...base, options: ['10', '20', '30', 'All of the above'], correctAnswer: 3, optionsScale: null,
    };
    const r = presentQuestion(fixed, rng(0.99));
    expect(r.options).toEqual(['10', '20', '30', 'All of the above']);
    expect(r.correctAnswer).toBe(3);
  });

  it('does not mutate its input', () => {
    const input = { ...prose, options: [...prose.options] };
    presentQuestion(input, rng(0.5));
    expect(input.options).toEqual(['Alpha', 'Beta', 'Gamma', 'Delta']);
    expect(input.correctAnswer).toBe(1);
  });
});

describe('presentQuestion — legacy numeric (optionsScale null, pre-Task-7 backfill)', () => {
  it('keeps an unbounded magnitude series (population figures) in stored order, never shuffled', () => {
    // stlmo-020 shape: ascending population figures, no scale yet.
    const unbounded: Question = {
      ...base,
      options: ['800,000', '1,000,000', '2,250,000', '5,000,000'],
      correctAnswer: 1,
      optionsScale: null,
    };
    for (let i = 0; i < 50; i++) {
      const r = presentQuestion(unbounded, Math.random);
      expect(r.options).toEqual(['800,000', '1,000,000', '2,250,000', '5,000,000']);
      expect(r.correctAnswer).toBe(1);
    }
  });

  it('still shuffles a bounded series (term lengths), tracking the answer by text', () => {
    const bounded: Question = {
      ...base,
      options: ['1 year', '2 years', '4 years', '6 years'],
      correctAnswer: 1,
      optionsScale: null,
    };
    const seen = new Set<number>();
    for (let i = 0; i < 200; i++) {
      const r = presentQuestion(bounded, Math.random);
      expect(r.options[r.correctAnswer]).toBe('2 years');
      expect([...r.options].sort()).toEqual([...bounded.options].sort());
      seen.add(r.correctAnswer);
    }
    expect(seen.size).toBeGreaterThan(1);
  });
});

// The two source-text-regex tests that used to live here (grepping sessionService.ts and
// game.ts for a `presentQuestion(` call) were deleted per code review: they passed green
// while the adaptive-mode first question was served UNPRESENTED (a Critical regression),
// because a regex can see that a call site exists without seeing whether its result is
// what actually gets served. Replaced by behavioural tests in
// `routes/game.presentation.test.ts`, which assert the served HTTP payload equals the
// stored session questions for all three paths a question can enter a session: classic
// start, adaptive start, and the adaptive append.
