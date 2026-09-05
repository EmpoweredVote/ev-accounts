import { describe, it, expect } from 'vitest';
import { matchTopics, TOPIC_PATTERNS } from './topic-lead-patterns.mjs';

// The fetching half of congress-sponsorship-leads.mjs needs an API key and a
// database. This half needs neither, and it is the half that decides what a bill
// is about — so it is the half worth pinning.
//
// Every title below is REAL, taken from records this pass actually read.

describe('matchTopics', () => {
  it('finds the two bills the Senate pilot seated chairs from', () => {
    expect(matchTopics('Raise the Wage Act of 2025')).toContain('minimum-wage');
    expect(matchTopics('Assault Weapons Ban of 2025')).toContain('gun-policy');
  });

  it('ignores bills with nothing to do with the nine topics', () => {
    // All real, all cosponsored or sponsored by Schiff.
    expect(matchTopics('Water Cyber Shield Act of 2026')).toEqual([]);
    expect(matchTopics('Human-Wildlife Conflict Reduction Act of 2026')).toEqual([]);
    expect(matchTopics('Higher Education Accreditation Accountability Act')).toEqual([]);
  });

  it('is dumb about direction on purpose — both sides of a topic match', () => {
    // A ban and a carry expansion are opposite chairs on the same ladder. Both
    // must surface: the pattern's job is to find the bill, not to score it.
    const ban = matchTopics('Assault Weapons Ban of 2025');
    const carry = matchTopics('Concealed Carry Reciprocity Act');
    expect(ban).toEqual(['gun-policy']);
    expect(carry).toEqual(['gun-policy']);
  });

  it('surfaces a real firearms bill whose title never says "gun"', () => {
    expect(matchTopics('State Firearms Dealer Licensing Enhancement Act')).toEqual(['gun-policy']);
  });

  it('lets one bill raise several topics rather than picking a winner', () => {
    const hits = matchTopics('A bill to condition arms sales to Israel and restrict border asylum processing');
    expect(hits).toContain('israel-military-aid');
    expect(hits).toContain('border-security');
  });

  it('does not match a title that merely contains a topic word inside another word', () => {
    // \bgun\b must not fire on "Gunnison" — a real place name in public-lands bills.
    expect(matchTopics('Gunnison Sage-Grouse Protection Act')).toEqual([]);
  });

  it('covers exactly the nine topics Season 2 added for federal officeholders', () => {
    expect(Object.keys(TOPIC_PATTERNS).sort()).toEqual([
      '2020-election', 'border-security', 'cannabis-policy', 'defense-spending',
      'gun-policy', 'israel-military-aid', 'military-intervention',
      'minimum-wage', 'ranked-choice-voting',
    ]);
  });

  it('returns nothing for an empty or missing title rather than throwing', () => {
    expect(matchTopics('')).toEqual([]);
    expect(matchTopics(undefined)).toEqual([]);
  });
});
