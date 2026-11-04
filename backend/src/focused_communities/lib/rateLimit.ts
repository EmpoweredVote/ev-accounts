import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

/**
 * Shared rate limiter for thread creation and reply posting.
 * 5 posts per hour per user, sliding window.
 *
 * Editing does NOT use this limiter — only create operations.
 *
 * When Upstash env vars are absent (dev/test), exports a stub that always
 * returns { success: true } so routes behave correctly without credentials.
 */
export const postRateLimiter: Ratelimit = (() => {
  if (
    process.env.UPSTASH_REDIS_REST_URL &&
    process.env.UPSTASH_REDIS_REST_TOKEN
  ) {
    return new Ratelimit({
      redis: Redis.fromEnv(),
      limiter: Ratelimit.slidingWindow(5, '1 h'),
      prefix: 'fc:rl',
    });
  }

  // Dev/test stub — always allows, mirrors Ratelimit.limit() return shape
  return {
    limit: async (_identifier: string) => ({
      success: true,
      limit: 5,
      remaining: 4,
      reset: Date.now() + 3600000,
      pending: Promise.resolve(),
    }),
  } as unknown as Ratelimit;
})();

/**
 * Impact ratings. 60 per hour per user, sliding — twelve times postRateLimiter's budget,
 * and deliberately so.
 *
 * 🔴 WHY NOT REUSE postRateLimiter. Its 5-an-hour shape is set by what a post COSTS: a
 * thread, a reply and a claim are permanent (connect.claims has no DELETE grant), carry
 * text a moderator has to read, and cannot be taken back, so five an hour is the price of
 * making spam answerable one row at a time. A rating is none of those things. It is one
 * integer, it carries no text, it is an UPSERT — so a reader who rates the same claim
 * twenty times leaves ONE row — and changing or re-casting it is free. Five an hour would
 * make the control unusable: a reader working down a single column of twenty children
 * would be refused at the fourth one.
 *
 * 60 is chosen as "more than anyone reads in an hour, less than a script wants". The real
 * ceiling on rows is the tree: one rating per claim per person, whatever the limiter says.
 *
 * Same `fc:rl` prefix and the same sliding window as postRateLimiter, because there is one
 * limiter mechanism in this module; the BUCKET is separated by namespacing the identifier
 * at the call site, so rating cannot exhaust the quota for writing, or the reverse.
 */
export const ratingRateLimiter: Ratelimit = (() => {
  if (process.env.UPSTASH_REDIS_REST_URL && process.env.UPSTASH_REDIS_REST_TOKEN) {
    return new Ratelimit({
      redis: Redis.fromEnv(),
      limiter: Ratelimit.slidingWindow(60, '1 h'),
      prefix: 'fc:rl',
    });
  }

  return {
    limit: async (_identifier: string) => ({
      success: true,
      limit: 60,
      remaining: 59,
      reset: Date.now() + 3600000,
      pending: Promise.resolve(),
    }),
  } as unknown as Ratelimit;
})();
