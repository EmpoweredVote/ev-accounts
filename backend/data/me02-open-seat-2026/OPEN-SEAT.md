# ME-02 was an OPEN seat, and our winner citation said otherwise

**Status 2026-11-17: fixed in production by `CC_0452`.** One citation changed, repo-wide. Nothing
was created, nothing was deleted, and Jared Golden still holds the seat.

`CC_0447` recorded Paul LePage's win and wrote this, live on a voter-facing page:

> Called 2026-11-12T18:31:29.417Z, **defeating incumbent Jared Golden.**

Golden was ME-02's incumbent and **was not a candidate**. He announced on 2025-11-05 that he would
not seek re-election. LePage defeated **Matthew Dunlap**, for an **open** seat.

## 🔴 The defect is not a typo. It is a two-way test that needed three branches.

AP's feed publishes an `incumbent` for a race. `CC_0447` compared it against the winner:

| AP comparison | What `CC_0447` wrote | Where |
|---|---|---|
| winner id **==** incumbent id | "Incumbent re-elected" | CA-23 Obernolte, NC-07 Rouzer |
| winner id **!=** incumbent id | "defeating incumbent X" | CA-04, CO-04 — **and ME-02** |

The first branch is careful work: it compares AP **candidate IDs**, not surnames, which is exactly
the namesake guard this repo pays for elsewhere. The hole is in the second.

🔴 **AP's `incumbent` is an attribute of the SEAT, not a ballot line.** "The winner is not the
incumbent" does not mean "the winner beat the incumbent". The incumbent may not have run. The
missing question is the third branch:

> **Is the incumbent's candidate id on a LOSING BALLOT LINE in this race?**
> **yes** → the winner defeated the incumbent.  **no** → open seat; the incumbent did not run.

⚠ **The same pass got four of five right, and that is the point.** A rule can be right most of the
time and still be the wrong rule. Four green rows are not evidence the rule is sound — they are
evidence the fifth case is rarer.

### 🔴 The evidence that the claim was false was inside the file the claim was built from

From `backend/data/house-2026-late-losers/ap-ballots-2026-11-17.json`, race `20261103ME20645`:

```
ap_incumbent : { candidate_id "66383", first "Jared", last "Golden" }
all_lines    : 60414 LePage · 174146 Dunlap · 179614 Blank Votes · 120523 Ward (write-in)
```

**AP names Golden as the incumbent and puts him on no ballot line, in the same object.** Nothing
had to be fetched to know this was wrong.

## The sources, each read as a document

| # | Source | What it settles |
|---|---|---|
| 1 | **Maine SoS, "2026 General Candidate List – FINAL"** (.xlsx), committed here | CD-2 printed **exactly two** names |
| 2 | **AP's own capture**, committed by `CC_0450` | AP's incumbent sits on no ballot line |
| 3 | **The Maine Monitor / NOTUS**, published 2025-11-05, page read 2026-11-17 | He announced he would not run |

### 1. The State's own list, parsed from its XML

Downloaded from `maine.gov/sos/elections-voting/upcoming-elections` and committed as
`me-2026-general-candidate-list-FINAL.xlsx`, so the claim re-reads offline. Office code `CG`,
District 2:

```
CG | Dist 2 | ... | Dunlap, Matthew G.
CG | Dist 2 | ... | LePage, Paul R.
```

Golden appears in **none** of the file's 456 rows.

🔴 **A NAME SEARCH THAT FINDS NOTHING IS A BROKEN SEARCH UNTIL A CONTROL PASSES.** The same probe
was run for names that must be there:

| probe | rows found |
|---|---|
| `lepage` | 2 |
| `dunlap` | 1 |
| `mills` | 1 |
| **`golden`** | **0** |

The detector is live, so the zero is an absence rather than a failure.

### 3. His own words, from the page and not from a search summary

> "Rep. Jared Golden announced Wednesday that he will not seek reelection", writing in the Bangor
> Daily News — *"I don't fear losing. What has become apparent to me is that I now dread the
> prospect of winning."*

⚠ **A web search summary was not the source for any name or date here.** It located the page; the
page was fetched and read. `WebFetch` fabricates names and dates and formats them as quotations,
and a name and a date are exactly what this correction turns on.

