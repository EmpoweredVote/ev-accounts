import { describe, expect, it } from 'vitest';
// @ts-expect-error -- .mjs generator, no types
import { parseRosters } from './gen-miami-dade-migrations.mjs';

/**
 * ⚠ TWO tables, unlike FL-5. Miami-Dade has a city half, so the COUNTS comment
 * carries city_* keys again — FL-4's shape, not FL-5's.
 *
 * 🔴 THE FIXTURE IS THE FULL 6 + 19 ROWS, AND IT HAS TO BE. parseRosters()
 * asserts the 5+1 / 13+1+5 SHAPE unconditionally — a commission seat mapped to a
 * wide district would still total correctly and would put that one person on
 * every address — so it refuses any subset.
 *
 * ⚠ The reused id is written **-1212402** with markdown emphasis, exactly as
 * ROSTERS.md carries it, so the parser's asterisk-stripping is exercised.
 */
const FIXTURE = `
### City of Miami

| Seat | Slug | Name | external_id | term_start | precision | how_started | source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Mayor | mia-mayor | Eileen Higgins | -1240081 | 2025-12-18 | day | elected | s |
| Commissioner, District 1 | mia-commissioner-1 | Miguel Angel Gabela | -1240082 | 2023-12-01 | month | elected | s |
| Commissioner, District 2 | mia-commissioner-2 | Damian Pardo | -1240083 | 2023-12-01 | month | elected | s |
| Commissioner, District 3 | mia-commissioner-3 | Rolando Escalona | -1240084 | 2025-12-17 | day | elected | s |
| Commissioner, District 4 | mia-commissioner-4 | Ralph "Rafael" Rosado | -1240085 | 2025-06-10 | day | elected | s |
| Commissioner, District 5 | mia-commissioner-5 | Christine King | -1240086 | 2021-11-10 | day | elected | s |

### Miami-Dade County

| Seat | Slug | Name | external_id | term_start | precision | how_started | source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Mayor | mdc-mayor | Daniella Levine Cava | -1240091 | 2020-11-17 | day | elected | s |
| Commissioner, District 1 | mdc-commissioner-1 | Oliver Gilbert | **-1212402** | 2020-11-17 | day | elected | s |
| Commissioner, District 2 | mdc-commissioner-2 | Marleine Bastien | -1240092 | 2022-11-22 | day | elected | s |
| Commissioner, District 3 | mdc-commissioner-3 | Keon Hardemon | -1240093 | 2020-11-17 | day | elected | s |
| Commissioner, District 4 | mdc-commissioner-4 | Micky Steinberg | -1240094 | 2022-11-22 | day | elected | s |
| Commissioner, District 5 | mdc-commissioner-5 | Vicki L. Lopez | -1240095 | 2025-11-19 | day | appointed | s |
| Commissioner, District 6 | mdc-commissioner-6 | Natalie Milian Orbis | -1240096 | 2025-05-06 | day | appointed | s |
| Commissioner, District 7 | mdc-commissioner-7 | Raquel A. Regalado | -1240097 | 2020-11-17 | day | elected | s |
| Commissioner, District 8 | mdc-commissioner-8 | Danielle Cohen Higgins | -1240098 | 2020-12-07 | day | appointed | s |
| Commissioner, District 9 | mdc-commissioner-9 | Kionne L. McGhee | -1240099 | 2020-11-17 | day | elected | s |
| Commissioner, District 10 | mdc-commissioner-10 | Anthony Rodriguez | -1240100 | 2022-11-22 | day | elected | s |
| Commissioner, District 11 | mdc-commissioner-11 | Roberto J. Gonzalez | -1240101 | 2022-11-23 | day | appointed | s |
| Commissioner, District 12 | mdc-commissioner-12 | Juan Carlos "JC" Bermudez | -1240102 | 2022-11-22 | day | elected | s |
| Commissioner, District 13 | mdc-commissioner-13 | René Garcia | -1240103 | 2020-11-17 | day | elected | s |
| Clerk of the Court and Comptroller | mdc-clerk-of-court | Juan Fernandez-Barquin | -1240105 | 2025-01-07 | day | elected | s |
| Sheriff | mdc-sheriff | Rosanna "Rosie" Cordero-Stutz | -1240106 | 2025-01-07 | day | elected | s |
| Property Appraiser | mdc-property-appraiser | Tomas Regalado | -1240107 | 2025-01-07 | day | elected | s |
| Tax Collector | mdc-tax-collector | Dariel Fernandez | -1240108 | 2025-01-07 | day | elected | s |
| Supervisor of Elections | mdc-supervisor-of-elections | Alina Garcia | -1240109 | 2025-01-07 | day | elected | s |

<!-- COUNTS: city_offices=6 city_people=6 county_offices=19 county_people=19 vacancies=0 -->
`;

