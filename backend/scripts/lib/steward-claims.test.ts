import { describe, it, expect } from 'vitest';
import { parseScope, relate, containmentWarnings, chooseScope, SKIP_BLOCKED } from './steward-claims.mjs';

// The whole point of the claims table is that concurrent sessions can SEE each other. Its
// exclusion constraint only catches EXACT scope collisions, and the design says so out loud:
// `county:06037` and `place:0642468` overlap in reality — Lomita sits inside Los Angeles County
// — but the strings differ, so the database will not stop you. That gap is what this module
// closes, as a WARNING rather than a constraint.
//
// 🔴 THE LA COUNTY AUDIT IS THE WORKED EXAMPLE. It covered 88 cities plus the county. Anyone
//    taking one of those cities while that audit ran would have been told nothing by the
//    database.

const claim = (scope: string, holder = 'other@empowered.vote') =>
  ({ scope, holder, machine: 'box', label: null, expires_at: new Date('2099-01-01') });

// Lomita is place 0642468 in county 06037 (Los Angeles); 0644000 is Los Angeles city.
const CHILD_COUNTY = new Map([['0642468', '06037'], ['0644000', '06037']]);

describe('parseScope', () => {
  it('reads the three jurisdiction kinds', () => {
    expect(parseScope('place:0642468').kind).toBe('place');
    expect(parseScope('county:06037').kind).toBe('county');
    expect(parseScope('state:CA').kind).toBe('state');
  });

  it('canonicalises case so state:CA and state:ca are one scope', () => {
    expect(parseScope('state:CA').canonical).toBe(parseScope('state:ca').canonical);
  });

  it('derives the state FIPS from the identifier itself, not from a lookup', () => {
    expect(parseScope('place:0642468').stateFips).toBe('06');
    expect(parseScope('county:06037').stateFips).toBe('06');
    expect(parseScope('state:CA').stateFips).toBe('06');
  });

  // Free-form scopes are deliberate: the schema comment reserves `worktree:<path>` for the
  // design's rollout step 6. They must parse, and must not pretend to geographic knowledge.
  it('accepts an unknown scope kind without inventing geography for it', () => {
    const s = parseScope('worktree:/c/ev-accounts-knight');
    expect(s.kind).toBe('other');
    expect(s.stateFips).toBeNull();
  });

  it('refuses a scope with no kind at all, rather than guessing one', () => {
    expect(() => parseScope('0642468')).toThrow(/kind/i);
    expect(() => parseScope('')).toThrow();
  });
});

describe('relate', () => {
  it('calls an identical scope the same scope', () => {
    expect(relate(parseScope('place:0642468'), parseScope('place:0642468'), CHILD_COUNTY)).toBe('same');
  });

  it('sees a state containing a county and a place inside it', () => {
    expect(relate(parseScope('state:CA'), parseScope('county:06037'), CHILD_COUNTY)).toBe('a-contains-b');
    expect(relate(parseScope('state:CA'), parseScope('place:0642468'), CHILD_COUNTY)).toBe('a-contains-b');
  });

  it('sees containment from the inside out too', () => {
    expect(relate(parseScope('place:0642468'), parseScope('state:CA'), CHILD_COUNTY)).toBe('b-contains-a');
  });

  it('puts Lomita inside Los Angeles County, which is the case the constraint misses', () => {
    expect(relate(parseScope('county:06037'), parseScope('place:0642468'), CHILD_COUNTY)).toBe('a-contains-b');
  });

  it('keeps different states apart', () => {
    expect(relate(parseScope('state:CA'), parseScope('county:13089'), CHILD_COUNTY)).toBe('unrelated');
  });

  it('keeps two places in one county apart — neither contains the other', () => {
    expect(relate(parseScope('place:0642468'), parseScope('place:0644000'), CHILD_COUNTY)).toBe('unrelated');
  });

  // 🔴 A MISSING MAPPING IS NOT AN ABSENCE OF OVERLAP. geofence_child_county leaves
  //    county_geo_id NULL for children it could not place, and `check:child-county` exists
  //    because the matview goes stale behind its source. Reporting "unrelated" for a place we
  //    cannot locate would turn "I do not know" into "you are clear" — the same inversion as a
  //    uniform answer from a broken detector.
  it('says unknown, never unrelated, when the place is not in the county mapping', () => {
    expect(relate(parseScope('county:06037'), parseScope('place:0699999'), CHILD_COUNTY)).toBe('unknown');
    expect(relate(parseScope('county:06037'), parseScope('place:0642468'), new Map())).toBe('unknown');
  });

  // The FIPS prefix is knowledge the mapping cannot take away: a 06 place is not in a 13 county
  // whatever the matview says, so this is a real answer rather than a shrug.
  it('still separates a place from a county in another state with no mapping at all', () => {
    expect(relate(parseScope('county:13089'), parseScope('place:0642468'), new Map())).toBe('unrelated');
  });

  it('reasons about nothing when either side is a non-jurisdiction scope', () => {
    expect(relate(parseScope('worktree:/c/x'), parseScope('state:CA'), CHILD_COUNTY)).toBe('unrelated');
  });
});

