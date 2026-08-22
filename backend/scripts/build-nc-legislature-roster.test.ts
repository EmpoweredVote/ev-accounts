import { describe, it, expect } from 'vitest';
import {
  pickSittingMember,
  parseNcgaDate,
  namesMatch,
  firstLastTokens,
  decodeHtmlEntities,
  normalizeNameForMatch,
} from './build-nc-legislature-roster.mjs';

describe('parseNcgaDate', () => {
  it('converts NCGA M/D/YY to ISO', () => {
    expect(parseNcgaDate('1/29/25')).toBe('2025-01-29');
    expect(parseNcgaDate('11/18/25')).toBe('2025-11-18');
    expect(parseNcgaDate('6/23/26')).toBe('2026-06-23');
  });
});

describe('pickSittingMember', () => {
  it('returns the only row when a district is uncontested', () => {
    const rows = [{ name: 'Jay Adams', appointedOn: null, resignedOn: null }];
    expect(pickSittingMember('96', rows).name).toBe('Jay Adams');
  });

  // HD-47: BOTH rows annotated — the easy shape.
  it('prefers the appointed successor over an annotated resignation', () => {
    const rows = [
      { name: 'Jarrod Lowery', appointedOn: null, resignedOn: '2025-10-07' },
      { name: 'John L. Lowery', appointedOn: '2025-10-13', resignedOn: null },
    ];
    expect(pickSittingMember('47', rows).name).toBe('John L. Lowery');
  });

  // HD-40: the DEPARTED member carries NO annotation. Filtering on "Resigned"
  // alone keeps both rows and seats two people in one seat.
  it('prefers the appointed successor when the predecessor is UNANNOTATED', () => {
    const rows = [
      { name: 'Joe John', appointedOn: null, resignedOn: null },
      { name: 'Phil Rubin', appointedOn: '2025-01-29', resignedOn: null },
    ];
    expect(pickSittingMember('40', rows).name).toBe('Phil Rubin');
  });

  // HD-119: same unannotated shape, different district.
  it('handles the second unannotated-predecessor district', () => {
    const rows = [
      { name: 'Mike Clampitt', appointedOn: null, resignedOn: null },
      { name: 'Anna Ferguson', appointedOn: '2026-04-16', resignedOn: null },
    ];
    expect(pickSittingMember('119', rows).name).toBe('Anna Ferguson');
  });

  // HD-90: the appointee is listed FIRST, so source order proves nothing.
  it('ignores source ordering', () => {
    const rows = [
      { name: 'Dan Kiger', appointedOn: '2026-06-23', resignedOn: null },
      { name: 'Sarah Stevens', appointedOn: null, resignedOn: '2026-06-16' },
    ];
    expect(pickSittingMember('90', rows).name).toBe('Dan Kiger');
  });

  it('takes the LATEST appointment when a seat turned over twice', () => {
    const rows = [
      { name: 'First Appointee', appointedOn: '2025-03-01', resignedOn: '2025-09-01' },
      { name: 'Second Appointee', appointedOn: '2025-09-15', resignedOn: null },
    ];
    expect(pickSittingMember('99', rows).name).toBe('Second Appointee');
  });

  // Failing loudly is the point: a shape we have not seen must not be guessed.
  it('throws when a contested district has no appointment date to arbitrate on', () => {
    const rows = [
      { name: 'Person A', appointedOn: null, resignedOn: null },
      { name: 'Person B', appointedOn: null, resignedOn: null },
    ];
    expect(() => pickSittingMember('7', rows)).toThrow(/district 7/i);
  });

  // essentials.office_terms.how_started has a CHECK constraint; a contested
  // district's survivor reached the seat by appointment, not election, and the
  // later migration must not silently assert 'elected' for these 8 people.
  it('marks the appointed successor of a contested district with howStarted appointed', () => {
    const rows = [
      { name: 'Jarrod Lowery', appointedOn: null, resignedOn: '2025-10-07' },
      { name: 'John L. Lowery', appointedOn: '2025-10-13', resignedOn: null },
    ];
    expect(pickSittingMember('47', rows).howStarted).toBe('appointed');
  });

  it('marks an uncontested member with howStarted elected', () => {
    const rows = [{ name: 'Jay Adams', appointedOn: null, resignedOn: null }];
    expect(pickSittingMember('96', rows).howStarted).toBe('elected');
  });
});


// -----------------------------------------------------------------------------
// Name normalization / matching — these are the pure functions that produced
// most of the real bugs this script hit against live data (HTML entities,
// credential suffixes, quoted nicknames, parenthetical Ballotpedia
// disambiguators). Every fixture below is a REAL name measured 2026-08-22,
// not an invented example.
// -----------------------------------------------------------------------------

