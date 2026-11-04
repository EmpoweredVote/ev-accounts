import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import {
  readMaRollCall, renderMaRollCall, parseMaRollCallRender, parseMaRollCallUrl, isMaRollCallUrl, ordinal,
  formatMaRollCallLine, parseMaRollCallLine, verifyMaRollCallLine, maRollCallLinesFor, maLabelFits, labelSurname,
} from './maRollCallEvidence.js';
import type { PdfTextItem } from './pdfText.js';
import { namesParty } from './partyLabels.js';

// Positioned text of two public roll calls, extracted with extractPdfItems from
// https://malegislature.gov/RollCall/193/HouseRollCall135.pdf and …/190/HouseRollCall389.pdf.
const fx = (name: string): PdfTextItem[] =>
  JSON.parse(readFileSync(fileURLToPath(new URL(`./__fixtures__/ma/${name}.json`, import.meta.url)), 'utf8'));

const URL_135 = 'https://malegislature.gov/RollCall/193/HouseRollCall135.pdf';
const URL_389 = 'https://malegislature.gov/RollCall/190/HouseRollCall389.pdf';
const rc135 = () => renderMaRollCall(readMaRollCall(fx('HouseRollCall-193-135'), '193')!);
const rc389 = () => renderMaRollCall(readMaRollCall(fx('HouseRollCall-190-389'), '190')!);
const Q135 = 'H.4885 - On acceptance of the report';
const line135 = (name: string, vote = 'Yea') => `Massachusetts House roll call 135 (193rd General Court), ${Q135}: ${name} voted ${vote}.`;

describe('parseMaRollCallUrl', () => {
  it('reads the General Court and roll number', () => {
    expect(parseMaRollCallUrl(URL_135)).toEqual({ court: '193', rollNum: 135 });
    expect(parseMaRollCallUrl(URL_389)).toEqual({ court: '190', rollNum: 389 });
  });
  it('refuses other documents, schemes and hosts', () => {
    expect(isMaRollCallUrl('https://malegislature.gov/Bills/193/H4885')).toBe(false);
    expect(isMaRollCallUrl('http://malegislature.gov/RollCall/193/HouseRollCall135.pdf')).toBe(false);
    expect(isMaRollCallUrl('https://malegislature.gov/RollCall/193/SenateRollCall135.pdf')).toBe(false);
    expect(isMaRollCallUrl('https://example.com/RollCall/193/HouseRollCall135.pdf')).toBe(false);
  });
  it('writes ordinals', () => {
    expect([ordinal(193), ordinal(190), ordinal(191), ordinal(192), ordinal(111), ordinal(112)])
      .toEqual(['193rd', '190th', '191st', '192nd', '111th', '112th']);
  });
});

