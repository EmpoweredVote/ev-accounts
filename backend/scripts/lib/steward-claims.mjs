/**
 * Jurisdiction claims: what a scope means, and which live claims overlap it.
 *
 * Design: docs/superpowers/specs/2026-09-04-steward-coordination-design.md (§3.2, §4.2, §4.4)
 * Schema: backend/migrations/CC_0070_steward_schema.sql
 *
 * ── WHY THIS MODULE EXISTS AT ALL ───────────────────────────────────────────────────────────
 *
 * `steward.claims` carries an exclusion constraint on (scope, lease range), so two live claims
 * on `place:0642468` are impossible. That is the whole of the STRUCTURAL guarantee, and the
 * schema comment states its limit rather than hiding it: the constraint compares SCOPE STRINGS.
 * `county:06037` and `place:0642468` overlap in reality — Lomita sits inside Los Angeles County
 * — but the strings differ, so the database will not stop you.
 *
 * The LA County audit is the worked example: it covered 88 cities plus the county. A second
 * session taking one of those cities mid-audit would have been told nothing.
 *
 * So hierarchical overlap is computed here and reported as a WARNING. Structural for exact
 * matches, advisory for containment — as agreed in the design, not as a shortfall against it.
 *
 * ── CONTAINMENT COMES FROM IDENTIFIERS PLUS ONE MATVIEW, NOT FROM AD-HOC GEOMETRY ───────────
 *
 * The design said the warning would be computed with `ST_Covers` over `geofence_boundaries`.
 * It is not, and the substitution is an improvement rather than a shortcut:
 *
 *   * state ⊃ county and state ⊃ place fall straight out of the FIPS prefix. A 2-digit prefix
 *     is not a guess and needs no query.
 *   * county ⊃ place is exactly what `essentials.geofence_child_county` already holds — the
 *     persisted result of that same ST_Covers derivation, with `check:child-county` in CI
 *     guarding it against going stale behind `geofence_boundaries`.
 *
 * Re-deriving the mapping ad hoc would produce a SECOND definition of "which county is this
 * city in", answerable differently from the one the rest of the repo serves. One definition,
 * with a staleness gate on it, beats a fresh query every time.
 *
 * 🔴 EVERY FUNCTION HERE IS PURE. The CLI owns the database and the printing; this owns the
 *    reasoning, so the reasoning can be tested without a production connection.
 */
import { fipsOf } from "./state-fips.mjs";

/** `chooseScope` found no candidate free. Exported so the CLI does not match on prose. */
export const SKIP_BLOCKED = "every-candidate-held";

const JURISDICTION_KINDS = new Set(["place", "county", "state"]);

/**
 * Split `kind:id` into something that can be reasoned about.
 *
 * `kind` is one of place | county | state, or `other` for anything else — the schema comment
 * reserves `worktree:<path>` for a later rollout step, so an unrecognised kind must PARSE and
 * must then claim no geographic knowledge whatsoever.
 *
 * 🔴 A BARE IDENTIFIER IS REFUSED, NOT GUESSED. `0642468` could be a place geoid; `06037`
 *    could be a county. Inferring the kind from the digit count would silently file a claim
 *    under a scope string nobody else will search for, which is worse than no claim: the
 *    session believes it is visible and it is not.
 */
export function parseScope(raw) {
  if (typeof raw !== "string" || !raw.trim()) throw new Error("a scope cannot be empty");
  const text = raw.trim();
  const at = text.indexOf(":");
  if (at < 1 || at === text.length - 1) {
    throw new Error(`scope "${text}" has no kind — write place:<geoid>, county:<fips> or state:<usps>`);
  }
  const kind = text.slice(0, at).toLowerCase();
  const idRaw = text.slice(at + 1).trim();
  if (!JURISDICTION_KINDS.has(kind)) {
    return { raw: text, canonical: `${kind}:${idRaw}`, kind: "other", id: idRaw, stateFips: null, countyFips: null };
  }

  // Jurisdiction ids fold case; a path-like `other` id must not, hence the split above.
  const id = idRaw.toLowerCase();
  const stateFips = kind === "state" ? fipsOf(id) : /^\d{2}/.test(id) ? id.slice(0, 2) : null;
  const countyFips = kind === "county" && /^\d{5}$/.test(id) ? id : null;
  return { raw: text, canonical: `${kind}:${id}`, kind, id, stateFips, countyFips };
}

