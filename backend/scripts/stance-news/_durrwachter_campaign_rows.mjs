// Wendy Durrwachter's one row that named the old pre-office exclusion, under the ruling of
// 2026-10-05 (Chris Cantrell: campaign statements count, and they need a link).
//
// The tracker already judged this one "no change": the blank carries a second, independent reason
// — reporting what residents told her names no rung. That holds. What comes out is the sentence
// asserting the material was inadmissible, which is now false and sits in a voter-facing field.
//
// Her campaign material was re-read against her other searched blanks. The Lester Park meet and
// greet is the only campaign passage in her corpus that carries her own words on a ladder subject,
// so no other row changes.
import fs from 'node:fs';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Wendy Durrwachter';

const SWEEP = 'A sweep of the three Duluth outlets that pass a differential control - the Duluth News Tribune, WDIO and Duluth Monitor - together with MinnPost and Sahan Journal, over 46 queries covering both spellings of her surname, returned 586 unique articles. Minnesota Reformer was searched separately and added no article naming her. 38 of them name her and all 38 were read. Perfect Duluth Day, FOX 21, Business North, Northern News Now and Duluth Reader could not be searched by any method found, so no outlet count here covers them. Her recorded votes were read from the council’s own roll calls: 31 divided votes across 76 meetings since she took office on 4 January 2024.';

const rows = [
  {
    topic_key: 'childcare',
    reasoning: 'Searched blank. ' + SWEEP + ' Her remarks on childcare come from a campaign meet and greet in Lester Park, held before she took office on 4 January 2024. That material is used, under the ruling of 2026-10-05, and it was read: she said she had been hearing that child care is hard to find and that waiting lists are long. She is reporting what residents told her, not stating what the community should do about it, and this ladder separates on how much public support to provide. It names no rung.',
  },
].map((r) => ({
  full_name: N, topic_key: r.topic_key, value: '', evidence_type: '', reasoning: r.reasoning,
  source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '',
}));

// Control: the sentence asserting the old standard must not survive.
const OLD = /That was before she took office on 4 January 2024, and reporting/;
if (rows.some((r) => OLD.test(r.reasoning))) { console.error('REFUSING: old-standard sentence survives'); process.exit(1); }

fs.writeFileSync(B + '/_rows/durrwachter-campaign-rows.json', JSON.stringify(rows, null, 1));
console.log('rows:', rows.length, '| scored:', rows.filter((r) => r.value).length);
