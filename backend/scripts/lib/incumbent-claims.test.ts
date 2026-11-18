import { describe, it, expect } from 'vitest';
import { checkCitation, verifyClaim, spellingsFor, DEFEAT_CLAIM } from './incumbent-claims.mjs';

// Every fixture below is a real shape read out of production on 2026-11-18, not an invented one.
// 30 citations mention an incumbent; 6 are the claim this gate checks and 20 are the MIRROR
// grammar, where the incumbent won. Both families are represented here, because a predicate that
// cannot tell them apart inverts the meaning of twenty true sentences.

const ca04 = {
  winner: { full_name: 'Eric Jones', first_name: 'Eric', last_name: 'Jones', result: 'won' },
  loser: { full_name: 'Mike Thompson', first_name: 'Mike', last_name: 'Thompson', result: 'lost' },
};
const CA04_ROWS = [ca04.winner, ca04.loser];
const CA04_LOSERS = [ca04.loser];

// ME-02 as CC_0447 left it: LePage won, Dunlap lost, and Jared Golden -- the seat's incumbent --
// holds no row at all, because he was not a candidate.
const ME02_ROWS = [
  { full_name: 'Paul LePage', first_name: 'Paul', last_name: 'LePage', result: 'won' },
  { full_name: 'Matthew Dunlap', first_name: 'Matthew', last_name: 'Dunlap', result: 'lost' },
  { full_name: 'Gregory A. Ward', first_name: 'Gregory', last_name: 'Ward', result: 'lost' },
];
const ME02_LOSERS = ME02_ROWS.filter((r) => r.result === 'lost');

describe('the claim this gate checks, and the mirror grammar it must not touch', () => {
  it('🔴 fires on the sentence that shipped: ME-02 named an incumbent who was not a candidate', () => {
    const row = {
      result: 'won',
      result_source:
        'AP called the race at 2026-11-12T18:31:29.417Z, defeating incumbent Jared Golden.',
    };
    const { claimsFound, violations } = checkCitation(row, ME02_LOSERS, ME02_ROWS);
    expect(claimsFound).toBe(1);
    expect(violations).toHaveLength(1);
    expect(violations[0].rule).toBe('defeated-incumbent-must-have-lost');
    expect(violations[0].unmatched).toContain('Jared Golden');
  });

  it('passes the true neighbour that shipped beside it', () => {
    const row = {
      result: 'won',
      result_source: 'AP called it at 2026-11-17T01:54:47.131Z, defeating incumbent Mike Thompson.',
    };
    expect(checkCitation(row, CA04_LOSERS, CA04_ROWS)).toMatchObject({
      claimsFound: 1, violations: [],
    });
  });

  it('🔴 leaves the MIRROR grammar alone — twenty real rows where the incumbent WON', () => {
    // Quoted Ballotpedia text on primary rows. Every one of these is true, and a predicate on
    // the two words alone would fail all of them.
    const quotes = [
      'Ballotpedia.org, Kansas\' 1st Congressional District election, 2026 — "Incumbent Tracey Mann defeated Craig Musser in the Republican primary for U.S. House."',
      '"Incumbent Wesley Bell defeated Cori Bush, Alissa Murphy, Carl Harris Sr. and Carl E. Henderson in the Democratic primary."',
      '"Incumbent Ann Wagner defeated Peter Pfeifer, Brandon Wilkinson, Matthew Grant, and Elizabeth Sparks-Holmes in the Republican primary for U.S. House."',
      '"Incumbent James Walkinshaw (D) defeated Arthur Purves (R) and Dianne Blais (G) in the general election."',
      '"Incumbent Steve Scalise (R) won election outright against Lauren Jewett (D), Randall Arrington (R), and Liddy Glass (Unaffiliated) in the primary."',
    ];
    for (const result_source of quotes) {
      // No losing rows supplied at all: if the regex matched, it could only fail.
      expect(checkCitation({ result_source, result: 'not_nominated' }, [], []))
        .toEqual({ claimsFound: 0, violations: [] });
    }
  });

  it('leaves the TX-22 twin-brother note alone — it names an incumbent who was not on the ballot', () => {
    const result_source =
      "AP distinguishes him (candidateID 170023) from the seat's incumbent Troy Nehls "
      + '(candidateID 68186), his twin brother, who was not on the ballot.';
    expect(checkCitation({ result_source, result: 'won' }, [], []))
      .toEqual({ claimsFound: 0, violations: [] });
  });
});

