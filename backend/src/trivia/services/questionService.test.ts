import { describe, it, expect } from 'vitest';
import { needsTopicRefresh, preferUnowned } from './questionService.js';
import type { DBQuestionRow } from './gameModes.js';

/**
 * WHY THIS EXISTS
 * ---------------
 * `loadTopicMap()` cached the topic map at module level under the comment
 * "these values never change during runtime". They do. Every new collection
 * scaffold inserts topic rows, and a long-lived process keeps serving the map
 * it loaded at boot. A question whose topic_id is missing from that map falls
 * through `topicMap.get(id) || 'Unknown'` — and `Question.topic` is rendered
 * straight onto the card by QuestionCard.tsx, so the player is shown the
 * literal word "Unknown".
 *
 * It surfaced when 137 questions were repointed onto nine newly created topics
 * to fix state collections showing each other's topic names. Every one of them
 * would have read "Unknown" until the next deploy.
 *
 * The decision is pulled out of the loader so it can be tested without a
 * database, the same way `skipReasonFor()` was pulled out of the preflight loop.
 *
 * The `unresolvable` set is the other half. Without it, a question pointing at
 * a topic row that genuinely does not exist — a deleted topic — would miss the
 * cache forever and trigger a fresh SELECT on every single request.
 */
describe('needsTopicRefresh', () => {
  const warm = () => new Map<number, string>([[1, 'Constitution'], [2, 'Supreme Court']]);
  const none = new Set<number>();

  it('refreshes when there is no cache at all', () => {
    expect(needsTopicRefresh(null, [], none)).toBe(true);
  });

  it('does not refresh a warm cache when nothing is required', () => {
    expect(needsTopicRefresh(warm(), [], none)).toBe(false);
  });

  it('does not refresh when every required topic is already cached', () => {
    expect(needsTopicRefresh(warm(), [1, 2, 1], none)).toBe(false);
  });

  it('refreshes when a required topic is missing from a warm cache', () => {
    // The case that produced "Unknown": topic 999 was created after boot.
    expect(needsTopicRefresh(warm(), [1, 999], none)).toBe(true);
  });

  it('does not refresh again for a topic a previous refresh could not resolve', () => {
    // Otherwise a question pointing at a deleted topic costs a SELECT per request.
    expect(needsTopicRefresh(warm(), [999], new Set([999]))).toBe(false);
  });

  it('still refreshes for a new missing topic even when another is unresolvable', () => {
    expect(needsTopicRefresh(warm(), [999, 1000], new Set([999]))).toBe(true);
  });

  it('refreshes for a missing topic even when the cache is empty rather than null', () => {
    // An empty map is a real cache state — a database with no topic rows yet.
    // It must not be confused with "not loaded".
    expect(needsTopicRefresh(new Map(), [5], none)).toBe(true);
    expect(needsTopicRefresh(new Map(), [], none)).toBe(false);
  });
});

/**
 * WHY THIS EXISTS
 * ---------------
 * A CTC collection bobit is granted the first time a question is answered correctly, and the
 * tableau needs 100 DISTINCT bobits in one collection to raise its 25 lines. Measured against
 * the live bank on 2026-10-11: the most engaged player on record had played 45 games -- about
 * 225 question slots -- and held 23 bobits spread over five collections, two lines deep at
 * best. The cause was selection, not content: the only record of what a player had already
 * seen was a 30-deep in-process Map in the game route, wiped by every deploy.
 *
 * `preferUnowned` is the fix, and it is deliberately a PREFERENCE. Excluding owned questions
 * would starve a 31-question collection into an empty pool and then into the JSON fallback,
 * and it would stop trivia doing the one thing repetition is for. Every picker takes from the
 * front of these pools, so ordering is the whole mechanism.
 */
describe('preferUnowned', () => {
  const row = (externalId: string, difficulty = 'easy') =>
    ({ externalId, difficulty } as DBQuestionRow);
  const ids = (rows: DBQuestionRow[]) => rows.map(r => r.externalId);

  it('floats questions the player has no bobit for to the front', () => {
    const rows = [row('a'), row('b'), row('c'), row('d')];
    expect(ids(preferUnowned(rows, new Set(['a', 'c'])))).toEqual(['b', 'd', 'a', 'c']);
  });

  it('keeps owned questions rather than dropping them', () => {
    // The whole design decision in one assertion. A 31-question collection whose player owns
    // most of it must still be able to fill five slots.
    const rows = [row('a'), row('b'), row('c')];
    const out = preferUnowned(rows, new Set(['a', 'b', 'c']));
    expect(out).toHaveLength(3);
    expect(new Set(ids(out))).toEqual(new Set(['a', 'b', 'c']));
  });

  it('is stable, so the shuffle upstream still decides the order within each group', () => {
    // Shuffling happens BEFORE this runs. If the partition reordered within a group it would
    // be handing every player the same questions in the same order.
    const rows = [row('a'), row('b'), row('c'), row('d'), row('e'), row('f')];
    expect(ids(preferUnowned(rows, new Set(['b', 'e'])))).toEqual(['a', 'c', 'd', 'f', 'b', 'e']);
  });

  it('changes nothing for a signed-out player, who owns nothing', () => {
    const rows = [row('a'), row('b'), row('c')];
    expect(preferUnowned(rows, new Set())).toBe(rows);
  });

  it('changes nothing for a player who owns the whole collection', () => {
    // Not a no-op by accident: it is the same list in the same order, which is what makes a
    // completed collection behave exactly as it does today.
    const rows = [row('a'), row('b'), row('c')];
    expect(ids(preferUnowned(rows, new Set(['a', 'b', 'c'])))).toEqual(['a', 'b', 'c']);
  });

  it('serves the whole collection before repeating, which is the point', () => {
    // The regression this guards: five games of five, drawing from the front each time and
    // recording what was earned. Before the fix the pool order ignored ownership entirely and
    // a player could see the same question in game 2 that they had answered in game 1.
    const pool = Array.from({ length: 25 }, (_, i) => row(`q${i}`));
    const owned = new Set<string>();
    const served: string[] = [];
    for (let game = 0; game < 5; game++) {
      const ordered = preferUnowned(pool, owned);
      for (const picked of ordered.slice(0, 5)) {
        served.push(picked.externalId);
        owned.add(picked.externalId);
      }
    }
    expect(served).toHaveLength(25);
    expect(new Set(served).size, 'every question served exactly once').toBe(25);
  });
});
