# The five CC_0447 House races — the losers pass

**Status 2026-11-17: 7 candidate rows recorded as `lost` (`CC_0450`).** Each carries
`result_certainty = 'called'`. Nothing is certified. Nothing is seated.

`CC_0447` recorded the five winners AP had called since `CC_0350` and deliberately recorded no
losers. This is that pass, and it follows `CC_0351`'s rule unchanged.

| Seat | Loser | Party | Votes | % | Note |
|---|---|---|---|---|---|
| CA-04 | Mike Thompson | Dem | 120,361 | 47.47 | defeated incumbent |
| CA-23 | Tessa Lynn Hodge | Dem | 105,783 | 49.17 | |
| CO-04 | Lauren Boebert | GOP | 184,220 | 47.89 | defeated incumbent |
| CO-04 | Douglas Mangeris | Lib | 12,742 | 3.31 | |
| ME-02 | Matthew Dunlap | Dem | 164,845 | 48.31 | **ranked choice**, final round 165,432 |
| NC-07 | Kimberly Hardy | Dem | 158,391 | 49.15 | |
| NC-07 | Maad Abu-Ghazalah | Lib | 3,173 | 0.98 | |

## 🔴 The rule: a loser is recorded because AP's ballot names them

> "Everyone in a called race who is not the winner lost" is the inference `CC_0339`, `CC_0350`
> and `CC_0447` each refused.

`CC_0351` wrote down why. Our `race_candidates` still carries **Lindsey Graham**, who died in
office on 2026-07-11 and was not on the November ballot. A blanket rule would have recorded a
dead man as losing an election he was not in.

So every row here was matched against **AP's own candidate list for that race**, one at a time.

## 🔴 Eight of our rows are non-winners. Seven are written. The eighth is the finding.

**CO-04's Luis Galvan is a declared WRITE-IN candidate**, and that one fact explains both of the
odd things about his row.

| | Luis Galvan | Douglas Mangeris |
|---|---|---|
| Seeded from | Colorado SoS 2026 General Candidate List | the **same** list |
| `candidate_status` | `filed` | `active` |
| On AP's CO-04 ballot | **no** | yes, 12,742 votes |
| Ballotpedia's CO-04 result table | `Luis Galvan (R) (Write-in)` — 0 votes | `Douglas Mangeris (L)` — 12,722 votes |

AP's CO-04 ballot carries the three printed lines and no write-in line at all, so AP's silence
about him is not evidence he was absent — it is evidence AP does not tabulate Colorado write-ins.
The reason his status differs from Mangeris' is that the Secretary of State's own list already
distinguished them.

⚠ **Ballotpedia's counts above are lower than AP's by a few hundred votes, and that is a
timestamp, not an error.** Its CO-04 table reads Laubacher 187,518 / Boebert 184,066 /
Mangeris 12,722 where AP reads 187,745 / 184,220 / 12,742; its CA-23 table is short by the same
shape. Both are unofficial tallies read at different moments while counting continued. **Every
number written to the database comes from AP**, which is the source the citation names.

