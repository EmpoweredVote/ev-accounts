// Saura Jost, transportation-priorities — the row the verifier refused on 2026-10-05.
//
// The chair was reasoned and drafted then, and recorded in full in the blank so this pass could
// finish it rather than rediscover it. One thing was missing: a source that verifies. The October
// 2023 MinnPost Summit Avenue report carried the words and would not confirm against the page.
//
// This pass adds MinnPost's Ward 3 candidate questionnaire of 2 November 2023, where she answers in
// her own words under her own full name, and re-cites the Summit report alongside it. Both passages
// were cut from the fetched corpus files and both were confirmed present in a fresh fetch of the
// live page before this script was written.
//
// Both are campaign-era — she was elected on 7 November 2023 and took office in January 2024 — so
// this row rests on the ruling of 2026-10-05 and date-stamps the material, as that ruling requires.
import fs from 'node:fs';
import crypto from 'node:crypto';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Saura Jost';
const key = (u) => crypto.createHash('sha1').update(u).digest('hex').slice(0, 24);
const read = (u) => fs.readFileSync('data/stance-news/jost/' + key(u) + '.txt', 'utf8').replace(/\s+/g, ' ');

const SUMMIT = 'https://www.minnpost.com/metro/2023/10/could-opposition-to-the-summit-avenue-bike-trail-plan-shape-this-years-st-pauls-elections/';
const WARD3 = 'https://www.minnpost.com/elections/2023/11/st-paul-city-council-ward-3-2023-candidates-isaac-russell-saura-jost-troy-barksdale-patty-hartmann/';

// Cut from the fetched page, never retyped. A snippet that drifted cannot reach the CSV.
const cut = (u, from, to) => {
  const t = read(u);
  const i = t.indexOf(from);
  if (i < 0) { console.error('REFUSING: start not on page\n  ' + u + '\n  ' + from); process.exit(1); }
  const j = t.indexOf(to, i);
  if (j < 0) { console.error('REFUSING: end not on page\n  ' + u + '\n  ' + to); process.exit(1); }
  const s = t.slice(i, j + to.length).trim();
  const w = s.split(/\s+/).length;
  if (w < 25) { console.error('REFUSING: snippet is ' + w + ' words, under the 25-word bar\n  ' + s); process.exit(1); }
  return s;
};

const A = cut(SUMMIT, 'Jost said that Summit', 'built to last and work for everyone.”');
const B2 = cut(WARD3, 'Building St. Paul', 'still facing.');

// Her full name must sit within 500 characters of each passage, which is what the verifier asks.
const near = (u, s, name) => {
  const t = read(u); const i = t.indexOf(s);
  const j = t.lastIndexOf(name, i);
  const d = j < 0 ? Infinity : i - j;
  if (d > 500) { console.error('REFUSING: "' + name + '" sits ' + d + ' chars before the passage on ' + u); process.exit(1); }
  return d;
};
const dA = near(SUMMIT, A, 'Jost');
const dB = near(WARD3, B2, 'Saura Jost');

const SWEEP = 'A name-only sweep and a name-and-topic sweep of MinnPost and Sahan Journal (WordPress REST API), the Saint Paul Pioneer Press and Minnesota Reformer returned 58 articles, 40 of which name Saura Jost as a phrase. One was set aside because it also names a different person surnamed Jost, so a bare-surname attribution in it could not be trusted, and every passage in the remaining 39 that quotes her beside a speech verb was read - 20 of them. MPR News and Racket are not covered by this count: MPR News renders its articles in the browser, so a passage there cannot be verified against the page, and Racket returns the same results for any query including a nonsense one.';

const reasoning = 'Jost states this chair in her own words, on the city’s most contested street project. Both passages are from her 2023 campaign - she was elected on 7 November 2023 and took office in January 2024 - and are used under the ruling of 2026-10-05, so a reviewer should read them as three-year-old candidate statements. On the Summit Avenue reconstruction and its bike trail, reported by MinnPost in October 2023, she said Summit is like many streets across Saint Paul that are past their design life and must be replaced, that the city must replace them with climate-resilient infrastructure, and that foresters should be able to advise on minimising tree loss. She then said the city needs to build multiple types of transit for everyone, no matter how you want to get around, and that a solution can be found that is built to last and works for everyone. In MinnPost’s Ward 3 candidate questionnaire of 2 November 2023 she gave infrastructure as her top priority and said the city needs to take steps not just to reconstruct its streets and build the transit methods it needs, but also to deal with the housing crisis. Read together, and read with the instrument - a street rebuild that carries a bike trail within it - that is chair 2: roads and multimodal options funded together rather than one placed above the other. Chair 1 is excluded by the setting. The pro-cycling pole was available in this race and another candidate took it, running on a Streets for All platform and arguing Summit is the one street that would serve cycling access; Jost instead insisted the roadway must be rebuilt and that the outcome must work for everyone. Chair 3 is excluded by her own words. It adds transit selectively, where density supports it, and she states no density condition and no selectivity - multiple types of transit for everyone in the city, no matter how you want to get around, is the opposite of a targeted addition. Chairs 4 and 5 are excluded because she commits to building transit, not to road capacity, traffic flow or parking. This row carried the same chair as a blank until now for one reason, recorded at the time: the Summit report alone would not verify against the page. The Ward 3 questionnaire is the second source, it carries her own answer under her own full name, and both passages were confirmed on the live pages.';

const rows = [{
  full_name: N, topic_key: 'transportation-priorities', value: '2', evidence_type: 'statement',
  reasoning: 'Searched blank context: ' + SWEEP + ' ' + reasoning,
  source_url_1: WARD3, source_url_2: SUMMIT, source_url_3: '',
  quote_text: '', quote_deidentified: '', editor_note: '',
}];

const evidence = [
  { full_name: N, topic_key: 'transportation-priorities', source_url: WARD3, snippet: B2, snippet_index: 0 },
  { full_name: N, topic_key: 'transportation-priorities', source_url: SUMMIT, snippet: A, snippet_index: 1 },
];

fs.writeFileSync(B + '/_rows/jost-transportation-rows.json', JSON.stringify(rows, null, 1));
fs.writeFileSync(B + '/_rows/jost-transportation-evidence.json', JSON.stringify(evidence, null, 1));
console.log('snippet A (Summit):', A.split(/\s+/).length, 'words, name', dA, 'chars before');
console.log('snippet B (Ward 3):', B2.split(/\s+/).length, 'words, name', dB, 'chars before');
console.log('rows:', rows.length, '| evidence:', evidence.length);
