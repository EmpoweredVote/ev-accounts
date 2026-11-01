import removeMd from 'remove-markdown';

// --- Cursor Pagination ---

export function encodeCursor(timestamp: string, id: string): string {
  return Buffer.from(JSON.stringify({ t: timestamp, id })).toString('base64url');
}

export function decodeCursor(cursor: string): { t: string; id: string } | null {
  try {
    const parsed = JSON.parse(Buffer.from(cursor, 'base64url').toString('utf8'));
    if (typeof parsed.t === 'string' && typeof parsed.id === 'string') return parsed;
    return null;
  } catch {
    return null;
  }
}

// --- Excerpt Generation ---

export function generateExcerpt(body: string, maxLength = 200): string {
  const plain = removeMd(body, { useImgAltText: false })
    .replace(/\s+/g, ' ')
    .trim();
  if (plain.length <= maxLength) return plain;
  const truncated = plain.slice(0, maxLength);
  const lastSpace = truncated.lastIndexOf(' ');
  return (lastSpace > 0 ? truncated.slice(0, lastSpace) : truncated) + '\u2026';
}

// --- Argument tree bounds ---

/**
 * How deep the argument tree may go. A root is depth 0, so this admits 50 levels of argument
 * beneath it.
 *
 * A Kialo-style debate runs 8-10 levels; 50 is far past any legitimate use while bounding the
 * breadcrumb to about 50 rows rather than the half-megabyte response a depth-500 claim would
 * produce — and that response is served to anonymous readers as `public, s-maxage=30`, so one
 * pathological claim would be cached and re-served rather than merely computed once.
 *
 * Erring high is the cheap direction: raising this later is a one-constant change plus a relaxed
 * CHECK, with no data migration, while lowering it orphans rows that already exist.
 *
 * 🔴 It lives here, not in a route, because THREE places have to agree on it and two of them are
 * sibling routers: routes/claimWrites.ts rejects a child of a parent already at the cap,
 * routes/claims.ts bounds the breadcrumb query by it, and CA_0344 puts it in a CHECK constraint
 * so it binds `postgres` too, which is exempt from every grant. Change it in all three or not at
 * all — the constraint is the one that will tell you.
 */
export const MAX_CLAIM_DEPTH = 50;

// --- Query Parameter Parsing ---

const MAX_LIMIT = 100;

export function parseLimit(raw: string | undefined, defaultLimit: number): number {
  const n = parseInt(raw ?? '', 10);
  if (isNaN(n) || n < 1) return defaultLimit;
  return Math.min(n, MAX_LIMIT);
}
