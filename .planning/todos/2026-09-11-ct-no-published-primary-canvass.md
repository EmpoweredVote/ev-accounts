# CT — no obtainable official canvass for the 2026 primary, and CD-1 is probably wrong

**Opened:** 2026-09-11 (Phase 167 cluster attempt, Connecticut)
**Status:** **no migration written.** 22 rows across 5 congressional races stay stale, 30 days past
their `provisional_until` of 2026-08-12, because no jurisdiction document could be obtained.

## 🔴 The likely exposure, which is why this matters

Multiple news outlets (CT Mirror, CT News Junkie, NBC Connecticut, Ballotpedia) report that
**Luke Bronin defeated 14-term incumbent John Larson** in the CD-1 Democratic primary on
2026-08-11, with Jillian Gilchrest third and Ruth Fortune fourth.

Our CD-1 field currently carries **all five** — Amy Chai, Jillian Gilchrest, **John B. Larson
(marked incumbent)**, Luke Bronin and Ruth Fortune — as active general-election candidates.

**Nothing was culled on that basis.** News reporting is not a jurisdiction document, and this phase
already has 1842's Kitsap lesson on the record: a web summary of that race reported 28,094/19,827
against the true 48,117/34,768 — right ratio, wrong magnitude. A defeated incumbent is exactly the
row where being confidently wrong is worst. But a CD-1 voter is very likely being shown a
four-candidate primary field with a defeated incumbent in it, and that should be fixed quickly
once the canvass is in hand.

## What was tried, so nobody repeats it

| source | result |
|---|---|
| `portal.ct.gov/.../election-results/election-results` | no 2026 entries; most recent year listed is 2023 |
| `portal.ct.gov/.../election-results/election-results-archive` | Statement of Vote archive stops at **2014** |
| `portal.ct.gov/.../candidate-lists-for-office/filed-candidates` | "current (or most recent) candidates" list is from **2014** |
| `electionhistory.ct.gov` | Next.js search app ("official source documents", 1787–2026); no discoverable route or API for a specific election; home page returns `hasBallots: false` |
| `electionresults.ct.gov`, `results.ct.gov`, `ctemsresults.ct.gov`, `ctelections.us` | all fail to resolve |
| `portal.ct.gov/-/media/sots/electionservices/electionresults/2026/2026primarysov.pdf` | **soft-404** — returns HTTP 200 with `Content-Type: text/html`, an HTML error page, not a PDF. Do not trust a 200 from this host without checking the content type |
| SOTS press releases | one August 2026 release (an Election Day hotline notice, 8/10); nothing on results or certification |
| Elections & Voting home page | links "August 11, 2026, Primary Sample Ballots" but no results, returns or canvass |

## Connecticut is blocked for a different reason from MN, NH and WI

Those three block automated access. Connecticut does not block anything — **it appears not to have
published the 2026 primary canvass anywhere discoverable.** That distinction matters: a browser
will not help here the way it will for Minnesota. Someone has to find the document, or ask for it.

## How to close it

1. Ask SOTS directly where the August 11, 2026 primary official returns are published
   (elections@ct.gov / the Elections Division). Connecticut compiles moderators' returns from each
   town; a certified statewide return exists somewhere.
2. Failing that, the **town-level moderators' returns** are official documents in their own right.
   CD-1 spans Hartford and surrounding towns; certified returns from the towns in the district
   would settle the Democratic primary.
3. Then write the cluster migration the way 1853 and 1856 are written: a tally table quoting the
   document, dispositions, and a post-verify block.

Our CT field, for whoever picks this up: CD-1 5 rows, CD-2 2, CD-3 4, CD-4 6, CD-5 5 — 22 in total,
all `provisional_until` 2026-08-12, all still `active`.
