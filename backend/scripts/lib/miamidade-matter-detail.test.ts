import { describe, it, expect } from 'vitest';
import { parseSponsors, parseMatter, field, nextCell } from '../miamidade-matter-detail.mjs';

// Real markup from matter.asp, read 2026-09-07. The multi-sponsor fixture below
// is the one that matters: a single-<font> regex returned only "Cohen Higgins"
// for it, on every matter fetched, and nearly cost two correct rows.

const FOUR_SPONSORS = `
<tr>
  <td valign="top"><font face="Arial" size="3"><strong>Sponsors: </strong></td>
  <td valign="top"><font face="Arial" size="3">Danielle Cohen Higgins, Prime Sponsor
  </font></td></tr>
  <tr><td valign="top">&nbsp;</td>
  <td valign="top"><font face="Arial" size="3">Sen. Rene Garcia, Co-Sponsor
  </font></td></tr>
  <tr><td valign="top">&nbsp;</td>
  <td valign="top"><font face="Arial" size="3">Vicki L. Lopez, Co-Sponsor
  </font></td></tr>
  <tr><td valign="top">&nbsp;</td>
  <td valign="top"><font face="Arial" size="3">Micky Steinberg, Co-Sponsor
  </font></td></tr>
<tr><td valign="top"><font face="Arial" size="3"><strong>Sunset Provision: </strong>No </font></td></tr>`;

describe('parseSponsors', () => {
  it('🔴 returns ALL FOUR sponsors, not just the prime', () => {
    const s = parseSponsors(FOUR_SPONSORS);
    expect(s).toHaveLength(4);
    expect(s.map((x) => x.name)).toEqual([
      'Danielle Cohen Higgins', 'Sen. Rene Garcia', 'Vicki L. Lopez', 'Micky Steinberg',
    ]);
  });

  it('keeps the role, because initiative and endorsement are different evidence', () => {
    const s = parseSponsors(FOUR_SPONSORS);
    expect(s[0].role).toBe('Prime Sponsor');
    expect(s.slice(1).every((x) => x.role === 'Co-Sponsor')).toBe(true);
  });

  it('reads Co-Prime as a prime role', () => {
    const html = `<strong>Sponsors: </strong></td><td><font>Danielle Cohen Higgins, Co-Prime Sponsor</font></td>
      <tr><td><font>Kevin Marino Cabrera, Co-Prime Sponsor</font></td></tr>
      <strong>Sunset Provision: </strong>`;
    const m = parseMatter(html, '250800');
    expect(m.prime_sponsors).toEqual(['Danielle Cohen Higgins', 'Kevin Marino Cabrera']);
  });

  it('stops at Sunset Provision rather than swallowing the rest of the page', () => {
    expect(parseSponsors(FOUR_SPONSORS).some((s) => /Sunset/i.test(s.name))).toBe(false);
  });

  it('returns an empty list when a matter has no sponsors, without throwing', () => {
    expect(parseSponsors('<html>no sponsors here</html>')).toEqual([]);
  });
});

describe('parseMatter', () => {
  const html = `
    <strong>File Type: </strong>Ordinance </td>
    <strong>Status: </strong>Adopted </td>
    <strong>Reference: </strong>25-59</td>
    <strong>File Name: </strong>APPLICATION NO. CDMP20240005 </td>
    <strong>Requester: </strong>Regulatory and Economic Resources </td>
    <strong>Agenda Date: </strong>6/26/2025 </td>
    <strong>Notes: </strong></td><td> </td><td><strong>Title: </strong></td>
    <td>ORDINANCE PROVIDING DISPOSITION OF APPLICATION NO. CDMP20240005</td>
    <strong>Sponsors: </strong></td><td><font>Anthony Rodriguez, Prime Sponsor</font></td>
    <strong>Sunset Provision: </strong>No`;

  it('separates prime sponsors from the full list', () => {
    const m = parseMatter(html, '241888');
    expect(m.prime_sponsors).toEqual(['Anthony Rodriguez']);
    expect(m.reference).toBe('25-59');
    expect(m.status).toBe('Adopted');
  });

  it('flags an item the administration requested', () => {
    // A department in `requester` plus a member as sponsor is weaker evidence of
    // that member's own position than an item they originated.
    expect(parseMatter(html, '241888').requester_is_department).toBe(true);
    const own = html.replace('Regulatory and Economic Resources', 'NONE');
    expect(parseMatter(own, '241888').requester_is_department).toBe(false);
  });

  it('takes Title from the NEXT cell, where the report puts it', () => {
    expect(nextCell(html, 'Title')).toBe('ORDINANCE PROVIDING DISPOSITION OF APPLICATION NO. CDMP20240005');
    expect(field(html, 'Reference')).toBe('25-59');
  });

  it('builds the citable source URL', () => {
    expect(parseMatter(html, '241888').source_url)
      .toBe('https://www.miamidade.gov/govaction/matter.asp?matter=241888');
  });
});
