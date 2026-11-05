# 2026-11-03 state executives — the results AP has called — `CC_0357`

Applied to production 2026-11-05. **53 candidacies written: 18 won, 35 lost**, across the
18 statewide-executive races AP covers in the six states we hold state-executive races for.
State executives go **0 → 18 won** and **0 → 35 lost**.

| race | winner | pct | losers | EEVP | AP incumbent of record |
| --- | --- | --- | --- | --- | --- |
| AZ Attorney General | Kris Mayes | 55.36 | Warren Petersen 44.64 | 85.51 | — |
| AZ Governor | Katie Hobbs | 55.57 | Andy Biggs 42.70; Risa Lombardo 0.89; Teri Hourihan 0.83; Gertritrude Gonzalez 0; Alice Novoa 0 | 85.51 | Katie Hobbs (Dem) |
| AZ Secretary of State | Adrian Fontes | 54.80 | Alexander Kolodin 43.79; Duwayne Collier 1.41 | 85.50 | — |
| CA Attorney General | Rob Bonta | 64.01 | Michael E. Gates 35.99 | 61.33 | — |
| CA Governor | Xavier Becerra | 64.19 | Steve Hilton 35.81 | 61.14 | Gavin Newsom (Dem) |
| CA Lieutenant Governor | Fiona Ma | 64.02 | Gloria Romero 35.98 | 61.24 | — |
| CA Secretary of State | Shirley N. Weber | 64.94 | Donald P. Wagner 35.06 | 61.17 | — |
| CO Attorney General | Jena Griswold | 58.16 | Michael Allen 41.84 | 86.19 | — |
| CO Governor | Phil Weiser | 60.49 | Victor Marx 33.96; Greg Lopez 2.80; Eric Mulder 1.59; Stephen T. Hamilton 0.63; Erik Underwood 0.32; Jeff Peckman 0.20 | 87.27 | Jared Polis (Dem) |
| CO Secretary of State | Amanda Gonzalez | 59.44 | James Wiley 37.62; Amanda Campbell 0.79; Celeste Landry 0.64 | 86.55 | — |
| IN Secretary of State | Beau Bayh | 51.81 | Max Engling 42.60; Greg Ballard 3.60; Lauri Shillings 1.99 | 98.02 | — |
| NV Attorney General | Nicole J. Cannizzaro | 56.26 | Adriana Guzman Fralick 41.54 | 90.14 | — |
| **NV Governor** | **Aaron Ford — flip** | 51.53 | Joe Lombardo 44.22 | 90.14 | Joseph Lombardo (GOP) |
| NV Lieutenant Governor | Sandra Jauregui | 54.32 | Stavros Anthony 41.22 | 90.11 | — |
| NV Secretary of State | Cisco Aguilar | 56.88 | Jim Marchant 39.47; Brad Barnhill 1.46; John T. Kennedy 0.85 | 90.09 | — |
| WI Attorney General | Josh Kaul | 54.72 | Eric Toney 45.28 | 98.50 | — |
| WI Governor | David Crowley | 54.08 | Thomas P. Tiffany 45.92 | 98.50 | Tony Evers (Dem) |
| WI Secretary of State | JoCasta Zamarripa | 50.69 | Jay Schroeder 45.53; Pete Karas 3.78 | 98.50 | — |

**NV Governor is the only seat AP flags as flipped**: the sitting governor Joe Lombardo
(GOP) lost. Four of the five governorships were open — Newsom, Polis and Evers were not on
their ballots and each seat was held by the same party; Hobbs is the one incumbent governor
who ran and won.

`ap-2026-11-05.json` is the joined `metadata.json` + `progress.json` response for these 18
races, verbatim, because a live feed is overwritten in place. `controls357.mjs` is the
tamper suite.

## 🔴 The two AP files disagree about shape, and the wrong guess is SILENT

`metadata.json`'s `candidates` is an **object map keyed by candidateID**.
`progress.json`'s `candidates` is an **ARRAY**.

Indexing the array as a map returns `undefined` for every candidate. The reconciliation
printed every percentage as `-` and **not one winner**, for 18 races AP had all marked
`Called`. That reads like a feed with no results in it, not like a broken reader.

▶ **It was caught only because the answer was UNIFORM.** Every race blank at once is a
detector failure; one race blank would have been a data question. The reader now throws if
`progress.candidates` is ever not an array, so the next shape change is loud.

