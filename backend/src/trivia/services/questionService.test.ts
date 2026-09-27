import { describe, it, expect } from 'vitest';
import { needsTopicRefresh } from './questionService.js';

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
