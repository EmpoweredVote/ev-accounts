---
name: project_colorado_springs_state_leg_degraaf
description: Worked example researching CO HD22 Rep. Ken DeGraaf on the 28-topic STATE scale — completecolorado.com/author/ pages, bill-shape screening, and honest low yield for a thin-record state legislator.
type: project
---

Researched Ken DeGraaf (CO House District 22, El Paso County) against the 28-topic
`scale-state.json` ladder using the harvested `leg-ken-degraaf.md` tier-1 file plus WebFetch.
Result: only 1 of 28 topics seated (climate-change), 27 skipped. This is a normal, honest yield
for a rank-and-file state rep with a thin outside-press footprint — do not over-reach to fill
rows.

**What worked:**
- `completecolorado.com/author/<slug>/` — if a legislator has ever published an op-ed there, this
  author-archive URL surfaces it directly (their `?s=<name>` search also works but returns the
  same handful of hits). This op-ed was the single richest source found: first-person, forward
  reasoning, and a clean quote, worth more than the entire bill-sponsorship list.
- `coloradohouserepublicans.com/news/<slug>` article URLs work once you have the slug from the
  member page's "In the News" list (the member page itself doesn't link full URLs — WebFetch the
  news list and ask specifically for the two article slugs by headline; it will infer the correct
  `/news/...` path).

**What didn't work / returned nothing for this legislator (all confirmed dead ends, not fetch
failures):**
- `pikespeakbulletin.org/?s=` and `socoinsider.com/?s=` — both returned **0 results** for
  "Ken DeGraaf" (these worked for other El Paso County figures per prior memory; they are simply
  silent on this particular rep — a genuine zero, not a tool problem).
- `coloradosun.com/?s=` and `coloradonewsline.com/?s=` — both **403** again, consistent with prior
  sessions' note that they're unreliable; don't burn more than one attempt each.
- `koaa.com/search?q=` — returned a nonzero match count (15) but the WebFetch summarizer could not
  surface any snippet actually naming him; the "one-on-one" trick from the brief only pays off if
  the person has actually been interviewed. Not every legislator has been.
- `leg.colorado.gov/legislators/<slug>?field_sessions_target_id=<session>` — does **not** work as a
  session-filter URL param; the brief's warning that leg.colorado.gov is current-session-only with
  no working selector is confirmed literally, don't try to hack around it with query params.

**Bill-shape screening that led to a SKIP despite having a prime-sponsored bill on-topic:**
HB26-1246 ("Consumer-Regulated Electric Utilities") lets new nonresidential/data-center loads form
their own utility exempt from PUC regulation — directly on the `data-centers` topic. But the topic's
chairs 2/4/5 are each **compound** ("requiring dedicated generation AND barring cost pass-through";
"streamlined permitting AND transparency requirements"; "incentives AND minimal barriers") and the
bill text only ever satisfies one clause of any of them (it's a narrow regulatory-exemption carve-out,
with no incentive program, no transparency mandate, no explicit ratepayer-cost provision). Per the
BRIEF's compound-chair rule, none of the three adjacent chairs could be honestly seated — skipped
the whole topic rather than picking "the closest one." A similar bipartisan-signed bill
(HB26-1250, civil asset forfeiture reform, actually signed into law) had no corresponding topic on
the 28-key state ladder at all — strong evidence of a real position with literally no chair to put
it in; note that in the report as a skip-for-no-topic-match, distinct from skip-for-insufficient-
evidence.

**Net lesson:** for a legislator with 6 current-session bills and one op-ed, expect ~1-3 seatable
rows, not a dozen — most of the bill list will be direction-only, off-axis, or compound-clause
mismatches. Reporting a 1/28 yield with a clear per-topic reason is the correct, honest output; it
is not a sign the research was incomplete.