describe('the name is matched from the data, never parsed out of the prose', () => {
  it('🔴 survives an initial and a suffix, which a sentence-boundary capture does not', () => {
    // /defeating incumbent ([^.]+)\./ -- the obvious implementation, and the one CC_0452's own
    // post-verify used -- truncates these at "Dan S." and "Carl Harris Sr.".
    const rows = [
      { full_name: 'Dan S. Sullivan', first_name: 'Dan', last_name: 'Sullivan', result: 'lost' },
      { full_name: 'Carl Harris Sr.', first_name: 'Carl', last_name: 'Harris', result: 'lost' },
      { full_name: 'A Winner', first_name: 'A', last_name: 'Winner', result: 'won' },
    ];
    const losers = rows.filter((r) => r.result === 'lost');
    for (const name of ['Dan S. Sullivan', 'Carl Harris Sr.']) {
      expect(checkCitation(
        { result_source: `A Winner defeated incumbent ${name}. Called by AP.`, result: 'won' },
        losers, rows,
      )).toMatchObject({ claimsFound: 1, violations: [] });
    }
  });

  it('accepts the plural form the matcher now generates, and checks EVERY name in it', () => {
    const rows = [
      { full_name: 'The Winner', first_name: 'The', last_name: 'Winner', result: 'won' },
      { full_name: 'Alice Ames', first_name: 'Alice', last_name: 'Ames', result: 'lost' },
      { full_name: 'Bob Booth', first_name: 'Bob', last_name: 'Booth', result: 'lost' },
    ];
    const losers = rows.filter((r) => r.result === 'lost');
    expect(checkCitation(
      { result_source: 'The Winner defeated incumbents Alice Ames and Bob Booth.', result: 'won' },
      losers, rows,
    )).toMatchObject({ claimsFound: 1, violations: [] });

    // 🔴 The second name is checked too -- a gate that validated only the first would pass this.
    const bad = checkCitation(
      { result_source: 'The Winner defeated incumbents Alice Ames and Carol Nobody.', result: 'won' },
      losers, rows,
    );
    expect(bad.violations).toHaveLength(1);
    expect(bad.violations[0].unmatched).toContain('Carol Nobody');
  });

  it('says so when the claim names somebody in the race who did not lose', () => {
    const bad = checkCitation(
      { result_source: 'Somebody defeated incumbent Eric Jones.', result: 'won' },
      CA04_LOSERS, CA04_ROWS,
    );
    expect(bad.violations[0].why ?? bad.violations[0].detail)
      .toMatch(/did not lose it \(result: won\)/);
  });
});

