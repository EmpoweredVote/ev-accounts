# Nav-page sweep — 2026-08-04

Run immediately after the operator ruling **"landing pages don't count as coverage"** (which flipped the
Newton and Portland `hasContext` chips, essentials `f0b26b4e`). Purpose: find every other stance row
propped up by a page that states no position.

**Outcome: 5 rows repaired by migration 1559, 5 rows recommended for retirement, 1 for re-sourcing, and
~30 rows that turned out NOT to be a defect.** The screen mattered more than the sweep.

---

## 🔴 Two over-fires before a usable screen

**Cut 1 — shape heuristic: 10,877 rows (33% of the corpus). Useless.**
Flagged any row whose citations all had no digit in the path and no path segment longer than 24 chars,
on the theory that articles carry dates or long slugs and nav pages do not. Its top hits were
`en.wikipedia.org/wiki/Ed_Markey`, `ontheissues.org/Senate/Ed_Markey.htm`, `ballotpedia.org/Maura_Healey`
and `katherineclark.house.gov/issues` — **per-person pages that DO state positions.** The screen matched
what a landing page looks like, not what makes one useless.

**Cut 2 — curated nav-path list: 53 rows / 28 politicians.** Better, but the list included `/about`, and
on a **campaign** site `/about` is substantive biography, not navigation. That is exactly the
`bilalmahmood.com/about` lesson from migration 1557, where the About page carried "Electric Action" and
"Upgrade California" and legitimately supported two rows.

**The distinguishing test is not the URL at all** — it is whether the cited page states a position
attributable to that person. That has to be checked per page. This is the sixteenth first-cut detector in
this audit to over-fire; the pattern holds.

## What the 53 actually decompose into

| class | rows | verdict |
|---|---|---|
| Government nav pages, already queued (Portland Ryan 6 + Wilson 2, Newton Laredo 3) | 11 | in the Portland/Newton clusters |
| Government nav pages, newly found | 6 | **5 retire, 1 re-source** — below |
| Dead / expired campaign sites | 5 | ✅ **re-pointed, migration 1559** |
| Live campaign `/about` pages with real content | ~31 | **not a defect** — ordinary sourcing-quality queue |

---

## ✅ Repaired by migration 1559 — dead campaign sites (5 rows)

Neither a nav page nor an invented outlet: the site itself is gone, so the citation is unfetchable.

| politician | rows | dead URL | capture used | verification |
|---|---|---|---|---|
| Fernando Dutra (Whittier CA council) | 3 | `dutra4whittier.com/about/` — **no A record**, curl exit 6 | **2026-03-06** (41 captures exist) | title `About Fernando - Fernando Dutra`, 129 name mentions; "prosper", "jobs", "environment", "public safety" all present |
| Chase LaPorte (KS-3 candidate) | 2 | `chaselaporte.com/about` — host resolves, **site expired**: `/about` and root both 404 with a Squarespace "This account has expired" body | **2026-08-02** (2 days before the fix) | title `About — Chase LaPorte for Congress | Kansas 3rd District Republican`; **"sanctity of life" verbatim**, plus Constitution, Kansas, inflation, "red tape", "keep more of what" — every distinctive term |

A lapsed campaign domain is the normal end state of a real campaign, not an invented outlet.

⚠ **Left unrepaired on purpose:** two of Dutra's three reasonings use phrasing absent from the page —
"smart economic growth" ("economic" 0 occurrences) and "fighting crime" ("crime" 0). The page supports the
substance; 1559 fixed unfetchability, not wording. Those two go to the sourcing-quality queue rather than
being blessed by a successful re-point.

---

## ✅ Retired by migration 1560 — 5 rows (operator-approved 2026-08-04)

Each is sole-sourced to a government nav page that was fetched and searched. The claim is about votes or
positions; the page contains a roster and nothing else.

| politician | topic | value | cited page | evidence against |
|---|---|---|---|---|
| Corey Robinson | Affordable Housing | 4 | `lowellma.gov/council` | Claims he "backed major projects in District 2" and "mill redevelopment". Page: name 2× (roster), **"affordable" 0, "mill" 0**, "housing" 1. |
| John Descoteaux | Affordable Housing | 4 | `lowellma.gov/council` | Claims "his votes reflect a pro-development stance". Same page, same counts. No vote is identified. |
| Rita Mercier | Affordable Housing | 4 | `lowellma.gov/council` | Claims she "backed several major mixed-use projects". Same page. |
| Steve Lavine | Taxation and Public Spending | 4 | `plano.gov/city-council` | Claims he opposed tax rate increases and favours lower property taxes. Page: name 2×, **"tax" 0, "budget" 0, "spending" 0.** |
| Kerry Thomson | Healthcare Access | 3 | `bloomington.in.gov/mayor` | 🔴 **The reasoning is an empty string** — a value with no stated reasoning at all. Page: name 20×, **"healthcare" 0**, "health" 1. |

