import { describe, it, expect } from 'vitest';
import {
  pickSittingMember,
  normalizeForMatch,
  splitDistrict,
  parseFlShortDate,
  parseSurnameFirst,
  parseElectedShort,
  dayAfter,
} from './build-fl-legislature-roster.mjs';

describe('dayAfter', () => {
  // These are the four real Florida House vacancies measured 2026-08-28. The
  // departed member's last day + 1 is the first VACANT day, which is what
  // offices.vacant_since means.
  it('computes the first vacant day for each real FL vacancy', () => {
    expect(dayAfter('2025-11-18')).toBe('2025-11-19'); // D113 Lopez
    expect(dayAfter('2026-05-20')).toBe('2026-05-21'); // D78  Persons-Mulicka
    expect(dayAfter('2026-08-05')).toBe('2026-08-06'); // D55  Steele
    expect(dayAfter('2026-08-21')).toBe('2026-08-22'); // D116 Perez
  });

  it('crosses a month boundary', () => {
    expect(dayAfter('2026-01-31')).toBe('2026-02-01');
    expect(dayAfter('2026-04-30')).toBe('2026-05-01');
  });

  it('crosses a year boundary', () => {
    expect(dayAfter('2025-12-31')).toBe('2026-01-01');
  });

  it('handles a leap day', () => {
    expect(dayAfter('2024-02-28')).toBe('2024-02-29');
    expect(dayAfter('2024-02-29')).toBe('2024-03-01');
    expect(dayAfter('2026-02-28')).toBe('2026-03-01');
  });

  it('refuses a non-ISO input rather than returning a wrong day', () => {
    expect(() => dayAfter('11/18/25')).toThrow();
    expect(() => dayAfter('2025-11-18T00:00:00Z')).toThrow();
  });
});

describe('parseFlShortDate', () => {
  it('converts the roster MM/DD/YY to ISO', () => {
    expect(parseFlShortDate('11/06/24')).toBe('2024-11-06');
    expect(parseFlShortDate('06/10/25')).toBe('2025-06-10');
    expect(parseFlShortDate('03/24/26')).toBe('2026-03-24');
  });

  it('refuses anything else rather than returning a wrong date', () => {
    expect(() => parseFlShortDate('2024-11-06')).toThrow();
    expect(() => parseFlShortDate('11/6/24')).toThrow();
    expect(() => parseFlShortDate('')).toThrow();
  });
});

