import { describe, it, expect } from 'vitest';
import {
  isActionAgendaUrl,
  parseActionAgendaLine,
  formatActionAgendaLine,
  verifyActionAgendaLine,
} from './actionAgendaEvidence.js';
import { verifyEvidence, type EvidenceRow, type StanceRow } from './researchVerifier.js';

const URL_2022 =
  'https://broward.legistar1.com/broward/meetings/2022/10/1115_M_County_Commission_22-10-25_Action_Agenda.pdf';

/**
 * Trimmed verbatim from the Broward County Commission Action Agenda for 25 October 2022
 * (the document Legistar links as that event's EventMinutesFile). The shape is what matters:
 * members are named ONCE in the attendance block, and each item records a bare tally plus
 * sentences naming only the exceptions.
 */
const PAGE = `
County Commission            Action Agenda - Published            October 25, 2022

                      Present: Vice-Mayor Lamar P. Fisher
                                   Commissioner Beam Furr
                                   Commissioner Steve Geller
                                   Commissioner Nan H. Rich
                                   Commissioner Tim Ryan
                                   Commissioner Jared E. Moskowitz
                                   Mayor Michael Udine

                      Absent: Commissioner Mark D. Bogen
                                   Commissioner Dale V.C. Holness

                                        CONSENT AGENDA

A motion was made by Commissioner Geller, seconded by Commissioner Rich and unanimously
carried, to approve the Consent Agenda consisting of Items 1 through 45.

48.    MOTION TO ADOPT Resolution amending Article 1.1 of the Administrative Rules Document:
       BrowardNext regarding amendments to the Environmentally Sensitive Lands Map of the
       Broward County Land Use Plan; and providing for severability and an effective date.

       ACTION: (T-12:05 PM) Approved Resolution No. 2022-509. (Refer to minutes for full
       discussion.)

       VOTE: 6-0. Commissioner Moskowitz was not present during the vote. Commissioner
       Bogen was not present.

49.    MOTION TO ENACT Ordinance, the title of which is as follows: AN ORDINANCE OF THE BOARD
       OF COUNTY COMMISSIONERS OF BROWARD COUNTY, FLORIDA, PERTAINING TO THE LIVING WAGE;
       INCREASING THE LIVING WAGE AND REQUIRING PAID TIME OFF.

       ACTION: (T-10:26 AM) Filed proof of publication and enacted Ordinance No. 2022-41 to
       become effective as provided by law. (Refer to minutes for full discussion.)

       VOTE: 7-0. Commissioner Bogen was not present.

50.    MOTION TO APPROVE a contested procurement award for janitorial services.

       ACTION: (T-2:14 PM) Approved. (Refer to minutes for full discussion.)

       VOTE: 5-2. Commissioner Furr voted no. Commissioner Geller voted no. Commissioner
       Bogen was not present.

51.    MOTION TO WITHDRAW the proposed naming rights agreement for the regional park.

       ACTION: (T-2:40 PM) Withdrawn at the request of the County Administrator.

52.    MOTION TO APPROVE the consent appointment of a seat on the Marine Advisory Committee.

       ACTION: (T-2:44 PM) Approved Resolution No. 2022-611.

       VOTE: 7-0. Commissioner Bogen was not present.
`;

const LIVING_WAGE_LINE =
  'Action agenda 2022-10-25, Ordinance No. 2022-41: Lamar P. Fisher was recorded Present and the vote was 7-0.';

describe('isActionAgendaUrl', () => {
  it('accepts a Legistar action-agenda PDF', () => {
    expect(isActionAgendaUrl(URL_2022)).toBe(true);
  });

  it('rejects the meeting AGENDA, which records no votes at all', () => {
    expect(isActionAgendaUrl(
      'https://broward.legistar1.com/broward/meetings/2022/10/1115_A_County_Commission_22-10-25_Regular_Meeting_Agenda.pdf',
    )).toBe(false);
  });

  // 🔴 Legistar does NOT zero-pad the month in the path: September 2024 is `/2024/9/`, not
  // `/2024/09/`. Found on the real Broward agendas for 2024-09-05 and 2023-03-14.
  it('accepts a single-digit month, which Legistar does not zero-pad', () => {
    expect(isActionAgendaUrl(
      'https://broward.legistar1.com/broward/meetings/2024/9/1155_M_County_Commission_24-09-05_Action_Agenda.pdf',
    )).toBe(true);
  });

  it('rejects a non-Legistar host', () => {
    expect(isActionAgendaUrl('https://example.com/meetings/2022/10/action_agenda.pdf')).toBe(false);
  });
});