Thomson's is the worst of the set: a voter-facing stance with no reasoning text and a citation that does
not mention the topic.

Blast radius, proven not assumed: Robinson 1→0 and Descoteaux 1→0 (emptied); Mercier 2→1, Lavine 6→5,
Thomson 20→19. **No `hasContext` chip breaks** — Lowell keeps 9 stanced officials of 12 seated, Plano
keeps 8 of 8, and Bloomington's coverage.js entry is address-based. `last_stances_researched_at` was
already NULL for all five, so the null-if-emptied step was a no-op.

⚠ **12 rows still cite these same nav pages** and are deliberately out of scope, because each pairs the
nav page with a co-source: `lowellma.gov/council` 11, `bloomington.in.gov/mayor` 1. A draft guard
asserting "nobody cites this page any more" failed on exactly this and had to be corrected to assert 12.
**Those 12 are a follow-up queue, not a clean bill of health** — the 1548 lesson is that a worthless
citation sharing a row with a plausible one is invisible to row-level checks.

## ⛔ Kevin McCarty — re-source ATTEMPTED and NOT POSSIBLE as written. Row left untouched.

Instruction was "re-source rather than retire". It could not be done faithfully.

🔴 **First, a correction to this document's own earlier draft.** I described `cityofsacramento.gov/mayor`
as "genuinely substantive — 147 name mentions, homeless 64, clean 36, ~19,700 words". That was wrong. The
page's only body prose is a two-sentence bio ("Kevin McCarty was elected as the 57th Mayor … From 2014 to
2024, McCarty served in the State Legislature"). The homeless/clean hits are the **site-wide navigation
menu**, and the word count is nav too. It is the same landing-page defect as the other five.

Two real candidates were found, fetched and read. Neither supports the row:

| candidate | status | why it fails |
|---|---|---|
| `cityofsacramento.gov/mayor-council/mayor/mayor-mccarty-memo/9-16-homelessness-plan-update` — "State of Homelessness Update" | ✅ live 200, official, mayor-specific, item-specific, substantive (6-point plan, "1375 beds … on track to add nearly 500 beds this year") | Supports "adding beds and shelter" (beds 12, shelter 13) but **"sanitation" 0**. The row's topic is *City Sanitation and Cleanliness*. |
| `mccartyformayor.com/issues/` | host **DEAD** (no A record); Wayback 2025-04-22 readable, 185 name mentions | **"sanitation" 0**, "clean" 1, "dumping" 1. Its one relevant passage is about the American River Parkway: *"We cannot sustain this treasure if we don't address dumping, camping and public safety. This is why I worked on a new law to ban illegal camping, while also fighting for $25 million for the county to provide services for those in need."* |

🔴 **That passage contradicts the row.** The reasoning says his approach is "adding beds and shelter
**rather than punitive sanitation enforcement**" — but he authored a camping ban and has said publicly
"We need to enforce the law. We can't have urban camping." The "coupling enforcement with social service
connections" half IS supported; the "rather than punitive enforcement" half is not.

Re-pointing to either page would attach a source that does not support the claim as written — the
Portland error in miniature. **Two honest options, operator's call:** retire the row, or keep it and
rewrite the reasoning to match the evidence (a balanced-to-enforcement posture), which changes a
voter-facing stance.

## Not a defect — ~31 rows

Live campaign `/about` pages with substantial policy content, e.g. `michelebotelhoforcongress.com/about`
(15,637 words, 124 policy terms), `wikstromforcongress.com/about` (169), `amandaforga.com/about` (97),
`aishawahab.com/about` (47). These are ordinary secondary-source-quality questions, not evidence absence,
and belong in the lower-priority stripped/quality queue.

⚠ **One false alarm of my own, recorded so it is not rediscovered as a finding:**
`elanaforbend.com/about` looked like an **empty 200** (0 words) — the "empty 200 fakes absence" class. It
is not. The page is 28,269 bytes with real content (climate 4, housing 4); my text extractor failed on its
markup. Re-checked before reporting.

---

## Gate blind spot, still open

`PRIMARY_SITE_NO_PATH` looks for a **bare host**, so `/council/agenda`, `/government/mayor` and
`/city-council` all pass it cleanly while evidencing nothing. A curated nav-path check would close the
class — but per cut 2 above it must be a **curated list of government nav paths**, never a shape
heuristic, and it must not treat a campaign-site `/about` as navigation.