// Every input below is a REAL name from the Florida roster, measured 2026-08-28.
// The shapes were found by scanning all 172 roster names, not assumed.
describe('parseSurnameFirst', () => {
  it('splits the ordinary case', () => {
    const r = parseSurnameFirst('Abbott, Shane G.');
    expect(r.last).toBe('Abbott');
    expect(r.given).toBe('Shane G.');
    expect(r.suffix).toBeNull();
    expect(r.full).toBe('Shane G. Abbott');
  });

  // A space-split on "First Last" would have guessed this wrong; the comma cannot.
  it('keeps a TWO-WORD surname intact', () => {
    const r = parseSurnameFirst('Bracy Davis, LaVon');
    expect(r.last).toBe('Bracy Davis');
    expect(r.full).toBe('LaVon Bracy Davis');
  });

  it('keeps a hyphenated surname intact', () => {
    expect(parseSurnameFirst('Persons-Mulicka, Jenna').full).toBe('Jenna Persons-Mulicka');
  });

  it('preserves a quoted nickname in full_name AND surfaces it as preferred', () => {
    const r = parseSurnameFirst('Caruso, Michael A. "Mike"');
    expect(r.full).toBe('Michael A. "Mike" Caruso');
    expect(r.preferred).toBe('Mike');
  });

  // 22 of the 160 carry a nickname; this one is the awkward case, because the nickname
  // itself begins with something that looks like an honorific.
  it('does NOT mistake an honorific INSIDE a nickname for a leading title', () => {
    const r = parseSurnameFirst('Hart-Lowman, Dianne "Ms Dee"');
    expect(r.full).toBe('Dianne "Ms Dee" Hart-Lowman');
    expect(r.honorific).toBeNull();
    expect(r.preferred).toBe('Ms Dee');
  });

  it('moves a suffix on the GIVEN side, after a second comma, into name_suffix', () => {
    const r = parseSurnameFirst('Massullo, Ralph E., Jr.');
    expect(r.last).toBe('Massullo');
    expect(r.given).toBe('Ralph E.');
    expect(r.suffix).toBe('Jr.');
    expect(r.full).toBe('Ralph E. Massullo, Jr.');
  });

  it('moves a suffix on the SURNAME side into name_suffix', () => {
    const r = parseSurnameFirst('Brannan III, Robert Charles "Chuck"');
    expect(r.last).toBe('Brannan');
    expect(r.suffix).toBe('III');
    expect(r.full).toBe('Robert Charles "Chuck" Brannan, III');
  });

  it('handles a surname-side Jr. together with a nickname', () => {
    const r = parseSurnameFirst('Griffitts Jr., Philip Wayne "Griff"');
    expect(r.last).toBe('Griffitts');
    expect(r.suffix).toBe('Jr.');
    expect(r.preferred).toBe('Griff');
    expect(r.full).toBe('Philip Wayne "Griff" Griffitts, Jr.');
  });

  // full_name is a MATCHING KEY downstream, so a title must not sit inside it.
  it('strips a leading honorific out of full_name but records it', () => {
    const r = parseSurnameFirst('Eskamani, Dr. Anna V.');
    expect(r.honorific).toBe('Dr.');
    expect(r.given).toBe('Anna V.');
    expect(r.full).toBe('Anna V. Eskamani');
  });

  it('strips the leading roster marker but keeps the name', () => {
    expect(parseSurnameFirst('* Casello, Joe').full).toBe('Joe Casello');
  });

  it('preserves accented characters byte-for-byte — this feeds full_name', () => {
    expect(parseSurnameFirst('Basabe, Fabián').full).toBe('Fabián Basabe');
    expect(parseSurnameFirst('López, Johanna').full).toBe('Johanna López');
    expect(parseSurnameFirst('Valdés, Susan L.').full).toBe('Susan L. Valdés');
  });

  it('refuses a name that is not surname-first rather than mangling it', () => {
    expect(() => parseSurnameFirst('Shane Abbott')).toThrow(/surname-first/i);
  });

  it('refuses a half-empty split', () => {
    expect(() => parseSurnameFirst('Abbott,')).toThrow(/empty half/i);
    expect(() => parseSurnameFirst(', Shane')).toThrow(/empty half/i);
  });

  // The Senate marks a vacancy by putting the word 'Vacant' in the name cell. This
  // MUST throw: silently accepting it would seat a politician called "Vacant".
  it('refuses the Senate vacancy placeholder', () => {
    expect(() => parseSurnameFirst('Vacant')).toThrow(/surname-first/i);
  });

  it('refuses an unrecognised trailing part rather than treating it as a suffix', () => {
    expect(() => parseSurnameFirst('Smith, John, Chairman')).toThrow(/Unrecognised trailing/i);
  });

  it('refuses a suffix on BOTH sides of the comma', () => {
    expect(() => parseSurnameFirst('Smith Jr., John, III')).toThrow(/BOTH sides/i);
  });
});

// Replaces an earlier continuousRunStart() suite. That function is deleted: it read the
// "Florida Senate Service" block as a continuous-service record, which it is not — it is
// a term SELECTOR that repeats the current term, lists every term a member served ANY
// part of, and does not show a gap. See the note in the .mjs before reinventing it.
describe('parseElectedShort', () => {
  // All four are real, from the only 4 Senate pages that carry this line (2026-08-28).
  it('parses the compact Elected line', () => {
    expect(parseElectedShort('Elected 6/10/2025')).toBe('2025-06-10'); // SD-19 Mayfield
    expect(parseElectedShort('Elected 12/9/2025')).toBe('2025-12-09'); // SD-11 Massullo
    expect(parseElectedShort('Elected 3/24/2026')).toBe('2026-03-24'); // SD-14 Nathan
    expect(parseElectedShort('Elected 9/2/2025')).toBe('2025-09-02');  // SD-15 Bracy Davis
  });

  it('zero-pads a single-digit month and day', () => {
    expect(parseElectedShort('Elected 1/2/2026')).toBe('2026-01-02');
  });

  it('returns null for any other line rather than inventing a date', () => {
    expect(parseElectedShort('Elected to the Senate on June 10, 2025')).toBeNull();
    expect(parseElectedShort('Party: Republican')).toBeNull();
    expect(parseElectedShort('Elected 2025')).toBeNull();
    expect(parseElectedShort('')).toBeNull();
  });
});

