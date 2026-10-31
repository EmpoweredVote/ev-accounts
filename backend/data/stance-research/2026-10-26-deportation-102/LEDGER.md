# Researching the 102 on `deportation` — 2026-10-26

**The cohort.** 102 active politicians who hold a non-zero Season 1 `immigration` stance, were
researched on a live successor topic (`deportation` or `local-immigration`) and **blanked there**,
and so now serve no immigration-family position at all. Built in `worklist.tsv` from production
(serving rule: Season 2 preferred, Season 3 excluded, live topics only).

| | rows |
|---|---:|
| state level | **82** (59 already blanked on `deportation`, 23 blanked only on `local-immigration`) |
| federal level | **11** (all blanked on `deportation`) |
| local level | 3 |
| level unresolved (no office or term record) | 6 |

## 🔴🔴 THE GATE THAT DECIDES THIS PASS, READ BEFORE ANY RESEARCH

`inform.compass_topic_roles` for `deportation`:

| role_scope | is_required | evidence_basis |
|---|---|---|
| federal | true | **`record`** |
| state | true | **`own-words`** |
| local | false | **`own-words`** |

Per CLAUDE.md "Scope decides the evidence" (ruling 2026-10-06, option B) and
`backend/src/lib/topicApplicability.ts`: `own-words` means **no lever at this level — a record
cannot seat the chair, only the person's own words can.**

⚖ **So for 85 of the 102 (82 state + 3 local), no bill, vote, co-sponsorship or signing can seat
them.** Only their own words about *federal removal policy* count. That is almost certainly why
they were blanked in the first place: a state legislator's vote on a state bill cannot reach a
ladder that asks "How far should the government go in deporting undocumented immigrants?"

## The ladder (Season 2, q9, revision 55c3167e)

1. Stop deportations entirely and protect undocumented immigrants from removal
2. Only deport undocumented immigrants convicted of serious violent crimes
3. Focus deportation on recent arrivals while leaving long-settled undocumented immigrants in place
4. Deport all undocumented immigrants, starting with those who have criminal records
5. Carry out a mass-deportation program to remove all undocumented immigrants, including
   long-settled families and workers

🔑 **Every rung is defined by a population boundary** — who is removed and who is left. That is the
clause the evidence has to reach, and it is the clause public officials almost never state.

## Triage: is there an own-words source at all? (all 102, `bp-triage.tsv`)

Ballotpedia **Candidate Connection** surveys are the one source type proven to reach an own-words
ladder (they seated Wein at 1 and Patterson at 4 — see `project_chair_evidence_gate_is_record_basis`).
Fetched with `curl -A` (Ballotpedia refuses WebFetch), PID-scoped temp file deleted every iteration,
HTTP status recorded beside every value:

| | people |
|---|---:|
| page reachable (HTTP 200) | 70 |
| of those, **completed a Candidate Connection survey** | **0** |
| explicitly "did not complete" | 57 |
| page fetched but survey status unclear | 13 |
| name slug 404 (needs disambiguation — 21 of them MA) | 32 |

⚠ A 404 here means the name slug did not resolve, **not** that the person has no page.

## Researched individually (federal first — the only level where records are admissible)

Every source below was fetched, not inferred. "No rung" = the evidence establishes a direction but
names no population boundary, so it cannot describe any one chair.