describe('parseActionAgendaLine', () => {
  it('round-trips the canonical line', () => {
    const parsed = parseActionAgendaLine(LIVING_WAGE_LINE);
    expect(parsed).toEqual({
      date: '2022-10-25',
      anchor: 'Ordinance No. 2022-41',
      name: 'Lamar P. Fisher',
      yeas: 7,
      nays: 0,
    });
    expect(formatActionAgendaLine(parsed!)).toBe(LIVING_WAGE_LINE);
  });

  it('returns null for prose that is not the canonical line', () => {
    expect(parseActionAgendaLine('Fisher voted for the living wage ordinance.')).toBeNull();
  });
});

describe('verifyActionAgendaLine', () => {
  it('verifies a member listed Present on a unanimous item', () => {
    const v = verifyActionAgendaLine(LIVING_WAGE_LINE, URL_2022, PAGE, 'Fisher', 'Lamar Fisher');
    expect(v.verdict).toBe('verified');
  });

  it('verifies every other member the same tally carries', () => {
    for (const [printed, last, full] of [
      ['Beam Furr', 'Furr', 'Quentin "Beam" Furr'],
      ['Steve Geller', 'Geller', 'Steven Anthony Geller'],
      ['Nan H. Rich', 'Rich', 'Nan H. Rich'],
      ['Michael Udine', 'Udine', 'Michael I. Udine'],
    ]) {
      const line = `Action agenda 2022-10-25, Ordinance No. 2022-41: ${printed} was recorded Present and the vote was 7-0.`;
      expect(verifyActionAgendaLine(line, URL_2022, PAGE, last, full).verdict).toBe('verified');
    }
  });

  it('refuses a member recorded Absent, however the line is written', () => {
    const line = 'Action agenda 2022-10-25, Ordinance No. 2022-41: Mark D. Bogen was recorded Present and the vote was 7-0.';
    expect(verifyActionAgendaLine(line, URL_2022, PAGE, 'Bogen', 'Mark D. Bogen').verdict)
      .toBe('name_not_present');
  });

  it('refuses a split vote — the tally does not say who was on which side', () => {
    const line = 'Action agenda 2022-10-25, a contested procurement award for janitorial services: Nan H. Rich was recorded Present and the vote was 5-2.';
    expect(verifyActionAgendaLine(line, URL_2022, PAGE, 'Rich', 'Nan H. Rich').verdict)
      .toBe('snippet_not_found');
  });

  it('refuses a member named as an exception at that item', () => {
    const line = 'Action agenda 2022-10-25, Resolution No. 2022-509: Jared E. Moskowitz was recorded Present and the vote was 6-0.';
    expect(verifyActionAgendaLine(line, URL_2022, PAGE, 'Moskowitz', 'Jared E. Moskowitz').verdict)
      .toBe('name_not_present');
  });

  it('still verifies the members the excepted item does carry', () => {
    const line = 'Action agenda 2022-10-25, Resolution No. 2022-509: Beam Furr was recorded Present and the vote was 6-0.';
    expect(verifyActionAgendaLine(line, URL_2022, PAGE, 'Furr', 'Quentin "Beam" Furr').verdict)
      .toBe('verified');
  });

  it('refuses when the line\'s tally disagrees with the page', () => {
    const line = 'Action agenda 2022-10-25, Ordinance No. 2022-41: Lamar P. Fisher was recorded Present and the vote was 9-0.';
    expect(verifyActionAgendaLine(line, URL_2022, PAGE, 'Fisher', 'Lamar Fisher').verdict)
      .toBe('snippet_not_found');
  });

  it('refuses when the anchor is not on the page', () => {
    const line = 'Action agenda 2022-10-25, Ordinance No. 2099-99: Lamar P. Fisher was recorded Present and the vote was 7-0.';
    expect(verifyActionAgendaLine(line, URL_2022, PAGE, 'Fisher', 'Lamar Fisher').verdict)
      .toBe('snippet_not_found');
  });

  it('refuses when the line names someone who is not this politician', () => {
    const v = verifyActionAgendaLine(LIVING_WAGE_LINE, URL_2022, PAGE, 'Geller', 'Steven Anthony Geller');
    expect(v.verdict).toBe('name_not_present');
  });

  it('matches the line date against an unpadded month', () => {
    const url = 'https://broward.legistar1.com/broward/meetings/2022/9/1115_M_County_Commission_22-09-25_Action_Agenda.pdf';
    const line = 'Action agenda 2022-09-25, Ordinance No. 2022-41: Lamar P. Fisher was recorded Present and the vote was 7-0.';
    expect(verifyActionAgendaLine(line, url, PAGE, 'Fisher', 'Lamar Fisher').verdict).toBe('verified');
  });

  it('refuses when the URL date does not match the line date', () => {
    const other = 'https://broward.legistar1.com/broward/meetings/2023/02/1200_M_County_Commission_23-02-21_Action_Agenda.pdf';
    expect(verifyActionAgendaLine(LIVING_WAGE_LINE, other, PAGE, 'Fisher', 'Lamar Fisher').verdict)
      .toBe('snippet_not_found');
  });

  // 🔑 THE SAFETY INVARIANT. The attendance block is parsed heuristically, so the rule only
  // attributes a vote when the document's OWN numbers reconcile: everyone listed Present, minus
  // those excepted at this item, must equal the Yea count. A parser that reads the roster wrong
  // breaks the arithmetic and the row is refused — it can never invent a voter.
  it('refuses when Present minus exceptions does not equal the Yea count', () => {
    const doctored = PAGE.replace('VOTE: 7-0. Commissioner Bogen was not present.', 'VOTE: 4-0.');
    const line = 'Action agenda 2022-10-25, Ordinance No. 2022-41: Lamar P. Fisher was recorded Present and the vote was 4-0.';
    expect(verifyActionAgendaLine(line, URL_2022, doctored, 'Fisher', 'Lamar Fisher').verdict)
      .toBe('snippet_not_found');
  });

  // The Absent block is not merely "a member the item happens to mention". A second absentee, whom
  // this item never names, must still be refused — otherwise the arithmetic alone would carry them,
  // since subtracting nobody still reconciles 7 Present against a 7-0 tally.
  it('refuses a member recorded Absent whom the item never mentions', () => {
    const line = 'Action agenda 2022-10-25, Ordinance No. 2022-41: Dale V.C. Holness was recorded Present and the vote was 7-0.';
    expect(verifyActionAgendaLine(line, URL_2022, PAGE, 'Holness', 'Dale V.C. Holness').verdict)
      .toBe('name_not_present');
  });

  // An item that carries no VOTE clause of its own must never borrow the next item's. Item 51 was
  // withdrawn; the next tally on the page belongs to item 52.
  it('refuses an item whose own VOTE clause is missing', () => {
    const line = 'Action agenda 2022-10-25, the proposed naming rights agreement for the regional park: Lamar P. Fisher was recorded Present and the vote was 7-0.';
    expect(verifyActionAgendaLine(line, URL_2022, PAGE, 'Fisher', 'Lamar Fisher').verdict)
      .toBe('snippet_not_found');
  });

  // 🔑 The two layouts are told apart by whether a title-led run ABUTS the label. A clerk who
  // mentions a member in the header before a `Present: <names>` block must not have that mention
  // mistaken for the roster — the run has to touch the label to count as the list in front of it.
  it('is not fooled by a title mentioned earlier in a label-leads-list page', () => {
    const page = PAGE.replace(
      '                      Present: Vice-Mayor',
      'Proclamation presented by Commissioner Udine. Meeting convened at 10:12 a.m. and adjourned '
      + 'at 1:09 p.m. Present: Vice-Mayor',
    );
    expect(verifyActionAgendaLine(LIVING_WAGE_LINE, URL_2022, page, 'Fisher', 'Lamar Fisher').verdict)
      .toBe('verified');
  });

  it('refuses a page with no attendance block at all', () => {
    const noRoster = PAGE.replace(/ *Present:[\s\S]*?Absent: Commissioner Mark D\. Bogen/, '');
    expect(verifyActionAgendaLine(LIVING_WAGE_LINE, URL_2022, noRoster, 'Fisher', 'Lamar Fisher').verdict)
      .toBe('name_not_present');
  });
});

