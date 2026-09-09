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

  it('🔴 catches the conditioned-incentive instrument the first narrowing lost', () => {
    // R-345-26, verbatim. Rung 3's conditionality almost word for word, and the
    // most on-axis item in the whole corpus. A pattern asking for "job creation"
    // missed it because the county wrote "JOB REQUIREMENT".
    const t = 'RESOLUTION DIRECTING THE COUNTY MAYOR TO ENFORCE THE TERMS OF THE DECLARATION OF '
      + 'RESTRICTIONS, INCLUDING THE JOB REQUIREMENT, IN CONNECTION WITH THE PAST CONVEYANCE OF '
      + 'PROPERTY TO AMAZON.COM SERVICES, LLC FOR ECONOMIC DEVELOPMENT PURPOSES';
    expect(matchLocalTopics(t)).toContain('economic-development');
  });

  it('🔴 does not read a recycling rebate as economic development', () => {
    // R-877-25, verbatim-ish. It matched only on the bare word "incentive" and
    // sent a reader through 24 leads for nothing.
    const t = 'RESOLUTION DIRECTING THE COUNTY MAYOR TO EVALUATE THE FEASIBILITY OF IMPLEMENTING '
      + 'INCENTIVE-BASED PROGRAMS TO ENCOURAGE WASTE DIVERSION AND RECYCLING COLLECTION, INCLUDING '
      + 'PAY-AS-YOU-THROW AND WASTE REDUCTION REBATE PROGRAMS';
    const hits = matchLocalTopics(t);
    expect(hits).toContain('city-sanitation');
    expect(hits).not.toContain('economic-development');
  });

  // 🔴 REFINED 2026-09-09 by the growth-and-development retune. The rule this test
  // protects is unchanged and still asserted below: a CRA is not a company-specific
  // incentive, so it never files under business attraction. What changed is the
  // disposition of a CRA's ANNUAL BUDGET. Filing budgets and board appointments under
  // growth put 43 housekeeping items in a 68-matter corpus that yielded two chairs; a
  // budget approval evidences no rung on any ladder. Financing POLICY still files under
  // growth — that is the half worth keeping, and it is pinned here so a future narrowing
  // cannot quietly take it.
  it('files a CRA annual budget under NOTHING — it is housekeeping, not a growth decision', () => {
    const t = 'RESOLUTION APPROVING THE FY2025-26 BUDGET OF THE N.W. 79TH STREET CORRIDOR '
      + 'COMMUNITY REDEVELOPMENT AGENCY AND ITS TAX INCREMENT FINANCING';
    expect(matchLocalTopics(t)).toEqual([]);
  });

  it('files redevelopment-area financing POLICY under growth, not business attraction', () => {
    // A CRA reinvests incremental property tax inside a designated area. It is
    // not a company-specific incentive, and the economic-development ladder has
    // no rung for it. Verbatim from 250514, which a `vice` substring bug in the
    // first draft of the carve-out wrongly dropped — it matched "serVICEs".
    const t = 'RESOLUTION URGING THE FLORIDA LEGISLATURE TO ENACT HB 363 OR SIMILAR '
      + 'LEGISLATION THAT WOULD AUTHORIZE COMMUNITY REDEVELOPMENT AGENCIES TO USE A PORTION '
      + 'OF TAX INCREMENT FINANCING FUNDS FOR CERTAIN BUSINESS SUPPORT SERVICES';
    const hits = matchLocalTopics(t);
    expect(hits).toContain('growth-and-development');
    expect(hits).not.toContain('economic-development');
  });

  it('files CRA creation — and its prohibition — under growth', () => {
    // The decisions the housekeeping flood was burying. 250695 is the clearest
    // growth-policy instrument in the CRA corpus and the old pattern lost it in noise.
    const necessity = 'RESOLUTION ACCEPTING THE FINDING OF NECESSITY FOR THE N.W. 7TH AVENUE '
      + 'CORRIDOR COMMUNITY REDEVELOPMENT AREA';
    const prohibit = 'ORDINANCE TO PROHIBIT THE CREATION OF COMMUNITY REDEVELOPMENT AGENCIES '
      + 'IN MIAMI-DADE COUNTY';
    expect(matchLocalTopics(necessity)).toContain('growth-and-development');
    expect(matchLocalTopics(prohibit)).toContain('growth-and-development');
  });

  it('🔴 excludes a chair designation but NOT a title merely containing "services"', () => {
    // The two substring traps the carve-out audit found. `vice` matched "serVICEs";
    // `designat` matched "coDESIGNATion". `chair` alone does the real work.
    const designation = 'RESOLUTION DESIGNATING JAMES E. MCDONALD AS VICE CHAIRMAN OF THE '
      + 'NARANJA LAKES COMMUNITY REDEVELOPMENT AGENCY';
    expect(matchLocalTopics(designation)).not.toContain('growth-and-development');
  });

  it('🔴 does not read "Section 8-9 of the Code" as Section 8 housing', () => {
    // Verbatim from ordinance 26-59. Bare `section 8` pulled 18 of 123 housing
    // matters in as junk — a permitting ordinance, building-official
    // qualifications, boats and waterways, delivery robots, feral cats — because
    // Miami-Dade ordinances say "Section 8-N of the Code" constantly.
    const t = 'ORDINANCE CREATING SECTION 8-9 OF THE CODE OF MIAMI-DADE COUNTY, FLORIDA; '
      + 'REQUIRING A SAME-DAY PERMITTING PROGRAM FOR CERTAIN RESIDENTIAL PROJECTS';
    expect(matchLocalTopics(t)).not.toContain('housing');
  });

  it('still reads a real Section 8 voucher item as housing', () => {
    expect(matchLocalTopics('SECTION 8 HOUSING VOUCHER SERVICES')).toContain('housing');
    expect(matchLocalTopics('SECTION 8 HOUSING')).toContain('housing');
  });

