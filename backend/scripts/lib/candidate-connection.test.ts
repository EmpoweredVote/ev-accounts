import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { parse } from 'node-html-parser';
import {
  isCandidateConnectionUrl, passageInSurveySection, sectionText, CC_ANCHOR_PATTERN,
} from './candidate-connection.mjs';
import { checkStanceRow, type ResearchRow, type BundleTopic, type BundlePolitician } from './stanceGate.js';

const HERE = path.dirname(fileURLToPath(import.meta.url));

const SURVEY = 'I believe every family deserves affordable housing near their jobs, and I will work to remove '
  + 'zoning barriers that keep homes out of reach for working people in our community every single year';
const BIO = 'Jane Doe is a member of the Indiana House. She was born in Bloomington and attended Indiana University '
  + 'where she studied public affairs before entering local government service in the county';
const HTML = `<div id="mw-content-text"><h2><span id="Biography">Biography</span></h2><p>${BIO}</p>
  <h2><span id="Campaign_themes">Campaign themes</span></h2><p>${SURVEY}</p>
  <h2><span id="Elections">Elections</span></h2><p>General election results</p></div>`;
const section = sectionText(parse(HTML).querySelector('#mw-content-text'));

const URL_BARE = 'https://ballotpedia.org/Jane_Doe';
const URL_CC = 'https://ballotpedia.org/Jane_Doe#Campaign_themes';

describe('isCandidateConnectionUrl (test 1: the URL)', () => {
  it.each([
    [URL_CC, true], ['https://www.ballotpedia.org/Jane_Doe#Campaign_themes', true],
    ['https://ballotpedia.org/Jane_Doe#campaign_themes', true],
    [URL_BARE, false], ['https://ballotpedia.org/Jane_Doe#Biography', false],
    ['https://ballotpedia.org/#Campaign_themes', false], ['https://ballotpedia.org#Campaign_themes', false],
    ['https://example.org/Jane_Doe#Campaign_themes', false],
    ['https://example.org/ballotpedia.org/Jane_Doe#Campaign_themes', false],
    ['https://ballotpedia.org/Jane_Doe?Candidate_Connection', false], ['not a url', false],
  ])('%s -> %s', (url, want) => expect(isCandidateConnectionUrl(url)).toBe(want));
});

describe('passageInSurveySection (test 2: the page text)', () => {
  it('finds the section between its own heading and the next', () => {
    expect(section).toContain('affordable housing');
    expect(section).not.toContain('born in Bloomington');
  });
  it('passes a passage taken from the survey section', () => expect(passageInSurveySection(section, SURVEY)).toBe(true));
  it('refuses a passage that is on the page but outside the survey section', () => expect(passageInSurveySection(section, BIO)).toBe(false));
  it('refuses a section that says the candidate has not completed the survey, even if the passage is in it', () => {
    const none = `Ballotpedia survey responses Jane Doe has not yet completed Ballotpedia's 2026 Candidate Connection survey. ${SURVEY}`;
    expect(passageInSurveySection(none, SURVEY)).toBe(false);
  });
  it('refuses when there is no section', () => {
    expect(passageInSurveySection(null, SURVEY)).toBe(false);
    expect(passageInSurveySection('', SURVEY)).toBe(false);
  });
});

// The two BALLOTPEDIA_ONLY predicates must agree. check-stance-sources.mjs is SQL, so its half is pinned
// by (a) reading the pattern it interpolates from the shared module and (b) running that same pattern,
// as a JS regex (Postgres ~* syntax is the same for this pattern), over a URL corpus beside the JS test.
describe('SQL and TS predicates agree', () => {
  const CORPUS = [URL_CC, 'https://www.ballotpedia.org/Jane_Doe#Campaign_themes', URL_BARE,
    'https://ballotpedia.org/Jane_Doe#Biography', 'https://ballotpedia.org/Jane_Doe?Candidate_Connection',
    'https://ballotpedia.org/#Campaign_themes', 'https://a.gov/x'];
  it('check-stance-sources.mjs builds its SQL from the shared pattern and keeps no other carve-out', () => {
    const src = readFileSync(path.join(HERE, '..', 'check-stance-sources.mjs'), 'utf8');
    expect(src).toContain("from './lib/candidate-connection.mjs'");
    expect(src).toContain("s ~* '${CC_ANCHOR_PATTERN}'");
    expect(src).not.toMatch(/ILIKE '%Candidate_Connection%'\s*\n\s*\)/);
  });
  it.each(CORPUS)('URL test matches the SQL regex on %s', (url) => {
    const sql = new RegExp(CC_ANCHOR_PATTERN, 'i').test(url);
    // SQL has no host check; the corpus holds no off-host URL that would differ except via the shared pattern.
    if (/ballotpedia\.org/.test(url)) expect(isCandidateConnectionUrl(url)).toBe(sql);
  });
});

describe('stanceGate C57 carve-out', () => {
  const topic: BundleTopic = {
    topic_id: 't', topic_key: 'housing', topic_revision_id: 'r', question_number: 1, title: 'h', question_text: '?',
    stances: [1, 2, 3, 4, 5].map((value) => ({ value, text: `rung ${value}` })),
    applies_federal: true, applies_state: true, applies_local: true, applies_judicial: false, applies_school: false,
  };
  const pol: BundlePolitician = { full_name: 'Jane Doe', politician_id: 'p', level: 'state', race_id: 'r' };
  const row = (url: string): ResearchRow => ({
    full_name: 'Jane Doe', topic_key: 'housing', value: 2, evidence_type: 'statement',
    reasoning: 'Says she will remove zoning barriers.', source_urls: [url],
  });
  const ev = (url: string, snippet: string) => [{ full_name: 'Jane Doe', topic_key: 'housing', source_url: url, snippet, snippet_index: 0 }];
  const ids = (url: string, snippet: string, surveySections?: Record<string, string | null>) =>
    checkStanceRow(row(url), { topic, politician: pol, evidence: ev(url, snippet), surveySections }).map((f) => f.check_id);
  const sections = { 'https://ballotpedia.org/Jane_Doe': section };

  it('POSITIVE CONTROL: a survey deep link with the passage inside the section passes', () =>
    expect(ids(URL_CC, SURVEY, sections)).not.toContain('ballotpedia-only'));
  it('NEGATIVE CONTROL: a bare bio URL stays BALLOTPEDIA_ONLY, even with survey text and sections supplied', () =>
    expect(ids(URL_BARE, SURVEY, sections)).toContain('ballotpedia-only'));
  it('NEGATIVE CONTROL: the anchor with a passage from the bio (outside the section) is refused', () =>
    expect(ids(URL_CC, BIO, sections)).toContain('ballotpedia-only'));
  it('fails closed: the anchor alone, with no page text supplied, is refused', () =>
    expect(ids(URL_CC, SURVEY)).toContain('ballotpedia-only'));
  it('fails closed: the page has no survey section', () =>
    expect(ids(URL_CC, SURVEY, { 'https://ballotpedia.org/Jane_Doe': null })).toContain('ballotpedia-only'));
});
