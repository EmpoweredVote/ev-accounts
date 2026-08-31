import { describe, expect, it } from 'vitest';
// @ts-expect-error -- .mjs generator, no types
import { parseRosters } from './gen-tallahassee-leon-migrations.mjs';

const FIXTURE = `
## Roster

### City of Tallahassee

| Seat | Slug | Name | external_id | term_start | precision | how_started | source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Seat 3 | seat-3 | Jeremy Matlow | -1240033 | 2018-11-01 | month | elected | talgov-matlow-bio |
| Seat 4, Mayor | seat-4-mayor | John Dailey | -1240034 | 2018-11-01 | month | elected | talgov-dailey-bio |
| Seat 5 | seat-5 | Dianne Williams-Cox | -1240035 |  | unknown | elected | leonvotes-elected-officials |

### Leon County

| Seat | Slug | Name | external_id | term_start | precision | how_started | source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Commissioner, At Large Group 2 | at-large-group-2 | Nick Maddox | -1240047 | 2010-11-01 | month | elected | leoncounty-leadingtheway |
| Superintendent of Schools | superintendent-of-schools | Rocky Hanna | -1240056 |  | unknown | elected | leonvotes-elected-officials |

<!-- COUNTS: city_offices=3 city_people=3 county_offices=2 county_people=2 vacancies=0 -->
`;

describe('parseRosters', () => {
  it('reads both tables and the declared counts', () => {
    const r = parseRosters(FIXTURE);
    expect(r.city).toHaveLength(3);
    expect(r.county).toHaveLength(2);
    expect(r.counts).toEqual({
      cityOffices: 3, cityPeople: 3, countyOffices: 2, countyPeople: 2, vacancies: 0,
    });
  });

  it('carries how_started and precision through instead of defaulting them', () => {
    const s3 = parseRosters(FIXTURE).city.find((s: any) => s.slug === 'seat-3');
    expect(s3.howStarted).toBe('elected');
    expect(s3.precision).toBe('month');
    expect(s3.termStart).toBe('2018-11-01');
  });

  it('keeps an unknown-precision row with no term_start', () => {
    const s5 = parseRosters(FIXTURE).city.find((s: any) => s.slug === 'seat-5');
    expect(s5.precision).toBe('unknown');
    expect(s5.termStart).toBe('');
    expect(s5.isVacant).toBe(false);
  });

  // FL-4 has no vacancy anywhere, which is itself a shape worth pinning.
  it('accepts a county table with no vacancy at all', () => {
    const r = parseRosters(FIXTURE);
    expect(r.county.some((s: any) => s.isVacant)).toBe(false);
    expect(r.counts.vacancies).toBe(0);
  });

  // 🔴 Every city seat is at-large here, so they must all share the citywide
  //    district and still carry five distinct titles.
  it('puts every city seat on the citywide district with a distinct title', () => {
    const r = parseRosters(FIXTURE);
    expect(r.city.every((s: any) => s.on === 'citywide')).toBe(true);
    expect(new Set(r.city.map((s: any) => s.title)).size).toBe(r.city.length);
  });

  // 🔴 The sixth officer is the whole charter-county difference from Manatee.
  it('recognises the Superintendent of Schools as a county officer', () => {
    const sup = parseRosters(FIXTURE).county.find((s: any) => s.slug === 'superintendent-of-schools');
    expect(sup).toBeDefined();
    expect(sup.chamber).toBe('Elected Officials');
    expect(sup.on).toBe('countywide');
  });

  it('splits a hyphenated surname without mangling it', () => {
    const s5 = parseRosters(FIXTURE).city.find((s: any) => s.slug === 'seat-5');
    expect(s5.firstName).toBe('Dianne');
    expect(s5.lastName).toBe('Williams-Cox');
  });

  // 🔴 THE FL-2 GUARD. That wave assumed 160 people for 160 offices and found
  // 155, and ON CONFLICT DO NOTHING would have absorbed the gap in silence.
  it('refuses a file whose tables disagree with its COUNTS line', () => {
    expect(() => parseRosters(FIXTURE.replace('city_people=3', 'city_people=5')))
      .toThrow(/COUNTS/);
    expect(() => parseRosters(FIXTURE.replace('county_offices=2', 'county_offices=13')))
      .toThrow(/COUNTS/);
    expect(() => parseRosters(FIXTURE.replace('vacancies=0', 'vacancies=1')))
      .toThrow(/COUNTS/);
  });

  it('refuses a file with no COUNTS line at all', () => {
    expect(() => parseRosters(FIXTURE.replace(/<!-- COUNTS.*-->/, ''))).toThrow(/COUNTS/);
  });

  it('refuses a duplicate external_id across the two tables', () => {
    const bad = FIXTURE.replace('-1240047', '-1240033');
    expect(() => parseRosters(bad)).toThrow(/duplicate/i);
  });

  it('refuses an unrecognised slug rather than silently dropping the seat', () => {
    const bad = FIXTURE.replace('| seat-3 |', '| seat-9 |');
    expect(() => parseRosters(bad)).toThrow(/seat-9/);
  });

  it('refuses a how_started the schema CHECK would reject', () => {
    const bad = FIXTURE.replace('| elected | talgov-matlow-bio |', '| anointed | talgov-matlow-bio |');
    expect(() => parseRosters(bad)).toThrow(/anointed/);
  });

  it('refuses a precision the schema CHECK would reject', () => {
    const bad = FIXTURE.replace('| month | elected | talgov-matlow-bio |', '| decade | elected | talgov-matlow-bio |');
    expect(() => parseRosters(bad)).toThrow(/decade/);
  });

  // A seated person with no term_start must declare 'unknown'; anything else is a
  // silently-dropped date.
  it('refuses a seated person with no term_start unless precision is unknown', () => {
    const bad = FIXTURE.replace('| -1240035 |  | unknown |', '| -1240035 |  | day |');
    expect(() => parseRosters(bad)).toThrow(/term_start/);
  });

  it('refuses a party marking left in a name', () => {
    const bad = FIXTURE.replace('John Dailey', 'John Dailey (DEM)');
    expect(() => parseRosters(bad)).toThrow(/part(y|isan)/i);
  });
});
