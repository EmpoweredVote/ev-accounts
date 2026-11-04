import { describe, expect, it } from 'vitest';
import {
  congressEnd, congressStart, currentCongress, externalIdFor, ordinal, parseBillStatus, statusOf, stripHtml,
} from './billStatus.js';

const wrap = (bill: string) => `<?xml version="1.0"?><billStatus><version>3.0.0</version><bill>${bill}</bill></billStatus>`;
const fallback = { congress: 117, type: 'HR' as const, number: '7299' };

const LAW = wrap(`
  <number>7299</number><type>HR</type><congress>117</congress><introducedDate>2022-03-30</introducedDate>
  <title>Strengthening VA Cybersecurity Act of 2022</title>
  <actions>
    <item><actionDate>2022-03-30</actionDate><text>Introduced in House</text><type>IntroReferral</type></item>
    <item><actionDate>2022-11-17</actionDate><text>Passed/agreed to in House: On motion to suspend the rules</text><type>Floor</type></item>
    <item><actionDate>2022-12-15</actionDate><text>Passed Senate with an amendment by Unanimous Consent.</text><type>Floor</type></item>
    <item><actionDate>2022-12-27</actionDate><text>Signed by President.</text><type>BecameLaw</type></item>
    <item><actionDate>2022-12-27</actionDate><text>Became Public Law No: 117-302.</text><type>BecameLaw</type></item>
  </actions>
  <laws><item><type>Public Law</type><number>117-302</number></item></laws>
  <policyArea><name>Armed Forces and National Security</name></policyArea>
  <subjects><legislativeSubjects><item><name>Computer security</name></item><item><name>Armed Forces and National Security</name></item></legislativeSubjects></subjects>
  <summaries>
    <summary><updateDate>2022-04-05T16:22:44Z</updateDate><text><![CDATA[<p>First <strong>summary</strong>.</p>]]></text></summary>
    <summary><updateDate>2022-12-05T19:43:23Z</updateDate><text><![CDATA[<p>Latest summary &amp; more.</p>]]></text></summary>
  </summaries>
  <sponsors><item><bioguideId>L000590</bioguideId><fullName>Rep. Lee, Susie [D-NV-3]</fullName><party>D</party></item></sponsors>
  <cosponsors>
    <item><bioguideId>B000001</bioguideId></item>
    <item><bioguideId>B000002</bioguideId><sponsorshipWithdrawnDate>2022-05-01</sponsorshipWithdrawnDate></item>
    <item><bioguideId>B000001</bioguideId></item>
  </cosponsors>
  <latestAction><actionDate>2022-12-27</actionDate><text>Became Public Law No: 117-302.</text></latestAction>`);