describe('normalizeForMatch', () => {
  it('NFD-strips diacritics by DELETING combining marks, not spacing them', () => {
    expect(normalizeForMatch('Ana María Rodríguez')).toBe('ana maria rodriguez');
    expect(normalizeForMatch('Berny Jacques')).toBe('berny jacques');
  });

  it('is case and whitespace insensitive', () => {
    expect(normalizeForMatch('  DANNY   Alvarez ')).toBe('danny alvarez');
  });
});

describe('splitDistrict', () => {
  it('parses the Senate session-scoped path', () => {
    expect(splitDistrict('/Senators/2024-2026/S40')).toBe(40);
    expect(splitDistrict('/Senators/2024-2026/S1')).toBe(1);
  });

  it('refuses a member-detail sub-path rather than returning the wrong number', () => {
    expect(() => splitDistrict('/Senators/2024-2026/S14/5523')).toThrow(/sub-path/i);
  });

  it('refuses the session segment itself', () => {
    expect(() => splitDistrict('/Senators/2024-2026/')).toThrow();
  });
});

describe('pickSittingMember', () => {
  it('returns the only row when a district is uncontested', () => {
    const rows = [{ name: 'Adam Anderson', assumedOn: '2022-11-08', departedOn: null }];
    expect(pickSittingMember('57', rows).name).toBe('Adam Anderson');
  });

  it('drops a row explicitly marked as departed', () => {
    const rows = [
      { name: 'Departed Member', assumedOn: '2022-11-08', departedOn: '2026-03-01' },
      { name: 'Sitting Member', assumedOn: '2026-06-02', departedOn: null },
    ];
    expect(pickSittingMember('12', rows).name).toBe('Sitting Member');
  });

  it('takes the LATEST assumed-office date when the predecessor is UNANNOTATED', () => {
    const rows = [
      { name: 'Old Member', assumedOn: '2022-11-08', departedOn: null },
      { name: 'New Member', assumedOn: '2026-06-02', departedOn: null },
    ];
    expect(pickSittingMember('55', rows).name).toBe('New Member');
  });

  it('ignores source ordering', () => {
    const rows = [
      { name: 'New Member', assumedOn: '2026-06-02', departedOn: null },
      { name: 'Old Member', assumedOn: '2022-11-08', departedOn: null },
    ];
    expect(pickSittingMember('78', rows).name).toBe('New Member');
  });

  it('returns the survivor when every other row is marked departed', () => {
    const rows = [
      { name: 'Gone A', assumedOn: '2022-11-08', departedOn: '2025-01-05' },
      { name: 'Gone B', assumedOn: '2025-02-01', departedOn: '2026-02-01' },
      { name: 'Here', assumedOn: '2026-03-01', departedOn: null },
    ];
    expect(pickSittingMember('113', rows).name).toBe('Here');
  });

  // Failing loudly is the point: a shape we have not seen must not be guessed.
  it('throws when a contested district has no date to arbitrate on', () => {
    const rows = [
      { name: 'Person A', assumedOn: null, departedOn: null },
      { name: 'Person B', assumedOn: null, departedOn: null },
    ];
    expect(() => pickSittingMember('116', rows)).toThrow(/district 116/i);
  });

  it('throws when two surviving rows tie on the same assumed-office date', () => {
    const rows = [
      { name: 'Person A', assumedOn: '2026-06-02', departedOn: null },
      { name: 'Person B', assumedOn: '2026-06-02', departedOn: null },
    ];
    expect(() => pickSittingMember('99', rows)).toThrow(/district 99/i);
  });

  it('throws when every row is marked departed — a vacancy is not a member', () => {
    const rows = [
      { name: 'Gone A', assumedOn: '2022-11-08', departedOn: '2026-02-01' },
    ];
    expect(() => pickSittingMember('7', rows)).toThrow(/district 7.*vacan/i);
  });
});