⚠ And the `statePostal` field is called `statePostal`. A filter on `r.state` silently
returned **zero** races — `state` exists on these objects and is a boolean meaning
"statewide". Printing the unfiltered count beside the filtered one is what exposed it.

## 🔴 This file OVERWRITES 11 rows, and they were a primary result wearing a general's clothes

Arizona's 11 rows read `advanced` — written by `CA_0281` on 2026-09-24 against the
**November** race row, meaning "won the primary, is on the November ballot". That is a fact
about the **primary**. The November result supersedes it.

Every prior value is written into the migration header, because there is no history table
and an `UPDATE` is final.

▶ **The companions were decided, not left.** `result_source` still carried Arizona's
primary-canvass citation and `result_recorded_at` still read 2026-09-24. Both are replaced.
Leaving either would have gone on citing and dating a record that no longer exists — the
defect `CC_0354` had to repair on 155 rows.

▶ **A pre-gate allows a pin to carry only NULL or `advanced`.** Anything else means someone
wrote here after this file was built, and it refuses. Tamper E proves it fires.

## The rest of the tier needs a different source

**16 of our 34 state-executive races are not in this file, because AP's feed does not carry
those offices at all** — its state-level coverage is Governor, Attorney General, Secretary
of State and Lieutenant Governor, and nothing else:

| office | races | note |
| --- | --- | --- |
| Treasurer | 6 | AZ, CA, CO, IN, NV, WI — all six |
| Controller | 2 | CA, NV |
| Superintendent of Public Instruction | 2 | AZ, CA |
| **Lieutenant Governor (CO, WI)** | 2 | 🔴 **runs on the Governor's TICKET** — AP publishes no separate race, and the result follows the Governor's. It is derivable, but from the ticket composition, not from this feed. Not guessed here. |
| AZ Corporation Commissioner | 1 | ⚠ **multi-seat (2 elected)** — "exactly one winner" is the WRONG shape for it |
| AZ State Mine Inspector | 1 | |
| CA Insurance Commissioner | 1 | |
| IN Comptroller | 1 | |

🔴 **Do not reach for the `CC_0357` pattern on the Arizona Corporation Commission.** Its
race elects two members, so the top-vote-getter gate and the one-winner gate are both
wrong there, in a way that would pass quietly for the one winner it did record.

## 🔴 Colorado Secretary of State: we hold a candidate who is on no ballot

**Alex Astley won the Libertarian primary and then withdrew in August 2026.** The party's
vacancy committee named **Sean Vadney**, whom a Denver judge put on the November ballot on
2026-09-04 (*Vadney v Griswold*, Denver District Court 2026CV33176). AP's ballot lists
Vadney at 1.51% and does not list Astley.

So our side has a candidacy row for a non-candidate, and no row for the person who actually
ran. **Astley is left NULL deliberately.** Recording `withdrew` is a different act with a
different source, and inferring a status from absence is the thing that is not allowed here.
Seeding Vadney is a separate act too. Both are owed; neither is done by this file.

## AP ballot lines we hold no row for

| race | AP candidate | pct |
| --- | --- | --- |
| CO Secretary of State | Sean Vadney (Lib) | 1.51 |
| NV Governor | Danielle Ford (NPA) | 2.80 |
| NV Lieutenant Governor | Janine Hansen (IAP) | 2.72 |

⚠ **NV Governor holds two people called Ford** — the winner **Aaron** Ford (Dem) and
**Danielle** Ford (NPA), who is not ours. Every row is pinned by `race_candidates.id` and
every name is asserted, so no last-name join decides anything. That is the TX-22
twin-brother hazard in a different costume.

🔴 **Nevada's "None of These Candidates" is a ballot line, not a person.** AP gives it
candidateID 100013 and it appears on all four NV ballots, polling 1.34–2.20%. It gets no
candidacy row, and the generator refuses to run if it is ever the winner — **in Nevada it
can be**, and then the office is filled by the runner-up.

## A call is not a canvass

`result_certainty` is `called` on all 53. AP reports `isCertified: false` for all 18 and
counting is live — California is at ~61% of the expected vote, Arizona ~85%. The
`certified` upgrade is a separate pass, per state.