describe('verifyEvidence — the action-agenda lane end to end', () => {
  const stanceFor = (): StanceRow => ({
    full_name: 'Lamar Fisher',
    politician_id: 'p-fisher',
    topic_key: 'minimum-wage',
    value: 1,
    reasoning: 'Enacted Ordinance No. 2022-41, raising the county living wage and indexing it annually to CPI-U.',
    source_urls: [URL_2022],
    evidence_type: 'record',
  });

  it('verifies the canonical line and publishes the line itself as the span', async () => {
    const ev: EvidenceRow = {
      full_name: 'Lamar Fisher', topic_key: 'minimum-wage',
      source_url: URL_2022, snippet: LIVING_WAGE_LINE, snippet_index: 1,
    };
    const r = await verifyEvidence({
      stanceRows: [stanceFor()], evidenceRows: [ev], threshold: 1,
      fetcher: async () => ({ ok: true, text: PAGE }),
      politicianNames: { 'Lamar Fisher': { fullName: 'Lamar Fisher', lastName: 'Fisher' } },
    });
    expect(r.pushable).toHaveLength(1);
    expect(r.pushable[0].verifiedSources[0].snippets[0].matchedSpan).toBe(LIVING_WAGE_LINE);
  });

  it('does not push a split-vote line through the lane', async () => {
    const line = 'Action agenda 2022-10-25, a contested procurement award for janitorial services: Lamar P. Fisher was recorded Present and the vote was 5-2.';
    const ev: EvidenceRow = {
      full_name: 'Lamar Fisher', topic_key: 'minimum-wage',
      source_url: URL_2022, snippet: line, snippet_index: 1,
    };
    const r = await verifyEvidence({
      stanceRows: [stanceFor()], evidenceRows: [ev], threshold: 1,
      fetcher: async () => ({ ok: true, text: PAGE }),
      politicianNames: { 'Lamar Fisher': { fullName: 'Lamar Fisher', lastName: 'Fisher' } },
    });
    expect(r.pushable).toHaveLength(0);
    expect(r.needsReResearch).toHaveLength(1);
  });
});