it('🔴 does not read Biscayne Bay water quality as the development-vs-preservation ladder', () => {
    // The local-environment ladder asks how to balance NEW DEVELOPMENT against ENVIRONMENTAL
    // PRESERVATION. Bay health is a real subject and a real part of this county's work, but no
    // rung of that ladder can be evidenced by it. 32 of the 43 leads the old pattern produced
    // were this, and they seated nobody.
    expect(matchLocalTopics('RESOLUTION URGING THE FLORIDA LEGISLATURE TO FUND BISCAYNE BAY WATER QUALITY ANALYTICS')).not.toContain('local-environment');
    expect(matchLocalTopics('RESOLUTION URGING FDEP TO FUND SEPTIC TO SEWER CONVERSION')).not.toContain('local-environment');
    expect(matchLocalTopics('RESOLUTION URGING A FLOOD RESILIENCY STUDY')).not.toContain('local-environment');
  });

  it('🔴 does not match a company whose name happens to contain "Resilient"', () => {
    // Verbatim shape of R-1177-25. `resilien` matched RESILIENT AQUARIUM LLC, the assignee on a
    // Seaquarium ground lease, and filed a property transaction under the environment ladder.
    // A uniform-looking stem is not a topic.
    const t = 'RESOLUTION AUTHORIZING AND APPROVING ASSIGNMENT OF LEASE FROM MS LEISURE COMPANY, INC. '
      + 'TO RESILIENT AQUARIUM LLC';
    expect(matchLocalTopics(t)).not.toContain('local-environment');
  });

  it('🔴 does not read a board appointment as an environmental position', () => {
    expect(matchLocalTopics('RESOLUTION APPOINTING SAM ACCURSIO TO THE BISCAYNE BAY WATERSHED MANAGEMENT ADVISORY BOARD')).not.toContain('local-environment');
  });

  it('🔴 finds the zoning-AND-environmental-protection ordinance the old pattern could not see', () => {
    // 25-105, verbatim-ish. Miami-Dade regulates this axis through Chapter 33 (zoning),
    // Chapter 24 (environmental protection) and Chapter 15 (trees and landscaping) at once.
    // The old pattern matched none of it, which is why a whole-Board pass found no instrument.
    const t = 'ORDINANCE RELATING TO ZONING AND ENVIRONMENTAL PROTECTION; AMENDING SECTIONS 33-1, '
      + '33-36.1, 24-5, 24-18, 15-1 AND 15-17 OF THE CODE OF MIAMI-DADE COUNTY, FLORIDA; REVISING '
      + 'PROVISIONS RELATED TO ZONING ADMINISTRATIVE ADJUSTMENTS TO INCLUDE CERTAIN SETBACKS; '
      + 'CREATING PROVISIONS RELATED TO COMPOSTING FACILITIES AND ENVIRONMENTAL CONTROL PLAN';
    expect(matchLocalTopics(t)).toContain('local-environment');
  });

  it('🔴 finds a mitigation bank, which is rung 4 fee-in-lieu by name', () => {
    // R-1170-25, verbatim-ish. A wetlands mitigation bank is how a developer pays to offset an
    // impact instead of preserving on site — the ladder's own rung-4 mechanism. Invisible before.
    const t = 'RESOLUTION DIRECTING THE COUNTY MAYOR TO EVALUATE THE FEASIBILITY OF UTILIZING '
      + 'MIAMI-DADE COUNTY PARKS AS LAND FOR A COUNTY-OWNED MITIGATION BANK';
    expect(matchLocalTopics(t)).toContain('local-environment');
  });

  it('keeps the land-preservation vocabulary that was already right', () => {
    expect(matchLocalTopics('RESOLUTION APPROVING THE MODIFIED ENVIRONMENTALLY ENDANGERED LANDS ACQUISITION LIST')).toContain('local-environment');
    expect(matchLocalTopics('RESOLUTION ACCEPTING A DEED CONVEYING A PARCEL IN THE PINE ROCKLAND PRESERVATION AREA FOR CONSERVATION PURPOSES')).toContain('local-environment');
    expect(matchLocalTopics('RESOLUTION DISBURSING FUNDS FROM THE TREE TRUST FUND TO INCREASE THE TREE CANOPY')).toContain('local-environment');
  });

  it('does not read a grounds-maintenance contract as a landscaping standard', () => {
    // JIREH LANDSCAPING, CORP. mows the airport. Bare `landscap` would file that here, so the
    // pattern asks for a requirement, ordinance, standard or code.
    expect(matchLocalTopics('RESOLUTION APPROVING AWARD OF CONTRACT TO JIREH LANDSCAPING, CORP. FOR GROUNDS MAINTENANCE SERVICES FOR MIAMI INTERNATIONAL AIRPORT')).not.toContain('local-environment');
  });

