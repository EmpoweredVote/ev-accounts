import { describe, it, expect } from 'vitest';
import { isValidScale, rollWindow, SCALE_LENGTH, SCALE_ANSWER_INDEX } from './answerScale.js';

describe('isValidScale — what the server is willing to roll against', () => {
  const good = ['7', '9', '11', '13', '15', '17', '19'];

  it('accepts a strictly ascending 7-mark scale', () => {
    expect(isValidScale(good)).toBe(true);
  });

  it('rejects a scale of the wrong length', () => {
    expect(isValidScale(['7', '9', '11', '13', '15', '17'])).toBe(false);
  });

  it('rejects null and undefined — these are the common case, not an error', () => {
    expect(isValidScale(null)).toBe(false);
    expect(isValidScale(undefined)).toBe(false);
  });

  it('rejects a scale that is not ascending', () => {
    expect(isValidScale(['7', '9', '13', '11', '15', '17', '19'])).toBe(false);
  });

  it('rejects equal adjacent marks — a tie makes the shown answer non-unique', () => {
    expect(isValidScale(['7', '9', '11', '11', '15', '17', '19'])).toBe(false);
  });

  it('rejects a scale whose marks are not all parseable magnitudes', () => {
    expect(isValidScale(['7', '9', '11', 'thirteen', '15', '17', '19'])).toBe(false);
  });

  it('rejects mixed units — "$500 million" against "$3 billion" cannot be compared', () => {
    expect(isValidScale(['$1 million', '$2 million', '$3 million', '$4 million',
                         '$5 million', '$6 million', '$3 billion'])).toBe(false);
  });
});

describe('rollWindow — the roll maps bijectively onto A/B/C/D', () => {
  const scale = ['7', '9', '11', '13', '15', '17', '19']; // answer is '13', index 3

  it('places the answer at D when the roll is 1', () => {
    const r = rollWindow(scale, 1);
    expect(r.options).toEqual(['7', '9', '11', '13']);
    expect(r.correctAnswer).toBe(3);
    expect(r.options[r.correctAnswer]).toBe('13');
  });

  it('places the answer at A when the roll is 4', () => {
    const r = rollWindow(scale, 4);
    expect(r.options).toEqual(['13', '15', '17', '19']);
    expect(r.correctAnswer).toBe(0);
    expect(r.options[r.correctAnswer]).toBe('13');
  });

  it('covers every position exactly once across the four rolls', () => {
    const seen = [1, 2, 3, 4].map((s) => rollWindow(scale, s).correctAnswer);
    expect([...seen].sort()).toEqual([0, 1, 2, 3]);
  });

  it('always includes the correct answer, and always ascending', () => {
    for (const s of [1, 2, 3, 4]) {
      const r = rollWindow(scale, s);
      expect(r.options).toHaveLength(4);
      expect(r.options[r.correctAnswer]).toBe(scale[SCALE_ANSWER_INDEX]);
      const nums = r.options.map(Number);
      expect(nums).toEqual([...nums].sort((a, b) => a - b));
    }
  });

  it('throws on a roll outside 1..4 rather than serving a window without the answer', () => {
    expect(() => rollWindow(scale, 0)).toThrow();
    expect(() => rollWindow(scale, 5)).toThrow();
  });

  it('exposes the shape it assumes', () => {
    expect(SCALE_LENGTH).toBe(7);
    expect(SCALE_ANSWER_INDEX).toBe(3);
  });
});
