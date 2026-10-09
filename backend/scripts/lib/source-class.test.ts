import { describe, expect, it } from 'vitest';
// @ts-expect-error -- plain .mjs helper shared with the detector scripts
import { sourceClass, sourceClassSql, GENERIC_PATTERNS, CANDIDATE_PAGE_PATTERNS } from './source-class.mjs';

describe('sourceClass', () => {
  it('treats a Ballotpedia page deep-linked to the survey section as the candidate speaking', () => {
    expect(sourceClass('https://ballotpedia.org/Mikel_Wein#Campaign_themes')).toBe('candidate-page');
    expect(sourceClass('https://BALLOTPEDIA.ORG/Mikel_Wein#campaign_themes')).toBe('candidate-page');
  });

  it('still refuses a BARE Ballotpedia page — the anchor is the whole difference', () => {
    expect(sourceClass('https://ballotpedia.org/Mikel_Wein')).toBe('generic');
  });

  it('treats a BallotReady profile as the candidate speaking: it has an Issue Stances section', () => {
    expect(sourceClass('https://www.ballotready.org/people/aisha-farooqi')).toBe('candidate-page');
  });

  it('keeps legislature member pages and encyclopedia biographies generic', () => {
    expect(sourceClass('https://en.wikipedia.org/wiki/Richard_Ojeda')).toBe('generic');
    expect(sourceClass('https://capitol.texas.gov/members/memberinfo.aspx?id=1')).toBe('generic');
    expect(sourceClass('https://www.congress.gov/member/cori-bush/B001224')).toBe('generic');
  });

  it('leaves a bill, a roll call or a news article alone', () => {
    expect(sourceClass('https://www.govtrack.us/congress/bills/118/hr1708')).toBe('specific');
    expect(sourceClass('https://www.govtrack.us/congress/votes/118-2024/h151')).toBe('specific');
    expect(sourceClass('https://wyoleg.gov/2025/Introduced/SF0190.pdf')).toBe('specific');
  });

  // The two classifiers must not drift: the SQL is what the detectors run, the JS is what
  // anything holding a URL runs, and a correction applied to one only is the bug this file exists
  // to prevent.
  it('names every pattern it classifies in the SQL it emits', () => {
    const sql = sourceClassSql('nu');
    for (const p of [...GENERIC_PATTERNS, ...CANDIDATE_PAGE_PATTERNS]) {
      expect(sql).toContain(p);
    }
    expect(sql).toContain('#Campaign_themes');
    // candidate-page must be decided BEFORE the bare-Ballotpedia fallback, or every deep link
    // would fall through to 'generic' and the correction would be inert.
    expect(sql.indexOf("'candidate-page'")).toBeLessThan(sql.indexOf("'generic'"));
  });
});
