import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import {
  readIgaRollCall, renderIgaRollCall, parseIgaRollCallRender, parseIgaRollCallUrl, isIgaRollCallUrl,
  formatIgaRollCallLine, parseIgaRollCallLine, verifyIgaRollCallLine, igaRollCallLinesFor, printedNameFits,
} from './igaRollCallEvidence.js';
import type { PdfTextItem } from './pdfText.js';
import { namesParty } from './partyLabels.js';

// Positioned text of three public roll calls, extracted with extractPdfItems (scripts in the PR).
const fx = (name: string): PdfTextItem[] =>
  JSON.parse(readFileSync(fileURLToPath(new URL(`./__fixtures__/iga/${name}.json`, import.meta.url)), 'utf8'));

const HOUSE_URL = 'https://iga.in.gov/pdf-documents/124/2025/senate/bills/SB0010/rollcalls/SB0010.340_H.pdf';
const SENATE_URL = 'https://iga.in.gov/pdf-documents/124/2025/senate/bills/SB0010/rollcalls/SB0010.66_S.pdf';
const house = () => renderIgaRollCall(readIgaRollCall(fx('rollcall-2025-SB0010.340_H'), '2025')!);
const senate = () => renderIgaRollCall(readIgaRollCall(fx('rollcall-2025-SB0010.66_S'), '2025')!);

describe('parseIgaRollCallUrl', () => {
  it('reads session, roll number and the voting chamber (the suffix, not the bill folder)', () => {
    expect(parseIgaRollCallUrl(HOUSE_URL)).toEqual({ session: '2025', rollNum: 340, chamber: 'House' });
    expect(parseIgaRollCallUrl(SENATE_URL)).toEqual({ session: '2025', rollNum: 66, chamber: 'Senate' });
    expect(parseIgaRollCallUrl('https://iga.in.gov/pdf-documents/122/2022ss1/senate/bills/SB0001/rollcalls/SB0001.12_H.pdf'))
      .toEqual({ session: '2022ss1', rollNum: 12, chamber: 'House' });
  });
  it('refuses other documents and hosts', () => {
    expect(isIgaRollCallUrl('https://iga.in.gov/pdf-documents/124/2025/senate/bills/SB0010/SB0010.04.ENRH.pdf')).toBe(false);
    expect(isIgaRollCallUrl('http://iga.in.gov/pdf-documents/124/2025/senate/bills/SB0010/rollcalls/SB0010.340_H.pdf')).toBe(false);
    expect(isIgaRollCallUrl('https://legiscan.com/IN/rollcall/SB0010/id/1532383')).toBe(false);
  });
});

describe('readIgaRollCall', () => {
  it('reads the House roll call: every group the size its heading prints', () => {
    const r = readIgaRollCall(fx('rollcall-2025-SB0010.340_H'), '2025')!;
    expect(r).toMatchObject({ chamber: 'House', rollNum: 340, result: 'Bill Passed', motion: 'SB 10 - Culp - 3rd Reading', detail: 'Voter registration' });
    expect([r.groups.Yea.length, r.groups.Nay.length, r.groups.Excused.length, r.groups['Not Voting'].length]).toEqual([66, 26, 5, 3]);
    expect(r.groups.Nay).toContain('Dant Chesser');
    expect(r.groups.Excused).toEqual(['Behning', 'Gore', 'Johnson', 'Pierce, K', 'Garcia Wilburn']);
    // The form's version footer ("v. 1.2") is not a member.
    expect(r.groups['Not Voting']).toEqual(['Burton', 'Lawson', 'Mr. Speaker']);
  });

  it('reads the Senate form and an older session with a two-line motion', () => {
    const s = readIgaRollCall(fx('rollcall-2025-SB0010.66_S'), '2025')!;
    expect(s).toMatchObject({ chamber: 'Senate', rollNum: 66, motion: 'SB 10 - Doriot - 3rd Reading' });
    expect(s.groups.Nay).toContain('Ford J.D.');
    const o = readIgaRollCall(fx('rollcall-2021-SB0421.515_H'), '2021')!;
    expect(o.motion).toBe('Motion to invoke Art. 4, Sec. 18 and suspend rules pursuant to House');
    expect([o.groups.Yea.length, o.groups.Nay.length, o.groups.Excused.length]).toEqual([88, 1, 11]);
  });

  it('fails closed when a name is lost (a group no longer matches its heading)', () => {
    const items = fx('rollcall-2025-SB0010.340_H').filter((i) => i.str !== 'Lawson');
    expect(readIgaRollCall(items, '2025')).toBeNull();
  });

  it('fails closed when a stray run lands among the names', () => {
    const items = [...fx('rollcall-2025-SB0010.340_H'), { page: 1, x: 468, y: 147.6, w: 30, str: 'Extra' }];
    expect(readIgaRollCall(items, '2025')).toBeNull();
  });
});

describe('render', () => {
  it('round-trips and names no party', () => {
    const t = house();
    const back = parseIgaRollCallRender(t)!;
    expect(back.motion).toBe('SB 10 - Culp - 3rd Reading');
    expect(back.groups.Nay).toHaveLength(26);
    expect(back.groups.Yea).toContain('Smith, H');
    expect(namesParty(t)).toBe(false);
  });
  it('refuses a render whose list disagrees with its count', () => {
    expect(parseIgaRollCallRender(house().replace('Nay (26):', 'Nay (25):'))).toBeNull();
  });
});