describe('spellingsFor — a bare surname is admitted only where it is unambiguous', () => {
  it('admits the surname when one candidate carries it', () => {
    expect(spellingsFor(ca04.loser, CA04_ROWS)).toContain('Thompson');
  });

  it('🔴 REFUSES the surname when two candidates in the race share it', () => {
    // The namesake hazard, which this repo has shipped: a bare surname would let the wrong
    // person satisfy the gate. TX-22's winner is the incumbent's twin brother.
    const rows = [
      { full_name: 'Trever Nehls', first_name: 'Trever', last_name: 'Nehls', result: 'won' },
      { full_name: 'Troy Nehls', first_name: 'Troy', last_name: 'Nehls', result: 'lost' },
    ];
    expect(spellingsFor(rows[1], rows)).not.toContain('Nehls');
    expect(spellingsFor(rows[1], rows)).toContain('Troy Nehls');

    // And the gate therefore refuses a claim that names only the shared surname.
    const bad = checkCitation(
      { result_source: 'Trever Nehls defeated incumbent Nehls.', result: 'won' },
      [rows[1]], rows,
    );
    expect(bad.violations).toHaveLength(1);
  });

  it('tolerates the AP/our-rows spelling drift that has its own review file', () => {
    // AP writes "Tessa Hodge"; we store first "Tessa", last "Lynn Hodge".
    const rows = [
      { full_name: 'Jay Obernolte', first_name: 'Jay', last_name: 'Obernolte', result: 'won' },
      { full_name: 'Tessa Lynn Hodge', first_name: 'Tessa', last_name: 'Lynn Hodge', result: 'lost' },
    ];
    expect(checkCitation(
      { result_source: 'Jay Obernolte defeated incumbent Tessa Lynn Hodge.', result: 'won' },
      [rows[1]], rows,
    )).toMatchObject({ violations: [] });
  });
});

describe('the two self-describing rules', () => {
  it('fires when a row calls itself the defeated incumbent but did not lose', () => {
    const v = checkCitation(
      { result_source: 'AP: 52.53%, the defeated incumbent.', result: 'won' }, [], [],
    ).violations;
    expect(v).toHaveLength(1);
    expect(v[0].rule).toBe('self-described-defeated-incumbent-must-have-lost');
  });

  it('passes the two real rows that say it, which did lose', () => {
    for (const result_source of ['AP: 47.47%, the defeated incumbent.', '…47.89%, the defeated incumbent.']) {
      expect(checkCitation({ result_source, result: 'lost' }, [], []).violations).toEqual([]);
    }
  });

  it('fires when "Incumbent re-elected" sits on a row that did not win', () => {
    const v = checkCitation(
      { result_source: 'Incumbent re-elected: AP winner candidateID 35605 equals AP incumbent 35605.', result: 'lost' },
      [], [],
    ).violations;
    expect(v).toHaveLength(1);
    expect(v[0].rule).toBe('incumbent-re-elected-must-have-won');
  });

  it('passes the two real re-elected rows, which did win', () => {
    const result_source =
      'Incumbent re-elected: AP winner candidateID 67998 equals AP incumbent candidateID 67998, '
      + 'so the shared surname is the same person, not a namesake.';
    expect(checkCitation({ result_source, result: 'won' }, [], []).violations).toEqual([]);
  });
});

describe('what it examined, not only what it rejected', () => {
  it('reports zero claims found for a citation that makes none', () => {
    expect(checkCitation(
      { result_source: 'AP called the race; 61.2% with 98% of the expected vote in.', result: 'won' },
      CA04_LOSERS, CA04_ROWS,
    )).toEqual({ claimsFound: 0, violations: [] });
  });

  it('handles a null citation without throwing', () => {
    expect(checkCitation({ result_source: null, result: 'won' }, [], []))
      .toEqual({ claimsFound: 0, violations: [] });
  });

  it('the global regex does not carry lastIndex between citations', () => {
    // A /g regex reused across calls skips matches when lastIndex survives. Two identical
    // citations in a row must give the identical verdict.
    const row = { result_source: 'X defeated incumbent Mike Thompson.', result: 'won' };
    const a = checkCitation(row, CA04_LOSERS, CA04_ROWS);
    const b = checkCitation(row, CA04_LOSERS, CA04_ROWS);
    expect(a).toEqual(b);
    expect(a.claimsFound).toBe(1);
  });

  it('finds BOTH claims when one citation makes two', () => {
    DEFEAT_CLAIM.lastIndex = 0;
    const row = {
      result_source: 'X defeated incumbent Mike Thompson. Earlier, Y defeated incumbent Nobody Here.',
      result: 'won',
    };
    const out = checkCitation(row, CA04_LOSERS, CA04_ROWS);
    expect(out.claimsFound).toBe(2);
    expect(out.violations).toHaveLength(1);
  });
});
