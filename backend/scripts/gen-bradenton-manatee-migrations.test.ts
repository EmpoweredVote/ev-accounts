import { describe, expect, it } from 'vitest';
// @ts-expect-error -- .mjs generator, no types
import { parseRosters } from './gen-bradenton-manatee-migrations.mjs';

const FIXTURE = `
## Roster

### City of Bradenton

| Seat | Slug | Name | external_id | term_start | precision | how_started | source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Mayor | mayor | Gene Brown | -1240001 | 2021-01-01 | month | elected | cityofbradenton-brown-bio |
| Ward 1 | ward-1 | Jayne Kocher | -1240002 |  | unknown | elected | cityofbradenton-council |
| Ward 3 | ward-3 | Kemp Schuessler | -1240004 | 2025-07-23 | day | appointed | cityofbradenton-schuessler-bio |

### Manatee County

| Seat | Slug | Name | external_id | term_start | precision | how_started | source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Commissioner, District 1 | commissioner-1 | VACANT |  |  |  |  | mymanatee-d1-vacant-2026-02-24 |
| Sheriff | sheriff | Charles R. "Rick" Wells | -1240021 | 2017-01-03 | day | elected | manateesheriff-wells-bio |

<!-- COUNTS: city_offices=3 city_people=3 county_offices=2 county_people=1 vacancies=1 -->
`;

describe('parseRosters', () => {
  it('reads both tables and the declared counts', () => {
    const r = parseRosters(FIXTURE);
    expect(r.city).toHaveLength(3);
    expect(r.county).toHaveLength(2);
    expect(r.counts).toEqual({
      cityOffices: 3, cityPeople: 3, countyOffices: 2, countyPeople: 1, vacancies: 1,
    });
  });

  it('carries how_started and precision through instead of defaulting them', () => {
    const w3 = parseRosters(FIXTURE).city.find((s: any) => s.slug === 'ward-3');
    expect(w3.howStarted).toBe('appointed');
    expect(w3.precision).toBe('day');
    expect(w3.termStart).toBe('2025-07-23');
  });

  it('keeps an unknown-precision row with no term_start', () => {
    const w1 = parseRosters(FIXTURE).city.find((s: any) => s.slug === 'ward-1');
    expect(w1.precision).toBe('unknown');
    expect(w1.termStart).toBe('');
    expect(w1.isVacant).toBe(false);
  });

  it('models a vacancy as a named absence, not a missing row', () => {
    const d1 = parseRosters(FIXTURE).county.find((s: any) => s.slug === 'commissioner-1');
    expect(d1).toBeDefined();
    expect(d1.isVacant).toBe(true);
    expect(d1.externalId).toBe('');
  });

  it('keeps a double quote inside a name intact', () => {
    const sh = parseRosters(FIXTURE).county.find((s: any) => s.slug === 'sheriff');
    expect(sh.name).toBe('Charles R. "Rick" Wells');
  });

  it('splits a name into first and last without mangling a quoted nickname', () => {
    const sh = parseRosters(FIXTURE).county.find((s: any) => s.slug === 'sheriff');
    expect(sh.firstName).toBe('Charles');
    expect(sh.lastName).toBe('Wells');
  });

  // 🔴 THE FL-2 GUARD. That wave assumed 160 people for 160 offices and found
  // 155, and ON CONFLICT DO NOTHING would have absorbed the gap in silence.
  it('refuses a file whose tables disagree with its COUNTS line', () => {
    expect(() => parseRosters(FIXTURE.replace('city_people=3', 'city_people=6')))
      .toThrow(/COUNTS/);
    expect(() => parseRosters(FIXTURE.replace('county_offices=2', 'county_offices=12')))
      .toThrow(/COUNTS/);
    expect(() => parseRosters(FIXTURE.replace('vacancies=1', 'vacancies=0')))
      .toThrow(/COUNTS/);
  });

  it('refuses a file with no COUNTS line at all', () => {
    expect(() => parseRosters(FIXTURE.replace(/<!-- COUNTS.*-->/, ''))).toThrow(/COUNTS/);
  });

  it('refuses a duplicate external_id across the two tables', () => {
    const bad = FIXTURE.replace('-1240021', '-1240001');
    expect(() => parseRosters(bad)).toThrow(/duplicate/i);
  });

  it('refuses an unrecognised slug rather than silently dropping the seat', () => {
    const bad = FIXTURE.replace('| ward-3 |', '| ward-9 |');
    expect(() => parseRosters(bad)).toThrow(/ward-9/);
  });

  it('refuses a how_started the schema CHECK would reject', () => {
    const bad = FIXTURE.replace('| appointed |', '| anointed |');
    expect(() => parseRosters(bad)).toThrow(/anointed/);
  });

  it('refuses a precision the schema CHECK would reject', () => {
    const bad = FIXTURE.replace('| month | elected |', '| decade | elected |');
    expect(() => parseRosters(bad)).toThrow(/decade/);
  });

  // A seated person with no term_start must declare 'unknown'; anything else is a
  // silently-dropped date.
  it('refuses a seated person with no term_start unless precision is unknown', () => {
    const bad = FIXTURE.replace('| -1240002 |  | unknown |', '| -1240002 |  | day |');
    expect(() => parseRosters(bad)).toThrow(/term_start/);
  });

  it('refuses a party marking left in a name', () => {
    const bad = FIXTURE.replace('Gene Brown', 'Gene Brown (R)');
    expect(() => parseRosters(bad)).toThrow(/part(y|isan)/i);
  });
});