⚠ **His vote total cannot be settled today, and the difference matters.** Colorado's county
abstracts are due to the Secretary of State within 22 days of the general election
([C.R.S. 1-10-105](https://colorado.public.law/statutes/crs_1-10-105)), so the document that can
confirm a certified write-in's count publishes **on or after 2026-11-25**. A 0 on an aggregator
before the canvass is not the same fact as a certified 0.

▶ **2026-11-25: read Colorado's abstract of votes, then decide Galvan.** `CC_0450`'s assertion 7
fails if anything writes a result on his row before that question is answered.

## 🔴 AP's ME-02 ballot carries both kinds of "write-in" at once

| Line | `first` | Votes | Treated as |
|---|---|---|---|
| `Blank Votes` | **none** | 6,021 | **not a person** — excluded from the match |
| `Gregory Ward (write-in)` | `Gregory` | 125 | **a person** — matched like any other |

A predicate on the words "write in" merges the two, and one on "blank" misses the general case —
`CC_0351` met the same shape spelled `Total Write-ins`. **The discriminator is the absence of a
first name**, which holds for both spellings. Control M2 proves the test is live: strip Gregory
Ward's first name and he is reclassified as an aggregate.

**Gregory Ward is the only AP line in these five races we hold no row for.** We cannot mark a
loss against a row that does not exist, and a losers pass is not where a missing contender gets
seeded. Assertion 11 fails if this migration creates one.

✅ **Closed 2026-11-17 by `CC_0451`**, which seeded him and recorded the loss. He is a **declared
write-in** on the Maine SoS's separate register — so he is the Galvan finding reflected: a write-in
AP's ballot holds and our data omitted, where Galvan is one our data holds and AP omits. Same
cause, opposite direction. Write-up: `backend/data/me02-write-in-2026/WARD.md`.

## ⚠ One name is spelled differently, and ours is the longer one

AP's CA-23 line reads **"Tessa Hodge"**. Our row reads **"Tessa Lynn Hodge"**. Confirmed outside
AP: Ballotpedia's CA-23 general-election result table also writes "Tessa Lynn Hodge". Same person.

She is matched by a fallback — *our `last_name` ends with AP's `last`, and the first names agree* —
because our row splits her name as `Tessa` / `Lynn Hodge`. The citation records both spellings,
and the `LOSER=` token carries **our** spelling, because assertion 2 compares that token against
the row's own `full_name`.

## The matcher, and the controls that prove it reads AP rather than guessing

`match-losers.mjs` takes two committed files and no database, so the match re-derives and
re-tampers offline:

```
node match-losers.mjs --ap ap-ballots-2026-11-17.json --ours before-values.json --out .
```

Clean run: **7 losers · 1 AP line we hold no row for · 1 row of ours AP omits · 1 spelling
difference · 1 aggregate line excluded.**

| Control | What it changes | Observed |
|---|---|---|
| M1 | Luis Galvan is added to AP's CO-04 ballot | **8 losers**, and "our rows AP omits" falls to 0 |
| M2 | Gregory Ward loses his first name | he is reclassified as an **aggregate**, 2 excluded |
| M3 | Tessa Hodge is renamed to an unmatchable string | **6 losers**; she moves to the omitted bucket |

🔴 **M1 is the one that matters.** It proves Galvan's exclusion is *caused by* AP's ballot rather
than by luck — the same control `CC_0351` ran on Lindsey Graham. A control that has only ever
passed proves nothing.

## The migration's own controls — eight tampers, each watched going red

| Control | What it changes | Result |
|---|---|---|
| A | Thompson and Hodge are given **each other's** citation, both pins edited consistently | ✅ `2 row(s) carry a result_source that does not name the candidate it is attached to` |
| B | Luis Galvan is recorded as a loser | ✅ `Luis Galvan was given a result; AP's CO-04 ballot does not name him` |
| C | every row claims `certified` | ✅ `7 row(s) do not carry certainty called with the canvass caveat` |
| D | Mangeris cites NC-07's AP race id, **name still correct** | ✅ `1 row(s) cite an AP race id their own race's winner does not cite` |
| E | Mangeris carries the seat label `(CO-14)`, **name and race id still correct** | ✅ `1 row(s) carry a seat label that is not the seat the row sits in` |
| F | a CA-47 row outside the five races gets this migration's marker | ✅ `8 row(s) repo-wide carry this migration's marker, expected exactly 7` |
| G | Gregory Ward is seeded with no result | ✅ `expected exactly one row left without a result (Luis Galvan), found 2` |
| H | Gregory Ward is seeded as a **winner**, so only the row count moves | ✅ `the five races held 13 rows and now hold 14` |

### 🔴 The gate must not read its expectation out of the migration

`CC_0447`, `CC_0448` and `CC_0449` each lost a control to the same defect: a check that compares
a row against the migration's **own declared** value is satisfied by any pin edited consistently,
so it tests a vocabulary instead of a pairing. Four migrations running now, so it is a house rule.

Controls A, D and E are three different ways to break a pairing, and each is caught by a different
assertion whose expectation comes from somewhere a tamper on the file cannot reach:

| Assertion | Expectation taken from |
|---|---|
| 2 — the citation names its own person | `rc.full_name`, read from the table |
| 3 — the citation names its own race | the **winner's** `result_source`, written to production by `CC_0447` |
| 4 — the citation names its own seat | `d.state` and `substr(d.geo_id, 3, 2)`, the row's own geography |

**D and E are deliberately layered.** D keeps the right name and breaks the race; E keeps the
right name *and* the right race id and breaks only the seat label. Without E, assertion 4 would
never have been watched failing on its own.

### ⚠ Control G fired on the wrong assertion, and that is recorded rather than tidied away

G was built for assertion 11 — *this migration creates and deletes nothing*. A seeded row with no
result is a second row without a result, so **assertion 8 caught it first and assertion 11 was
shadowed**. H seeds the same person as a winner instead: assertion 6 does not count him (he
carries neither a `WINNER=` token naming himself nor `CC_0447`'s marker), 8, 9 and 10 all stay
satisfied, and only the row count moves. Then assertion 11 fires.

▶ **An earlier gate catching the fault is not evidence that the later one works.**

### 🟢 Two schema CHECK constraints caught control H before the gate did

`race_candidates_result_needs_source` and `race_candidates_won_needs_certainty` both rejected the
seeded row before the post-verify block ran. They are real guards, they were not written for this
migration, and a result written without a citation cannot reach this table.

## 🟢 What it overwrites: nothing

All four result columns — `result`, `result_certainty`, `result_source`, `result_recorded_at` —
were **NULL on all seven rows**, read from production and recorded in `before-values.json`, which
holds all 13 rows in the five races, winners included. Unlike `CC_0351`, where 104 of 599 rows
carried a state ballot-qualification citation that had to be appended rather than replaced, no
citation is destroyed here. The pre-check refuses if any of the four is non-NULL, so the header
cannot quietly go stale.

The rows' `source` column — where the candidacy came from — is not touched.

## Source, read twice

AP's own results feed, no key:

```
https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/metadata.json
https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/progress.json
```

Captured **2026-11-17 14:26Z** into `ap-ballots-2026-11-17.json` — AP's full ballot for the five
races, every line, not just the winner. Re-fetched for this pass rather than reusing `CC_0447`'s
03:00Z capture, and every vote count, percentage and `lastUpdated` stamp came back identical.

⚠ A bare `curl` gets 403. The feed needs a browser `User-Agent`, `Referer: https://apnews.com/`
and `--compressed`.

🔴 **A media call is not a state canvass.** AP reports `isCertified: false` for all five races.
Assertion 5 fails if any row claims otherwise.

## Files beside this one

| File | What it is |
|---|---|
| `ap-ballots-2026-11-17.json` | AP's full candidate list for the five races — every line, with votes, percentages and the winner flag |
| `before-values.json` | all 13 rows in the five races as production held them before `CC_0450` |
| `match-losers.mjs` | the matcher, so the match re-derives and re-tampers with no database |
| `losers-2026-11-17.json` | the 7 matches, with both spellings and how each was matched |
| `our-rows-ap-omits.json` | Luis Galvan |
| `ap-lists-we-hold-no-row-for.json` | Gregory Ward |
| `spelling-review.json` | Tessa Lynn Hodge |

## What is still open on these five races

| Item | Shape |
|---|---|
| **Luis Galvan** | Decide after Colorado's abstract, due on or after **2026-11-25** |
| ~~**Gregory Ward**~~ | ✅ **CLOSED 2026-11-17 by `CC_0451`** — seeded as **Gregory A. Ward** (the Maine SoS declared write-in register spells him with a middle initial) and recorded `lost`/`called`. See `backend/data/me02-write-in-2026/WARD.md` |
| `certified` | A later pass, per state, against that state's own canvass — none of the five is certified yet |
| Seating | These winners take office **2027-01-03**. Nothing here seats anybody |
