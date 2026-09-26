import { describe, it, expect } from 'vitest';
import { mkdtempSync, mkdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { parseSourceProfile, loadSourceProfiles, resolveProfile, profileSeatChamber, profileTag } from './sourceProfiles.js';

const HEADER = `profile: ca-votes
version: 1
scope: state:CA
body: legislature
match:
  url_prefixes:
    - https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml
page_kind: vote
rules:
  vote_block: aye-count
  chamber: word-before-floor
  name_format: surname
seat_titles:
  Senator: upper
  Assembly Member: lower
controls:
  - batch: b
    snapshot: aa219c5b
    person: Maria Elena Durazo
    office_title: Senator
    instrument: SB 1174 (2023-2024)
    record_kind: vote
    actor_quote: "Dodd, Durazo, Eggman"
    tally_quote: "Ayes Count 30 Noes Count 8 NVR Count 2"
    expect: pass`;
const md = (h: string, body = '# CA votes\n\nProse.') => `---\n${h}\n---\n${body}\n`;

describe('parseSourceProfile', () => {
  it('parses a valid header; not_chamber_after defaults to []', () => {
    const p = parseSourceProfile(md(HEADER), 'f.md');
    expect(p.profile).toBe('ca-votes');
    expect(p.rules).toEqual({ vote_block: 'aye-count', chamber: 'word-before-floor', not_chamber_after: [], name_format: 'surname' });
    expect(p.url_prefixes).toEqual(['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml']);
    expect(p.seat_titles).toEqual({ Senator: 'upper', 'Assembly Member': 'lower' });
    expect(profileTag(p)).toBe('ca-votes@1');
  });
  it.each([
    ['an unknown top-level key', HEADER + '\nextra: 1', /f\.md: unknown key "extra"/],
    ['an unknown rule kind', HEADER.replace('word-before-floor', 'regex-please'), /f\.md: rules\.chamber "regex-please"/],
    ['an unknown rules key', HEADER.replace('  name_format: surname', '  name_format: surname\n  pattern: "Senate.*"'), /f\.md: unknown key "rules\.pattern"/],
    ['a missing field', HEADER.replace('scope: state:CA\n', ''), /f\.md: missing "scope"/],
    ['no pass control', HEADER.replace('expect: pass', 'expect: name-collision'), /f\.md: needs at least one control with expect: pass/],
    ['a bad seat chamber', HEADER.replace('Senator: upper', 'Senator: middle'), /f\.md: seat_titles\.Senator "middle"/],
    ['a bad record_kind', HEADER.replace('record_kind: vote', 'record_kind: tweet'), /f\.md: controls\[0\]\.record_kind "tweet"/],
    ['bill-origin chamber on a non-author/bill-text page', HEADER.replace('word-before-floor', 'bill-origin'), /f\.md: rules\.chamber bill-origin is only valid for page_kind author \| bill-text/],
  ])('rejects %s', (_label, h, re) => expect(() => parseSourceProfile(md(h), 'f.md')).toThrow(re));
  it('rejects a file with no front matter', () => expect(() => parseSourceProfile('# no header', 'f.md')).toThrow(/f\.md: no front matter/));
});

describe('resolveProfile', () => {
  const a = parseSourceProfile(md(HEADER), 'a.md');
  const b = parseSourceProfile(md(HEADER.replace('profile: ca-votes', 'profile: ca-root').replace('https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml', 'https://leginfo.legislature.ca.gov/')), 'b.md');
  it('longest prefix wins', () => {
    expect(resolveProfile([b, a], 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=1')?.profile).toBe('ca-votes');
    expect(resolveProfile([b, a], 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml')?.profile).toBe('ca-root');
  });
  it('no match → null', () => expect(resolveProfile([a, b], 'https://iga.in.gov/x')).toBeNull());
});

describe('profileSeatChamber', () => {
  const p = parseSourceProfile(md(HEADER), 'a.md');
  it('reads seat_titles case-insensitively', () => expect(profileSeatChamber(p, 'assembly member')).toBe('lower'));
  it('falls back to seatChamber for a title the profile does not list', () => expect(profileSeatChamber(p, 'State Senator')).toBe('upper'));
});

describe('loadSourceProfiles', () => {
  const dirWith = (files: Record<string, string>) => {
    const d = mkdtempSync(join(tmpdir(), 'sp-'));
    for (const [rel, text] of Object.entries(files)) { mkdirSync(join(d, rel, '..'), { recursive: true }); writeFileSync(join(d, rel), text); }
    return d;
  };
  it('loads every .md under the dir except README.md', () => {
    const d = dirWith({ 'README.md': '# not a profile', 'states/CA/a.md': md(HEADER) });
    expect(loadSourceProfiles(d).map((p) => p.profile)).toEqual(['ca-votes']);
  });
  it('rejects a duplicate profile id', () => {
    const d = dirWith({ 'a.md': md(HEADER), 'b.md': md(HEADER) });
    expect(() => loadSourceProfiles(d)).toThrow(/duplicate profile "ca-votes"/);
  });
  it('rejects the same url prefix in two profiles', () => {
    const d = dirWith({ 'a.md': md(HEADER), 'b.md': md(HEADER.replace('profile: ca-votes', 'profile: other')) });
    expect(() => loadSourceProfiles(d)).toThrow(/url prefix .* in both/);
  });
});
