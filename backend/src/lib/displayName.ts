/**
 * displayName — the single home for the account contract's "never null/empty" name guarantee.
 *
 * WHY THIS EXISTS
 * getAccountMe returns a top-level display_name that consumers (the folded Civic Spaces slice
 * assigner among them) write into NOT NULL columns. A null base name (public.users) with the
 * user's chosen pseudonym stranded in connect.connected_profiles produced a 500 on /assign
 * (ev-cto watchlist #70). This module resolves the name, and when there is genuinely none it
 * mints a pseudonym. For Inform/Connected accounts display_name IS the pseudonym — there is no
 * separate real name — so an auto-generated one is a valid identity.
 */

// Curated so no AdjectiveAnimal pair reads as an insult. CamelCase pieces; the joined form is
// e.g. "RapidWolverine" (decision 2026-09-13, Chris Andrews).
const ADJECTIVES = [
  'Amber', 'Autumn', 'Bold', 'Brave', 'Bright', 'Calm', 'Cedar', 'Clever', 'Cobalt', 'Coral',
  'Cosmic', 'Crimson', 'Daring', 'Dawn', 'Eager', 'Ember', 'Fair', 'Gentle', 'Golden', 'Grand',
  'Hazel', 'Humble', 'Indigo', 'Ivory', 'Jade', 'Jolly', 'Keen', 'Kind', 'Lively', 'Loyal',
  'Lunar', 'Mellow', 'Merry', 'Mighty', 'Noble', 'Olive', 'Onyx', 'Placid', 'Quick', 'Quiet',
  'Rapid', 'Ruby', 'Sage', 'Scarlet', 'Silver', 'Solar', 'Spry', 'Stellar', 'Sunny', 'Swift',
  'Teal', 'Tidal', 'Trusty', 'Valiant', 'Vivid', 'Witty',
]

const ANIMALS = [
  'Otter', 'Wolverine', 'Falcon', 'Heron', 'Bison', 'Marten', 'Osprey', 'Lynx', 'Puffin',
  'Badger', 'Beaver', 'Sparrow', 'Finch', 'Marmot', 'Ibis', 'Crane', 'Egret', 'Salmon', 'Sable',
  'Stoat', 'Tapir', 'Vole', 'Wren', 'Gecko', 'Newt', 'Quail', 'Raven', 'Robin', 'Skink', 'Turtle',
  'Vireo', 'Walrus', 'Whale', 'Bittern', 'Dunlin', 'Godwit', 'Kestrel', 'Merlin', 'Plover',
  'Hare', 'Moose', 'Pika',
]

export function firstNonBlank(...values: Array<string | null | undefined>): string | undefined {
  for (const v of values) {
    if (typeof v === 'string') {
      const trimmed = v.trim()
      if (trimmed !== '') return trimmed
    }
  }
  return undefined
}

// FNV-1a 32-bit — a tiny dependency-free stable hash. It only indexes the word lists, so its
// statistical quality is irrelevant; stability across processes is the whole point.
function hash32(seed: string): number {
  let h = 0x811c9dc5
  for (let i = 0; i < seed.length; i++) {
    h ^= seed.charCodeAt(i)
    h = Math.imul(h, 0x01000193)
  }
  return h >>> 0
}

function pair(a: number, b: number): string {
  return ADJECTIVES[a % ADJECTIVES.length] + ANIMALS[b % ANIMALS.length]
}

/**
 * A stable pseudonym derived from a seed (the user id). Same seed → same name forever, with no
 * stored state and no DB round-trip. Used only as the read-time last-resort guard in
 * getAccountMe and the write guard in upsertConnectedProfile — it fires only for an account
 * with no name ANYWHERE, which after the backfill and sign-up enforcement is essentially never.
 * It is NOT uniqueness-checked (a read path cannot be), so it is deliberately not how a name is
 * normally assigned — see generateUniqueAutoName.
 */
export function deterministicAutoName(seed: string): string {
  const h = hash32(seed)
  return pair(h, h >>> 8)
}

export interface Queryable {
  query<T = unknown>(text: string, params?: unknown[]): Promise<{ rows: T[] }>
}

/**
 * A random pseudonym that is free at creation time: pick an AdjectiveAnimal, and if
 * public.users already holds it (case-insensitive) append 2, 3, … until free. Best-effort:
 * there is a negligible TOCTOU window between this check and the caller's insert, acceptable
 * for the only caller (a no-name WorkOS sign-up). Names are not globally unique by constraint;
 * this only stops auto-names from colliding, which is the RapidWolverine concern.
 */
export async function generateUniqueAutoName(db: Queryable): Promise<string> {
  for (let attempt = 0; attempt < 8; attempt++) {
    const h = hash32(`${Date.now()}-${Math.random()}-${attempt}`)
    const base = pair(h, h >>> 8)
    for (let n = 0; n < 50; n++) {
      const candidate = n === 0 ? base : `${base}${n + 1}`
      const { rows } = await db.query<{ one: number }>(
        `SELECT 1 AS one FROM public.users WHERE lower(btrim(display_name)) = lower($1) LIMIT 1`,
        [candidate]
      )
      if (rows.length === 0) return candidate
    }
  }
  // Astronomically unlikely exhaustion — a time-seeded name no check cleared, still non-empty,
  // so the never-null guarantee holds.
  return deterministicAutoName(`${Date.now()}-${Math.random()}`)
}