## 🟢 What is *not* wrong, and must not be "fixed"

**Golden still holds the seat.** His `office_terms` row — `term_start` 2019-01-03, open-ended,
from `unitedstates/congress-legislators` via migration 1536 — is correct, and `CC_0452` does not
touch it. A **retiring** incumbent holds the office until the term ends on **2027-01-03**, exactly
as a **defeated** one does. The repo already knows that a losing incumbent still holds the seat;
this is the same rule reached from the other side.

🔴 **Assertion 10 pins it**, because the obvious misreading of this correction is "then Golden
should not be in `office_current_holder`". Control M was watched making it fire.

### The four other `CC_0447` winner citations were checked and are all TRUE

Each was tested twice — against our own `office_terms`, and against AP's ballot:

| Seat | Claim | Verdict |
|---|---|---|
| CA-04 | Jones "defeating incumbent Mike Thompson" | ✅ Thompson holds CA-04 **and** lost the race, 120,361 to 133,179 |
| CO-04 | Laubacher "defeating incumbent Lauren Boebert" | ✅ Boebert holds CO-04 **and** lost the race, 184,220 to 187,745 |
| CA-23 | Obernolte "Incumbent re-elected" | ✅ winner id == incumbent id |
| NC-07 | Rouzer "Incumbent re-elected" | ✅ winner id == incumbent id |

The two loser rows reading "the defeated incumbent" (Thompson, Boebert) are each talking about
themselves, and each is its seat's holder and a losing line. All five are left exactly as they are.

## What the migration overwrote, written down before it was destroyed

`result_source` has no history table, and this repo has no `schema_migrations` to replay from, so
an `UPDATE` is final: the previous value exists nowhere the moment it commits. `CA_0335` cost a
full production clone by recording only its new values — **and destroyed the evidence for its own
premise in the bargain.**

So the old string is in `before-values.json` and in the migration's header, verbatim, with
`md5_before = 32379de0539db5d416bcbec49ba34b13` and `length_before = 474`.

🔴 **The header claim is GATED, not merely stated.** The pre-check refuses to write anything unless
the live value still hashes to that md5 — so if someone else edited the citation in between, the
migration stops instead of overwriting their work. Control B was watched making it fire.
▶ **A recorded old value is only testable while the old value is still there. Gate on it.**

🟢 **The write is a `replace()` on the live string, not a restatement of it.** Only the
35-character clause moves; the AP race id, both vote counts, the ranked-choice final round, the
call timestamp and the canvass caveat survive **by construction** rather than by careful retyping.

## ⚠ The first dry run failed, because the fix quoted the thing it was fixing

The corrected citation originally ended `...which replaced the clause "defeating incumbent Jared
Golden" written by CC_0447`. **Assertion 2 refused it** — it tests that the false sentence is not
in the field *at all*, and a quotation is still in the field. A reader skimming the citation would
have met the false claim in quotation marks.

It now refers to the clause without reproducing it. The verbatim text lives in the header and in
`before-values.json`, where a reader is looking at a record rather than a citation.
▶ **A gate that is blunter than you expected is usually right.** Kept as control F.

## Controls — seventeen tampers, each watched going red

Every assertion **and** all three pre-checks were reached.

| Control | What it changes | Gate that caught it |
|---|---|---|
| A | the pin points at CA-04's winner | ✅ pre-check (0 ME-02 winners named LePage) |
| B | the header's recorded md5 is edited | ✅ pre-check (live hash disagrees) |
| C | a clause that occurs zero times | ✅ pre-check (0 occurrences) |
| D | a **Jared Golden candidacy row** is created in ME-02 | ✅ pre-check (the premise would be false) |
| E | CA-04's loser citation is edited too | ✅ 1 (`2 citation(s) repo-wide changed`) |
| F | the new text **repeats the false claim** | ✅ 2 |
| G | CA-04's defeated incumbent is **renamed** | ✅ 3 |
| P | the citation names **Dunlap** as the winner | ✅ 4 |
| Q | the citation carries **(ME-12)** | ✅ 5 |
| H | the `replace()` **swallows the canvass caveat** | ✅ 6 |
| I | the row's **certainty** is changed | ✅ 7 |
| J | the **marker is dropped** | ✅ 8 (`0 row(s)`, expected 1) |
| K | a **politicians** row is created | ✅ 9 (`91881 → 91882`) |
| L | a **politician_images** row appears | ✅ 9 (`9839 → 9840`) |
| O | a candidate row is created in CA-04 with no citation | ✅ 9 (`6896 → 6897`) |
| M | **Golden's term is closed** | ✅ 10 |
| N | CA-23's row leaves the `CC_0447` cohort | ✅ 11 |