| person | what was read | finding |
|---|---|---|
| **Robert B. Aderholt** (AL) | `aderholt.house.gov/issues/immigration` | Page does not address removal of people already here. "I feel very strongly that amnesty should not be automatically granted" + border-first. **No rung.** |
| **Laurel M. Lee** (FL) | press-release search | Border, parole, Mayorkas impeachment, H.R. 30 (removability on a second sex-offence/DV conviction). Criminal-removal grounds do not establish a limit. **No rung.** |
| **Kurt Alme** (MT, Senate candidate) | NBC Montana, 2026-10-18, direct quotes | "I helped secure the border as United States attorney, by prosecuting criminal illegal aliens." Never uses "deport"; states no scope. **No rung.** |
| **Tom Cole** (OK) | his own weekly column, 2018-07-10 | Names the "estimated 11 million" and says nothing about what should happen to them; supports legal status for DACA recipients only. **No rung.** |
| **James Comer** (KY) | own press releases + Oversight releases | "Illegal alien criminals … have no right to be here", anti-amnesty, anti-sanctuary. Criminal-removal plus opposition to status ≠ a removal boundary. **No rung.** |
| **Ann Wagner** (MO) | `wagner.house.gov/issues/immigration` | Whole page fetched: border security and state/local cooperation; **no sentence mentions removal.** **No rung.** |
| **John W. Mannion** (NY) | `mannion.house.gov/issues/immigration` | Full record read: Stop Excessive Force in Immigration Act, Immigration Court Due Process Protection Act, Dream and Promise Act, TPS Review Act, voted against ICE funding. Restrictive direction, **but no removal boundary** — matches the original blank's "OMISSION FOR COMMITMENT" shape. **No rung.** |
| **Dwight Evans** (PA) | search; `evans.house.gov/immigration` **HTTP 403** to WebFetch and to curl | Constituent ICE casework and DHS accountability. **No rung.** ⚠ Search also returned **Gabe Evans (R-CO-08)** — a different member; not used. |
| **Greg Abbott** (TX, state) | **primary**: `gov.texas.gov` release of 2025-01-29, fetched | His own words direct agencies to "assist federal immigration officers to investigate, arrest, detain, and deport illegal immigrants in Texas" — **unqualified, no limit by criminal record or length of residence**, and no mention of long-settled families or workers. Reaches "remove all" but **cannot separate rung 4 from rung 5**, which is the clause that distinguishes them. **No rung on this evidence.** |

🔴 **Not researched yet:** Brett Guthrie (KY), Jack Bergman (MI), Mike Ezell (MS) — their
house.gov issue pages 404 on all four common paths; they need a press-release search each.
Plus the 90 state/local/unresolved rows.

⚠ **A near-miss worth recording.** The Starr County land offer for deportation facilities, widely
attached to Texas, was **Land Commissioner Dawn Buckingham's letter**, not Abbott's. Seating Abbott
on it would have been the wrong-person defect of migrations 1896/1897 all over again.

## ⚖ The finding this pass produced

**The evidence that exists in public does not have the shape this ladder requires.** Pro-enforcement
officials say "deport illegal immigrants" and "criminal illegal aliens" with no upper boundary, which
is consistent with rungs 3, 4 and 5 at once. Restrictionist-sceptical officials say "protect
families", "due process", "pathway for Dreamers" with no lower boundary, consistent with rungs 1, 2
and 3 at once. The rungs are separated by *who is left alone* — recent arrivals vs long-settled
families and workers — and that is the one thing almost nobody states.

That is a **ladder-scope** observation (see `project_ladder_scope_findings`), not a research gap:
more searching of the same kind reproduces the same blanks, which is exactly what migrations 1902,
1903, 1908, 1909, 1911, 1926, 1927, 1930, 1942 and 1947 already found one cohort at a time.

🔑 **The honest product of researching this cohort is therefore mostly `inform.topic_research_outcomes`
rows (`outcome = 'no-stance'`), not chairs.** That table is **empty in production today**, and
`getResearchStates` already renders from it: a recorded no-find turns an empty spoke into
"We researched {name} and found no public stance on deportation." Nothing has been written.

## ✅ THE FULL PASS — ALL 102 RESEARCHED, 2026-10-26

Operator approved triage depth for the remaining 93: one targeted own-words search each, seat only
the extremes, record the rest. **Result: 102 researched, 0 seated, 102 `no-stance`.**

Per-person source and verdict: `triage-results.tsv` (93 rows) plus the 9 in the table above.

### Why nothing seated — the same clause refused every row
Every rung is defined by **who is left alone**. Pro-enforcement evidence says "deport illegal
immigrants" / "criminal illegal aliens" with no upper bound → fits rungs 3, 4 and 5 at once.
Restriction-sceptical evidence says "due process", "protect families", "pathway for Dreamers" with
no lower bound → fits 1, 2 and 3 at once. The three closest misses:

| person | their own words | why it stops short |
|---|---|---|
| **Greg Abbott** (TX) | gov.texas.gov 2025-01-29, fetched: agencies to "investigate, arrest, detain, and **deport illegal immigrants in Texas**" | unqualified — reaches "remove all" but cannot separate 4 from 5, and rung 4's "starting with those who have criminal records" is absent |
| **Jack Bergman** (MI) | "deporting criminal illegal aliens", "end illegal immigration", opposes "any form of amnesty" | criminal-first + no-amnesty still never says who is **not** removed |
| **Melissa Hurtado** (CA) | "people with criminal pasts have no place in our communities" | one-sided; never "only", silent on everyone else |

### What the cohort DOES talk about — and why it lands on a different ladder
Roughly 30 of the 102 have real public positions on immigration. Nearly all of them sit on the
**state-cooperation** axis (`local-immigration`), not the federal removal axis:
Keenan (police need not work with ICE), Vieira (federal preemption; the Select Board "should not be
handling immigration"), Michael O. Moore ("we can't overreact"), Ashe (police not "forced to round
up immigrants"), Friedman and Rush (Safe Communities / PROTECT Act), Romero (opposes SB8),
Bernal and Walle (SB4), Gervin-Hawkins ("we need jobs — not jails", on a detention warehouse),
Yaroslavsky (motion to sue over federal agents' conduct), Bhojani and Ray Lopez (due process and a
fatal shooting), McNerney (an "appalling" deportation), Eddie Morales (a temporary **asylum**
suspension — admissions, not removal).
🔑 **That is the finding: this cohort's immigration speech is about what the STATE may do, and the
deportation ladder asks what the FEDERAL government should do.** For 85 of them a record cannot
seat the chair anyway, so the two never meet.

### ⚠ Misattributions caught and not written
- A search returned a senate.texas.gov ICE letter as **Molly Cook's**; the fetched PDF is signed
  **Sarah Eckhardt (D14)** — Cook is D15. Caught only by opening the primary.
- The Starr County deportation-facility land offer is **Land Commissioner Dawn Buckingham's**, not
  Abbott's.
- Searches also surfaced Susan Collins for Nick Collins, Will Cain for Briscoe Cain, Gabe Evans for
  Dwight Evans, the filmmaker Michael Moore for Sen. Michael O. Moore, Mayra Flores for Lulu Flores,
  David Bier for David Biele, Steve King for Steve Toth, and Bennie/Mike Thompson for Senfronia
  Thompson. None was used. This is the defect class of migrations 1896/1897.

### The write
`backend/migrations/1950_deportation_research_outcomes_102.sql` — 102 rows into
`inform.topic_research_outcomes` (deportation, Season 2, `no-stance`, researched_on 2026-10-26).
**Dry-run with ROLLBACK passes all four guards; NOT YET APPLIED.**
Guard 3 is the load-bearing one: no target may hold a seated deportation answer, or the outcome
would contradict the compass. Post-flight asserts `politician_answers` and `politician_context` are
byte-for-byte untouched — this migration INSERTs into exactly one table and moves no chair.
`check-migration-numbers` and `check-migration-reservations` both OK (slot 1950 reserved).

⚖ **Why `no-stance` and not `doesnt-fit`:** `doesnt-fit` renders the person's own words from
`inform.own_words_passages`, each with a source_url. The ~30 above would qualify, but most of those
quotes reached this pass through search summaries rather than fetched pages, and the project's rule
is never to cite an unfetched URL. Upgrading a subset later is additive and needs only the fetches.

## Files

- `worklist.tsv` — the 102, with level, immigration value, deportation state and the blank's reason
- `triage-results.tsv` — per-person source and verdict for the 93 researched at triage depth
- `bp-triage.tsv` — Ballotpedia reachability and survey status for all 102 (status beside every value)
- `bp-triage.sh`, `house-issues.sh` — the sweep scripts