describe('canonical line', () => {
  const line = 'Indiana House roll call 340 (2025), SB 10 - Culp - 3rd Reading: Culp voted Yea.';
  it('formats and parses', () => {
    const l = parseIgaRollCallLine(line)!;
    expect(l).toEqual({ chamber: 'House', rollNum: 340, session: '2025', motion: 'SB 10 - Culp - 3rd Reading', name: 'Culp', vote: 'Yea' });
    expect(formatIgaRollCallLine(l)).toBe(line);
    expect(parseIgaRollCallLine('Indiana House roll call 515 (2021), Motion to invoke Art. 4, Sec. 18 and suspend rules pursuant to House: Smith, V voted Yea.'))
      .toMatchObject({ motion: 'Motion to invoke Art. 4, Sec. 18 and suspend rules pursuant to House', name: 'Smith, V' });
  });

  it('verifies the line against the record', () => {
    expect(verifyIgaRollCallLine(line, HOUSE_URL, house(), 'Culp', 'Kendell Culp')).toEqual({ verdict: 'verified', matchOffset: 0 });
  });

  it('refuses a wrong vote, roll, motion or URL', () => {
    const v = (l: string, url = HOUSE_URL) => verifyIgaRollCallLine(l, url, house(), 'Culp', 'Kendell Culp').verdict;
    expect(v(line.replace('voted Yea', 'voted Nay'))).toBe('snippet_not_found');
    expect(v(line.replace('roll call 340', 'roll call 341'))).toBe('snippet_not_found');
    expect(v(line.replace('3rd Reading', '2nd Reading'))).toBe('snippet_not_found');
    expect(v(line, SENATE_URL)).toBe('snippet_not_found');
  });

  it('is name_not_present when the record holds the vote for someone else', () => {
    expect(verifyIgaRollCallLine(line, HOUSE_URL, house(), 'Pressel', 'Jim Pressel').verdict).toBe('name_not_present');
  });
});

describe('printedNameFits', () => {
  it('matches surnames, initials, dotted initials and two-word surnames', () => {
    expect(printedNameFits('Smith, H', 'Smith', 'Hal Smith')).toBe(true);
    expect(printedNameFits('Smith, H', 'Smith', 'Vernon Smith')).toBe(false);
    expect(printedNameFits('Walker K', 'Walker', 'Kyle Walker')).toBe(true);
    expect(printedNameFits('Walker K', 'Walker', 'Greg Walker')).toBe(false);
    expect(printedNameFits('Ford J.D.', 'Ford', 'J.D. Ford')).toBe(true);
    expect(printedNameFits('Dant Chesser', 'Chesser', 'Shane Dant Chesser')).toBe(true);
    expect(printedNameFits('Garcia Wilburn', 'Wilburn', 'Victoria Garcia Wilburn')).toBe(true);
    expect(printedNameFits("O'Brien", "O'Brien", "Tim O'Brien")).toBe(true);
    expect(printedNameFits('Goss-Reaves', 'Goss-Reaves', 'Lori Goss-Reaves')).toBe(true);
  });
  it('never matches the Speaker line', () => {
    expect(printedNameFits('Mr. Speaker', 'Speaker', 'Mr. Speaker')).toBe(false);
  });
});

describe('igaRollCallLinesFor', () => {
  it('builds the line for the person, and none for an absent name', () => {
    expect(igaRollCallLinesFor(SENATE_URL, senate(), 'Alting', 'Ron Alting'))
      .toEqual(['Indiana Senate roll call 66 (2025), SB 10 - Doriot - 3rd Reading: Alting voted Yea.']);
    expect(igaRollCallLinesFor(SENATE_URL, senate(), 'Walker', 'Greg Walker'))
      .toEqual(['Indiana Senate roll call 66 (2025), SB 10 - Doriot - 3rd Reading: Walker G voted Nay.']);
    expect(igaRollCallLinesFor(SENATE_URL, senate(), 'Nobody', 'Ann Nobody')).toEqual([]);
  });
});

describe('verifyEvidence — Indiana roll-call lane end to end', () => {
  it('verifies a canonical line on the roll-call PDF and publishes the line itself', async () => {
    const { verifyEvidence } = await import('./researchVerifier.js');
    const line = 'Indiana House roll call 340 (2025), SB 10 - Culp - 3rd Reading: Culp voted Yea.';
    const result = await verifyEvidence({
      stanceRows: [{ full_name: 'Kendell Culp', politician_id: 'p1', topic_key: 'voting-rights', value: 4, reasoning: 'Voted YES on SB 10 (2025).', source_urls: [HOUSE_URL] }],
      evidenceRows: [{ full_name: 'Kendell Culp', topic_key: 'voting-rights', source_url: HOUSE_URL, snippet: line, snippet_index: 0 }],
      fetcher: async () => ({ ok: true, text: house() }),
      threshold: 1,
      politicianNames: { 'Kendell Culp': { fullName: 'Kendell Culp', lastName: 'Culp' } },
    });
    expect(result.pushable).toHaveLength(1);
    expect(result.pushable[0].verifiedSources[0]).toMatchObject({ url: HOUSE_URL });
  });
});