describe('containmentWarnings', () => {
  it('is silent when nothing overlaps', () => {
    expect(containmentWarnings(parseScope('place:0642468'), [claim('state:GA')], CHILD_COUNTY)).toEqual([]);
  });

  it('reports the exact holder, so a takeover can name who is being taken over', () => {
    const w = containmentWarnings(parseScope('place:0642468'), [claim('place:0642468')], CHILD_COUNTY);
    expect(w).toHaveLength(1);
    expect(w[0].relation).toBe('same');
    expect(w[0].claim.holder).toBe('other@empowered.vote');
  });

  it('reports the county claim that swallows the city being claimed', () => {
    const w = containmentWarnings(parseScope('place:0642468'), [claim('county:06037')], CHILD_COUNTY);
    expect(w.map((x) => x.relation)).toEqual(['b-contains-a']);
  });

  it('reports the cities already claimed inside a county being claimed', () => {
    const w = containmentWarnings(parseScope('county:06037'),
      [claim('place:0642468'), claim('place:0644000'), claim('place:1304000')], CHILD_COUNTY);
    expect(w).toHaveLength(2);
  });

  it('surfaces an unknown mapping rather than dropping it', () => {
    const w = containmentWarnings(parseScope('county:06037'), [claim('place:0642468')], new Map());
    expect(w.map((x) => x.relation)).toEqual(['unknown']);
  });
});

describe('chooseScope', () => {
  // `--if-held skip` is what turns "do not run the laptop while I am working" into "the laptop
  // works around me automatically". The candidate list comes from the CALLER, per the design's
  // open decision — there is no jurisdiction work queue to pick from.
  it('takes the first candidate nobody holds', () => {
    const got = chooseScope(['place:0642468', 'place:0644000'], [claim('place:0642468')], CHILD_COUNTY);
    expect(got.scope.canonical).toBe('place:0644000');
  });

  it('reports what it skipped, so a silent cap cannot look like coverage', () => {
    const got = chooseScope(['place:0642468', 'place:0644000'], [claim('place:0642468')], CHILD_COUNTY);
    expect(got.skipped.map((s) => s.scope.canonical)).toEqual(['place:0642468']);
  });

  // 🔴 A CONTAINING CLAIM MUST NOT BLOCK EVERY CANDIDATE INSIDE IT. One `state:CA` claim would
  //    otherwise starve the laptop of all 88 LA cities and it would report "nothing to do" — a
  //    workaround sized in units of a bug. Only an EXACT live claim blocks; a hierarchical
  //    overlap is carried out as a warning on whatever gets picked.
  it('is blocked only by an exact claim, and still warns about the container it picked inside', () => {
    const got = chooseScope(['place:0642468'], [claim('county:06037')], CHILD_COUNTY);
    expect(got.scope.canonical).toBe('place:0642468');
    expect(got.warnings.map((w) => w.relation)).toEqual(['b-contains-a']);
  });

  it('returns nothing to do when every candidate is held, rather than picking one anyway', () => {
    const got = chooseScope(['place:0642468'], [claim('place:0642468')], CHILD_COUNTY);
    expect(got.scope).toBeNull();
    expect(got.reason).toBe(SKIP_BLOCKED);
    expect(got.skipped).toHaveLength(1);
  });
});