it('🔴 does not read a submerged-lands lease as a zoning matter', () => {
    // Matter 261104, verbatim shape. Bare \`land use plan\` matched the "associated LAND USE PLAN"
    // of a state lease with the Board of Trustees of the Internal Improvement Trust Fund — ONE
    // matter that then appeared in NINE commissioners' residential-zoning leads.
    const t = 'RESOLUTION AUTHORIZING THE COUNTY MAYOR TO NEGOTIATE AND EXECUTE AN AMENDMENT TO '
      + 'LEASE NUMBER 4653 AND ASSOCIATED LAND USE PLAN WITH THE BOARD OF TRUSTEES OF THE INTERNAL '
      + 'IMPROVEMENT TRUST FUND OF THE STATE OF FLORIDA';
    expect(matchLocalTopics(t)).not.toContain('residential-zoning');
  });

  it('🔴 does not read a single-family MORTGAGE programme as single-family ZONING', () => {
    // Rung 5 argues about single-family-ONLY ZONING. Bare \`single family\` was pulling Housing
    // Finance Authority bond items and solid-waste collection studies onto that ladder.
    expect(matchLocalTopics('HFA SINGLE FAMILY MORTGAGE REVENUE BONDS')).not.toContain('residential-zoning');
    expect(matchLocalTopics('RESOLUTION DIRECTING A STUDY OF SOLID WASTE COLLECTION AT SINGLE FAMILY HOMES')).not.toContain('residential-zoning');
    // …but the zoning sense still lands.
    expect(matchLocalTopics('ORDINANCE ELIMINATING SINGLE-FAMILY ONLY ZONING')).toContain('residential-zoning');
  });

  it('🔴 files a Rapid Transit Zone ordinance under BOTH zoning and transportation', () => {
    // Chapter 33C is how Miami-Dade upzones, and not one RTZ ordinance reached the zoning ladder
    // before 2026-09-08. It is procedural for transportation (it adds named parcels) and on-axis
    // for zoning (it upzones them), so both tags are correct — this is not a collision.
    const t = 'ORDINANCE RELATING TO THE RAPID TRANSIT SYSTEM-DEVELOPMENT ZONE; AMENDING SECTION '
      + '33C-2 OF THE CODE; AMENDING THE METROMOVER SUBZONE OF THE RAPID TRANSIT ZONE TO ADD '
      + 'CERTAIN PRIVATE PROPERTY';
    const hits = matchLocalTopics(t);
    expect(hits).toContain('residential-zoning');
    expect(hits).toContain('transportation-priorities');
  });

  it('🔴 finds the Live Local ordinance whose title literally opens "RELATING TO ZONING"', () => {
    // 26-47. It reached transportation only, because the pattern wanted "zoning amendment" and the
    // county wrote "RELATING TO ZONING". Streamlining approvals is rung 4 vocabulary; it has to be
    // visible for a reader to weigh it.
    const t = 'ORDINANCE RELATING TO ZONING; CREATING SECTION 33-39.5 OF THE CODE; PROVIDING FOR '
      + 'ADMINISTRATIVE ACCEPTANCE AND APPROVAL OF COVENANTS RELATING TO THE LIVE LOCAL ACT IN '
      + 'CONNECTION WITH PROPOSED DEVELOPMENTS LOCATED WITHIN TRANSIT-ORIENTED DEVELOPMENTS';
    expect(matchLocalTopics(t)).toContain('residential-zoning');
  });

  it('keeps the plain zoning vocabulary it always had', () => {
    expect(matchLocalTopics('ORDINANCE APPROVING A REZONING TO PERMIT 240 DWELLING UNITS PER ACRE')).toContain('residential-zoning');
    expect(matchLocalTopics('RESOLUTION APPROVING CDMP APPLICATION NO. CDMP20240020')).toContain('residential-zoning');
    expect(matchLocalTopics('ORDINANCE RELATING TO THE DOWNTOWN KENDALL URBAN CENTER DISTRICT')).toContain('residential-zoning');
  });

