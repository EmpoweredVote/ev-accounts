import { describe, expect, it } from 'vitest';
// @ts-expect-error -- .mjs generator, no types
import { parseRosters } from './gen-palm-beach-migrations.mjs';

/**
 * ⚠ ONE table, not two. FL-4's fixture has "### City of Tallahassee" and
 * "### Leon County"; Palm Beach County has no city half, so the COUNTS comment
 * carries no city_* keys either.
 *
 * 🔴 THE FIXTURE IS THE FULL TWELVE ROWS, AND IT HAS TO BE. parseRosters()
 * asserts the 7 + 5 SHAPE unconditionally -- a commission seat mapped countywide
 * would still total twelve and would put that commissioner on every Palm Beach
 * address -- so it refuses any subset. A six-row fixture was tried first and was
 * correctly rejected; see the "refuses an incomplete roster" case below.
 */
const FIXTURE = `
### Palm Beach County

| Seat | Slug | Name | external_id | term_start | precision | how_started | source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Commissioner, District 1 | commissioner-1 | Maria G. Marino | -1240061 | 2020-11-01 | month | elected | s |
| Commissioner, District 2 | commissioner-2 | Gregg K. Weiss | -1240062 | 2018-11-01 | month | elected | s |
| Commissioner, District 3 | commissioner-3 | Joel G. Flores | -1240063 | 2024-11-01 | month | elected | s |
| Commissioner, District 4 | commissioner-4 | Marci Woodward | -1240064 | 2022-11-01 | month | elected | s |
| Commissioner, District 5 | commissioner-5 | Maria Sachs | -1240065 | 2020-11-01 | month | elected | s |
| Commissioner, District 6 | commissioner-6 | Sara Baxter | -1240066 | 2022-11-01 | month | elected | s |
| Commissioner, District 7 | commissioner-7 | Bobby Powell Jr. | -1240067 | 2024-11-01 | month | elected | s |
| Clerk of the Circuit Court & Comptroller | clerk-of-circuit-court | Shannon Ramsey-Chessman | -1240071 | 2026-08-18 | day | appointed | s |
| Property Appraiser | property-appraiser | Dorothy Jacks | -1240072 | 2017-01-01 | month | elected | s |
| Sheriff | sheriff | Ric L. Bradshaw | -1240073 | 2005-01-04 | day | elected | s |
| Supervisor of Elections | supervisor-of-elections | Wendy Sartory Link | -1240074 | 2019-01-01 | year | appointed | s |
| Tax Collector | tax-collector | Anne M. Gannon | -1240075 | 2007-01-01 | month | elected | s |

<!-- COUNTS: county_offices=12 county_people=12 vacancies=0 -->
`;

