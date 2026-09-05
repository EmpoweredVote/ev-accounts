import { describe, it, expect } from 'vitest';
import {
  normalizeName,
  parseOfficeHolders,
  parseSponsorReport,
  resolveCodes,
} from '../miamidade-sponsorship-leads.mjs';
import { matchLocalTopics } from './topic-lead-patterns.mjs';

// The fetching half needs the network and a database. This half needs neither,
// and it is the half that decides WHO a record belongs to and WHAT it is about
// — so it is the half worth pinning.
//
// Every fixture below is REAL markup or a real name, taken from the Miami-Dade
// Legislative Information Center on 2026-09-05.

describe('normalizeName', () => {
  it('matches the county list to our roster across the four real differences', () => {
    // Each of these pairs is a live mismatch between essentials.politicians and
    // the county's OfficeHolders select. All four broke a naive equality check.
    expect(normalizeName('René Garcia')).toBe(normalizeName('Sen. Rene Garcia'));
    expect(normalizeName('Oliver Gilbert')).not.toBe(normalizeName('Oliver G. Gilbert, III'));
    expect(normalizeName('Juan Carlos "JC" Bermudez')).toBe(normalizeName('Juan Carlos Bermudez'));
    expect(normalizeName('Danielle Cohen Higgins')).not.toBe(normalizeName('Eileen Higgins'));
  });

  it('DELETES combining marks rather than spacing them', () => {
    // A space here would make "Ren e Garcia" and silently fail every comparison.
    expect(normalizeName('René')).toBe('rene');
    expect(normalizeName('José')).toBe('jose');
  });

  it('keeps two different people apart', () => {
    // Both are real, both sat on this commission, and both end in "Higgins".
    expect(normalizeName('Eileen Higgins')).not.toBe(normalizeName('Danielle Cohen Higgins'));
  });
});

describe('parseOfficeHolders', () => {
  const html = `
    <select name="OfficeHolders">
      <option value="B742">Keon Hardemon</option>
      <option value="B744">Raquel A. Regalado</option>
      <option value="B779">Raquel A. Regalado</option>
      <option value="B740">Sen. Rene Garcia</option>
      <option value="AllHolders">All Office Holders</option>
    </select>`;

  it('keeps BOTH codes for a name that appears twice', () => {
    // 🔴 Regalado really is listed as B744 AND B779. Taking the first match
    // silently drops half her record, and nothing downstream would notice.
    const holders = parseOfficeHolders(html);
    const regalado = holders.filter((h) => normalizeName(h.name) === normalizeName('Raquel A. Regalado'));
    expect(regalado.map((h) => h.code).sort()).toEqual(['B744', 'B779']);
  });

  it('drops non-person options', () => {
    expect(parseOfficeHolders(html).map((h) => h.code)).not.toContain('AllHolders');
  });

  it('refuses silently returning nothing when the form changes', () => {
    expect(() => parseOfficeHolders('<html>no select here</html>')).toThrow(/OfficeHolders select not found/);
  });
});