`result_recorded_at` is `now()`, **measured** at the write:
`2026-11-05 15:22:24.462639+00` on all 53, microseconds and all. It is not derived, unlike
the 1,009 rows `CC_0354` had to date from git commit timestamps.

## Controls

Six tampers, each asserted PRESENT in the file before running, each planting one fault.
All six fired.

| | fault planted | gate aimed at | observed |
| --- | --- | --- | --- |
| A | CO Governor's winner and loser transposed | top-vote-getter | `the winner is not the top vote-getter: CO Governor: Victor Marx won on 33.96% but Phil Weiser polled 60.49%` |
| B | a pinned candidacy filed under the CA Governor race | pin exists in its stated race | `only 52 of the 53 pinned rows exist in their stated race` |
| C | four extra rows stamped outside the 53 | over-reach, vs the pre-write snapshot | `57 state-executive row(s) changed, expected exactly 53` |
| D | AP's spelling of a name written in | pin still names the expected person | `a pinned id no longer names the expected candidate: NV Governor Joseph Lombardo <> Joe Lombardo` |
| E | one pin repointed at a candidacy whose prior result is `not_nominated` | the overwrite gate | `a pinned row carries an unexpected prior result: AZ Attorney General Rodney Glassman = not_nominated` |
| F | a pin repointed at Alex Astley, the deliberately-undecided row | *(aimed at the undecided-names gate)* | 🔴 **SHADOWED** — fired `1 of the 7 leave-alone rows was changed` instead |

- **E needed the name to travel with the id.** Changing the id alone trips the NAME gate,
  which runs earlier. Moving both is still ONE fault — "this file targets the wrong
  candidacy" — and it is the only way to reach the overwrite gate.
- **F is labelled by what it tested, not by what it was for.** It reached post-verify
  check 4, and that turned out to be worth knowing: I had assumed check 4 was subsumed by
  the snapshot diff, and it is **not**, because the tampered pin is still pinned so the
  diff still counts exactly 53. F tests check 4.