describe('parseRosters', () => {
  it('reads the one table and the declared counts, with no city key', () => {
    const r = parseRosters(FIXTURE);
    expect(r.county).toHaveLength(12);
    expect(r.counts).toEqual({ countyOffices: 12, countyPeople: 12, vacancies: 0 });
    // ⚠ FL-4 returned a `city` array. This wave must not.
    expect((r as Record<string, unknown>).city).toBeUndefined();
  });

  it('carries how_started and precision through instead of defaulting them', () => {
    const d2 = parseRosters(FIXTURE).county.find((s: any) => s.slug === 'commissioner-2');
    expect(d2.howStarted).toBe('elected');
    expect(d2.precision).toBe('month');
    expect(d2.termStart).toBe('2018-11-01');
  });

  it('splits an uncomma’d suffix — "Bobby Powell Jr." is Bobby / Powell / Jr.', () => {
    const d7 = parseRosters(FIXTURE).county.find((s: any) => s.slug === 'commissioner-7');
    expect(d7.firstName).toBe('Bobby');
    expect(d7.lastName).toBe('Powell');
    expect(d7.nameSuffix).toMatch(/^Jr/);
  });

  it('keeps the middle initial off the last name — "Ric L. Bradshaw"', () => {
    const s = parseRosters(FIXTURE).county.find((x: any) => x.slug === 'sheriff');
    expect(s.firstName).toBe('Ric');
    expect(s.lastName).toBe('Bradshaw');
    expect(s.middleInitial).toBe('L');
  });

  // 🔴 Palm Beach has NO at-large commissioner. Every commission seat must hang
  //    off an X0039 district; only the five officers may be countywide.
  it('puts all seven commission seats on commdist and only the officers countywide', () => {
    const { county } = parseRosters(FIXTURE);
    const comm = county.filter((s: any) => s.chamber === 'Board of County Commissioners');
    expect(comm).toHaveLength(7);
    expect(comm.every((s: any) => s.on === 'commdist')).toBe(true);
    expect(comm.map((s: any) => s.n).sort((a: number, b: number) => a - b)).toEqual([1, 2, 3, 4, 5, 6, 7]);
    const off = county.filter((s: any) => s.chamber === 'Elected Officials');
    expect(off).toHaveLength(5);
    expect(off.every((s: any) => s.on === 'countywide')).toBe(true);
  });

  // 🔴 Leon's sixth officer, and two circuit offices the county's own page
  //    miscategorises, must not survive a copy-paste.
  it('has no Superintendent of Schools, State Attorney or Public Defender', () => {
    const titles = parseRosters(FIXTURE).county.map((s: any) => s.title);
    for (const t of ['Superintendent of Schools', 'State Attorney', 'Public Defender']) {
      expect(titles).not.toContain(t);
    }
    expect(titles).toContain('Clerk of the Circuit Court & Comptroller');
  });

  // 🔴 First Florida wave to write an appointment. FL-2/3/4 were all 'elected'.
  it('carries how_started = appointed through for the two appointed officers', () => {
    const { county } = parseRosters(FIXTURE);
    const appointed = county.filter((s: any) => s.howStarted === 'appointed').map((s: any) => s.slug);
    expect(appointed.sort()).toEqual(['clerk-of-circuit-court', 'supervisor-of-elections']);
  });

  // 🔴 Zero unknown precisions, and the histogram the migration's gates assert.
  it('has no unknown-precision row and the measured histogram', () => {
    const { county } = parseRosters(FIXTURE);
    const hist: Record<string, number> = {};
    for (const r of county) hist[r.precision] = (hist[r.precision] ?? 0) + 1;
    expect(hist).toEqual({ day: 2, month: 9, year: 1 });
    expect(county.every((r: any) => r.termStart !== '')).toBe(true);
  });

  it('attaches the Clerk description and nothing else', () => {
    const { county } = parseRosters(FIXTURE);
    const withDesc = county.filter((s: any) => s.description);
    expect(withDesc.map((s: any) => s.slug)).toEqual(['clerk-of-circuit-court']);
    expect(withDesc[0].description).toMatch(/suspended, not removed/i);
  });

  it('attaches aliases without inventing them', () => {
    const { county } = parseRosters(FIXTURE);
    const byslug = Object.fromEntries(county.map((s: any) => [s.slug, s.aliases]));
    expect(byslug['sheriff']).toEqual(['Ric Bradshaw']);
    expect(byslug['commissioner-6']).toEqual(['Sara Marie Baxter']);
    // Publisher and ballot name agree for these three — no alternate invented.
    expect(byslug['clerk-of-circuit-court']).toEqual([]);
    expect(byslug['property-appraiser']).toEqual([]);
    expect(byslug['commissioner-5']).toEqual([]);
  });

  describe('refusals', () => {
    // 🔴 A SUBSET IS NOT A VALID ROSTER. The 7 + 5 shape is asserted
    //    unconditionally, so an incomplete file is refused rather than generating
    //    a migration that would seat fewer offices than the county has.
    it('refuses an incomplete roster, even with a matching COUNTS comment', () => {
      const NL = String.fromCharCode(10);
      const subset = FIXTURE.split(NL)
        .filter((l) => !/commissioner-[1467]|property-appraiser|tax-collector/.test(l))
        .join(NL)
        .replace('county_offices=12 county_people=12', 'county_offices=6 county_people=6');
      expect(() => parseRosters(subset)).toThrow(/expected 7 commission seats, got 3/);
      expect(() => parseRosters(subset)).toThrow(/expected 5 constitutional officers, got 3/);
    });

    it('refuses a file with no COUNTS comment', () => {
      expect(() => parseRosters(FIXTURE.replace(/<!-- COUNTS:[^>]*-->/, ''))).toThrow(/COUNTS comment/);
    });

    it('refuses a COUNTS comment that disagrees with the table', () => {
      expect(() => parseRosters(FIXTURE.replace('county_offices=12', 'county_offices=13')))
        .toThrow(/COUNTS: table has 12 rows/);
    });

    // 🔴 The failure this shape exists to catch: a commissioner mapped countywide
    //    still totals 12 and would appear for every address in the county.
    it('refuses a commission seat that is not on a commdist', () => {
      // commissioner-6 is a DISTRICT seat here; Leon's equivalent slug was at-large.
      const bad = FIXTURE.replace(
        '| Commissioner, District 6 | commissioner-6 |',
        '| Commissioner, At Large Group 1 | at-large-group-1 |',
      );
      expect(() => parseRosters(bad)).toThrow(/unrecognised slug "at-large-group-1"/);
    });

    it('refuses a party marking left in a name, including (DEM) and (WRI)', () => {
      for (const tag of ['(DEM)', '(REP)', '(WRI)', '(NPA)']) {
        const bad = FIXTURE.replace('Maria G. Marino', `Maria G. Marino ${tag}`);
        expect(() => parseRosters(bad)).toThrow(/party marking left in the name/);
      }
    });

    it('refuses an external_id outside this wave’s own sub-range', () => {
      // -1240031 is legitimately FL-4's. It is in the band but not this wave's.
      const bad = FIXTURE.replace('-1240061', '-1240031');
      expect(() => parseRosters(bad)).toThrow(/outside THIS WAVE's sub-range/);
    });

    it('refuses a missing term_start that does not declare unknown', () => {
      const bad = FIXTURE.replace('| 2017-01-01 | month |', '|  | month |');
      expect(() => parseRosters(bad)).toThrow(/no term_start but precision is "month"/);
    });

    it('refuses a how_started the CHECK would reject', () => {
      const bad = FIXTURE.replace('| year | appointed |', '| year | anointed |');
      expect(() => parseRosters(bad)).toThrow(/how_started "anointed"/);
    });

    it('refuses a duplicate external_id', () => {
      const bad = FIXTURE.replace('-1240062', '-1240061');
      expect(() => parseRosters(bad)).toThrow(/duplicate external_id/);
    });
  });
});