describe('readMaRollCall', () => {
  it('reads roll call 135: every mark counted and equal to the printed tally', () => {
    const r = readMaRollCall(fx('HouseRollCall-193-135'), '193')!;
    expect(r).toMatchObject({ rollNum: 135, court: '193', bill: 'H.4885', question: 'On acceptance of the report', date: '2024-07-18' });
    expect(r.tally).toEqual({ yeas: 124, nays: 33, notVoting: 2 });
    expect([r.groups.Yea.length, r.groups.Nay.length, r.groups['Not Voting'].length]).toEqual([124, 33, 2]);
    expect(r.groups.Yea).toEqual(expect.arrayContaining(['Kilcoyne', 'Diggs', 'Moran M.', 'Ramos, A.', 'Fluker Oakley']));
    expect(r.groups.Nay).toEqual(expect.arrayContaining(['Smola', 'Haddad', 'Jones', 'Whipps']));
    expect(r.groups['Not Voting']).toEqual(['Markey', 'Pignatelli']);
    expect(r.afterVote).toEqual(['Farley-Bouvier']);
  });

  it('reads roll call 389 (2018), with two members printed "Hunt, D." and "Hunt, R."', () => {
    const r = readMaRollCall(fx('HouseRollCall-190-389'), '190')!;
    expect(r).toMatchObject({ rollNum: 389, bill: 'H.4670', question: 'On acceptance of the conference report', date: '2018-06-28' });
    expect([r.groups.Yea.length, r.groups.Nay.length, r.groups['Not Voting'].length]).toEqual([133, 15, 5]);
    expect(r.groups.Yea).toContain('Hunt, D.');
    expect(r.groups['Not Voting']).toContain('Hunt, R.');
  });

  it('fails closed when a label is lost (a count no longer matches the tally)', () => {
    expect(readMaRollCall(fx('HouseRollCall-193-135').filter((i) => i.str !== 'Kilcoyne'), '193')).toBeNull();
  });

  it('fails closed when a mark is lost (a label with no mark), even if the tally were reprinted to match', () => {
    const items = fx('HouseRollCall-193-135').map((i) => ({ ...i }));
    const kil = items.find((i) => i.str === 'Kilcoyne')!;
    const mark = items.find((i) => /^[YNXP]$/.test(i.str) && Math.abs(i.y - kil.y) < 4 && kil.x - i.x > 0 && kil.x - i.x < 60)!;
    // Lower the printed YEAS too, so only the unmarked label (not the tally) can refuse the read.
    items.find((i) => i.str === '124')!.str = '123';
    expect(readMaRollCall(items.filter((i) => i !== mark), '193')).toBeNull();
  });

  it('fails closed when a mark is flipped (the tally no longer matches)', () => {
    const items = fx('HouseRollCall-193-135').map((i) => ({ ...i }));
    const smola = items.find((i) => i.str === 'Smola')!;
    const mark = items.find((i) => i.str === 'N' && Math.abs(i.y - smola.y) < 4 && smola.x - i.x > 0 && smola.x - i.x < 60)!;
    mark.str = 'Y';
    expect(readMaRollCall(items, '193')).toBeNull();
  });
});

describe('render', () => {
  it('round-trips and names no party', () => {
    const t = rc135();
    const back = parseMaRollCallRender(t)!;
    expect(back).toMatchObject({ rollNum: 135, court: '193', bill: 'H.4885', question: 'On acceptance of the report', date: '2024-07-18' });
    expect(back.groups.Nay).toHaveLength(33);
    expect(namesParty(t)).toBe(false);
    expect(namesParty(rc389())).toBe(false);
  });
  it('refuses a render whose list disagrees with its count', () => {
    expect(parseMaRollCallRender(rc135().replace('Nay (33):', 'Nay (32):'))).toBeNull();
  });
});

describe('canonical line', () => {
  it('formats and parses', () => {
    const l = { rollNum: 135, court: '193', bill: 'H.4885', question: 'On acceptance of the report', name: 'Kilcoyne', vote: 'Yea' as const };
    expect(formatMaRollCallLine(l)).toBe(line135('Kilcoyne'));
    expect(parseMaRollCallLine(line135('Kilcoyne'))).toEqual(l);
    expect(parseMaRollCallLine(line135('Ramos, A.', 'Nay'))).toMatchObject({ name: 'Ramos, A.', vote: 'Nay' });
    expect(namesParty(line135('Kilcoyne'))).toBe(false);
  });
  it('refuses a wrong ordinal and other wording', () => {
    expect(parseMaRollCallLine(line135('Kilcoyne').replace('193rd', '193th'))).toBeNull();
    expect(parseMaRollCallLine('Kilcoyne voted Yea on H.4885.')).toBeNull();
  });
});

describe('labelSurname / maLabelFits', () => {
  it('splits an initial off a label', () => {
    expect(labelSurname('Moran M.')).toEqual(['moran', true]);
    expect(labelSurname('Ramos, A.')).toEqual(['ramos', true]);
    expect(labelSurname('Fluker Oakley')).toEqual(['fluker oakley', false]);
    expect(labelSurname('Kilcoyne')).toEqual(['kilcoyne', false]);
  });
  it('a bare surname the roll call prints for two members names neither', () => {
    expect(maLabelFits('Hunt', ['Hunt', 'Hunt, R.'], 'Hunt', 'Daniel J. Hunt')).toBe(false);
    expect(maLabelFits('Hunt', ['Hunt', 'Kane'], 'Hunt', 'Daniel J. Hunt')).toBe(true);
    expect(maLabelFits('Hunt, R.', ['Hunt', 'Hunt, R.'], 'Hunt', 'Randy Hunt')).toBe(true);
  });
});