- 🔴 **The undecided-names gate is unreachable by tamper from here.** Every NULL row in the
  18 races is either pinned or on the leave-alone list, so changing the undecided set means
  dropping a pin (trips the 53-count gate) or duplicating one (the temp table's `PRIMARY
  KEY` rejects it). It is held by reading — **but it has already failed once for real**:
  its first version expected Astley alone, fired during the dry run, and NAMED Greg Roeberg
  and Karrin Taylor Robson. A gate that has failed on real data has better evidence behind
  it than a synthetic tamper would give it.

## 🔴 A gate of this file's own fired on the first dry run, and the gate was wrong — twice

1. **`18 of the 18 races do not hold exactly one winner`.** All eighteen, which is the
   signature of a broken query rather than bad data. Joining `calls` (53 rows) to each
   race's candidates fans out, so every race's winner was counted once per pinned row.
   Fixed with `SELECT DISTINCT race_id FROM calls`. Prod was unchanged.
2. **`the undecided rows in the 18 races are not exactly Alex Astley: Alex Astley; Greg
   Roeberg; Karrin Taylor Robson`.** My expectation was wrong, not the data: both of those
   are `candidate_status = 'withdrawn'` and were already NULL. The gate now names all three
   **and** asserts the two really do read withdrawn-and-undecided.

▶ Both were caught because the gates **named** what they found instead of counting it.

## Verified against production after applying

| check | result |
| --- | --- |
| State-executive candidacies | 112 (unchanged) |
| won / lost | **18 / 35** (was 0 / 0) |
| `advanced` remaining | 13 (was 24 — the 11 Arizona rows superseded) |
| `not_nominated` | 10 (unchanged) |
| still NULL | 36 (was 78) |
| Rows changed by this file | exactly 53, every one pinned |
| Rows claiming `certified` | 0 |
| won/lost with no `result_recorded_at` | 0 |
| won/lost dated before 2026-11-04 | 0 |
| Distinct timestamps across the 53 | 1 — `2026-11-05 15:22:24.462639+00` |
| Races holding exactly one winner | 18 of 18 |
| Races with a loser and no winner | 0 |

## Still open in this tier

- **16 state-executive races AP does not cover** (table above). CO and WI Lieutenant
  Governor are the cheapest: both follow their Governor's ticket.
- **CO SoS**: record Alex Astley's withdrawal; seed Sean Vadney.
- **Seed 3 AP ballot lines we hold no row for** (Vadney, Danielle Ford, Janine Hansen).
- `certified` upgrades, per state, as each canvasses. Nothing is certified today.
- **We hold state-executive races for only 6 states.** AP called 36 governorships on
  2026-11-03. The other 30 states' executives are not seeded at all — that is the state
  tier, not a gap in this file.

---

# 🔴 `CC_0357` DID NOT FINISH THE TIER, AND THE WAY IT LOOKED FINISHED IS THE LESSON

`CC_0357` recorded 18 state-executive results and reported the tier done. **AP had called 98.**

It was scoped to *races we already hold*, which is the right scope for a results migration
and the wrong scope for the question "are the state executives recorded". The difference
never showed, because **a race that does not exist produces no row, no gap and no error** —
it is simply absent from every count the migration took.

▶ **THE CHECK THAT CATCHES IT RUNS THE OTHER WAY ROUND: start from the SOURCE's list, not
from ours.** `ap-state-exec-gap.mjs` does that — it walks all 104 AP state-executive races
and classifies each against our data. Measured 2026-11-05:

| | n | |
| --- | --- | --- |
| recorded by us | 18 | `CC_0357` |
| **seat exists, NO 2026 race row** | **76** | across **32 states** — the gap |
| we hold no such seat | 4 | CT Secretary of State · DC Attorney General · MA Secretary of State · TX Railroad Commissioner |
| AP has not called it | 6 | AK Governor · IA AG · KS Gov/AG/SoS · OH AG |

We hold **258 state-executive seats across 51 jurisdictions** and only **34** had a 2026 race
row. The seats and their officeholders were seeded long ago; the 2026 *races* were not.
🔴 **"The office is seeded" and "the election is seeded" are different claims, and the first
is the one that looks reassuring.**

⚠ **The gap script nearly lied in the same way.** Its first run reported `0` recorded and `0`
in the gap, because Postgres returns `count(*)` as a **string** and every `=== 0` comparison
silently failed. It was caught only because the buckets summed to 4 against 98 called.
▶ **Print the sum and assert it. A classifier that drops rows looks like a clean result.**

## `CC_0358` — Texas, the worked pattern

Applied 2026-11-05. **3 races created · 4 people seeded · 10 candidacies (3 won, 7 lost).**
Nothing updated, nothing deleted; every statement is an INSERT.

| race | winner | pct | losers |
| --- | --- | --- | --- |
| Texas Governor 🔴 **flip** | Gina Hinojosa (Dem) | 52.82 | Greg Abbott (GOP, **sitting governor**) 45.69; Pat Dixon (Lib) 1.50 |
| Texas Lieutenant Governor | Vikki Goodwin (Dem) | 51.73 | Dan Patrick (GOP, **sitting Lt Gov**) 45.64; Anthony Cristo (Lib) 1.73; Kevin McCormick (Grn) 0.90 |
| Texas Attorney General | Nathan Johnson (Dem) | 52.37 | Mayes Middleton (GOP) 45.94; Tom Oxford (Lib) 1.69 |

All three at **99% of the expected vote**. Two sitting statewide officials were beaten. The
Attorney General seat was open: **Ken Paxton holds it and ran for the US Senate instead** —
an open seat, not a missing row, and why no candidate in that race is marked incumbent.

### 🔴 A control found a gate this file did not have

Five tampers, each asserted present in the file, each planting one fault. **Four fired. The
fifth PASSED**, and that is the finding:

| | fault planted | observed |
| --- | --- | --- |
| A | Governor's winner and loser transposed | `the winner is not the top vote-getter: Texas Governor: Greg Abbott won on 45.69% but Gina Hinojosa polled 52.82%` |
| B | seed a person who already exists (Dan Patrick) | `a person this file seeds already exists: Dan Patrick (efac375f-…, active=true)` |
| C | a race pointed at an office that already holds one | `1 race(s) already exist on these offices for 2026-11-03` |
| D | AP's spelling of a name, matching nobody | `a candidate does not resolve to exactly one person: Nathan M. Johnson -> 0` |
| E | the incumbency flag moved from the losing incumbent to the winner | 🔴 **DRY RUN OK — NOT CAUGHT** |

**E passed because the post-verify compared `is_incumbent` against this file's own table.**
The write reads that table and the check read the same table, so a tampered file **agreed
with itself** — exactly the shape the top-vote-getter cross-check exists to break, repeated
on a different column because nobody asked the question twice.

▶ **The fix is an independent fact, not a careful re-read.**
`essentials.office_current_holder` says who holds the seat and this file does not supply it.
The gate now checks **both directions** — marked-but-not-holding and holding-but-not-marked
— and E fires:

```
incumbency disagrees with the current officeholder: Texas Lieutenant Governor: this file
marks Vikki Goodwin as incumbent, but the seat is held by Dan Patrick; Texas Lieutenant
Governor: Dan Patrick holds this seat but is not marked incumbent
```

⚠ **A COUNT of incumbents would never have caught E** — one `true` moved to another row and
the total did not change. The gate had to compare per row.

- **C was shadowed first**: I used Nevada's Governor *race* id where an *office* id belongs,
  so it tripped the earlier "target offices exist" gate. A real refusal, of the wrong gate.
- **A tamper that did not apply nearly slipped through too**: the control script's `must()`
  check refused to build when my guessed column padding did not match the file. Without it
  the tamper file would have been byte-identical to the original and reported `DRY RUN OK`.

### Sourcing

Numbers, parties, AP candidate ids and the winner flag: **AP only**. The four new people's
identity and party were established from Ballotpedia, *"Texas state executive official
elections, 2026"*, read 2026-11-05.

🔴 **That page is authoritative for identity and STALE for numbers** — its Governor table
reads Hinojosa 56.3% on 4,219,438 votes against AP's 52.82% on 5,230,929 at 99% counted.
Ballotpedia was mid-count. **Not one number in `CC_0358` comes from it.**

🟢 It also settled a contradiction: a web search put **Mike Collier (Ind.)** on the Lieutenant
Governor ballot and AP did not list him. The page files him under *"Withdrawn or disqualified
candidates"*. AP's ballot was right and the search summary was stale — **open the page**.

⚠ A sweep of every row sharing the four surnames, **archived rows included**, found two
unrelated pre-existing duplicate pairs: **`Arthur Dixon` ×2** (one active from ballotpedia,
one archived from `federal_2026_bulk_seed`) and **`Jessica McCormick` / `Jessica Mccormick`**
— the second invisible to the `(first_name, last_name)` guard because that comparison is
**case-sensitive**. Neither is touched here. Both are owed a look.

### Texas is NOT finished, and the remainder is named

- **Railroad Commissioner** — AP called it (Jon Rosenthal (Dem) 52.51%, Bo French (GOP)
  45.55%, Arthur DiBianca (Lib) 1.93%) and **we hold no such office**. Creating one is a
  district + office + current-holder decision, an occupancy act with its own sourcing bar.
  Its AP response is kept in `ap-tx-2026-11-05.json` so the numbers survive the live feed.
- **Comptroller, Land Commissioner, Agriculture Commissioner** — we hold all three seats,
  all three were on the ballot, and **AP publishes no race for any of them**.
- **Write-ins are not in AP's ballot.** Ballotpedia lists Edward Giles (Ind., write-in, 0
  votes) for Governor, and Stephen Samuelson (Ind., write-in, 751) and Arturo Espinosa for
  Lieutenant Governor. This file seeds AP's ballot only, so those rows are **absent rather
  than wrong**. Said out loud so nobody reads our ballot as complete.

### Verified against production after applying

| check | result |
| --- | --- |
| Texas state-executive races | 3 |
| Texas candidacies | 10 — 3 won, 7 lost |
| Incumbents marked | 2 — Abbott and Patrick, both beaten, both confirmed against `office_current_holder` |
| The 4 seeded people | exist exactly once each; 0 marked incumbent |
| Rows claiming `certified` | 0 |
| `result_recorded_at` | `2026-11-05 16:33:14.275464+00` on all 10 — measured, microseconds and all |
| **State-executive winners nationally** | **21** (18 from `CC_0357` + 3 here) |

### Still owed on the national gap

**73 AP-called state-executive races across 31 states** still have no race row, plus the 4
seats we do not hold and the 6 AP has not called. ▶ **Re-run `ap-state-exec-gap.mjs` before
each batch** — AP's uncalled six will shrink, and the gap is the thing to measure, not ours.
