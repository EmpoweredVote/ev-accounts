import { describe, expect, it } from 'vitest';
import { formatRollCallLine, isRollCallXmlUrl, parseRollCallLine, verifyRollCallLine } from './rollCallEvidence.js';
import { verifyEvidence, type EvidenceRow, type StanceRow } from './researchVerifier.js';

const URL = 'https://clerk.house.gov/evs/2024/roll345.xml';
// Shaped like the clerk's XML, whitespace collapsed as the fetcher returns it.
const XML = `<?xml version="1.0" encoding="utf-8"?> <rollcall-vote> <vote-metadata> <majority>R</majority>
<congress>118</congress> <rollcall-num>345</rollcall-num> <legis-num>H R 8281</legis-num>
<vote-question>On Passage</vote-question> <action-date>10-Jul-2024</action-date> </vote-metadata> <vote-data>
<recorded-vote> <legislator name-id="G000558" sort-field="Guthrie" unaccented-name="Guthrie" party="R" state="KY" role="legislator">Guthrie</legislator> <vote>Aye</vote> </recorded-vote>
<recorded-vote> <legislator name-id="J000032" sort-field="Jackson (IL)" unaccented-name="Jackson (IL)" party="D" state="IL" role="legislator">Jackson (IL)</legislator> <vote>No</vote> </recorded-vote>
<recorded-vote> <legislator name-id="J000304" sort-field="Jackson (TX)" unaccented-name="Jackson (TX)" party="R" state="TX" role="legislator">Jackson (TX)</legislator> <vote>Aye</vote> </recorded-vote>
</vote-data> </rollcall-vote>`;
const LINE = 'House roll call 345 (2024), H R 8281, On Passage: Guthrie (KY) voted Aye.';

describe('rollCallEvidence', () => {
  it('formats and parses the canonical line, which prints no party', () => {
    const l = parseRollCallLine(LINE)!;
    expect(l).toEqual({ rollNum: 345, year: 2024, legisNum: 'H R 8281', question: 'On Passage', surname: 'Guthrie', state: 'KY', vote: 'Aye' });
    expect(formatRollCallLine(l)).toBe(LINE);
    expect(LINE).not.toMatch(/\b(Republican|Democratic|Independent)\b|\((R|D|I)\)|\bparty\b/i);
  });
  it('recognises House roll-call XML URLs only', () => {
    expect(isRollCallXmlUrl(URL)).toBe(true);
    expect(isRollCallXmlUrl('https://clerk.house.gov/evs/2024/roll345')).toBe(false);
    expect(isRollCallXmlUrl('https://www.govinfo.gov/content/pkg/BILLS-118hr8281eh/html/BILLS-118hr8281eh.htm')).toBe(false);
  });
  it('verifies a line that matches the record field by field', () => {
    expect(verifyRollCallLine(LINE, URL, XML, 'Guthrie').verdict).toBe('verified');
  });
  it('tells two members with one surname apart by state', () => {
    const tx = 'House roll call 345 (2024), H R 8281, On Passage: Jackson (TX) voted Aye.';
    expect(verifyRollCallLine(tx, URL, XML, 'Jackson').verdict).toBe('verified');
    expect(verifyRollCallLine(tx.replace('(TX)', '(IL)'), URL, XML, 'Jackson').verdict).toBe('snippet_not_found');
  });
  it('refuses a wrong vote, bill, question, roll number or year', () => {
    for (const bad of [
      LINE.replace('voted Aye', 'voted No'),
      LINE.replace('H R 8281', 'H R 22'),
      LINE.replace('On Passage', 'On Motion to Recommit'),
      LINE.replace('roll call 345', 'roll call 346'),
      LINE.replace('(2024)', '(2025)'),
    ]) expect(verifyRollCallLine(bad, URL, XML, 'Guthrie').verdict).toBe('snippet_not_found');
  });
  it('matches a roll name the clerk prints with a first name or initial', () => {
    const xml = XML.replace('</vote-data>', '<recorded-vote> <legislator name-id="G000581" sort-field="Gonzalez, Vicente" unaccented-name="Gonzalez, Vicente" party="D" state="TX" role="legislator">Gonzalez, Vicente</legislator> <vote>Aye</vote> </recorded-vote> <recorded-vote> <legislator name-id="G000594" sort-field="Gonzales, Tony" unaccented-name="Gonzales, Tony" party="R" state="TX" role="legislator">Gonzalez, T.</legislator> <vote>No</vote> </recorded-vote> </vote-data>');
    const v = 'House roll call 345 (2024), H R 8281, On Passage: Gonzalez, Vicente (TX) voted Aye.';
    expect(verifyRollCallLine(v, URL, xml, 'Gonzalez', 'Vicente Gonzalez').verdict).toBe('verified');
    expect(verifyRollCallLine(v, URL, xml, 'Gonzalez', 'Tony Gonzalez').verdict).toBe('name_not_present');
    const t = 'House roll call 345 (2024), H R 8281, On Passage: Gonzalez, T. (TX) voted No.';
    expect(verifyRollCallLine(t, URL, xml, 'Gonzalez', 'Tony Gonzalez').verdict).toBe('verified');
    expect(verifyRollCallLine(t, URL, xml, 'Gonzalez', 'Vicente Gonzalez').verdict).toBe('name_not_present');
  });
  it("refuses a line about someone else's surname", () => {
    expect(verifyRollCallLine(LINE, URL, XML, 'Barr').verdict).toBe('name_not_present');
  });
  it('verifyEvidence verifies the line on the roll-call page and publishes the line itself', async () => {
    const stance: StanceRow = { full_name: 'Brett Guthrie', politician_id: 'p1', topic_key: 'voting-rights', value: 5,
      reasoning: 'Yea on H.R. 8281 (2024).', source_urls: [URL], evidence_type: 'record' };
    const ev: EvidenceRow = { full_name: 'Brett Guthrie', topic_key: 'voting-rights', source_url: URL, snippet: LINE, snippet_index: 1 };
    const r = await verifyEvidence({
      stanceRows: [stance], evidenceRows: [ev], threshold: 1,
      fetcher: async () => ({ ok: true, text: XML }),
      politicianNames: { 'Brett Guthrie': { fullName: 'Brett Guthrie', lastName: 'Guthrie' } },
    });
    expect(r.pushable).toHaveLength(1);
    expect(r.pushable[0].verifiedSources[0].snippets[0].matchedSpan).toBe(LINE);
  });
});