/**
 * 🔴 THE LAYOUT THE VERIFIER ACTUALLY SEES. `pdftotext -layout` prints the attendance table as
 * `Present: <names> Absent: <names>`, but the pipeline's own extractPdfText walks the PDF's text
 * runs and emits the two-column table as `<names> Present: <names> Absent:` — the LABEL TRAILS ITS
 * LIST. Both excerpts below are the real renders, fetched through fetchForVerification.
 */
const PAGE_EXTRACTED = 'County Commission Action Agenda - Published October 25, 2022 MEETING OF OCTOBER 25, 2022 '
  + '(Meeting convened at 10:05 a.m. and adjourned at 12:35 p.m.) PLEDGE OF ALLEGIANCE was led by '
  + 'Commissioner Beam Furr, District 6 . CALL TO ORDER was led by Mayor Michael Udine, District 3 . '
  + 'MOMENT OF SILENCE In honor of our past and present brave men and women of the United States Armed '
  + 'Forces , who have served our country and continue to serve our country , at home and abroad . '
  + 'Vice-Mayor Lamar P. Fisher Commissioner Beam Furr Commissioner Steve Geller Commissioner Nan H. Rich '
  + 'Commissioner Tim Ryan Commissioner Jared E. Moskowitz Mayor Michael Udine Present: '
  + 'Commissioner Mark D. Bogen Absent: CONSENT AGENDA A motion was made by Commissioner Geller, '
  + 'seconded by Commissioner Rich and unanimously carried, to approve the Consent Agenda. '
  + '48. MOTION TO ADOPT Resolution amending Article 1.1 of the Administrative Rules Document. '
  + 'ACTION: (T-12:05 PM) Approved Resolution No. 2022-509. (Refer to minutes for full discussion.) '
  + 'VOTE: 6-0. Commissioner Moskowitz was not present during the vote. Commissioner Bogen was not present. '
  + '49. MOTION TO ENACT Ordinance, PERTAINING TO THE LIVING WAGE; INCREASING THE LIVING WAGE AND '
  + 'REQUIRING PAID TIME OFF. (Sponsored by the Board of County Commissioners) ACTION: (T-10:26 AM) '
  + 'Filed proof of publication and enacted Ordinance No. 2022-41 to become effective as provided by law. '
  + '(Refer to minutes for full discussion.) VOTE: 7-0. Commissioner Bogen was not present. END PUBLIC HEARING';

const URL_2026 =
  'https://broward.legistar1.com/broward/meetings/2026/10/1205_M_County_Commission_26-10-20_Action_Agenda.pdf';