describe('parseRosters', () => {
  it('returns both city and county, unlike FL-5', () => {
    const r = parseRosters(FIXTURE);
    expect(r.city).toHaveLength(6);
    expect(r.county).toHaveLength(19);
    expect(r.counts).toEqual({
      cityOffices: 6, cityPeople: 6, countyOffices: 19, countyPeople: 19, vacancies: 0,
    });
  });

  // 🔴 The reuse: exactly one id outside the new sub-range, and it is the declared
  //    one. ⚠ Unlike the plan's draft, -1240093 IS used — this wave's roster does
  //    not reserve a gap where District 1's id would have fallen. The invariant
  //    that matters is "one id outside, and it is -1212402".
  it('accepts exactly one reused external_id outside the new sub-range', () => {
    const ids = parseRosters(FIXTURE).county.map((s: any) => Number(s.externalId));
    const outside = ids.filter((n) => !(n >= -1240109 && n <= -1240081));
    expect(outside).toEqual([-1212402]);
    expect(ids).toHaveLength(19);
  });

  it('strips markdown emphasis from the reused id and flags the row', () => {
    const d1 = parseRosters(FIXTURE).county.find((s: any) => s.slug === 'mdc-commissioner-1');
    expect(d1.externalId).toBe('-1212402');
    expect(d1.isReused).toBe(true);
    // ...and nothing else is a reuse.
    const reused = parseRosters(FIXTURE).county.filter((s: any) => s.isReused);
    expect(reused.map((s: any) => s.slug)).toEqual(['mdc-commissioner-1']);
  });

  // 🔴 Two-word surnames: the override must win over splitName().
  it('overrides the surname for Cohen Higgins and Levine Cava', () => {
    const byslug = Object.fromEntries(parseRosters(FIXTURE).county.map((s: any) => [s.slug, s]));
    expect(byslug['mdc-commissioner-8'].firstName).toBe('Danielle');
    expect(byslug['mdc-commissioner-8'].lastName).toBe('Cohen Higgins');
    expect(byslug['mdc-mayor'].firstName).toBe('Daniella');
    expect(byslug['mdc-mayor'].lastName).toBe('Levine Cava');
  });

  // ⚠ And splitName() alone would silently DROP the middle word — the reason the
  //   override exists rather than a widened heuristic.
  it('demonstrates why the override is needed: the un-overridden split loses a word', () => {
    const byslug = Object.fromEntries(parseRosters(FIXTURE).county.map((s: any) => [s.slug, s]));
    // Bermudez keeps a two-word GIVEN name and must NOT be overridden.
    expect(byslug['mdc-commissioner-12'].firstName).toBe('Juan');
    expect(byslug['mdc-commissioner-12'].lastName).toBe('Bermudez');
  });

  it('strips a quoted nickname without eating the surname', () => {
    const byslug = Object.fromEntries([
      ...parseRosters(FIXTURE).city, ...parseRosters(FIXTURE).county,
    ].map((s: any) => [s.slug, s]));
    expect(byslug['mia-commissioner-4'].firstName).toBe('Ralph');
    expect(byslug['mia-commissioner-4'].lastName).toBe('Rosado');
    expect(byslug['mdc-sheriff'].firstName).toBe('Rosanna');
    expect(byslug['mdc-sheriff'].lastName).toBe('Cordero-Stutz');
  });

  // 🔴 All five officers share one published date.
  it('gives all five officers 2025-01-07 at day precision', () => {
    const off = parseRosters(FIXTURE).county.filter((s: any) => s.chamber === 'Elected Officials');
    expect(off).toHaveLength(5);
    expect(off.every((s: any) => s.termStart === '2025-01-07' && s.precision === 'day')).toBe(true);
    expect(off.every((s: any) => s.on === 'countywide')).toBe(true);
  });

  // 🔴 FOUR appointed commissioners, not the two the plan predicted. The SOE hides
  //    D8 and D11 because both have since won ordinary four-year terms.
  it('marks districts 5, 6, 8 and 11 appointed and nobody else', () => {
    const { city, county } = parseRosters(FIXTURE);
    const appointed = county.filter((s: any) => s.howStarted === 'appointed').map((s: any) => s.slug).sort();
    expect(appointed).toEqual([
      'mdc-commissioner-11', 'mdc-commissioner-5', 'mdc-commissioner-6', 'mdc-commissioner-8',
    ]);
    // Every city term is elected.
    expect(city.every((s: any) => s.howStarted === 'elected')).toBe(true);
  });

  // ⚠ Same title in two governments must not be treated as a duplicate.
  it('allows Mayor and Commissioner, District 1 in both governments', () => {
    const r = parseRosters(FIXTURE);
    expect(r.city.some((s: any) => s.title === 'Mayor')).toBe(true);
    expect(r.county.some((s: any) => s.title === 'Mayor')).toBe(true);
    expect(r.city.filter((s: any) => s.title === 'Commissioner, District 1')).toHaveLength(1);
    expect(r.county.filter((s: any) => s.title === 'Commissioner, District 1')).toHaveLength(1);
    // ...and they hang off DIFFERENT anchors.
    expect(r.city.find((s: any) => s.title === 'Mayor').on).toBe('citywide');
    expect(r.county.find((s: any) => s.title === 'Mayor').on).toBe('countywide');
  });

  // 🔴 The city commission is single-member; Tallahassee's was entirely at-large.
  it('puts all five city commission seats on commdist_city and only the Mayor citywide', () => {
    const { city } = parseRosters(FIXTURE);
    const comm = city.filter((s: any) => s.chamber === 'City Commission');
    expect(comm).toHaveLength(5);
    expect(comm.every((s: any) => s.on === 'commdist_city')).toBe(true);
    expect(comm.map((s: any) => s.n).sort((a: number, b: number) => a - b)).toEqual([1, 2, 3, 4, 5]);
    const mayor = city.filter((s: any) => s.chamber === 'Office of the Mayor');
    expect(mayor).toHaveLength(1);
    expect(mayor[0].on).toBe('citywide');
  });

  it('puts all thirteen county commission seats on commdist', () => {
    const comm = parseRosters(FIXTURE).county.filter((s: any) => s.chamber === 'Board of County Commissioners');
    expect(comm).toHaveLength(13);
    expect(comm.every((s: any) => s.on === 'commdist')).toBe(true);
    expect(comm.map((s: any) => s.n).sort((a: number, b: number) => a - b))
      .toEqual([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]);
  });

  it('has no Superintendent of Schools, State Attorney or Public Defender', () => {
    const r = parseRosters(FIXTURE);
    const titles = [...r.city, ...r.county].map((s: any) => s.title);
    for (const t of ['Superintendent of Schools', 'State Attorney', 'Public Defender']) {
      expect(titles).not.toContain(t);
    }
    // ⚠ HIS OWN SITE's form, not the SOE's and not Palm Beach's.
    expect(titles).toContain('Clerk of the Court and Comptroller');
    expect(titles).not.toContain('Clerk of the Circuit Court and Comptroller');
    expect(titles).not.toContain('Clerk of the Circuit Court & Comptroller');
  });

  it('attaches aliases without inventing them, and none for the reused row', () => {
    const r = parseRosters(FIXTURE);
    const byslug = Object.fromEntries([...r.city, ...r.county].map((s: any) => [s.slug, s.aliases]));
    expect(byslug['mdc-commissioner-13']).toEqual(['Rene Garcia']);
    expect(byslug['mdc-sheriff']).toEqual(['Rosie Cordero-Stutz', 'Rosanna Cordero-Stutz']);
    // 🔴 Gilbert's row belongs to another wave; this migration does not UPDATE it,
    //    so his published 'Oliver G. Gilbert, III' is deliberately NOT an alias.
    expect(byslug['mdc-commissioner-1']).toEqual([]);
    expect(byslug['mia-commissioner-2']).toEqual([]);
  });

  describe('refusals', () => {
    it('refuses an incomplete roster, even with a matching COUNTS comment', () => {
      const NL = String.fromCharCode(10);
      const subset = FIXTURE.split(NL)
        .filter((l) => !/mdc-commissioner-(1[0-3]|[4-9])\b/.test(l))
        .join(NL)
        .replace('county_offices=19 county_people=19', 'county_offices=9 county_people=9');
      expect(() => parseRosters(subset)).toThrow(/expected 13 county commission seats/);
    });

    it('refuses a file with no COUNTS comment', () => {
      expect(() => parseRosters(FIXTURE.replace(/<!-- COUNTS:[^>]*-->/, ''))).toThrow(/COUNTS comment/);
    });

    it('refuses a COUNTS comment that disagrees with the table', () => {
      expect(() => parseRosters(FIXTURE.replace('county_offices=19', 'county_offices=20')))
        .toThrow(/COUNTS: county table has 19 rows/);
    });

    // 🔴 An id outside the sub-range that is NOT a declared reuse is a collision.
    //    ⚠ -1212410 is outside the Florida LOCAL band ENTIRELY (it is in the
    //    congressional band, where the real reuse lives), so it is refused by the
    //    band check before the sub-range check ever runs. Both messages end in
    //    "is not a declared reuse" — that clause is the assertion.
    it('refuses an id from the congressional band that is not a declared reuse', () => {
      const bad = FIXTURE.replace('| -1240082 |', '| -1212410 |'); // another congressional candidate
      expect(() => parseRosters(bad)).toThrow(/-1212410 is outside the Florida LOCAL band/);
      expect(() => parseRosters(bad)).toThrow(/is not a declared reuse/);
    });

    it('refuses the declared reuse appearing on the wrong slug', () => {
      const bad = FIXTURE
        .replace('| mdc-commissioner-1 | Oliver Gilbert | **-1212402** |', '| mdc-commissioner-1 | Oliver Gilbert | -1240104 |')
        .replace('| mdc-commissioner-3 | Keon Hardemon | -1240093 |', '| mdc-commissioner-3 | Keon Hardemon | **-1212402** |');
      expect(() => parseRosters(bad)).toThrow(/is a declared reuse for "mdc-commissioner-1", but appears on "mdc-commissioner-3"/);
    });

    it('refuses a roster that drops the declared reuse entirely', () => {
      const bad = FIXTURE.replace('**-1212402**', '-1240104');
      expect(() => parseRosters(bad)).toThrow(/declared reuse -1212402 \(mdc-commissioner-1\) does not appear/);
    });

    it('refuses an external_id belonging to an earlier Florida wave', () => {
      // -1240065 is legitimately FL-5's (Maria Sachs).
      const bad = FIXTURE.replace('| -1240092 |', '| -1240065 |');
      expect(() => parseRosters(bad)).toThrow(/outside THIS WAVE's sub-range/);
    });

    it('refuses a party marking left in a name, including (DEM) and (WRI)', () => {
      for (const tag of ['(DEM)', '(REP)', '(WRI)', '(NPA)']) {
        const bad = FIXTURE.replace('Marleine Bastien', `Marleine Bastien ${tag}`);
        expect(() => parseRosters(bad)).toThrow(/party marking left in the name/);
      }
    });

    it('refuses a commission seat mapped to an unknown slug', () => {
      const bad = FIXTURE.replace(
        '| Commissioner, District 6 | mdc-commissioner-6 |',
        '| Commissioner, At Large Group 1 | mdc-at-large-group-1 |',
      );
      expect(() => parseRosters(bad)).toThrow(/unrecognised slug "mdc-at-large-group-1"/);
    });

    it('refuses a missing term_start that does not declare unknown', () => {
      const bad = FIXTURE.replace('| 2025-05-06 | day |', '|  | day |');
      expect(() => parseRosters(bad)).toThrow(/no term_start but precision is "day"/);
    });

    it('refuses a how_started the CHECK would reject', () => {
      const bad = FIXTURE.replace('| 2025-11-19 | day | appointed |', '| 2025-11-19 | day | anointed |');
      expect(() => parseRosters(bad)).toThrow(/how_started "anointed"/);
    });

    it('refuses a duplicate external_id', () => {
      const bad = FIXTURE.replace('| -1240093 |', '| -1240092 |');
      expect(() => parseRosters(bad)).toThrow(/duplicate external_id/);
    });

    it('refuses a term_start that is not YYYY-MM-DD', () => {
      const bad = FIXTURE.replace('| 2025-12-18 |', '| Dec 18 2025 |');
      expect(() => parseRosters(bad)).toThrow(/is not YYYY-MM-DD/);
    });
  });
});