it('🔴 does not read the county signing a lease as a position on rent regulation', () => {
    // Bare \`landlord\` caused 23 of 23 false positives on this ladder, and every other
    // alternative fired zero times. A county is a landlord constantly, and none of it is a
    // position on regulating rents.
    const leases = [
      'RESOLUTION APPROVING A LEASE BETWEEN MIAMI-DADE COUNTY, AS LANDLORD, AND SUITED FOR SUCCESS, INC., AS TENANT',
      'DEVELOPMENT LEASE AGREEMENT WITH KASE LLC IN WHICH THE COUNTY IS LANDLORD',
      'HAULOVER RESTAURANT LEASE WITH THE COUNTY AS LANDLORD',
    ];
    for (const t of leases) expect(matchLocalTopics(t)).not.toContain('rent-regulation');
  });

  it('still reads every real rent-regulation instrument', () => {
    const real = [
      'ORDINANCE ESTABLISHING RENT STABILIZATION FOR MULTIFAMILY UNITS',
      'ORDINANCE REPEALING RENT CONTROL',
      'ORDINANCE CREATING A TENANTS BILL OF RIGHTS',
      'ORDINANCE REQUIRING 60 DAYS NOTICE OF A RENT INCREASE OVER FIVE PERCENT',
      'ORDINANCE ESTABLISHING JUST CAUSE EVICTION REQUIREMENTS',
      'ORDINANCE AMENDING THE LANDLORD-TENANT PROVISIONS OF THE CODE',
      'RESOLUTION ESTABLISHING TENANT PROTECTIONS IN COUNTY-ASSISTED HOUSING',
    ];
    for (const t of real) expect(matchLocalTopics(t)).toContain('rent-regulation');
  });

  it('stays quiet on the ceremonial calendar', () => {
    expect(matchLocalTopics('RESOLUTION CONGRATULATING THE MIAMI HEAT')).toEqual([]);
    expect(matchLocalTopics('PROCLAMATION DECLARING DELTA DAY AT MIAMI-DADE COUNTY')).toEqual([]);
  });
});
