import { describe, it, expect } from 'vitest';
import {
  parseVotingOfficeHolders,
  parseVotingRecord,
  splitActionLine,
} from '../miamidade-voting-record.mjs';

// Every fixture is real markup from the Miami-Dade Voting Record report, read on
// 2026-09-07. The fetching half needs the network; this half decides whose vote
// it is and what the vote was, so this is the half worth pinning.

describe('parseVotingOfficeHolders', () => {
  // 🔴 The voting-record form uses BARE NUMBERS. Sponsor.asp uses B-prefixed
  // codes for the same people, and passing the wrong format returns a clean
  // empty report rather than an error.
  const html = `
    <select name="OfficeHolders">
      <option value="688"></option>
      <option value="775">Marleine Bastien</option>
      <option value="743">Danielle Cohen Higgins</option>
      <option value="744">Raquel A. Regalado</option>
      <option value="779">Raquel A. Regalado</option>
    </select>`;

  it('reads bare numeric codes, not the sponsor report B-prefixed ones', () => {
    const h = parseVotingOfficeHolders(html);
    expect(h.find((x) => x.name === 'Marleine Bastien')?.code).toBe('775');
    expect(h.every((x) => /^\d+$/.test(x.code))).toBe(true);
  });

  it('still surfaces both of Regalado codes', () => {
    const codes = parseVotingOfficeHolders(html)
      .filter((x) => x.name === 'Raquel A. Regalado').map((x) => x.code).sort();
    expect(codes).toEqual(['744', '779']);
  });

  it('drops the blank option rather than inventing a person', () => {
    expect(parseVotingOfficeHolders(html).some((x) => !x.name)).toBe(false);
  });

  it('throws rather than return nothing if the form changes', () => {
    expect(() => parseVotingOfficeHolders('<html>nope</html>')).toThrow(/voting-record form changed/);
  });
});

describe('splitActionLine', () => {
  it('splits the run-together date, body and action', () => {
    const r = splitActionLine('4/23/2026BCC - Comprehensive Development Master Plan &amp; ZoningAdopted');
    expect(r.date).toBe('4/23/2026');
    expect(r.body).toBe('BCC - Comprehensive Development Master Plan & Zoning');
    expect(r.action).toBe('Adopted');
  });

  it('prefers the longest action so "Adopted as amended" beats "Adopted"', () => {
    expect(splitActionLine('1/1/2026Housing CommitteeAdopted as amended').action).toBe('Adopted as amended');
    expect(splitActionLine('1/1/2026Housing CommitteeApproved with conditions').action).toBe('Approved with conditions');
  });

  it('🔴 recognises the phrase that was 102 of the first run 120 unlabelled actions', () => {
    const r = splitActionLine('12/18/2025BCC - Comprehensive Development Master Plan &amp; ZoningApproved staff recommendation');
    expect(r.action).toBe('Approved staff recommendation');
  });

  it('recognises the two denial phrasings that do not end in "Denied"', () => {
    expect(splitActionLine('1/1/2026BCC - CDMP &amp; ZoningDenied without prejudice').action).toBe('Denied without prejudice');
    expect(splitActionLine('1/1/2026BCC - CDMP &amp; ZoningMotion to deny').action).toBe('Motion to deny');
  });

  it('🔴 leaves an unknown action NULL and keeps the raw text, rather than guessing', () => {
    // A mis-split action would misreport how somebody voted.
    const r = splitActionLine('3/3/2026Some CommitteeSomething Nobody Has Seen');
    expect(r.action).toBeNull();
    expect(r.body).toBeNull();
    expect(r.action_raw).toBe('Some CommitteeSomething Nobody Has Seen');
  });
});