describe('verifyMaRollCallLine', () => {
  it('verifies a member printed by surname alone', () => {
    expect(verifyMaRollCallLine(line135('Kilcoyne'), URL_135, rc135(), 'Kilcoyne', 'Meghan Kilcoyne')).toEqual({ verdict: 'verified', matchOffset: 0 });
    expect(verifyMaRollCallLine(line135('Smola', 'Nay'), URL_135, rc135(), 'Smola', 'Todd M. Smola').verdict).toBe('verified');
  });
  it('verifies a member printed with an initial only when the initial fits', () => {
    expect(verifyMaRollCallLine(line135('Moran M.'), URL_135, rc135(), 'Moran', 'Michael J. Moran').verdict).toBe('verified');
    expect(verifyMaRollCallLine(line135('Moran M.'), URL_135, rc135(), 'Moran', 'Frank A. Moran').verdict).toBe('name_not_present');
    expect(verifyMaRollCallLine(line135('Ramos, O.'), URL_135, rc135(), 'Ramos', 'Orlando Ramos').verdict).toBe('verified');
    expect(verifyMaRollCallLine(line135('Ramos, O.'), URL_135, rc135(), 'Ramos', 'Angelo Ramos').verdict).toBe('name_not_present');
  });
  it('refuses a bare surname that two members share', () => {
    // Plant a second bare "Kilcoyne" in the Nay list: the label no longer names one member.
    const t = rc135().replace('Nay (33): Turco;', 'Nay (34): Kilcoyne; Turco;');
    expect(verifyMaRollCallLine(line135('Kilcoyne'), URL_135, t, 'Kilcoyne', 'Meghan Kilcoyne').verdict).toBe('name_not_present');
  });
  it('refuses a wrong mark', () => {
    expect(verifyMaRollCallLine(line135('Kilcoyne', 'Nay'), URL_135, rc135(), 'Kilcoyne', 'Meghan Kilcoyne').verdict).toBe('snippet_not_found');
    expect(verifyMaRollCallLine(line135('Smola', 'Yea'), URL_135, rc135(), 'Smola', 'Todd M. Smola').verdict).toBe('snippet_not_found');
  });
  it('refuses another politician with the label', () => {
    expect(verifyMaRollCallLine(line135('Kilcoyne'), URL_135, rc135(), 'Diggs', 'Kip A. Diggs').verdict).toBe('name_not_present');
    expect(verifyMaRollCallLine(line135('Mr. Speaker'), URL_135, rc135(), 'Mariano', 'Ronald Mariano').verdict).toBe('name_not_present');
  });
  it('refuses a line on the wrong URL, roll call or question', () => {
    expect(verifyMaRollCallLine(line135('Kilcoyne'), URL_389, rc135(), 'Kilcoyne', 'Meghan Kilcoyne').verdict).toBe('snippet_not_found');
    expect(verifyMaRollCallLine(line135('Kilcoyne'), URL_135, rc389(), 'Kilcoyne', 'Meghan Kilcoyne').verdict).toBe('snippet_not_found');
    expect(verifyMaRollCallLine(line135('Kilcoyne').replace('H.4885', 'H.4886'), URL_135, rc135(), 'Kilcoyne', 'Meghan Kilcoyne').verdict).toBe('snippet_not_found');
    expect(verifyMaRollCallLine(line135('Kilcoyne'), URL_135, 'Y Kilcoyne Y Diggs', 'Kilcoyne', 'Meghan Kilcoyne').verdict).toBe('snippet_not_found');
  });
});

describe('maRollCallLinesFor', () => {
  it('cuts one line for a member, none for a non-member, none for a mismatched URL', () => {
    expect(maRollCallLinesFor(URL_135, rc135(), 'Kilcoyne', 'Meghan Kilcoyne')).toEqual([line135('Kilcoyne')]);
    expect(maRollCallLinesFor(URL_389, rc389(), 'Hunt', 'Randy Hunt')).toEqual([
      'Massachusetts House roll call 389 (190th General Court), H.4670 - On acceptance of the conference report: Hunt, R. voted Not Voting.',
    ]);
    expect(maRollCallLinesFor(URL_135, rc135(), 'Nobody', 'Ann Nobody')).toEqual([]);
    expect(maRollCallLinesFor(URL_389, rc135(), 'Kilcoyne', 'Meghan Kilcoyne')).toEqual([]);
  });
});