describe('parseBillStatus', () => {
  it('reads a bill that became law', () => {
    const b = parseBillStatus(LAW, fallback)!;
    expect(b.externalId).toBe('117-HR-7299');
    expect(b.number).toBe('HR 7299');
    expect(b.statusLabel).toBe('Signed');
    expect(b.signedAt).toBe('2022-12-27');
    expect(b.passedAt).toBe('2022-12-15');
    expect(b.introducedAt).toBe('2022-03-30');
    expect(b.summary).toBe('Latest summary & more.');
    expect(b.topicTags).toEqual(['Armed Forces and National Security', 'Computer security']);
    expect(b.url).toBe('https://www.congress.gov/bill/117th-congress/house-bill/7299');
    expect(b.rawStatus).toBe('Became Public Law No: 117-302.');
  });

  it('keeps only bioguide ids: no party or name, withdrawn cosponsors dropped, duplicates merged', () => {
    const b = parseBillStatus(LAW, fallback)!;
    expect(b.sponsorBioguide).toBe('L000590');
    expect(b.cosponsorBioguides).toEqual(['B000001']);
    expect(JSON.stringify(b)).not.toMatch(/Lee|\[D-|"D"/);
  });

  it('a bill that passed only one chamber keeps its stage label', () => {
    const b = parseBillStatus(wrap(`
      <number>5</number><type>S</type><congress>119</congress><introducedDate>2025-01-09</introducedDate><title>T</title>
      <actions><item><actionDate>2025-02-01</actionDate><text>Passed Senate without amendment by Unanimous Consent.</text><type>Floor</type></item></actions>
      <latestAction><actionDate>2025-02-03</actionDate><text>Received in the House and referred to the Committee on Energy.</text></latestAction>`),
      { congress: 119, type: 'S', number: '5' })!;
    expect(b.statusLabel).toBe('In Committee');
    expect(b.passedAt).toBeNull();
    expect(b.signedAt).toBeNull();
  });

  it('a simple resolution passes with one chamber', () => {
    const b = parseBillStatus(wrap(`
      <number>9</number><type>HRES</type><congress>119</congress><introducedDate>2025-01-09</introducedDate><title>T</title>
      <actions><item><actionDate>2025-01-20</actionDate><text>Agreed to in House</text><type>Floor</type></item></actions>
      <latestAction><actionDate>2025-01-20</actionDate><text>Agreed to in House</text></latestAction>`),
      { congress: 119, type: 'HRES', number: '9' })!;
    expect(b.statusLabel).toBe('Passed');
    expect(b.passedAt).toBe('2025-01-20');
  });

  it('reads the older layout (billNumber / billType) and falls back to the file name', () => {
    const b = parseBillStatus(wrap('<billNumber>10</billNumber><billType>HR</billType><congress>117</congress><title>Old</title>'),
      { congress: 117, type: 'HR', number: '10' })!;
    expect(b.externalId).toBe('117-HR-10');
    const none = parseBillStatus(wrap('<title>No ids</title>'), { congress: 113, type: 'HR', number: '77' })!;
    expect(none.externalId).toBe('113-HR-77');
    expect(none.statusLabel).toBe('Introduced');
  });

  it('returns null when there is no bill', () => {
    expect(parseBillStatus('<billStatus></billStatus>', fallback)).toBeNull();
  });
});

describe('statusOf', () => {
  it('orders law, passed, reported, committee, introduced', () => {
    expect(statusOf('HR', 'x', true, new Set())).toBe('Signed');
    expect(statusOf('HR', 'x', false, new Set(['house', 'senate']))).toBe('Passed');
    expect(statusOf('HR', 'Committee on X reported favorably', false, new Set())).toBe('Reported');
    expect(statusOf('HR', 'Referred to the Committee on X.', false, new Set())).toBe('In Committee');
    expect(statusOf('HR', 'Introduced in House', false, new Set())).toBe('Introduced');
  });
});

describe('congress helpers', () => {
  it('works out the Congress in session', () => {
    expect(currentCongress(new Date('2026-10-31T00:00:00Z'))).toBe(119);
    expect(currentCongress(new Date('2027-01-02T12:00:00Z'))).toBe(119);
    expect(currentCongress(new Date('2027-01-03T12:00:00Z'))).toBe(120);
    expect(currentCongress(new Date('2025-01-03T00:00:00Z'))).toBe(119);
  });
  it('gives start and end dates', () => {
    expect(congressStart(119).toISOString()).toBe('2025-01-03T00:00:00.000Z');
    expect(congressEnd(119).toISOString()).toBe('2027-01-03T00:00:00.000Z');
  });
  it('names ordinals', () => {
    expect([102, 111, 112, 113, 119, 120, 121].map(ordinal)).toEqual(['102nd', '111th', '112th', '113th', '119th', '120th', '121st']);
  });
  it('builds external ids and strips html', () => {
    expect(externalIdFor(119, 'hr', '1')).toBe('119-HR-1');
    expect(stripHtml('<p>A&nbsp;<b>b</b> &amp; c</p>')).toBe('A b & c');
  });
});