/** The same layout with NO Absent block at all — the run simply ends at the label. */
const PAGE_2026 = 'County Commission Action Agenda - Published October 20, 2026 MEETING OF OCTOBER 20, 2026 '
  + 'Domestic Violence Awareness Month Proclamation presented by Commissioner Udine. '
  + 'Meeting convened at 10:12 a.m. and adjourned at 1:09 p.m. '
  + 'Mayor Mark D. Bogen Commissioner Lamar P. Fisher Commissioner Beam Furr Commissioner Steve Geller '
  + 'Vice-Mayor Robert McKinzie Commissioner Nan H. Rich Commissioner Hazelle P. Rogers '
  + 'Commissioner Alexandra P. Davis Commissioner Michael Udine Present: CALL TO ORDER Call to order was '
  + 'led by Mayor Mark Bogen, District 2. CONSENT AGENDA '
  + '2. MOTION TO APPROVE Terminal Building Lease Agreement with Breeze Aviation Group, Inc. '
  + 'ACTION: (T-10:29 AM) Approved. VOTE: 9-0. '
  + '7. MOTION TO APPROVE Sixth Amendment to the Agreement with WSP USA, Inc. for Transit Systemwide Study. '
  + 'ACTION: (T-10:31 AM) Approved. (Refer to minutes for full discussion.) '
  + 'VOTE: 8-0. Commissioner Rich abstained from voting. '
  + '45. MOTION TO ENACT Ordinance pertaining to qualified vendor lists established as CBE reserves. '
  + 'ACTION: (T-10:32 AM) Approved Resolution No. 2026-406. (Refer to minutes for full discussion.) '
  + 'VOTE: 8-1. Commissioner Furr voted no.';

describe('verifyActionAgendaLine — the label-trails-its-list layout the pipeline renders', () => {
  it('verifies every member of a unanimous item', () => {
    for (const [printed, last] of [
      ['Lamar P. Fisher', 'Fisher'], ['Beam Furr', 'Furr'], ['Steve Geller', 'Geller'],
      ['Nan H. Rich', 'Rich'], ['Michael Udine', 'Udine'],
    ]) {
      const line = `Action agenda 2022-10-25, Ordinance No. 2022-41: ${printed} was recorded Present and the vote was 7-0.`;
      expect(verifyActionAgendaLine(line, URL_2022, PAGE_EXTRACTED, last, printed).verdict)
        .toBe('verified');
    }
  });

  it('refuses the absentee, who sits between the two trailing labels', () => {
    const line = 'Action agenda 2022-10-25, Ordinance No. 2022-41: Mark D. Bogen was recorded Present and the vote was 7-0.';
    expect(verifyActionAgendaLine(line, URL_2022, PAGE_EXTRACTED, 'Bogen', 'Mark D. Bogen').verdict)
      .toBe('name_not_present');
  });

  it('reconciles an item that excepts a member who IS on the roster', () => {
    const base = 'Action agenda 2022-10-25, Resolution No. 2022-509: ';
    expect(verifyActionAgendaLine(`${base}Beam Furr was recorded Present and the vote was 6-0.`,
      URL_2022, PAGE_EXTRACTED, 'Furr', 'Beam Furr').verdict).toBe('verified');
    expect(verifyActionAgendaLine(`${base}Jared E. Moskowitz was recorded Present and the vote was 6-0.`,
      URL_2022, PAGE_EXTRACTED, 'Moskowitz', 'Jared E. Moskowitz').verdict).toBe('name_not_present');
  });

  it('handles a roster with no Absent block at all', () => {
    const line = 'Action agenda 2026-10-20, Terminal Building Lease Agreement with Breeze Aviation Group: Hazelle P. Rogers was recorded Present and the vote was 9-0.';
    expect(verifyActionAgendaLine(line, URL_2026, PAGE_2026, 'Rogers', 'Hazelle P. Rogers').verdict)
      .toBe('verified');
  });

  it('carries the other eight past an abstention and refuses the abstainer', () => {
    const base = 'Action agenda 2026-10-20, Sixth Amendment to the Agreement with WSP USA, Inc.: ';
    expect(verifyActionAgendaLine(`${base}Beam Furr was recorded Present and the vote was 8-0.`,
      URL_2026, PAGE_2026, 'Furr', 'Beam Furr').verdict).toBe('verified');
    expect(verifyActionAgendaLine(`${base}Nan H. Rich was recorded Present and the vote was 8-0.`,
      URL_2026, PAGE_2026, 'Rich', 'Nan H. Rich').verdict).toBe('name_not_present');
  });

  it('still refuses a split vote in this layout', () => {
    const line = 'Action agenda 2026-10-20, Resolution No. 2026-406: Steve Geller was recorded Present and the vote was 8-1.';
    expect(verifyActionAgendaLine(line, URL_2026, PAGE_2026, 'Geller', 'Steve Geller').verdict)
      .toBe('snippet_not_found');
  });
});