### 🔴 Sixth migration running, same house rule

A check comparing a row against the migration's **own declared** value is satisfied by any pin
edited consistently. The gates whose expectation comes from outside this file:

| Assertion | Expectation taken from |
|---|---|
| 1 — one citation changed | the md5 of **all 5,296 citations**, captured in the same transaction |
| 3 — the claim names a real opponent | `essentials.race_candidates` — this file declares no name here |
| 4 — names its own person | `rc.full_name`, from the table |
| 5 — names its own seat | `d.state` + `substr(d.geo_id, 3, 2)` |
| 6 — the numbers survived | **CC_0450's Dunlap citation**, which carries the same final round |
| 10 — Golden still seated | `office_current_holder`, a table this file never writes |
| pre-check | **production's own md5**, which no edit to this file can change |

### 🔴 Four controls exist only because the obvious tamper was shadowed

Assertion 1 fires on *any* second citation changing, so every control aimed at a **later** gate had
to avoid touching a second citation at all:

- **G** (assertion 3) renames the *row* rather than editing a citation — `full_name` is not hashed.
- **N** (assertion 11) moves a *timestamp*, dropping CA-23 out of the cohort silently.
- **P** and **Q** (assertions 4 and 5) fix the clause correctly **first**, then break the winner
  token / seat label **on the same row**, so only one citation has changed.
- **J** (assertion 8) drops the marker rather than adding a second one.

▶ **An earlier gate catching the fault is not evidence that the later one works.** Fourth migration
running where controls had to be rebuilt around a shadow.

### ⚠ One control failed to APPLY and looked exactly like a pass of the wrong kind

Control K first read `INSERT INTO essentials.politicians (… is_incumbent …)` and died with
`column "is_incumbent" of relation "politicians" does not exist`. The dry run printed **FAILED**,
which is what a working control prints too. **`is_incumbent` lives on `race_candidates`.**
▶ **Read what the red SAYS, not that it is red.** A tamper that never applied proves nothing.
(⚠ CLAUDE.md's occupancy section still instructs setting `politicians.is_incumbent` on every
insert. The column is not there. Observed, not acted on — it is not this migration's to fix.)

## What this deliberately does not do

- **It does not re-stamp `result_recorded_at`.** The *result* did not change; a citation did.
  Moving that timestamp would claim the call was re-read today, and it was not.
- **It creates no `race_candidates` row for Golden.** He was not a candidate — a row would assert
  the opposite of the finding. Pre-check P3 refuses if one exists.
- **It adds no general CI gate for the three-branch rule.** That gate wants to read AP's ballot,
  which lives in a committed JSON file rather than in the database, so it belongs with the matcher
  in `match-losers.mjs`, not in a post-verify block. 🔴 **Assertion 3 pins the half that IS
  answerable in SQL — every "defeating incumbent X" claim repo-wide must name somebody holding a
  losing row in that same race — and that half alone would have caught `CC_0447`.**

## Files beside this one

| File | What it is |
|---|---|
| `before-values.json` | the overwritten value, its md5 and length, plus the verdict on every other "incumbent" claim in the repo |
| `me-2026-general-candidate-list-FINAL.xlsx` | the State's own final list of printed ballot names, committed so the claim re-reads offline |

## Still open

| Item | Shape |
|---|---|
| **2026-11-23** | Maine's official tabulation is due within 20 days; then certify all 13 rows in the five races |
| **2026-11-25** | Colorado's abstract, then decide Luis Galvan |
| **The matcher gate** | Teach `match-losers.mjs` the third branch, so the next pass cannot repeat this |
| **Seating** | LePage takes office **2027-01-03**. Golden holds ME-02 until then. Nothing here seats or unseats anybody |