describe('resolveCodes', () => {
  // The real list, as the county serves it.
  const HOLDERS = [
    { code: 'B741', name: 'Oliver G. Gilbert, III' },
    { code: 'B744', name: 'Raquel A. Regalado' },
    { code: 'B779', name: 'Raquel A. Regalado' },
    { code: 'B743', name: 'Danielle Cohen Higgins' },
    { code: 'B699', name: 'Eileen Higgins' },
    { code: 'B740', name: 'Sen. Rene Garcia' },
    { code: 'B742', name: 'Keon Hardemon' },
  ];

  it('returns EVERY code for a name listed twice', () => {
    const r = resolveCodes('Raquel A. Regalado', HOLDERS);
    expect(r.match).toBe('exact');
    expect(r.codes.map((c) => c.code).sort()).toEqual(['B744', 'B779']);
  });

  it('recovers a sitting commissioner from a middle initial, and says it was fuzzy', () => {
    // Our roster says "Oliver Gilbert"; the county says "Oliver G. Gilbert, III".
    // Exact-only matching stranded a seated commissioner on the first real run.
    const r = resolveCodes('Oliver Gilbert', HOLDERS);
    expect(r.match).toBe('fuzzy');
    expect(r.codes.map((c) => c.code)).toEqual(['B741']);
  });

  it('folds the honorific and the accent in one step', () => {
    const r = resolveCodes('René Garcia', HOLDERS);
    expect(r.match).toBe('exact');
    expect(r.codes.map((c) => c.code)).toEqual(['B740']);
  });

  it('prefers an exact match over a fuzzy one', () => {
    const r = resolveCodes('Keon Hardemon', HOLDERS);
    expect(r.match).toBe('exact');
  });

  it('🔴 refuses rather than collapse two real people who share a surname', () => {
    // Both Higginses sat on this commission. A first+last fallback that accepted
    // "Higgins" would seat one person's record on the other.
    const r = resolveCodes('Cohen Higgins', HOLDERS);
    expect(r.codes).toEqual([]);
    expect(r.match).toBe('none');
  });

  it('reports a miss instead of guessing the nearest name', () => {
    const r = resolveCodes('Someone Not Listed', HOLDERS);
    expect(r.codes).toEqual([]);
    expect(r.match).toBe('none');
  });
});

describe('parseSponsorReport', () => {
  // Verbatim from Hardemon's report, including the upstream U+FFFD corruption
  // and the "No sponsor" annotation. Trimmed only of routing rows.
  const REAL = `
<tr VALIGN="top">
 <td ALIGN="left" valign="top" bgcolor="FFFFFF" width="8" rowspan="1"><font SIZE="2" FACE="Arial"><b>Resolution</b>&nbsp;&nbsp;<a href="matter.asp?matter=261553"><b>261553</b></a></font></td>
 <td ALIGN="left" colspan="3" valign="top" bgcolor="FFFFFF" width="360"><font SIZE="2" FACE="Arial"><b>DECLARATION OF RESTRICTIVE COVENANTS FOR ARSHT</B>&nbsp;&nbsp;</font></td>
 <td ALIGN="left" colspan="2" valign="top" bgcolor="FFFFFF" width="239"><font SIZE="2" FACE="Arial"><b>Status:</b>&nbsp;&nbsp;&nbsp;In Committee&nbsp;</font></td>
</tr>
 <tr VALIGN="top">
 <td ALIGN="left" valign="top" bgcolor="FFFFFF" width="110"><font SIZE="2" FACE="Arial">Agenda Date:<br>10/6/2026<br></b>8C</b></font></td>
 <td ALIGN="left" colspan="6" valign="top" bgcolor="FFFFFF" width="490"><font SIZE="2" FACE="Arial">RESOLUTION APPROVING TERMS OF A DECLARATION OF RESTRICTIVE COVENANT ON THE ADRIENNE ARSHT CENTER (�ARSHT CENTER�), UPGRADING THE ARSHT CENTER�S BUILDING MANAGEMENT SYSTEM&nbsp;</font></td>
</tr>
<tr><td>Notes:   CUA - No sponsor - pending September cmte</td></tr>
<tr VALIGN="top">
 <td ALIGN="left" valign="top" bgcolor="FFFFFF" width="8" rowspan="1"><font SIZE="2" FACE="Arial"><b>Ordinance</b>&nbsp;&nbsp;<a href="matter.asp?matter=261519"><b>261519</b></a></font></td>
 <td ALIGN="left" colspan="3" valign="top" bgcolor="FFFFFF" width="360"><font SIZE="2" FACE="Arial"><b>SOLID WASTE COLLECTION</B>&nbsp;&nbsp;</font></td>
 <td ALIGN="left" colspan="2" valign="top" bgcolor="FFFFFF" width="239"><font SIZE="2" FACE="Arial"><b>Status:</b>&nbsp;&nbsp;&nbsp;Adopted&nbsp;</font></td>
</tr>
 <tr VALIGN="top">
 <td ALIGN="left" valign="top" bgcolor="FFFFFF" width="110"><font SIZE="2" FACE="Arial">Agenda Date:<br>9/1/2026<br></b>14A4</b>R-767-26</font></td>
 <td ALIGN="left" colspan="6" valign="top" bgcolor="FFFFFF" width="490"><font SIZE="2" FACE="Arial">ORDINANCE APPROVING NON-AD VALOREM ASSESSMENT ROLLS FOR THE SOLID WASTE COLLECTION SERVICE AREA&nbsp;</font></td>
</tr>`;

  const items = parseSponsorReport(REAL);

  it('splits the flat table into one record per matter', () => {
    expect(items).toHaveLength(2);
    expect(items.map((i) => i.matter_id)).toEqual(['261553', '261519']);
  });

  it('reads type, subject, status and the enacted number', () => {
    expect(items[1].matter_type).toBe('Ordinance');
    expect(items[1].subject).toBe('SOLID WASTE COLLECTION');
    expect(items[1].status).toBe('Adopted');
    expect(items[1].enacted_number).toBe('R-767-26');
    expect(items[1].agenda_date).toBe('9/1/2026');
  });

  it('builds a citable per-item source URL', () => {
    expect(items[0].source_url).toBe('https://www.miamidade.gov/govaction/matter.asp?matter=261553');
  });

  it('🔴 raises the flag when the item says it has no sponsor', () => {
    // The report was requested FOR Hardemon and this item still says "No sponsor".
    // Attribution has to be checked on the item page, never inherited.
    expect(items[0].notes_flag_no_sponsor).toBe(true);
    expect(items[1].notes_flag_no_sponsor).toBe(false);
  });

  it('🔴 reports corrupted characters instead of guessing them', () => {
    // The source stores U+FFFD where quotes and apostrophes were. Repairing it
    // would invent punctuation in text that reaches voters.
    expect(items[0].text_has_lost_characters).toBe(true);
    expect(items[0].title).toContain('�');
    expect(items[1].text_has_lost_characters).toBe(false);
  });

  it('attaches topic leads from the operative title, not the abbreviated subject', () => {
    // "SOLID WASTE COLLECTION" is the subject line; the sanitation lead should
    // survive either way, but the title is what carries the verbs.
    expect(items[1].topics).toContain('city-sanitation');
  });
});