describe('parseVotingRecord', () => {
  // Two real entries, trimmed. The first is a zoning public hearing, the second
  // a CDMP disposition ordinance.
  const REAL = `
<tr VALIGN="top">
<td ALIGN="left" valign="top" bgcolor="FFFFFF" width="20" ><b><a href="matter.asp?matter=231439">231439</a></b></td>
<td ALIGN="left" valign="top" bgcolor="FFFFFF" width="300"><b>PH NO. Z2022000221</b></td>
<td ALIGN="left" valign="top" bgcolor="FFFFFF" width="20"><b>Zoning</b></td>
</tr>
<tr VALIGN="top">
<td ALIGN="left" valign="top" bgcolor="FFFFFF" width="20" >Z-1-25</td>
<td ALIGN="left" colspan="4" valign="top" bgcolor="FFFFFF">PH NO: Z2022000221  --  DISTRICT(S): 08  --  APPLICANT: ARCHIMEDES XXII, LLC.</td>
</tr>
<tr VALIGN="top">
<td> </td>
<td ALIGN="left" valign="top" bgcolor="FFFFFF" width="300">1/30/2025BCC - Comprehensive Development Master Plan &amp; ZoningApproved with conditions</td>
<td ALIGN="right" valign="top" bgcolor="FFFFFF" width="5">VOTED:Yes</td>
</tr>
<tr VALIGN="top">
<td ALIGN="left" valign="top" bgcolor="white" width="20" ><b><a href="matter.asp?matter=232066">232066</a></b></td>
<td ALIGN="left" valign="top" bgcolor="white" width="300"><b>OCLA, LLC</b></td>
<td ALIGN="left" valign="top" bgcolor="white" width="20"><b>Ordinance</b></td>
</tr>
<tr VALIGN="top">
<td ALIGN="left" valign="top" bgcolor="white" width="20" >26-22</td>
<td ALIGN="left" colspan="4" valign="top" bgcolor="white">ORDINANCE RELATING TO MIAMI-DADE COUNTY COMPREHENSIVE DEVELOPMENT MASTER PLAN; PROVIDING DISPOSITION OF APPLICATION NO. CDMP20230018, FILED BY OCLA, LLC, IN THE MAY 2023 CYCLE TO AMEND THE COUNTY'S COMPREHENSIVE DEVELOPMENT MASTER PLAN</td>
</tr>
<tr VALIGN="top">
<td> </td>
<td ALIGN="left" valign="top" bgcolor="white" width="300">4/23/2026BCC - Comprehensive Development Master Plan &amp; ZoningAdopted</td>
<td ALIGN="right" valign="top" bgcolor="white" width="5">VOTED:No</td>
</tr>`;

  const items = parseVotingRecord(REAL);

  it('splits the flat table into one record per matter', () => {
    expect(items).toHaveLength(2);
    expect(items.map((i) => i.matter_id)).toEqual(['231439', '232066']);
  });

  it('reads the enacted number, the voting type and the subject', () => {
    expect(items[0].voting_type).toBe('Zoning');
    expect(items[0].enacted_number).toBe('Z-1-25');
    expect(items[1].voting_type).toBe('Ordinance');
    expect(items[1].enacted_number).toBe('26-22');
    expect(items[1].subject).toBe('OCLA, LLC');
  });

  it('attaches THIS member vote, with its date, body and action', () => {
    expect(items[0].actions).toEqual([{
      date: '1/30/2025',
      body: 'BCC - Comprehensive Development Master Plan & Zoning',
      action: 'Approved with conditions',
      action_raw: 'BCC - Comprehensive Development Master Plan & ZoningApproved with conditions',
      voted: 'Yes',
    }]);
    expect(items[1].actions[0].voted).toBe('No');
  });

  it('🔴 flags a land-use disposition as direction-unread', () => {
    // "Adopted" + "Voted: Yes" on an ordinance PROVIDING DISPOSITION OF an
    // application may be a vote to DENY the development. The action and the vote
    // together do not say which way it went; only the ordinance does.
    expect(items[1].direction_is_unread).toBe(true);
    expect(items[0].direction_is_unread).toBe(true); // PH NO: zoning hearing
  });

  it('does not flag an ordinary matter as direction-unread', () => {
    const plain = parseVotingRecord(REAL.replace(
      /ORDINANCE RELATING TO[\s\S]*?MASTER PLAN(?=<\/td>)/,
      'RESOLUTION ACCEPTING A GRANT FOR LIBRARY BOOKS'));
    expect(plain[1].direction_is_unread).toBe(false);
  });

  it('builds a citable per-matter source URL', () => {
    expect(items[0].source_url).toBe('https://www.miamidade.gov/govaction/matter.asp?matter=231439');
  });
});