/**
 * How `a` and `b` sit relative to each other:
 *   'same' | 'a-contains-b' | 'b-contains-a' | 'unrelated' | 'unknown'
 *
 * 🔴 'unknown' IS NOT 'unrelated', AND COLLAPSING THE TWO IS THE DANGEROUS DIRECTION.
 *    `geofence_child_county` leaves `county_geo_id` NULL for children it could not place, and
 *    the matview can lag its source — that is why `check:child-county` exists. Answering
 *    "unrelated" for a city we cannot locate converts "I do not know" into "you are clear",
 *    which is precisely how a broken detector reads as a clean result.
 */
export function relate(a, b, childCounty) {
  if (a.canonical === b.canonical) return "same";
  if (a.kind === "other" || b.kind === "other") return "unrelated";

  const contains = (outer, inner) => {
    if (outer.kind === inner.kind) return false;            // no self-nesting between peers
    if (outer.kind === "state") {
      // A prefix is knowledge, not a lookup: nothing beginning 06 sits in a 13 state.
      return !!outer.stateFips && outer.stateFips === inner.stateFips;
    }
    if (outer.kind === "county" && inner.kind === "place") {
      if (outer.stateFips && inner.stateFips && outer.stateFips !== inner.stateFips) return false;
      const county = childCounty?.get(inner.id) ?? null;
      return county === null ? null : county === outer.countyFips;   // null == cannot tell
    }
    return false;                                            // place ⊃ county/state is not a thing
  };

  const ab = contains(a, b);
  if (ab === true) return "a-contains-b";
  const ba = contains(b, a);
  if (ba === true) return "b-contains-a";
  if (ab === null || ba === null) return "unknown";
  return "unrelated";
}

/**
 * Live claims that touch `scope`, each tagged with how. Anything genuinely unrelated is
 * dropped; `same` is kept, because the caller needs the exact holder's name to report it or
 * to take the lease over.
 *
 * @param {object} scope             from parseScope()
 * @param {Array<{scope:string}>} liveClaims  rows from steward.claims, released/expired already excluded
 * @param {Map<string,string>} childCounty    place geo_id -> county geo_id
 */
export function containmentWarnings(scope, liveClaims, childCounty) {
  const out = [];
  for (const claim of liveClaims ?? []) {
    let other;
    try {
      other = parseScope(claim.scope);
    } catch {
      continue;                       // a scope already in the table that this parser cannot read
    }
    const relation = relate(scope, other, childCounty);
    if (relation === "unrelated") continue;
    out.push({ claim, scope: other, relation });
  }
  return out;
}

/**
 * Pick the first candidate scope nobody holds — `--if-held skip`.
 *
 * 🔴 ONLY AN EXACT LIVE CLAIM BLOCKS A CANDIDATE. Treating containment as blocking would let
 *    one `state:CA` claim starve a queue of all 88 LA cities, and the caller would then report
 *    "nothing to do" — a workaround sized in units of a bug, and indistinguishable from an
 *    empty work list. Hierarchical overlap travels out as a warning on whatever gets picked.
 *
 * Returns {scope, warnings, skipped, reason}. `scope` is null when every candidate is held;
 * `skipped` always names what was passed over, so a silent cap cannot read as coverage.
 */
export function chooseScope(candidates, liveClaims, childCounty) {
  const skipped = [];
  for (const raw of candidates ?? []) {
    const scope = parseScope(raw);
    const warnings = containmentWarnings(scope, liveClaims, childCounty);
    const held = warnings.find((w) => w.relation === "same");
    if (held) {
      skipped.push({ scope, heldBy: held.claim });
      continue;
    }
    return { scope, warnings, skipped, reason: null };
  }
  return { scope: null, warnings: [], skipped, reason: SKIP_BLOCKED };
}