describe('matchLocalTopics', () => {
  it('reads county vocabulary the federal patterns never see', () => {
    expect(matchLocalTopics('ORDINANCE AMENDING THE URBAN DEVELOPMENT BOUNDARY')).toContain('growth-and-development');
    expect(matchLocalTopics('RESOLUTION APPROVING A DECLARATION OF RESTRICTIVE COVENANTS AND REZONING TO PERMIT 240 DWELLING UNITS PER ACRE')).toContain('residential-zoning');
    expect(matchLocalTopics('RESOLUTION RELATING TO THE DOCUMENTARY SURTAX FOR AFFORDABLE HOUSING')).toContain('housing');
    expect(matchLocalTopics('ORDINANCE RELATING TO 287(g) AGREEMENTS WITH FEDERAL IMMIGRATION AUTHORITIES')).toContain('local-immigration');
  });

  it('is dumb about direction, exactly like the federal map', () => {
    // Expanding and restricting the same lever must both surface.
    expect(matchLocalTopics('ORDINANCE ESTABLISHING RENT STABILIZATION')).toContain('rent-regulation');
    expect(matchLocalTopics('ORDINANCE REPEALING RENT CONTROL')).toContain('rent-regulation');
  });

  it('does not pretend to cover the education ladders', () => {
    // Florida schools are run by a separately elected board, so a county
    // commissioner has no rung. Absent on purpose, not by oversight.
    expect(matchLocalTopics('RESOLUTION URGING THE SCHOOL BOARD TO REVIEW ITS LIBRARY MATERIALS POLICY')).not.toContain('education-library-books');
  });

  it('stays quiet on the ceremonial calendar', () => {
    expect(matchLocalTopics('RESOLUTION CONGRATULATING THE MIAMI HEAT')).toEqual([]);
    expect(matchLocalTopics('PROCLAMATION DECLARING DELTA DAY AT MIAMI-DADE COUNTY')).toEqual([]);
  });
});