describe('decodeHtmlEntities', () => {
  it('decodes numeric hex entities ncleg.gov actually renders in names', () => {
    // ncleg's own House list literally contains "Erin Par&#xE9;" — the raw,
    // un-decoded HTML entity — in place of "Erin Paré".
    expect(decodeHtmlEntities('Erin Par&#xE9;')).toBe('Erin Paré');
    expect(decodeHtmlEntities('Ren&#xE9;e A. Price')).toBe('Renée A. Price');
  });

  it('decodes &quot; — ncleg renders a quoted preferred name literally', () => {
    // Jerry "Alan" Branson goes by his middle name; ncleg's list shows this
    // as `Jerry &quot;Alan&quot; Branson`.
    expect(decodeHtmlEntities('Jerry &quot;Alan&quot; Branson')).toBe('Jerry "Alan" Branson');
  });
});

describe('normalizeNameForMatch', () => {
  // 🔴 Standing rule: NFD combining marks must be DELETED, not replaced with a
  // space. Pinned here so a future "fix" (e.g. `.replace(/[̀-ͯ]/g, ' ')`
  // instead of `''`) fails loudly instead of silently splitting names like
  // "Paré" into "par e".
  it('deletes NFD combining marks rather than spacing them', () => {
    expect(normalizeNameForMatch('Paré')).toBe('pare');
    expect(normalizeNameForMatch('Paré')).not.toContain(' ');
    expect(normalizeNameForMatch('Renée')).toBe('renee');
  });
});

describe('firstLastTokens', () => {
  it('strips a professional credential suffix (measured: Timothy Reeder, MD)', () => {
    expect(firstLastTokens('Timothy Reeder, MD')).toEqual({ first: 'timothy', last: 'reeder' });
  });

  it('strips a generational suffix AND a middle initial together (measured: David W. Craven, Jr.)', () => {
    expect(firstLastTokens('David W. Craven, Jr.')).toEqual({ first: 'david', last: 'craven' });
  });

  it('strips quotes around a preferred name but keeps the LEGAL first name (measured: Jerry "Alan" Branson)', () => {
    // firstLastTokens has no concept of "goes by a middle name" — it reduces
    // to the legal first token, "jerry", not the preferred "alan". That gap
    // is exactly why the roster builder relies on the ncleg.gov member id,
    // not name matching, to confirm this person's identity.
    expect(firstLastTokens('Jerry "Alan" Branson')).toEqual({ first: 'jerry', last: 'branson' });
  });

  it('strips a middle initial (measured: Edward C. Goodwin)', () => {
    expect(firstLastTokens('Edward C. Goodwin')).toEqual({ first: 'edward', last: 'goodwin' });
    expect(firstLastTokens('Ed Goodwin')).toEqual({ first: 'ed', last: 'goodwin' });
  });
});

describe('namesMatch', () => {
  it('matches through a middle initial difference (measured: John L. Lowery vs John Lowery)', () => {
    expect(namesMatch('John L. Lowery', 'John Lowery')).toBe(true);
  });

  it('matches through a credential suffix (measured: Timothy Reeder, MD)', () => {
    expect(namesMatch('Timothy Reeder, MD', 'Timothy Reeder')).toBe(true);
  });

  it('matches through a generational suffix (measured: David W. Craven, Jr.)', () => {
    expect(namesMatch('David W. Craven, Jr.', 'David Craven')).toBe(true);
  });

  it('matches an HTML-entity-decoded name against its plain form (measured: Erin Paré)', () => {
    expect(namesMatch(decodeHtmlEntities('Erin Par&#xE9;'), 'Erin Paré')).toBe(true);
  });

  // These four are the real, unresolved boundary: genuine nicknames and a
  // quoted preferred name that firstLastTokens cannot and should not paper
  // over. The roster builder accepts these ONLY via the independently-cited
  // ncleg.gov member id (see buildRoster), never via namesMatch — pinning
  // namesMatch itself as false here documents that the two mechanisms are
  // deliberately separate, not that these are unresolved bugs.
  it('does NOT match a nickname against the legal first name (measured: Edward C. Goodwin vs Ed Goodwin)', () => {
    expect(namesMatch('Edward C. Goodwin', 'Ed Goodwin')).toBe(false);
  });

  it('does NOT match a preferred middle name against the legal first name (measured: Jerry "Alan" Branson vs Alan Branson)', () => {
    expect(namesMatch('Jerry "Alan" Branson', 'Alan Branson')).toBe(false);
  });

  // Negative case: two genuinely DIFFERENT people (HD-47's predecessor and
  // successor) must never be reported as the same person merely because they
  // share a last name and a similar-looking first name.
  it('does NOT match two different people who share a last name (measured: Jarrod Lowery vs John L. Lowery)', () => {
    expect(namesMatch('Jarrod Lowery', 'John L. Lowery')).toBe(false);
  });
});
