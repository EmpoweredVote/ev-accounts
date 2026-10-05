// Re-research of Roz Randorf's campaign-decided rows under the ruling of 2026-10-05
// (Chris Cantrell: campaign statements count, and they need a link).
//
// Two rows carried the old exclusion. `local-environment` was decided ON it — the 2019 watershed
// remark was the only environment material in her corpus and the row set it aside, so the row had
// no other reason. `childcare` named the exclusion but also carried an independent reason, so its
// verdict stands and only the false sentence comes out.
//
// The candidacy announcement of 22 April 2019 was read for every other searched blank she holds.
// It is a list of subjects — economic growth, housing, public safety, quality streets, child care,
// senior citizens — and names no rung on any ladder, so no other row changes.
//
// Result: still no chair. Admissibility was not what held this row out; the ladder is.
import fs from 'node:fs';
import crypto from 'node:crypto';

const B = 'data/stance-research/2026-10-04-knight-mn-cities';
const N = 'Roz Randorf';
const key = (u) => crypto.createHash('sha1').update(u).digest('hex').slice(0, 24);
const read = (u) => fs.readFileSync('data/stance-news/randorf/' + key(u) + '.txt', 'utf8');

const WIN = 'https://www.duluthnewstribune.com/news/anderson-randorf-kennedy-win-duluth-city-council-races';
const ANN = 'https://www.duluthnewstribune.com/news/randorf-to-run-for-duluth-city-council';

// Every passage this reasoning characterises is asserted present in the fetched page, so a remark
// that drifted from the corpus — or was never there — cannot reach the CSV. Both rows stay blank,
// so neither cites a source; this control is what stands in for the snippet check.
const must = (u, s) => { if (!read(u).includes(s)) { console.error('REFUSING: passage not in corpus page\n  ' + u + '\n  ' + s); process.exit(1); } };
must(WIN, 'but not at the expense of the Lake Superior watershed');
must(WIN, 'what she viewed as the defining issue in the open race');
must(WIN, 'It was probably three out of every four doors');
must(ANN, 'child care resources and the needs of our senior citizens');
must(ANN, 'April 22, 2019');

const SWEEP = 'A sweep of the three Duluth outlets that pass a differential control - the Duluth News Tribune, WDIO and Duluth Monitor - together with MinnPost and Sahan Journal, over 23 queries, returned 609 unique articles. Minnesota Reformer was searched separately and added no article naming her. 50 of them name Randorf and all 50 were read. Perfect Duluth Day, FOX 21, Business North, Northern News Now and Duluth Reader could not be searched by any method found, so no outlet count here covers them.';

// Date-stamped so a reviewer can weigh staleness: this is 2019 material, seven years back and two
// terms ago, which is the oldest campaign evidence admitted anywhere in this slice.
const CAMPAIGN = ' Her statements as a candidate are used, under the ruling of 2026-10-05. She was elected to the 3rd District seat on 5 November 2019 and took office in January 2020, so this material is from the 2019 campaign and is seven years old.';

const rows = [
  {
    topic_key: 'local-environment',
    reasoning: 'Searched blank. ' + SWEEP + ' On the Lester Park golf course decision, which developed 63 acres and left 207 in a P-1 open space zone, her only quoted remark in office describes what the P-1 designation does: certain things cannot be built on it and it cannot be transferred to a developer. That describes the zoning tool, not a position on how the city should balance development against preservation.' + CAMPAIGN + ' On election night she was asked what she viewed as the defining issue in the open race, and answered that it is about the Lake Superior watershed and having Duluth be a good, livable, safe place, where the city can bring livable-wage jobs but not at the expense of the Lake Superior watershed. She added that this was loud and clear at about three out of every four doors. It is real evidence and it does rule out one end of this ladder: chair 4 treats environmental cost as a manageable trade-off against clear economic benefit, and she says plainly that jobs are not to be bought at the watershed’s cost. It does not choose among the three chairs that remain. She names no mechanism - no development she would block or sharply limit, no burden on a developer to prove a project will not do damage before it may proceed, and no standard applied with or without flexibility - so chairs 1, 2 and 3 are each consistent with what she said. The remark is also an answer about which issue the race was about, reporting what she heard at the doors, rather than a statement of how she would balance the two. Her only other campaign material is the candidacy announcement of 22 April 2019, which does not mention the environment.',
  },
  {
    topic_key: 'childcare',
    reasoning: 'Searched blank. ' + SWEEP + CAMPAIGN + ' Childcare appears once, in that candidacy announcement of 22 April 2019, where she writes that she looks forward to supporting economic growth, housing, public safety, quality streets, child care resources and the needs of our senior citizens. That is a list of subjects she would support. This ladder separates on how much the community should do about the cost and supply of child care, and naming it among six subjects states no level of support, so it names no rung. No later passage states a position.',
  },
].map((r) => ({
  full_name: N, topic_key: r.topic_key, value: '', evidence_type: '', reasoning: r.reasoning,
  source_url_1: '', source_url_2: '', source_url_3: '', quote_text: '', quote_deidentified: '', editor_note: '',
}));

// Control: the sentences asserting the old standard must not survive anywhere in this file.
const OLD = [/before she took office in January 2020 and is not used/, /predates her taking office/];
const survivors = rows.filter((r) => OLD.some((re) => re.test(r.reasoning)));
if (survivors.length) { console.error('REFUSING: old-standard sentence survives in', survivors.map((r) => r.topic_key)); process.exit(1); }

fs.writeFileSync(B + '/_rows/randorf-campaign-rows.json', JSON.stringify(rows, null, 1));
console.log('rows:', rows.length, '| scored:', rows.filter((r) => r.value).length);
console.log('topics:', rows.map((r) => r.topic_key).join(', '));
