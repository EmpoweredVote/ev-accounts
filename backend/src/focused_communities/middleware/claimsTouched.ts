// The one channel by which a claim write tells the cache which OTHER rows it changed.
//
// It is a module of its own, and small on purpose. middleware/claimInvalidation.ts — the reader —
// imports routes/claims.ts for the key builders, and therefore the whole read side; a route file
// that only wants to say "I also moved these rows" must not drag that in behind it. So the
// contract lives here, the `res.locals` key is written in exactly one place, and a route imports
// nothing it does not use.

import type { Response } from 'express';

/** Same shape the claim routes accept. An id that is not one names no claim. */
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const TOUCHED = 'fcClaimsTouched';

/**
 * Publish ids the invalidation middleware cannot work out for itself.
 *
 * routes/claimCuration.ts is the only caller, because it is the only file in the module that
 * rewrites rows other than the one named in the URL: a move's OLD parent is gone from the row by
 * the time the middleware reads it back, and the swept subtree appears in no response at all.
 *
 * Nulls and undefineds are accepted and dropped, so a call site can pass `row.parent_claim_id`
 * without a guard. Ids are lower-cased here as everywhere else that an id reaches a cache key:
 * the read side canonicalises before it mints one, so a delete that did not would name a key
 * nobody ever wrote while the live entry survived.
 *
 * Marking is not deleting. The middleware acts only on a 2xx response, so ids marked inside a
 * transaction that then rolls back cost nothing.
 */
export function markClaimsTouched(res: Response, ...ids: readonly (string | null | undefined)[]): void {
  const already = (res.locals[TOUCHED] as string[] | undefined) ?? [];
  res.locals[TOUCHED] = already.concat(
    ids
      .filter((id): id is string => typeof id === 'string' && UUID_RE.test(id))
      .map((id) => id.toLowerCase())
  );
}

/** Everything marked on this response, canonical and possibly empty. */
export function touchedClaims(res: Response): readonly string[] {
  return (res.locals[TOUCHED] as string[] | undefined) ?? [];
}
