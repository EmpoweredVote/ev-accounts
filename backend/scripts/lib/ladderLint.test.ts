import { describe, it, expect } from 'vitest';
import { lintRungs } from './ladderLint';

const summary = (h: ReturnType<typeof lintRungs>) => h.map((x) => `${x.rung}:${x.check}`);

describe('lintRungs', () => {
  it('equity control rev 1 gives 6 hits', () => {
    const hits = lintRungs([
      'Fund dedicated equity offices and staff to close gaps between student groups',
      'Require equity training for staff and set measurable goals to close gaps between groups',
      'Measure results for each student group and steer extra support to those falling behind',
      'Offer the same supports to every struggling student, without grouping them by race or identity',
      'Eliminate equity programs, training, and staff from the district',
    ]);
    expect(summary(hits)).toEqual(['1:and', '2:and', '3:and', '4:without', '4:every/any/all', '5:and']);
  });

  it('library Draft A: only "all students" on rungs 3, 4, 5', () => {
    const hits = lintRungs([
      'Bar schools from removing or restricting a book because someone objects to its content',
      'Answer a challenge by letting the parent restrict the book for their own child',
      'Remove a challenged book for all students after a review body finds it unsuitable',
      'Pull a challenged book from all students until a review decides',
      'Remove a challenged book for all students with no review',
    ]);
    expect(hits).toHaveLength(3);
    expect(hits.every((h) => h.check === 'every/any/all')).toBe(true);
    expect(hits.map((h) => h.rung)).toEqual([3, 4, 5]);
  });
});
