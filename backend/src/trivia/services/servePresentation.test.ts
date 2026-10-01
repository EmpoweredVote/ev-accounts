import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
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

describe('every path that puts a question in a session presents it first', () => {
  it('createSession presents', () => {
    const src = readFileSync('src/trivia/services/sessionService.ts', 'utf8');
    expect(src).toMatch(/presentQuestion\(/);
  });

  it('the adaptive append presents — this is the entry point that gets forgotten', () => {
    const src = readFileSync('src/trivia/routes/game.ts', 'utf8');
    const push = src.slice(src.indexOf('session.questions.push('));
    expect(src).toMatch(/const presented = presentQuestion\(nextQ\)/);
    expect(push.slice(0, 40)).toContain('presented');
  });
});
