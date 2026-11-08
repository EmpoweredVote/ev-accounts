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

---

# `CC_0359` — the national fan-out, and the gap is now ZERO

Applied 2026-11-05. **73 races created · 143 people seeded · 212 candidacies (73 won, 139 lost)
across 30 states.** Every statement is an INSERT; nothing is updated and nothing is deleted.

▶ **Measured from AP's side before and after, with `ap-state-exec-gap.mjs`:**

| | before | after |
| --- | --- | --- |
| AP state-executive races | 104 | 104 |
| called by AP | 98 | 98 |
| **recorded by us** | **21** | **94** |
| **seat held, NO race row** | **73** | **0** |
| we hold no such seat | 4 | 4 |
| not yet called | 6 | 6 |

94 state-executive winners now stand across **37 states**. 🟢 **The four AP offices are closed
except for the six races AP has not called and the four seats we do not hold.**

## Two independent sources, reconciled race by race BEFORE anything was written

AP gave the ballot, the parties, every number and the winner flag. Ballotpedia's
*"&lt;State&gt; state executive official elections, 2026"* pages — one per state, 30 of them, read
2026-11-05 — gave identity: the full name spelling and a per-person article URL, which is
recorded in each seeded politician's `source`.

🔴 **Those pages are authoritative for identity and STALE for numbers.** Maine's governor reads
261,518 votes there against AP's 382,760. **Not one number in `CC_0359` comes from Ballotpedia.**

The two ballots were then compared candidate by candidate:

```
AP gap races:                  73
paired with a Ballotpedia tbl: 73
AP candidacies paired:        212
```

**Zero contradictions. The two sources agree on every winner in all 73 races.** The report is
committed as `crosscheck-report-2026-11-05.txt`.

### 🔴 The cross-check only became believable after THREE parser bugs, and each looked like data

| what it printed | what it was |
| --- | --- |
| "NO Ballotpedia general-election table found" for six states' Secretary of State | ⚠ Ballotpedia writes the state **either way**: `Governor of Alabama` but `Alabama Secretary of State`. Stripping only the suffix lost six real tables and reported them as absent |
| eight states' **governors** absent from Ballotpedia | 🔴 **A GOVERNOR AND LIEUTENANT GOVERNOR ARE ONE BALLOT LINE.** Ballotpedia prints the ticket — "Byron Donalds / Bryan Avila" — and AP names only the head. Matching on the last word of the string paired AP's governor against the **running mate's** surname |
| 200 "disagreements" on the first run | mostly the two above, plus comparing AP's raw name (which carries `(write-in)` inside it) and demanding party *strings* match when Ballotpedia spells parties out in full |

▶ **A source-comparison tool reports ITS OWN bugs as findings about the data**, in exactly the
register a real finding would use. The way out was that the failures were *shaped* — all six of
one office, all of one office type — and a uniform answer is a broken detector.

## What the reconciliation actually caught

🔴 **"Total Write-ins" is not a person.** AP candidate id `100008` sits on 17 of the 73 ballots,
with votes and a percentage, exactly like a candidate. It is the Nevada
"None of These Candidates" trap in a second costume: **229 AP rows, 212 people.**

🔴 **AP TRUNCATES NAMES.** AP publishes `T. Shannon`, `L. Taylor`, `C. Reynolds`, `H. Paige`;
they are T. W. Shannon, L. Webb Taylor, Christopher Reynolds and H. Brooke Paige. **27 of the
212 names differ between the two sources.** Seeded rows take Ballotpedia's spelling.

🔴 **BUT THE SPLIT COMES FROM AP, WHICH PUBLISHES `first` AND `last` AS SEPARATE FIELDS.** So
"Jose Javier Rodriguez" splits to `("Jose Javier", "Rodriguez")`, not `("Jose", "Javier
Rodriguez")`, and "T. W. Shannon" to `("T. W.", "Shannon")`. **A first-token-is-the-first-name
rule gets both wrong, and the error is invisible once it is a column.** Every one of the 143
splits was asserted against AP's own surname field; the assertion rejected five and all five
were real:

- ⚠ **AP puts `(write-in)` inside the SURNAME field too**, not only the composed name — three rows.
- **`Pro-Life` is a legal mononym.** Idaho's Constitution Party candidate for Governor
  ([ballotpedia.org/Pro-Life_(Marvin_Thomas_Richardson)](https://ballotpedia.org/Pro-Life_(Marvin_Thomas_Richardson)),
  read 2026-11-05: *"Pro-Life (formerly Marvin Thomas Richardson) ... was born Marvin Thomas
  Richardson on August 5, 1941"*). `first_name` is NULL because there is no given name.
- **Charles Morgan (TN)** — AP's surname field reads "Van Morgan"; his own Ballotpedia article is
  titled "Charles Morgan (Tennessee)". Ballotpedia owns the spelling.

🔴 **AND THE ACCENTS COME BACK FROM AP.** Ballotpedia drops them — "Jose Javier Rodriguez",
"Amanda Lopez Askin" against AP's "José" and "López". Both are seeded accented. **Prod has no
`unaccent` extension, so a name stored one way is unfindable by the other.**

⚠ **DECLARED WRITE-INS ARE LARGELY ABSENT FROM AP'S BALLOT, SO THEY ARE ABSENT HERE.** Ballotpedia
lists **43** write-in candidates AP does not carry, across AL, CT, DE, FL, IL, MI, MN, NY, OH, TN
and VT — Michigan alone has nine. AP carries three (Jacob Burnett in Idaho, Randy Wilcox and
John Glowa in Maine) and those three are seeded `is_write_in = true`. The rest are **absent
rather than wrong.** Said out loud so nobody reads our ballot as the whole ballot.

## 🔴 Three proposed matches were CONTRADICTED by what the person already holds

The resolver's strongest rung is anchored on a fact the file does not supply: AP flags a
candidate incumbent **and** `office_current_holder` names that same person for that same seat.
40 of 69 matched that way. The other 29 were name matches — **a hypothesis, not a finding**, and
reading what each person currently holds threw three of them out:

| AP's candidate | the row the name matched | why it is a different person |
| --- | --- | --- |
| **Doug Jones**, AL Governor | `Doug Jones` 3216400f | came from **Colorado's** certified candidate list (`CC_0276`) and is a candidate for **CO State Representative on this same day** |
| **David Graham**, DE Attorney General | `David C. Graham` 25ab585b | came from the **Kansas** Secretary of State's 2026 candidate list (`CA_0233`); a candidate for **KS Senator on this same day** |
| **José Javier Rodriguez**, FL Attorney General | `Jose J. Rodriguez` 2ab06b40 | holds a **California school-board seat**, Trustee Area 2, since 2024-12-16 |

Each would have attached a statewide result to the wrong human. 🔴 **This is the TX-22
twin-brother defect, and a name match cannot see it. What saw it was asking the database what
that person already holds** — one extra column, and it is the whole difference.

Four others were confirmed by hand the same way: **Tanya F. Miller** (a Georgia state
representative, who won the Georgia attorney generalship), **Jermaine L. Johnson, Sr.** (a South
Carolina state representative), **James B. Rutledge III** — whose own campaign site
[electjim.com](https://electjim.com/) reads *"JIM RUTLEDGE FOR ATTORNEY GENERAL"* and
*"PROTECTING MARYLAND'S CONSTITUTION"* — and **Richard Bennett**.

🔴 **BALLOTPEDIA'S FULLER SPELLING SURFACED A DUPLICATE AP'S SPELLING COULD NOT.** AP writes
"Rick Bennett" and that matched one row. Ballotpedia writes "Richard Bennett" and that matched
**three**:

- `Rick Bennett` **e73bd689** — holds the **Maine** state senate seat. ✅ the right man.
- `Richard Bennett` f3242669 — a **Mississippi** state representative. A different person.
- `Rick Bennett` f64c1364 — **archived**, sourced from `en.wikipedia.org/wiki/Rick_Bennett_(Maine_politician)`.
  ⚠ **A pre-existing duplicate of the same Maine man.** Not touched here. Owed a look.

## Three seeded people share a name with someone we already hold, deliberately

And 🔴 **"a different person with a confusable name" and "a name the guard refuses" are NOT the
same set** — the first draft of this file conflated them and its own staleness gate refused it.
The guard checks **two** keys and they catch different rows:

| | clashes on full name | clashes on (first, last) | needs an allowance |
| --- | --- | --- | --- |
| Doug Jones | ✅ | ✅ | yes |
| David Graham vs `David C. Graham` | ✗ | ✅ (his columns read plainly "David" / "Graham") | yes |
| José Javier Rodriguez vs `Jose J. Rodriguez` | ✗ | ✗ | **no** |

A second gate fails the file if a listed name has **stopped** clashing, so the allowance cannot
rot into a blanket excuse.

🟢 **THE DATABASE'S OWN TRIGGER AGREED, INDEPENDENTLY.** The dry run raised
`DUPLICATE_POLITICIAN_NAME: 1 active politician row(s) already carry the name Doug Jones`, with
the right default advice — *"a sitting officeholder running for a different seat is the normal
case, not a different person"*. It is not this case. The escape hatch
(`SET LOCAL essentials.allow_duplicate_name`) is opened for that one statement and **closed on
the next line**, so it covers nothing else in the transaction.

## ⚠ Three races carry one candidate, and one is a call on NO VOTES AT ALL

| | | |
| --- | --- | --- |
| AR Attorney General | Tim Griffin | 100%, 620,639 votes — unopposed |
| RI Secretary of State | Gregg Amore | 100%, 274,697 votes — unopposed |
| **SD Attorney General** | **Lance Russell** | **0%, 0 votes, eevp = 0** |

🔴 **SOUTH DAKOTA IS A CALL ON THE BALLOT, NOT ON THE COUNT.** AP marks Russell the winner with
nothing counted, because he is the only name on it. The seat is decided and `won` is the right
value; the percentage means nothing, and no percentage is stored.

⚠ **TENNESSEE ELECTED A GOVERNOR ON 45.49%** — Marsha Blackburn against fourteen others. The gate
asserts the winner is the **top** vote-getter, never that they cleared 50%. A `> 50%` gate would
have failed a correct file. None of the 73 is ranked-choice and none elects more than one seat;
both were read from AP rather than assumed.

## The controls found a gate that did not exist

Seven tampers, each asserted present in the file it writes, each aimed at a different gate.
**Six fired. One passed, and that is the finding.**

| | fault planted | observed |
| --- | --- | --- |
| A | winner and loser transposed (AL Governor) | `the winner is not the top vote-getter: AL Governor: Doug Jones won on 47.94% but Tommy Tuberville polled 52.06%` |
| B | a second race on a seat that already has one | `1 race(s) already exist on these offices for 2026-11-03` |
| C | incumbency moved from the losing incumbent to the winner (VT Lt Gov) | `incumbency disagrees with the current officeholder: ... this file marks Molly Gray incumbent, but the seat is held by John S. Rodgers; ... John Rodgers holds this seat and is not marked incumbent` |
| D | a pinned uuid swapped for another real, active person | `a pinned politician is not the person this file names: AL Governor: this file names Tommy Tuberville (AP: Thomas Tuberville) but the pinned row is Marsha Blackburn` |
| E | a name dropped from the collision allowance | `a person this file seeds already exists: Doug Jones already exists as Doug Jones (...); Doug Jones splits to the same (first, last) as ...` |
| F | a seeded person's `last_name` corrupted, `full_name` left intact | 🔴 **DRY RUN OK — NOT CAUGHT** |
| G | a race filed under another state's election row | `an election row is not the 2026-11-03 general of its state: AL -> AR 2026 Statewide General AR 2026-11-03` |

### 🔴 F: "Robertson-Changed" was written to production's shape with no complaint

Nothing compared the three name columns to each other. It matters because `first_name` and
`last_name` are **the columns the repo's own duplicate guard keys on** — so a wrong split makes
that person invisible to it, which is the same blindness CLAUDE.md already records for
differently-cased and accented rows. The gate now requires `full_name` to begin with
`first_name` and end with `last_name`, and F fires:

```
a seeded name does not match its own split: Katherine Robertson splits to (Katherine, Robertson-Changed)
```

⚠ **It is a WEAKER gate than D and the file says so.** It compares three columns this file wrote
against each other, not against an outside fact — it catches a typo or a bad split, never a
wrong person. The outside check is only possible where an existing row exists to check against,
and a seeded person by definition has none.

### 🔴 D is the gate CC_0358's controls bought, generalised

`CC_0358`'s control E showed that checking `is_incumbent` against *the file's own table* proves
nothing, because a tampered file agrees with itself. The same shape was waiting here one column
over: **69 candidacies carry a hand-chosen `politician_id`, and the INSERT takes the name FROM
THAT ROW.** A swapped uuid would be written under the wrong person's name and every other gate
would still pass. The independent fact is that the NAME comes from AP and Ballotpedia while the
ROW comes from the database. They are compared on (first word, last word) — two sources
legitimately differ in the middle ("Andrea Campbell" for "Andrea Joy Campbell") but never at
both ends. **Measured: all 69 agree with no exceptions, so the gate carries no allowance list
to go stale.**

### ⚠ B was shadowed first, and the shadow looked like a pass

Swapping only the office id left the row saying `'AL'` while pointing at a Nevada office, so it
tripped the earlier *"an office is not where this file says"* gate — a real refusal, of a
different gate, which proves nothing about the duplicate-race one. **`CC_0358`'s control C went
the same way.** The row had to be made internally consistent (Nevada office, Nevada label,
Nevada election) so every upstream gate passes and only the intended one is left to catch it.

### ⚠ A guard that times out is a guard that does not run

The duplicate-name check timed out on its first dry run: calling the normalising function on
**both** sides of a join defeats every index, so it was 143 seeds × 91,353 politicians × 2 keys.
Normalising the 91,353 rows **once** into an indexed temp table turns it into 286 index lookups,
and the whole file now dry-runs in about three seconds. 🔴 **The same table carries a positive
control** — it asserts it can see a politician known to exist, and that it loaded more than
50,000 rows, before any check is allowed to trust its silence.

## Verified against production after applying

| check | result |
| --- | --- |
| State-executive candidacies nationally | 334 |
| **State-executive winners nationally** | **94**, across **37 states** |
| Rows written by `CC_0359` | 212 — 73 won, 139 lost |
| Incumbents marked | 40, every one cross-checked against `office_current_holder` |
| Write-ins marked | 3 |
| People seeded | 143 — all active, none marked incumbent |
| Rows claiming `certified` | 0 |
| `result_recorded_at` | one measured value on all 212: `2026-11-05 18:18:16.654469+00` |
| **`ap-state-exec-gap.mjs`, re-run from AP's side** | **gap = 0**, buckets sum to 98 ✔ |

## What is still owed at this tier

- **6 races AP has not called**: AK Governor (ranked choice, 73.81% counted), IA Attorney
  General, KS Governor / AG / Secretary of State, OH Attorney General. ▶ **Re-run
  `ap-state-exec-gap.mjs`** — this bucket shrinks on its own.
- **4 seats we hold no office for**, each an occupancy act with its own sourcing bar, not a
  results migration: CT Secretary of State (Stephanie Thomas), DC Attorney General (Brian
  Schwalb), MA Secretary of State (William Galvin), TX Railroad Commissioner (Jon Rosenthal).
- 🔴 **AP COVERS ONLY FOUR OFFICES**, so a zero gap here is NOT "every state executive is
  recorded". Treasurers, auditors, controllers, superintendents, insurance and labor
  commissioners, land and agriculture commissioners were on these ballots and **AP publishes no
  race for any of them.** Ballotpedia does — the 30 pages already saved here hold 180
  general-election tables against the 73 AP races, so the source for that work is on disk.
- **Certification**: all 334 rows read `called`. AP reports `isCertified: false` for every race.
- The two duplicate pairs from `CC_0358` (`Arthur Dixon` ×2, `Jessica McCormick`/`Jessica
  Mccormick`) and now a third: `Rick Bennett` e73bd689 / f64c1364.

---

# `CC_0360` / `CC_0361` — the offices AP does not publish

Applied 2026-11-06. **31 races created · 47 people seeded · 13 existing races recorded ·
106 candidacies · 45 winners.** State-executive winners nationally: **94 → 139, across 38 states.**

🔴 **CC_0359 drove the AP gap to zero and that was never "the tier is recorded".** Measured from
AP's own feed, every `officeName` it carries for 2026-11-03 is: U.S. House, Governor, U.S.
Senate, Attorney General, Secretary of State, Lieutenant Governor, Mayor, U.S. Delegate,
Railroad Commissioner, and ballot measures. **Not one treasurer, comptroller, controller,
auditor, superintendent, chief financial officer, land or agriculture commissioner.** Those seats
were on the ballot and no AP race exists for them, so no AP-side check could ever see them.

## 🔴 A third kind of gap: a race the source itself does not carry

AP publishes a Lieutenant Governor race in **ten** states and none in the **six** where the office
runs on the governor's ticket — **CT, HI, MA, NM, PA, WI**. Those six are invisible to an AP-side
reconciliation because there is no AP row to reconcile *against*. They are not "uncalled" and not
"missing a seat"; they simply never appear. Five are created in `CC_0360` and Wisconsin's existing
race is recorded in `CC_0361`.

## 🔴🔴 And the trap inside them: the Lieutenant Governor row names the GOVERNOR

Ballotpedia renders a ticket LG contest as the gubernatorial ticket. Wisconsin's winning row reads
**"David Crowley / Sarah Godlewski"** with the tick on **Crowley, who was running for GOVERNOR**.
Reading the table would have seated six governors in six lieutenant governors' chairs:

| | the row says | the office is actually won by |
| --- | --- | --- |
| CT | Ned Lamont | **Susan Bysiewicz** |
| HI | Joshua Green | **Derek Kawakami** |
| MA | Maura Healey | **Kim Driscoll** |
| NM | Debra Haaland | **Stephanie Garcia Richard** |
| PA | Josh Shapiro | **Austin Davis** |
| WI | David Crowley | **Sarah Godlewski** |

Every one of those wrong answers is a real, famous, plausible name for that state. ▶ **In a ticket
votebox the NARRATIVE is authoritative and the row is the ticket head**; the candidate taken is the
running mate, and the sentence was confirmed to lead with that same running mate in all six.
🟢 A gate now refuses any ticket-LG candidate who also appears on that election's Governor ballot,
and a control proved it by planting Josh Shapiro in Pennsylvania's lieutenant governorship.

## The sourcing standard changed, so it was tested rather than assumed

`CC_0358` and `CC_0359` used Ballotpedia for **identity only** and took every number and the winner
from AP. With no AP race, Ballotpedia has to carry the outcome. Two measurements decided what may
be taken from it:

⚠ **ITS COUNTS HAVE NOT SETTLED.** Against AP's authoritative totals on the 71 races where both
name a winner, only **45 (63%)** are within 0.5%. Maine's governor still reads 261,518 against AP's
382,760 — **68% of the real figure, and unchanged from the day before.** Only **3 of 70** counts
moved in 24 hours, so these tables are not converging; many are frozen part-counted.

🟢 **ITS WINNER FLAG IS A CALL, NOT A LEADER.** On those same 71 races the flag agreed with AP's
call **71 times out of 71** — while the counts beneath it ran up to 32% short. The two are
independent. And it **withholds** the flag: Kansas's governor's race shows Cindy Holscher ahead
50.3–49.7 on 1.09m votes **on its own page** and carries no winner, exactly where AP has also not
called. A leader-takes-the-tick system would have ticked her.

▶ **So the flag is used and NO NUMBER IS.** No vote count or percentage is written to any column,
and none is stated as fact in either header. ⚠ This is still **one** source where `CC_0359` had
two; `result_certainty` is `'called'` and `result_source` names Ballotpedia and the date.

🟢 **The page states each outcome twice** — a CSS class on a table row and an editor's sentence —
produced separately, so one can be wrong while the other is right. **All 44 races agree on both.**
Not a second source; what this source makes available.

## What the fetch itself tried to hide

🔴 **WI and WY answered `curl` with HTTP 202 and a ZERO-BYTE body, three retries each.** A WAF
rejection can be 200 or 202, so `r.ok` is never the test — the size was. Both were read in
Playwright instead. ▶ **A zero-byte file parses cleanly and yields nothing, which reads as "that
state held no elections"** — so every input is size-checked before parsing and a state that yields
no votebox is named. The Playwright extractor was then validated against Wyoming parsed both ways:
same offices, same candidates, same parties, same winner flags.

⚠ Seven states have no Ballotpedia page at all (**KY MS NJ NC VA WA WV**, `wgRelevantArticleId: 0`)
and hold no 2026-11-03 state-executive race on our side either. Consistent, not proven.

## Mapping, where a miss reads as a finding

Three states name the same seat differently and came back as "we hold no such seat" — a false
absence: Rhode Island's **General Treasurer**, Texas's **Comptroller of Public Accounts**,
Indiana's **Comptroller of State**. ⚠ Arizona holds **five** offices titled plainly "Commissioner";
exactly one carries a 2026 race, and that race's five candidates are precisely Ballotpedia's five,
so the pin is to that race rather than a guess among five.

## 🔴 Two citations pointed at the wrong person

On a ticket row Ballotpedia prints **two** links — the governor's article and the running mate's —
so the obvious "first href" gives one person's page to another. Worse, for **David M. Gallegos**
(NM) and **John Thomas** (PA) the second link is an **anchor into the governor candidate's page**
(`#Campaign_themes`): they have no article of their own. Citing it would be a **fabricated citation
in the one field that carries provenance**. A slug check caught both; those two cite the state
page, which does name them, and a gate refuses any source containing a fragment.

## 🔴 No AP surname field exists here

`CC_0359` could assert all 143 of its splits against AP's own `last` column. AP publishes none of
these offices, so nothing outside the name says where the surname starts. 44 of the 47 seeds are
two words and have one possible split; three were read off their own articles —
**"Stephanie Garcia Richard"** (the surname is the pair, not "Richard"), **"David M. Gallegos"**,
**"V. Alonzo Echavarria-Garza"**. A last-token rule gets the first one wrong.

## The controls found a gate that was too weak to work

Seven tampers, each aimed at a different gate.

| | fault planted | observed |
| --- | --- | --- |
| A | the ticket HEAD taken instead of the running mate (Josh Shapiro into PA's lieutenant governorship) | `a ticket lieutenant-governor candidate is on the Governor ballot — the ticket HEAD was taken instead of the running mate: PA Lieutenant Governor: Josh Shapiro` |
| B | a loser promoted, so a race holds two winners | `1 race(s) in this file do not hold exactly one winner` |
| C | a seeded surname corrupted (`Echavarria-Garza` → `Garza`) | 🔴 **DRY RUN OK — NOT CAUGHT** |
| D | a seed cited to an anchor inside another person's article | `a seeded source is not a plain Ballotpedia page` |
| E | one of Arizona's TWO winners demoted | `a race does not elect as many winners as it has seats: AZ Commissioner: 1 winner(s) for 2 seat(s)` |
| F | a prior value claimed that the row does not hold | `a pinned row does not hold the prior value this file recorded: CA Controller Malia M. Cohen = NULL (this file expected advanced)` |
| G | a row the file promises not to touch, written anyway | `a row this file does not pin was changed: Katherine Haley: not_nominated -> lost` |

### 🔴 C: the gate existed and was the wrong shape

`CC_0359` added a split gate after its own control, written as *"full_name must end with
last_name"*. That is true of `"V. Alonzo Echavarria-Garza"` and `"Garza"` — **so the corruption
passed.** A hyphenated surname contains its own tail. ▶ **The fix is equality, not containment:**
`full_name = first_name || ' ' || last_name`, which all 47 satisfy and which has no such hole.
⚠ **A gate inherited from a previous migration is not a gate that has been tested here.** This one
was carried forward, looked right, and was load-bearing against exactly the case it could not see.

### ⚠ G was shadowed first, for the fourth time in this series

Widening the `UPDATE`'s `WHERE` to the whole race made the `FROM`-join match several `calls` rows
per target, so Postgres wrote an arbitrary one and the **pinned** rows came out wrong. It failed on
*"only 14 of the 34 pinned rows hold their stated result"* — a real refusal of the gate **before**
the one being tested. ▶ **A tamper must leave everything else correct, or it never reaches its
target.** Re-aimed as a second `UPDATE` on one deliberately-untouched row, it fires properly.

## `CC_0361` overwrites, so the old values are in its header

34 rows: **13 held `advanced`** (Arizona's primary outcomes, written against these same November
races — the normal shape, and the gate refuses any other prior value) and **21 held NULL**.
`result_source` and `result_recorded_at` are replaced alongside `result`; a stale timestamp is
worse than a null, and `CC_0354` had to repair 155 rows that had one.

⚠ **7 rows are deliberately untouched**: six primary losers (`not_nominated`) and one withdrawal.
Leaving `not_nominated` alone is the point — they did not reach this ballot.
⚠ **Two people on Ballotpedia's ballot are absent from our races** — Daniel Wagner (WI Lt Gov) and
Joseph Kexel (WI Treasurer), both declared write-ins. Recorded, never invented.
⚠ **Shawn Oliver (MA Lt Gov) withdrew and stayed on the ballot**, so his row reads
`candidate_status = 'withdrawn'` with `result = 'lost'` — votes were cast for him. "Never filed"
would have been a deletion; this is not that.

## Verified against production after applying

| check | result |
| --- | --- |
| State-executive races nationally | 141 |
| Candidacies | 406 |
| **Winners** | **139**, across **38 states** (was 94 / 37) |
| `CC_0360` | 72 rows, 31 winners, 47 people seeded |
| `CC_0361` | 34 rows, 14 winners, one measured timestamp |
| Rows still `advanced` | **0** |
| Races whose winners ≠ seats | 0 |
| Rows claiming `certified` | 0 |
| Rows still NULL | 15 — all accounted for: 3 withdrawals, CA's two uncalled races (4), Colorado's Lieutenant Governor (7, no Ballotpedia table), and Alex Astley |

## Still owed

- **Ballotpedia marks no winner yet** on CA Commissioner of Insurance, CA Superintendent of Public
  Instruction, OH Auditor, OH Treasurer, IA Auditor and others — 27 voteboxes in all.
- 🟢 **Ballotpedia has now called Iowa's Attorney General** — *"Nate Willems (D) defeated incumbent
  Brenna Bird (R)"* — and **AP has not**. Left for the AP pass, since it is an AP-covered office
  and this is the one place the two sources differ. ▶ Worth re-running `ap-state-exec-gap.mjs`.
- **Colorado's Lieutenant Governor** has a race and seven candidates and no Ballotpedia table.
- **119 Ballotpedia voteboxes match no seat we hold**: state boards of education, public service
  and utility commissions, university regents, Massachusetts's Governor's Council, New Hampshire's
  Executive Council, the Office of Hawaiian Affairs, and single seats such as Alabama's Auditor and
  Connecticut's Comptroller. Creating those is an office-and-occupancy act, not a results migration.
- The 4 AP-called seats we hold no office for, and certification everywhere.

---

# `CC_0362` — the 7 the reconciliation had hidden, and what the other 90 actually need

Applied 2026-11-06. **3 races created · 5 candidacies inserted · 6 updated · 2 people seeded ·
7 winners.** State-level winners: **139 → 146 across 39 states.** Occupancy baseline unmoved at
**238**, which this file asserts in its own post-verify because it creates no office.

## 🔴 The correction: "119 match no seat we hold" was my WHERE clause, not the data

`CC_0360`'s header reported 119 voteboxes as matching no seat. The reconciliation loaded our
offices with `district_type = 'STATE_EXEC'` and nothing else. **Utah's 15 State Board of Education
districts are `STATE_BOARD_EDUCATION`** and **California's 4 Board of Equalization districts are
`STATE_BOARD`**, so every one of them came back absent — and five of them were carrying a live
2026 race the whole time.

▶ **A PREDICATE READS THE SHAPE OF A VALUE, NEVER WHAT THE VALUE IS.** The filter was reported as
a fact about the world. Re-run against *every* office, 119 resolves to:

| | | |
| --- | --- | --- |
| **7** | seats we hold and can record | **this file** |
| 90 | no office of ours at all | three tiers, below |
| 22 | Ballotpedia marks no winner | nothing to do yet |

⚠ These seats already carry **real geometry** — `ocd-division/country:us/state:ut/sboe:N` and
`06-sboe-d3`. That is precisely why they must not be rebuilt as new offices, and the gate asserts
each target is a Utah state-board seat with a non-empty `geo_id`.

🔴 Three candidates are anchored on `office_current_holder` for the exact seat, not on a name
match — and one of them, **Joseph Kerry, HOLDS Utah District 2 and lost it**, having withdrawn
while staying on the ballot. His row reads `candidate_status = 'withdrawn'` with `result = 'lost'`.

### Controls

| | fault planted | observed |
| --- | --- | --- |
| A | the District 1 holder pinned to District 4's office | `a pinned politician is not the person this file names: … Jennie Earl but the pinned row is LeAnn Wood` |
| B | the hyphenated surname corrupted (`Callow-Heusser` → `Heusser`) | `a seeded name does not match its own split` |
| C | a pin repointed at a row that already holds a result | `a pinned row already holds a result, which this file did not record` |
| E | the race pointed at a Nevada `STATE_EXEC` office | `an office is not a Utah state-board seat with real geometry: … NV STATE_EXEC geo=32` |

🔴 **B is the case `CC_0360`'s split gate could not see.** That gate read *"full_name must end with
last_name"* — and `"Cathy Callow-Heusser"` ends with `"Heusser"` too. Equality has no such hole.
⚠ **C was shadowed twice before it landed**: adding a seventh row tripped the count gate, swapping
only the id tripped the name gate. A tamper has to satisfy every earlier gate to reach its own.
⚠ **A fifth gate — the before-image check on unpinned rows — is VACUOUS here and the file says
so.** All six rows in the four touched races are pinned, so nothing can make it fire. It is kept
because it costs nothing and goes live if a seventh candidacy appears; the identical gate was
proved by `CC_0361`'s control G.

## What the remaining 90 need, measured and committed

The full inventory is `outstanding-state-exec-2026-11-06.json`. 🔴 **None of these is a results
migration. Each needs a prerequisite that cannot be inferred:**

**Tier 1 — 34 single-member statewide constitutional offices** (auditors, comptrollers,
agriculture / insurance / labour / lands commissioners, superintendents, a tax commissioner).
Geometry is easy — the state FIPS, exactly as the other 48 statewide seats do it. The blocker is
occupancy: 🔴 **an office with no `office_terms` row raises the unflagged
`offices_missing_terms` baseline**, which stands at **238** and which CLAUDE.md says must never be
raised. So each office must be created *with its current holder seated*, and that holder has to be
sourced. **20 of the 34 are named by the election page itself** ("Incumbent X …"); 14 are not, and
a pass over their offices' own websites cleanly resolved only 5 more — Kansas 403s, Oklahoma's
labour and insurance pages 404, South Dakota's host does not resolve. ⚠ For Oklahoma's
superintendent the page yields the fragment `"ields,</b>…State Superintendent"`. **That is a name
to guess, and guessing an officeholder is the single most expensive error in this repo.**

**Tier 2 — 7 seats that are ONE SEAT OF A MULTI-MEMBER BODY**: Hawaii's OHA at-large trustees
(3 seats), Michigan's State Board of Education and State University Board of Trustees (2 each),
North Dakota's Public Service Commission, Oklahoma's Corporation Commissioner, South Dakota's
Public Utilities Commission, Texas's Railroad Commission. 🔴 **A seat-numbering decision comes
first.** Creating one office for "the seat up in 2026" leaves nothing to distinguish it from the
seats up in 2028, and two years from now nobody can tell which is which. Arizona models its
Corporation Commission as **five separate Commissioner offices** — that is the precedent to follow,
and it is a modelling choice, not a lookup.

**Tier 3 — 49 districted seats across 14 bodies**: state boards of education (AL, CO, KS, NE, TX),
public service commissions (AL, GA, LA, NE), university regents (CO, NE), New Mexico's Public
Education Commission, Massachusetts's Governor's Council, New Hampshire's Executive Council.
🔴 **Their boundaries are not in our geofence tables.** `districts.geo_id` is a lookup key, and the
only identifier available — the state FIPS — would make address search tell a voter in one district
that they are represented by another district's member. **That is a false claim to a voter, which
is worse than the seat being absent.** Utah's school board shows the right shape: real OCD
divisions, loaded as geography first.

---

# `CC_0363` — creating 25 statewide executive offices, and seating them

Applied 2026-11-06. **25 chambers · 25 districts · 25 offices · 25 office_terms · 25 races ·
57 politicians · 54 candidacies (25 won, 29 lost).** State-level winners **146 → 171 across 40
states**. 🟢 **Occupancy baseline unchanged: 293 / 55 / 238.** Address reachability: nothing
regressed.

🔴 **This is an OCCUPANCY ACT, not a results migration**, and the reason is a gate. An office with
no `office_terms` row sits in `offices_missing_terms`; the unflagged count is **238** and
CLAUDE.md says it must **never** be raised. Creating 25 offices and walking away would have taken
it to **263** and handed the next person a red gate for drift nobody introduced. So each office is
created *with its current holder seated*, and the post-verify asserts the baseline is still 238.

⚠ **THE HOLDER IS NOT THE WINNER.** A certified result is not a fact about who holds a seat —
taking office is a separate, later event. **14 of the 25 winners are someone other than the
sitting officeholder**, and it is the sitting ones who are seated here.

## How each holder was established

- **5 from the office's own website** — `agi.alabama.gov`, `cosl.org`, `illinoiscomptroller.gov`,
  `osa.state.mn.us`, `nmstatelands.org`. These are rosters, not race pages.
- **20 from Ballotpedia's own "Incumbent X …" sentence.** That is a statement about who *holds*
  the seat rather than about the count — the distinction CLAUDE.md draws — but it is an
  aggregator, and each term's `source` says so explicitly rather than implying a roster.

🔴 **NO TERM START IS INVENTED.** Not one source publishes when the current holder's term began,
and "first elected" is not a term start. Every term is **open-ended with
`start_precision = 'unknown'`** and `how_started = 'unknown'` (several of these people were
appointed, not elected). A plausible date would have been a fabrication.

🔴 **NINE TIER-1 OFFICES ARE DELIBERATELY ABSENT** because neither route produced a name: Kansas's
insurance page 403s, Oklahoma's labour and insurance pages 404, South Dakota's auditor host does
not resolve, and Oklahoma's superintendent page yields only a fragment ending "ields," before
"State Superintendent". **Guessing an officeholder is the most expensive error available here**,
so those nine wait for a real roster: KS Commissioner of Insurance, OK Commissioner of Insurance,
OK Commissioner of Labor, OK Superintendent of Public Instruction, SC Commissioner of Agriculture,
SC Comptroller General, SD State Auditor, VT State Auditor, WY Superintendent of Public Instruction.

## 🔴 Three more name matches thrown out on what the person already holds

| matched row | why it is someone else |
| --- | --- |
| `John King` 30f77168 | holds a **California local council seat**, source `scraped` — not Georgia's Insurance and Safety Fire Commissioner |
| `Mike Foley` 38277535 | a candidate for **Minnesota's** U.S. Representative — not Nebraska's Auditor of Public Accounts |
| `Chris Jones` d9ceca31 | a candidate for **Arkansas's** U.S. Representative — not Iowa's Secretary of Agriculture candidate |

That is **six** contradicted matches across this series, every one caught by the same one extra
column. Two matches were *kept* on the same evidence: **Cole Jester** holds Arkansas's Secretary
of State and contested its Commissioner of State Lands, and **Stephanie Garcia Richard** is the row
`CC_0360` seeded, who currently holds New Mexico's Commissioner of Public Lands.

⚠ **The politicians snapshot went stale mid-task and nearly caused duplicates.** It was pulled
before `CC_0360` and `CC_0362` applied, so Stephanie Garcia Richard — seeded an hour earlier —
resolved as NEW. Re-pulled before the final resolution. **A snapshot taken before your own writes
is not a snapshot of production.**

## Controls

| | fault planted | observed |
| --- | --- | --- |
| A | the `office_terms` insert disabled — offices created but unseated | `25 of the 25 new offices have no term and would raise the drift metric` |
| B | Alabama's FIPS written as Alaska's | `a FIPS disagrees with the state's existing districts: AL Auditor: this file says FIPS 02 but AL districts use 01` |
| C | a name dropped from the collision allowance | `a person this file seeds already exists: John King already exists as John King (…)` |
| D | a compound given name corrupted (`Keisha Sean` to `Keisha`) | `a seeded name does not match its own split` |
| E | a new office titled as one we already hold | `this file would duplicate an office we already hold: AL Auditor already exists as STATE_EXEC "Treasurer"` |

🔴 **A is the control that matters**: it proves the baseline gate catches the exact failure that
makes office creation dangerous. 🔴 **D is the third appearance of the split defect** — "Keisha
Sean Waites" still *ends with* "Waites", so `CC_0360`'s containment form could not see a
first-name corruption at all. 🔴 **E is the gate written because of `CC_0362`**: a reconciliation
that filtered on `STATE_EXEC` reported seats we *do* hold as absent, so this gate checks every
district type before creating anything.

⚠ Two mechanical faults the dry run caught: `chambers.slug` is a **generated column** and cannot
be inserted (the rows join back on `name_formal`), and the holder lookup built its key from
"AL Auditor" where the people table is keyed "AL|…" — 24 of 25 holders resolved to nobody and the
gate said so rather than seating silently.

---

# `CC_0364` — the seven multi-member bodies, built whole

Applied 2026-11-07. **7 chambers · 7 districts · 35 offices created and 2 moved · 35 office_terms ·
7 races · 61 politicians · 36 candidacies (11 won, 25 lost).** State-level 2026 results go from
**178 races / 171 winners** to **185 / 182**, still across 40 states.
🟢 **Occupancy baseline unchanged: 293 / 55 / 238.** Address reachability: nothing regressed.

## 🔴 The blocker was a seat-numbering decision, and production had already made it

`outstanding-state-exec-2026-11-06.json` set these seven aside with one sentence: *"creating one
office for the seat up in 2026 leaves no way to tell it from the seats up in 2028."* Arizona's
Corporation Commission, already in the database, answers it — **one chamber, one shared
`STATE_EXEC` district on the state FIPS, five identical offices all titled "Commissioner", and the
2026 contest as ONE race carrying `seats = 2`.** No numbers anywhere. Every body here is built that
way.

🔴 **The corollary is that the whole body has to be created, not just the seat that was up.** An
office is a seat, and `chambers.official_count` states how many the body has; three offices in a
chamber that says eight is a vacancy that does not exist. So all 37 seats were created and all 37
are seated, each from the body's **own roster**:

| body | seats | filled 2026 | roster |
| --- | --- | --- | --- |
| HI Office of Hawaiian Affairs Board of Trustees | 9 | 3 at-large | `oha.org` |
| MI State Board of Education | 8 | 2 | `michigan.gov/mde` |
| MI Michigan State University Board of Trustees | 8 | 2 | `trustees.msu.edu` |
| ND Public Service Commission | 3 | 1 | `psc.nd.gov` |
| OK Corporation Commission | 3 | 1 | `oklahoma.gov/occ` |
| SD Public Utilities Commission | 3 | 1 | `puc.sd.gov` |
| TX Railroad Commission | 3 | 1 | `rrc.texas.gov` |

## 🔴🔴 `district_type` is a routing key, not a label — and it nearly cost Michigan its board

The first draft filed Michigan's State Board of Education under `STATE_BOARD_EDUCATION` and the
MSU trustees under `STATE_BOARD`, because those are the types whose **names** fit. Reading
`buildStatewideQuery` before writing the file is what stopped it:

```sql
d.district_type IN ('NATIONAL_UPPER', 'NATIONAL_EXEC', 'STATE_EXEC', 'NATIONAL_JUDICIAL', 'JUDICIAL')
```

**`STATE_BOARD` and `STATE_BOARD_EDUCATION` are not in that list.** They reach a voter only through
the geofence join, keyed on a particular `mtfcc` — `X0003` for Utah's SBOE, `X-CA-SBOE` for
California's Board of Equalization, `G5220` for DC — because every one of those boards is
**districted**. Michigan's board is elected statewide at large and has no polygon of its own, so
the type whose name fits would have made all eight members **unreachable from every Michigan
address, silently**. All seven bodies are `STATE_EXEC`, which is what Arizona's commission already
is.

▶ The general form: ask what a column is *read by* before choosing its value. This is the same
hazard as an empty `geo_id`, wearing a different hat.

## 🔴 Which seat was up is a claim a December pass will act on, so it is asserted

A race attaches to **one** office, and that office is what a seating pass will replace. Arizona's
existing 2-seat race hangs off an arbitrary one of its five offices. This file can do better,
because every outgoing member is published:

- **SD** — the Commission's own home page: *Gary Hanson, Elected 2002, 2008, 2014, 2020, **Term
  Ends 2027***. Don Haggar takes that seat.
- **OK** — the Commission's own *Commissioner's Terms* table: **Todd Hiett, 01/11/2021–01/11/2027**.
  Brad Boles takes it.
- **TX** — **Jim Wright**, assumed 2021-01-01, term ends 2027-01-01. Jon Rosenthal takes it.
- **MI** — Pritchett and Tilley (both assumed 2019-01-01, terms end 2027-01-01); Scott and Tebay
  (terms end 2027-01-01). All four re-elected.
- **ND** — Sheri Haugen-Hoffart, re-elected.
- **HI** — Souza, Galuteria and Waihee IV. The fourth at-large seat is Keli'i Akina's, to 2028.

21 of the 37 seats publish a term-end year, and a gate checks **every one of them** against the
ballot column: a seat this contest filled must end its term in 2027, a seat it did not must end
later. The other 16 publish no year and are **skipped rather than assumed**.

🟢 **AP labels the Texas seat `"Term Exp 2032"`** — the only seat label any source in this whole
programme publishes. It is recorded in the race description, **not** in the office title: a label
that names a term goes stale the next time the seat is filled, which is exactly what makes it a
race fact rather than an office fact.

## 🔴 OHA's board was split across three chambers, and this file makes it one

`CC_0363` created the Maui and Oahu Resident Trustee seats. Its builder treated every statewide
office alike, so each got its **own single-seat chamber and district** — two of **nine** seats on
one board. Both offices are **moved**: `chamber_id` and `district_id` are repointed, the office
rows keep their ids, and their terms and races are untouched, so nothing cascades. The two chambers
and two districts they vacate are then deleted.

⚠ **`offices.chamber_id` and `offices.district_id` have NO foreign key.** Deleting a chamber or a
district does not cascade and does not error — it silently orphans every office pointing at it.
The file counts the references before and after, and the post-verify checks the *whole* offices
table for a dangling pointer, not just its own rows.
⚠ An emptied district would also be a fresh `DEAD_GEOGRAPHY` bucket in the master-only address
reachability gate, so leaving them behind was not an option either.

## 🔴 A roster and an aggregator contradicted each other about a living officeholder

OHA's own board page, read 2026-11-07, lists **John D. Waihee IV** as a sitting At-large Trustee.
Ballotpedia, read the same day, files the office under *"Prior offices"*, *"Years in office:
2000 - 2026"*, and says *"He left office on November 3, 2026."*

**The chamber's own roster outranks every aggregator, and election day is not a departure date.**
He is seated as the current holder of the seat Ikaika Anderson won. This is the holder-is-not-the-
winner rule with a visible counter-example attached.

## Identity

4 of the 65 people already existed and are pinned by uuid, each judged on what that row already
holds:

| row | what it holds | verdict |
| --- | --- | --- |
| `Roger Victory` 8a85a630 | Senator @MI | **KEPT** — Ballotpedia's page for the MSU trustee candidate *is* that senator's page |
| `Jon Rosenthal` f5f63005 | Representative @TX | **KEPT** — and he wins a statewide executive seat while sitting in the Texas House |
| `Carmen Hulu Lindsey` c669df3a | OHA Maui Resident Trustee | **KEPT** — `CC_0363`'s row, moved into the board |
| `Kalei Akaka` 3fa0ddec | OHA Oahu Resident Trustee | **KEPT** — same |

🔴 **"Adrian Akina (also known as Keali'i)" is not Keli'i Akina.** Ballotpedia's own page says
Adrian Akina *lost* the 2026 at-large election; the sitting at-large trustee Keli'i Akina won in
**2024** and holds the seat to 2028-11-07. One letter apart, both Akinas, both OHA at-large, both
named on the same results table. They are two rows, and reading one page settled it.

⚠ **Full-name equality cannot see a middle initial.** The roster says "Tiffany D. Tilley" and
"Brianna T. Scott"; Ballotpedia's candidate rows say "Tiffany Tilley" and "Brianna Scott". Seeding
both forms would have created two rows for each woman. A **second sweep on surname + first
initial** caught the pair and found nothing else: Kanani Souza (HI Representative), Joann Pritchett
(WI Alder), Bobby Scott (VA), Dan/David/Deb Patterson, Cabot/Carla/Clarke Nelson and Tom Craddick
are all different people.

## Term starts

34 of the 35 new terms are open-ended with `start_precision = 'unknown'`: no roster publishes when
the member took the seat, and "first elected" is not a term start. The one exception is sourced
from the body's own page — **Jill Kringstad, "appointed to the Commission in Jan. 2025 by Governor
Kelly Armstrong"** — written `2025-01-01` at `'month'` precision with `how_started = 'appointed'`.

## Controls

| | fault planted | observed |
| --- | --- | --- |
| A | the whole seating step removed | `35 of the 37 offices have no term and would raise the drift metric` |
| B | Michigan's FIPS written as Minnesota's | `a FIPS disagrees with the state's existing districts: MI SBE: this file says FIPS 27 but MI uses 26` |
| C | MSU's 8th trustee refiled under the State Board | `a body does not create its whole membership: MI SBE: 9 seats for official_count 8; MI MSU: 7 seats for official_count 8` |
| D | the Texas race moved onto Christi Craddick's seat | `a seat is marked up against its own published term end: TX RRC#2 (Christi Craddick): up=true but the body says the term ends 2031` |
| E | the Jon Rosenthal pin repointed at Roger Victory | `a pinned person is not who this file names: Jon Rosenthal is the row Roger Victory (8a85a630…)` |
| F | a compound given name halved | `a seeded name does not match its own split: Mary Anne Hering splits to (Mary, Hering)` |
| G | the seating **and** the every-office-is-seated gate removed | `the unflagged offices-missing-terms baseline moved to 273 — it was 238 and must never be raised` |

🔴 **G is the one that proves the number.** A is caught by the post-verify's own "every new office
is seated" gate, which never lets the `238` assertion run — so A proves that gate and nothing more.
G removes it too, leaving the drift baseline as the only thing between 35 empty offices and
production, and it reports **273**, exactly the +35 predicted.

🔴 **C was shadowed on the first attempt** — the seventh time in this series. Deleting the eighth
MSU trustee tripped the row-count gate (`expected 37 seats, found 36`), a correct catch for a
*different* claim. Moving the seat into another body instead keeps the count at 37 and reaches the
completeness gate. **A tamper has to satisfy every earlier gate to reach its own.**

🔴 **F is the fourth appearance of the split defect.** "Mary Anne Hering" still *ends with*
"Hering", so `CC_0360`'s containment form cannot see a corrupted given name at all. Only exact
reconstruction can.

## Measured on the live endpoint, not reasoned about

`https://ev-accounts-api.onrender.com/api/essentials/address-search` after the migration:

- `1000 Bishop St, Honolulu, HI` → **all 9 OHA trustees**
- `124 W Allegan St, Lansing, MI` → **all 8 State Board members and all 8 MSU trustees**
- `1701 N Congress Ave, Austin, TX` → **all 3 Railroad Commissioners**

## What tier 2 leaves behind

Tier 2 of `outstanding-state-exec-2026-11-06.json` is now closed. Still outstanding from that
inventory: the **9 statewide offices** whose current officeholder no reachable roster would give
up, the **49 districted board seats** that need real sub-state geometry, and the **22 voteboxes
Ballotpedia has not called** — including **Michigan's University of Michigan Board of Regents and
Wayne State University Board of Governors**, which are the same shape as the two Michigan boards
built here and will slot straight into this pattern the moment they are called.

---

# `CC_0366` — the tier-3 seats that need no new polygon

Applied 2026-11-07. **4 chambers · 20 districts (4 statewide, 16 congressional) · 16 copied
polygons · 26 offices · 26 office_terms · 9 races · 44 politicians · 23 candidacies (9 won).**
State-level 2026 results go from **177 races / 182 winners** to **186 / 191**, still across 40
states. 🟢 **Occupancy baseline unchanged: 293 / 55 / 238.** Address reachability: nothing
regressed.

## 🔴🔴 Tier 3 said all 49 of its seats needed real sub-state geometry. Nine do not

The inventory was built from Ballotpedia's office titles, and a title that reads *District 3* or
*Place 1* reads as districted. Two of these four bodies are nothing of the kind:

- **Georgia's Public Service Commission** — *"Though each commissioner must be a resident of the
  district he represents for 12 months prior to election, commissioners are chosen in **statewide
  elections** and not by the citizens of their district."* The district is a residency rule on the
  **candidate**. Every Georgia voter votes in every PSC race.
- **Alabama's Public Service Commission** — Place 1 and Place 2 are the last two seats filled
  under a **three-member at-large commission**.

▶ **A DISTRICT IN THE TITLE IS A CLAIM ABOUT THE CANDIDATE, NOT NECESSARILY ABOUT THE ELECTORATE.**
Read who votes before deciding a seat needs geometry. This is the same shape as the Office of
Hawaiian Affairs finding in `CC_0364`, where "Maui Resident Trustee" turned out to be elected by
the whole state — it has now been the right question three times.

## 🟢 The other seven reuse a polygon production already holds

Colorado's **State Board of Education** and the **University of Colorado Board of Regents** are
each nine members: eight elected **by congressional district** and one at large. Both boards' own
sites list every member against a congressional district, and the Regents' site gives each
member's term years — the three running 2021–27 are exactly the three seats Ballotpedia carries
as 2026 contests.

So each board district is a **copy of the congressional polygon, taken inside the database**:

```sql
INSERT INTO essentials.geofence_boundaries (...)
SELECT ..., src.geometry, ...
  FROM ... JOIN essentials.geofence_boundaries src
    ON src.mtfcc = 'G5200' AND src.geo_id = mp.src_geo_id;
```

Nothing is downloaded, reprojected or digitised, so **the CRS hazard cannot arise** — and all
eight sources were measured SRID 4326 and `ST_IsValid` before the copy, with gates asserting it
again at run time. Colorado has no `G5200V26` rows, so there is one congressional map in
production and no vintage to choose between; a gate refuses the file if that ever stops being
true. After the apply, every copied polygon's area matches its source to the square mile
(156/156, 11540/11540, 50087/50087 …).

## 🔴 A new layer for a state board needs a read-path line, and only one of the two did

`X0003` is already admitted for `STATE_BOARD_EDUCATION` — Utah's board — and **the rule is not
state-scoped**, so Colorado's eight education districts join with **no code change at all**. The
Regents are `STATE_BOARD`, and the `X%` catch-all admits only `LOCAL`, `COUNTY` and `JUDICIAL`, so
a new layer had to be added explicitly to **both** `districtQueries.ts` and `geoIdGuard.ts`, which
say in their own comments that they must stay in step.

⚠ **`geofence_boundaries.mtfcc` is `varchar(10)`.** The first draft called the layer
`X-STATE-BOARD` (13 characters) and the only thing that caught it was
`value too long for type character varying(10)` at INSERT time, **after every other gate had
passed**. The layer is `X-ST-BOARD`, exactly 10, and a unit test now pins the length.

## Measured, not reasoned — twice, and they disagree on purpose

`/api/essentials/address-search` against **live production**, after the migration:

| address | returned |
| --- | --- |
| 11 S Union St, Montgomery, AL | all **3** Public Service Commissioners |
| 206 Washington St SW, Atlanta, GA | all **5** Public Service Commissioners |
| 200 E Colfax Ave, Denver, CO | **State Board of Education Member, District 1 — Lisa Escárcega**, plus both at-large seats |

🔴 **The Denver address does NOT yet return University of Colorado Regent, District 1** — and that
is the proof the code change is load-bearing. The deployed API has the data and the polygons but
not the `X-ST-BOARD` line, so the same address resolves the `X0003` board and not the `X-ST-BOARD`
one. The districted regent seats appear on the next backend deploy; the at-large regent already
shows, because it comes through the statewide branch.

The gate says the same thing from the other side. `check-address-reachability.mjs` reads the guard
out of `geoIdGuard.ts`, so with the new line it reports `UNREACHABLE 7 (baseline 7)` — and with
the line removed it reports **15, with a new `co|STATE_BOARD observed 8` bucket**. The eight
regent districts are reachable because of that line and for no other reason.

## Rosters

Every seat is seated from the body's own site, and Ballotpedia's officeholder table independently
agrees on all four:

- `psc.alabama.gov` — Cynthia Lee Almond (President), Jeremy H. Oden (Place 1), Chris V. Beeker III (Place 2)
- `psc.ga.gov` — District 1 Jason Shaw, 2 Alicia M. Johnson, 3 Peter Hubbard, 4 Lauren McDonald, 5 Stan Wise
- `cde.state.co.us/cdeboard` — all nine against a congressional district
- `regents.cu.edu` — all nine, with term years

⚠ **The holder is not the winner:** 4 of the 9 winners replace the sitting member — Matt Gentry
for Jeremy H. Oden, Jim Zeigler for Chris V. Beeker III, Shelia Edwards for Stan Wise, Edie Hooton
for Callie Rennison.

⚠ **Colorado's State Board District 3 is created and seated but carries no race.** It was on the
2026 ballot — Ballotpedia's published rotation puts Districts 1, 3 and 7 in this cycle, and all
three have a votebox — but no winner has been called, so it belongs to the uncalled pass. The seat
table keeps the two facts in separate columns, `on_ballot_2026` and `race_recorded`, and a gate
refuses a race on a seat that was not on the ballot.

## Identity

All 44 people are new; nothing is pinned and no collision is excused. Both sweeps — full name, and
surname + first initial — returned only plainly different people: Jimmy Gordon (MN) for James O.
Gordon, Jeanette and Johnny Shaw for Jason Shaw, Faye Johnson for Fitz Johnson, Scott and Stephanie
Wise for Stan Wise, Rex and Rick Scott for Ray Scott, Patricia Mueller for Paul Mueller.

🟢 **The sweep is not blind, and the control says which part of it is thin.** Production holds 64
Colorado House and 35 Senate members and 180 Georgia House and 55 Senate members, so it can see
those states. It holds **no Alabama state legislators at all**, which is why Cynthia Lee Almond —
a former Alabama state representative — comes back new rather than matched.

## Controls

| | fault planted | observed |
| --- | --- | --- |
| A | the seating **and** the every-office-is-seated gate removed | `the unflagged offices-missing-terms baseline moved to 264 — it was 238 and must never be raised` |
| B | each board district copied from the NEXT congressional district along | `a copied polygon is not its source: …/sboe:1 is not identical to 0801; …` (all 16) |
| C | Colorado's at-large board member refiled under the Regents | `CO SBE: 8 seats for official_count 9; CO REGENTS: 10 seats for official_count 9` |
| D | Wanda James's seat marked as on the 2026 ballot | `CO REGENTS#1 (Wanda James): on_ballot=true but the body says the term ends 2029` |
| E | Georgia's District 3 treated as real geography | `a body would load polygons into no layer: GA PSC has cd seats but no layer` |
| F | a compound surname halved | `a seeded name does not match its own split: Kristi Burton Brown splits to (Kristi, Brown)` |
| — | the `X-ST-BOARD` line removed from `geoIdGuard.ts` | the reachability gate goes `UNREACHABLE 7 → 15` with a new `co|STATE_BOARD observed 8` bucket, and `geoIdGuard.test.ts` goes `1 failed \| 20 passed` |

🔴 **B is the geometry control and it is the one worth reading.** Every polygon it writes is still
a real, valid, SRID-4326 Colorado congressional district, and the set still tiles the state — so
shape, projection and coverage all look perfect, and every voter is told the wrong board member.
What catches it is the gate that each copy `ST_Equals` the congressional district it **claims** to
be. A point-in-polygon uniqueness check would not: a consistent permutation passes that.

⚠ **F's first draft proved nothing.** It wrote `('Kristi Burton', 'Brown')`, which reconstructs
`Kristi Burton Brown` exactly — a tamper that cannot trip the comparison tests nothing at all. It
drops the middle name instead. This is the fifth appearance of the split defect.

⚠ **A false red, nearly recorded as a control passing.** `vitest` leaves a `.vite-temp` directory
inside the worktree's otherwise-absent `node_modules`, and the *next* run resolves itself from
there and dies with `ERR_MODULE_NOT_FOUND` before any test executes. Judged on exit code alone
that reads as "the test failed", which is exactly the answer a control wants to hear. Clear
`node_modules` before each run and read the `Tests` line, not the exit code.

## What tier 3 still needs — 40 seats

**Derivable from polygons we already hold, blocked on a composition:**
- **KS State Board of Education (5)** — each district is four contiguous state senatorial
  districts and we hold all 40 Kansas senate polygons. Which four is not published anywhere
  found; K.S.A. 72-250 and 72-251 turn out to be about officers and quorum.
- **MA Governor's Council (8)** — each district is five contiguous senatorial districts and we
  hold all 40 Massachusetts senate polygons **with their real names**. The senate districts are
  *named*, not numbered, so TIGER's `25D01…25D40` ordering cannot be assumed to be the
  "consecutive" order the constitution means. Guessing it hands voters the wrong councillor.

**Needs an imported polygon:** AL State Board of Education (4), LA PSC (2), NE PSC (1), NE State
Board of Education (3), NE Regents (1), NH Executive Council (5), NM Public Education Commission
(4), TX State Board of Education (7).
⚠ New Hampshire's councillor districts are defined by statute as lists of towns and wards, which
would be a union of county subdivisions — but we hold `G4040` for only 11 states and New Hampshire
is not one of them.

---

# `CC_0369` — Texas's State Board of Education, and the first imported polygon

Applied 2026-11-07. **1 chamber · 15 districts · 15 geofence polygons · 15 offices · 15
office_terms · 7 races · 28 politicians · 15 candidacies (7 won).** State-level 2026 results go
from **186 races / 191 winners** to **193 / 198**, across 40 states.
🟢 **Occupancy baseline unchanged: 293 / 55 / 238.** Address reachability: nothing regressed.

## 🔴🔴 The shapefile in the official dataset would have been the Holladay failure again

The Texas Legislative Council publishes PLANE2106 as both a shapefile and a KML. `PLANE2106.prj`
reads:

```
PROJCS["NAD_1983_Lambert_Conformal_Conic", ...
  PARAMETER["False_Easting",1000000.0], PARAMETER["False_Northing",1000000.0],
  ... UNIT["Meter",1.0]]
```

Texas-centric Lambert Conformal Conic **in metres**. Loaded as SRID 4326 those numbers are valid,
correctly shaped polygons that match no address on Earth — exactly how Holladay's five wards went
in, and **every geometric check passes**. KML is WGS84 lon/lat *by specification*, so the KML is
what was used and there is no projection left to get wrong.

The parser still bounds-checks every one of the 263,933 coordinate pairs against Texas
(−107..−93, 25..37) and stops on the first that fails, and the loader re-checks each polygon's
bounding box after insert. A control that reprojects the real data to Web Mercator metres and
relabels it 4326 is refused on the first district:
`sboe:1 bbox -11871739,3070060 .. -10920254,3763658 is outside Texas — WRONG CRS`.

## Which map, and how that was settled

The Capitol Data Portal carries exactly four SBOE plans, and the other three state their own end
dates in their titles — `plane2100` and `plane120` "2013-2022", `plane100` "2003-2012".
**PLANE2106, "STATE BOARD OF EDUCATION DISTRICTS, JANUARY 2023", is the only one still open**, and
Texas's 2025 mid-decade redistricting did not redraw this map. Provenance — URLs, byte counts and
sha256 digests — is in the header of `scripts/CC_0369-parse-plane2106-kml.mjs`.

## 🟢 No read-path change was needed

`districtQueries.ts` and `geoIdGuard.ts` already admit `(X0003, STATE_BOARD_EDUCATION)` for Utah's
board, and **that rule is not state-scoped**, so Texas's rows join as they are. The `geo_id`
carries the state (`ocd-division/country:us/state:tx/sboe:N`), so nothing collides with Utah's.

## 7.9 MB of geometry is not in the migration

263,933 coordinate pairs is too much to embed, so the polygons are loaded by
`scripts/CC_0369-tx-sboe-geofences.mjs`, which **must run first** — the same split `CA_0205` used
for California's Board of Equalization. The migration then asserts the rows are there, are valid
4326 Texas polygons, cover the state, and reach the right member.

## The map is checked against geometry production already trusts

Measured by the loader and asserted again in the migration:

| check | result |
| --- | --- |
| union against our TIGER Texas outline (`G4000` '48') | **99.890% of Texas covered** |
| worst pairwise overlap between two districts | **0.000000%** |
| Texas incorporated places (`G4110`) resolving to exactly one district | **1,228 of 1,228** — none to zero, none to two |
| board members' home towns wholly inside their own district | **9 of 9** |

The home town is evidence **independent of the map being checked**: the board's own members page
gives it, and Texas law requires a member to be a bona fide resident of the district with one
year's continuous residence.

⚠ **Six members' towns anchor nothing, and that was measured rather than assumed.** El Paso, San
Antonio, Pasadena, Houston, Pearland and Frisco each straddle a district line — Houston touches
districts 4, 6, 7 and 8, and an interior point of it lands in 4. Only the nine towns that lie
wholly inside one district are used.

## Controls

**On the loader:**

| | fault planted | observed |
| --- | --- | --- |
| A | the real data reprojected to Web Mercator metres, relabelled 4326 | `sboe:1 bbox … is outside Texas — WRONG CRS` |
| B | District 7 dropped from the file | `expected 15 districts … found 14` |
| C | the geometry of Districts 2 and 15 swapped, numbers kept | `anchor town(s) not wholly inside their member's district: Midland city -> 2, expected 15; Corpus Christi city -> 15, expected 2` |

🔴 **C is the one worth reading.** With the labels swapped the map passes *every structural check*
— 15 districts, all valid 4326 inside Texas, union covering 99.89%, zero overlap, all 1,228 places
resolving to exactly one district. Only the anchor guard, which brings in evidence from outside
the map, can tell.

**On the migration:**

| | fault planted | observed |
| --- | --- | --- |
| A | the seating **and** the every-office-is-seated gate removed | `the baseline moved to 253 — it was 238 and must never be raised` |
| B | the districts filed under layer `X0099` | `only 0 of the 15 districts meet a geofence row on (geo_id, mtfcc)` |
| C | Districts 2 and 15's **members** swapped | `the anchor table and the seat table name different members: D2: anchor says LJ Francis, seat says Aaron Kinsey; …` |
| D | a middle initial dropped from a compound given name | `a seeded name does not match its own split: Marisa B. Perez-Diaz splits to (Marisa, Perez-Diaz)` |

## 🔴🔴 Control C passed the first time, and the gate was the problem

The point-to-member gate originally read the expected name out of the `seat` table — the same
table the seating had just been written from. So when the control put two members in each other's
seat, the chain resolved Aaron Kinsey for Corpus Christi and the gate compared that with a `seat`
row that *also* said Aaron Kinsey. **It was asking the data to agree with itself, and it agreed.**

The fix is a second, independent statement of the roster: the anchor table now carries the
member's name as a literal, a gate requires the two statements to match before either is used, and
the chain is compared against the anchor. A one-line tamper now fires. ▶ **A gate that reads its
expectation from the thing it is checking is not a gate.** This is the sixth shadowed or vacuous
control in this series, and the first that was vacuous rather than shadowed.

⚠ The split defect makes its **sixth** appearance: "Marisa B. Perez-Diaz" still ends with
"Perez-Diaz".

## Measured on the live endpoint

`/api/essentials/address-search` for `1100 Congress Ave, Austin, TX` returns **State Board of
Education Member, District 5 — Rebecca Bell-Metereau**, alongside the three Railroad Commissioners
`CC_0364` created. No deploy was needed, because `X0003` was already in the deployed read path.

In the database, the whole chain resolves for every town tried: Austin → District 5 →
Rebecca Bell-Metereau (with Allison Bush recorded as the 2026 winner); Lufkin → District 9 →
Keven Ellis (Kason Huddleston won); DeSoto → District 13 → Tiffany Clark, re-elected; Midland and
Amarillo → District 15 → Aaron Kinsey, whose seat was not on the ballot.

## What this file does not record

⚠ **District 8 is created and seated but carries no race.** Eight districts were on the 2026
ballot — 2, 5, 6, 7, 8, 9, 13 and 14 — and District 8 (Audrey Young) is the one Ballotpedia has
not called. The seat table keeps `on_ballot_2026` and `race_recorded` apart and a gate refuses a
race on a seat that was not on the ballot.

⚠ **The holder is not the winner:** five of the seven winners replace the sitting member.

## Tier 3 after Texas — 33 seats

**Blocked only on a composition** (the polygons are already in production): KS State Board of
Education (5) and MA Governor's Council (8).
**Needs an imported polygon** (20): AL State Board of Education (4), LA PSC (2), NE PSC (1), NE
State Board of Education (3), NE Regents (1), NH Executive Council (5), NM Public Education
Commission (4). Texas was the largest of them, and the route it proves — find the state's
redistricting portal, prefer the KML over the shapefile, load under `X0003` with no code change,
and anchor on members' home towns — should carry to the rest.

⚠ **ONE CI GUARD I DID NOT KNOW ABOUT, AND IT WAS RIGHT.** `check-postgis-spatial-ref-guard.mjs`
refuses a `::geography` cast in any migration: a geography cast reads `public.spatial_ref_sys`,
which `anon` can write, and ev-cto decision 0006 accepted that risk on the strict condition that
no new SQL re-opens it. The coverage gate used two geography casts. It now takes the ratio of two
**planar** areas over the same patch of Texas, where the distortion cancels — measured against
production, planar says **99.891%** and geodesic **99.890%**, so it is the same test. The guard
scans `backend/migrations` and `supabase/migrations` only, so the loader script, which does the
geodesic measurement, is out of scope and keeps it.
⚠ The amended file cannot be dry-run end to end any more, because its own first gate correctly
refuses a second apply ("the chamber this file creates already exists"). The changed gate was run
on its own against production instead. **No written data differs between the version that ran and
the version committed.**

## ▶ The recipe for the next imported polygon

Texas proved the route; Alabama, Louisiana, New Mexico and Nebraska repeated it. ⚠ **UPDATED
2026-11-07 — Alabama (`CC_0370`), Louisiana (`CC_0371`), New Mexico (`CC_0372`) and all three
Nebraska boards (`CC_0373`-`CC_0375`) are DONE.** **ONE body is left: the NH Executive Council
(5 seats)**, and its source is found — see the end of this file. For each:

1. **Find the state's redistricting portal.** Texas runs CKAN:
   `data.capitol.texas.gov/api/3/action/package_search?q=...` and `package_show?id=<plan>`.
   Others will differ; an ArcGIS FeatureServer is the other common shape — Alabama's is the
   Reapportionment Office's own `_2021_Alabama_State_Bd_of_Education`, found by looking for
   the organisation that also publishes that state's House, Senate and congressional plans.
   🔴 **An ArcGIS service is NOT already in 4326 — Alabama's is Web Mercator (3857).**
   `outSR=4326` makes the SERVER reproject; the query must carry it, and the result still
   has to be bounds-checked.
2. **Pick the plan whose title carries no end date.** Texas's four SBOE plans each state their own
   validity in the title; three said "2013-2022" or "2003-2012".
   🔴🔴 **AND A FILE NAMED `..._final.pdf` CAN BE OLDER THAN THE AMENDMENT THAT PASSED.**
   Nebraska publishes `reg_lb8_final.pdf`, assembled the day LB 8 passed, whose map sheets were
   drawn three days before AM41 was adopted. Four of its eight districts are pre-amendment.
   The bill history settles it (`AM41 · adopted`), and the state GIS agrees with AM41.
   ⚠ **The plan IDENTIFIER does not change when a plan is amended** — LB 8 adopts
   `REG21-39003-1 … -8` and AM41 kept those names — so citing the map name proves nothing
   about which version you hold. **Read the date printed inside the map frame.**
   🔴🔴 **AND CHECK THAT THE BILL BEHIND IT PASSED.** New Mexico filed two PEC redistricting
   bills in 2021 and BOTH DIED; the one a search finds first, HB 6, reads exactly like the law
   and its action line says "Action Postponed Indefinitely". The act in force, HB 9, assigns
   Torrance county to a different district. A gate built from the wrong bill refuses a correct
   map, and the obvious next move is to loosen the gate. ⚠ Also check whether the BODY still
   exists: three New Mexico joint resolutions proposed replacing this commission outright and
   all three died in the House.
3. 🔴 **Prefer the KML. Read the `.prj` of any shapefile before you read its geometry.** Texas's
   is Lambert Conformal Conic in metres, and loaded as 4326 it is valid, correctly shaped and
   matches no address on Earth.
4. **Parse with `CC_0369-parse-plane2106-kml.mjs` as the model** for a KML, or
   `CC_0370-fetch-al-sboe-arcgis.mjs` for an ArcGIS FeatureServer. Both bounds-check every
   coordinate against the state and stop on the first that fails; neither drops anything
   silently. The Texas one refuses a hole or a second ring outright because PlanE2106 has
   none; the Alabama one carries them, because that plan has both (District 6 has a hole,
   District 8 is two parts). It also records each raw response's sha256, and refuses the
   file unless the district populations sum to the state's census total.
5. **Load with `CC_0369-tx-sboe-geofences.mjs` or `CC_0370-al-sboe-geofences.mjs` as the model**, under **`X0003` if the body is a
   board of education** (no code change — that rule is not state-scoped). Any other kind of state
   board goes under `X-ST-BOARD`, which `CC_0366` added to `districtQueries.ts` and
   `geoIdGuard.ts`. ⚠ `mtfcc` is `varchar(10)`.
6. **Gate the map against geometry we already trust**: union vs the state outline (`G4000`),
   pairwise overlap, and every incorporated place (`G4110`) resolving to exactly one district.
   ⚠ **Not every state HAS `G4110` rows in production — Alabama has none.** Fall back to
   ZCTAs (`G6350`) for point resolution.
   🟢 **Then anchor it on evidence from OUTSIDE the map, because nothing above can see two
   districts' labels swapped.** In order of preference:
   (a) the plan's own **county or parish composition** — from the statute (`CC_0370`, 62 of
       Alabama's 67 counties) or from the Legislature's **block equivalency file**, which
       most states publish beside the shapefile and which gives it at block level
       (`CC_0371`). 🟢 **Better still, get it TWICE**: Louisiana's block file and the
       commission's own district pages are independent of each other and of the map, and
       `reconcile-la-psc-parishes.mjs` refuses to emit a table unless they agree;
   (b) otherwise members' **home towns**, and only the ones that lie **wholly** inside one
       district (`CC_0369`).
   ⚠ Use an AREA test, not `ST_Covers`: Alabama's plan disagrees with TIGER by slivers and
     strict containment failed on 55 of 62 counties. Louisiana's is drawn on census VTDs and
     comes out at a clean 100%. Same gate, same thresholds, different data.
   🔴 And the split arm needs a tamper of its OWN. The whole-county arm runs first, and no
     geometry tamper breaks a split while leaving the whole ones right.
   🔴 **MEASURE THE SHARE DISTRIBUTION BEFORE CHOOSING A FLOOR.** 0.5% worked for Alabama and
     Louisiana and REFUSED A CORRECT NEW MEXICO MAP: Otero county's second district is a real
     0.4962% of it. The floor belongs ten times below the smallest TRUE share in that state.
     ⚠ **AND MEASURE IT THE WAY THE GATE WILL.** Nebraska's union coverage is 99.9966% as a
     ratio of planar areas and 99.9019% as an `ST_Difference` in square metres — two different
     questions, and only one of them is the gate.
   🔴🔴 **THE STATE MAY DEFINE ITS DISTRICTS BY MAP REFERENCE, WITH NO COUNTY TEXT AT ALL.**
     Nebraska's three boards are redistricted by "the adoption of maps by reference" and the
     statutes name no county. Where that happens, build the composition from the **Secretary
     of State's certified canvass books**: a county that cast votes in a district's race is in
     that district, and a split county votes in both. Cover every district by using several
     canvasses, and make the districts that appear twice agree. ▶ And bound the parse by the
     book's OWN table of contents — a blacklist of other headings cannot see the heading you
     did not think of, and the 2024 Nebraska book would have fed a judicial district straight
     into the Board of Regents.
   🔴 **COUNT THE DISTRICTS YOU CANNOT ANCHOR, AND SAY SO.** New Mexico has four: three lie
     entirely inside one split county and a fourth is made only of parts of split counties. A
     permutation of the three passes every gate there is. `CC_0372` plants it as a control and
     records that it passes, rather than leaving it to be found.
7. **Migration with `emit369.mjs`, `emit370.mjs` or `emit371.mjs` as the model** — 371 is the
   one to copy for a body that is NOT a board of education, since it files under `X-ST-BOARD`. Create the whole body, seat every member, assert
   the 238 baseline, and finish with the point-to-member chain.
8. Run `check-address-reachability.mjs` and probe the live endpoint for a real address.

🔴🔴 **IF THE STATE HAS TWO BODIES ON ONE CUSTOM LAYER, SCOPE EVERY QUERY BY THE GEO_ID PREFIX.**
Nebraska is the first: its Public Service Commission and its Board of Regents are both
`(X-ST-BOARD, STATE_BOARD)` in state 31. Louisiana's commission and Colorado's regents share
that layer too, but in different states, so `(mtfcc, state)` was enough by accident. A count,
a coverage test or an "already exists" pre-gate keyed on `(mtfcc, state)` alone silently reads
both bodies as one. Both loaders and both migrations carry a control that proves the scoping
is load-bearing.

⚠ **TAKE A ZCTA'S TEST POINT FROM THE PART OF IT INSIDE THE STATE.** Three Nebraska ZCTAs
straddle a state line and `ST_PointOnSurface` lands outside the state — two looked like holes
in the district map and one like a district reaching into Iowa. Clipping to the state outline
first removes all three cases and needs no exclusion list.

🔴🔴 **RUN THE LOADER'S CONTROLS BEFORE THE REAL LOAD, OR DELETE THE ROWS FIRST.** The loaders
insert `ON CONFLICT (geo_id, mtfcc) DO NOTHING`, so once the correct polygons are committed a
tampered dry run inserts NOTHING and every gate checks the rows that were already there. A Web
Mercator file and a map with two districts swapped both reported `DRY RUN OK` that way in
`CC_0372`, with one line of `inserted 0 row(s)` as the only sign. All three loaders now refuse a
dry run that does not insert its full set.

⚠ **Kansas's State Board of Education (5) and Massachusetts's Governor's Council (8) are NOT in
this list.** Their polygons are already in production — they are unions of state senate districts
we hold — and they are blocked only on *which* senate districts compose each one. That is a
sourcing problem, not a geometry one.

# `CC_0370` — Alabama's State Board of Education, and the statute as the anchor

Applied 2026-11-07. **1 chamber · 8 districts · 8 geofence polygons · 8 offices · 8
office_terms · 4 races · 13 politicians · 7 candidacies (4 won).** State-level 2026 results go
from **193 races / 198 winners** to **197 / 202**, still across 40 states.
🟢 **Occupancy baseline unchanged: 293 / 55 / 238.** Address reachability: nothing regressed
(BAD_GEOMETRY 4, DEAD_GEOGRAPHY 17, UNREACHABLE 7, all at baseline).

## 🟢🟢 THE ANCHOR IS THE STATUTE, AND IT IS A BETTER ANCHOR THAN A HOME TOWN

Texas anchored its map on nine board members' **home towns**, because Texas law requires a member
to live in the district. That route does not exist in Alabama: **production holds no incorporated
places (`G4110`) for Alabama at all** — only 67 counties, 7 congressional districts and 656 ZCTAs.

Something better does. **Code of Alabama § 16-3-1.1 *is* the map.** It lists each district as a
set of whole counties followed by the census tracts and blocks of the counties it splits. 62 of
Alabama's 67 counties are assigned whole; 5 are split. So the gate is: each of the 62 lies inside
exactly the district the law names, and each of the 5 is shared by exactly the districts the law
names. That is evidence written in 2021, before this GIS file was published, and it covers the
**whole state** rather than nine points in it.

Measured against production, the map reproduces the statute to the sliver:

| check | result |
| --- | --- |
| union against our TIGER Alabama outline (`G4000` '01') | **99.939% covered** |
| worst pairwise overlap between two districts | **0.000000%** |
| the eight districts' total area | **52,420 sq mi**, which is Alabama's |
| the 62 counties § 16-3-1.1 assigns WHOLE | **all ≥ 99.9966%** inside their own district |
| the largest sliver leaking into any OTHER district | **0.0034%** (Bullock into D2) |
| the 5 counties it SPLITS | Mobile **1/5** · Jefferson **3/4/7** · Montgomery **3/5** · Talladega **3/6** · Tuscaloosa **4/7** |
| Alabama ZCTAs (`G6350`) resolving to exactly one district | **656 of 656** |

⚠ **`ST_Covers` IS THE WRONG TEST AND IT FAILED ON 55 OF THE 62.** The plan's line work and
TIGER's disagree by slivers along every shared boundary, so strict containment is not what the
statute means. The thresholds — 99.9% in, 0.01% out — were chosen **after** measuring the real
distribution, and sit about 30x clear of it on both sides.

🔴 **THE SPLIT ARM SETTLED A READING OF THE LAW THAT THE TEXT ITSELF LEAVES AMBIGUOUS.** The
Legislature's published bill text gives District 5's county list as *"… Wilcox County, **Mo
County**:"*. Mobile or Montgomery? The tract numbers say Mobile — District 1 takes Mobile County
tracts 31.00–70.00 and District 5's list runs 2.00–35.01, which is one county divided between two
districts — and Montgomery is named separately in the same section with its own tracts. That was a
**reading**, so it was written into the gate as a claim and tested rather than assumed. The
geometry answers Mobile = D1 50.68% / D5 49.31%. If the reading had been wrong the file would have
stopped.

## 🔴🔴 THE SERVICE IS WEB MERCATOR, AND THE CONTROL THAT PROVES THE GUARD WAS SHADOWED AT FIRST

The Alabama Legislative Reapportionment Office's ArcGIS layer reports
`{wkid: 102100, latestWkid: 3857}` and an extent of `-9848795, 3522128 .. -9449716, 4164973` —
**metres**. Taken as served and labelled 4326 that is the Holladay failure exactly. The query asks
for `outSR=4326`, the parser bounds-checks all 71,244 coordinate pairs against Alabama, and the
loader checks each bounding box again after INSERT.

🔴 **CONTROL A FAILED, CORRECTLY, FOR THE WRONG REASON, AND THAT LOOKED LIKE A PASS.** The first
version of the loader computed each district's area in square miles with a `::geography` cast *in
the same SELECT as the bounding-box guard*, for a log line. Run against the Web Mercator tamper it
died inside PostGIS — `lwgeom_area_spher(oid) returned area < 0.0` — **before the CRS guard was
reached**. The transaction rolled back and the run went red, so nothing bad happened and nothing
was learned: the gate under test had never executed. The area measurement now runs after the CRS
guard, and the control fails where it should:
`ocd-division/…/sboe:1 bbox -9842293,3522128 .. -9550003,3770101 is outside Alabama — WRONG CRS`.
▶ **Nothing that needs lon/lat to be lon/lat may run before the gate that checks it is.**

## Which map, and how that was settled

The 2021 plan, enacted in the 2021 First Special Session as the **McClendon SBOE Plan 1** and
codified whole as **§ 16-3-1.1**. Alabama redistricts only in the first session after each
decennial census (Const. 1901, Art. IX §§ 197-200). The 2023 remedial litigation redrew the
**congressional** map and, separately, state Senate districts, and left this one alone; it took
effect for the 2022 board elections and governed the 2026 ones.

🟢 **The layer identifies itself.** Its eight `POPULATION` values sum to **5,024,279** — Alabama's
2020 apportionment population to the person — and `IDEAL_VALU` is **628,035**, that figure over
eight. No map drawn on another census can do that. The fetch script asserts both, which is how
this service was chosen over the two unattributed copies of the same plan also on ArcGIS Online.

⚠ **THE LEGISLATURE'S OWN PAGE FOR THIS MAP IS STALE.**
`alison.legislature.state.al.us/reapportionment-board-education-state-map` still reads
**"Board of Education State Map: 2011 State Education Districts"**, with a broken image. The
operative text is the statute, and the Reapportionment Office's GIS agrees with it. *A source can
be authoritative for one field and out of date for another* — here, for the whole page.

## The board has nine members and this file creates eight

§ 16-3-1: *"The State Board of Education shall be composed of the Governor as an ex officio member
and eight members elected from districts provided by general law."* The Governor's presidency is a
power of the **Governor's office**, which production already holds, not a seat of its own, so no
row is created for it. `official_count` is **9**, the chamber holds **8** offices, and the
post-verify asserts both numbers and that `remarks` says why. **A gap nothing asserts is a
decision the next pass has to make again.**

## 🔴 Two of the four winners replace the sitting member, and the date is in the statute

| district | holder today | 2026 |
| --- | --- | --- |
| 2 | Tracie West (R) | 🏆 **re-elected**, over Jamie McCurry (D) |
| 4 | Yvette Richardson (D) | 🏆 **re-elected**, unopposed |
| 6 | Marie Manning (R) | 🏆 **Cathi Bradford** (R) won, over Angela Morgan (D) |
| 8 | Wayne Reynolds (R) | 🏆 **Emily Jones** (R) won, over Shatika Armstrong (D) |

All eight seats are seated with their **current** holder. Manning and Reynolds were not on the
November ballot and are still in office.

▶ **2027-01-18 — SEAT BRADFORD IN DISTRICT 6 AND JONES IN DISTRICT 8.** § 16-3-1: a member holds
office *"from the first Monday after the second Tuesday in January next after"* the election. In
January 2027 the second Tuesday is the 12th, so the first Monday after it is the **18th**. The
chamber's `inauguration_rules` carries that sentence and the date, and a gate asserts it is there.

Districts 1, 3, 5 and 7 were last elected in 2024 and are next up in **2028** — Alabama staggers
its board by parity, even districts in midterms and odd ones in presidential years.

## Rosters and identity

Two independent rosters, read 2026-11-07, agree on all eight districts: the board's own members
page (`alabamaachieves.org/state-board-of-education/`) and Ballotpedia's officeholder table. Where
they differ it is only in form — the board page prints degrees and maiden names (*Yvette M.
Richardson, Ed.D.*, *Kelly McCarthy Mooney*, *Tonya S. Chestnut, Ed.D.*, *Allen Long, M.D.*,
*Wayne Reynolds, Ed.D*) — so Ballotpedia's plain form is used, because the Ballotpedia page is the
source each politician row cites.

All 13 people are new. A sweep of all **91,735** politicians on both full name *and* (first, last)
returned nothing for any of them, including Emily Jones, Angela Morgan and Allen Long, which is
why it was run. 🟢 The sweep is not blind: its positive control found Tommy Tuberville.

🔴 **EVERY SOURCE URL WAS FETCHED AND READ, NOT COMPOSED FROM THE NAME — AND ONE OF THEM WAS A
DISAMBIGUATION PAGE.** `ballotpedia.org/Allen_Long` returns **HTTP 200**, contains the words
"Allen Long", and is a list of two different men: *"Allen Long may refer to: Allen Long (Alabama),
Allen Long (California)."* Only the "does this page mention the Alabama State Board of Education"
test caught it, and that test would **not** catch the same thing for a name whose other bearer
also sits on a school board — so `resolve-al-sboe.mjs` now refuses a disambiguation page by name.
Emily Jones's page is `/Emily_Jones_(Alabama)` for the same reason. ▶ **A slug built from a name is
a guess; the committed source is the URL that was opened and read.**

## Controls

**On the loader** (`controls370-loader.mjs`):

| | fault planted | observed |
| --- | --- | --- |
| A | the real data reprojected to Web Mercator metres, relabelled 4326 | `sboe:1 bbox -9842293,3522128 … is outside Alabama — WRONG CRS` |
| B | District 7 dropped from the file | `expected 8 districts … found 7` |
| C | the geometry of Districts 2 and 6 swapped, numbers kept | `the statute puts these counties wholly in one district and the map does not: Russell County is only 0.0000% in D2; … Calhoun County is only 0.0025% in D6; …` |
| D | the geometry of Districts 4 and 7 swapped (they share Tuscaloosa) | the same gate, on D4 and D7's counties |
| E | the statute table claims Tuscaloosa for districts 4 and **6** | `a county the statute splits is shared with the wrong districts: Tuscaloosa County -> 4,7, statute says 4,6` |

🔴 **C IS THE ONE WORTH READING, AND E EXISTS BECAUSE C AND D ARE NOT ENOUGH.** With two districts'
labels swapped the map passes *every structural check* — 8 valid 4326 polygons inside Alabama, a
union covering 99.939%, zero overlap, all 656 ZCTAs resolving to exactly one district. Only the
statute can tell. But C and D both fire on the **whole-county** arm, which runs first, so the
**split** arm had only ever been watched passing — and no geometry tamper breaks a split while
leaving all 62 whole counties right. E tampers the statute table instead. *A gate that has only
ever passed proves nothing.*

**On the migration** (`controls370.mjs`):

| | fault planted | observed |
| --- | --- | --- |
| A | the seating **and** the every-office-is-seated gate removed | `the baseline moved to 246 — it was 238 and must never be raised` |
| B | the districts filed under layer `X0099` | `only 0 of the 8 districts meet a geofence row on (geo_id, mtfcc)` |
| C | Districts 2 and 6's **members** swapped in the seat table | `the anchor table and the seat table name different members: D2: anchor says Tracie West, seat says Marie Manning; …` |
| D | the office-to-district join reversed (`md.d = 9 - s.d`) | `an anchor county does not reach its board member: Baldwin County -> Wayne Reynolds (expected Jackie Zeigler); …` |
| E | the statute table claims Coffee County for District 6 | `the statute puts these counties wholly in one district and the map does not: Coffee County is only 0.0000% in D6` |
| F | a middle name dropped from a compound given name | `a seeded name does not match its own split: Tonya Smith Chestnut splits to (Tonya, Chestnut)` |
| G | `official_count` set to 8 | `official_count is 8, not 9 — the board has 9 members and the Governor is the ninth` |

🟢 **D IS THE CONTROL `CC_0369` COULD NOT WRITE.** Texas's control C swapped two members in the
seat table, and the **pre-gate** caught it — which proved the two-statements-of-the-roster design
but left the point-to-member **chain** itself still only ever watched passing. Reversing the
office-to-district join instead leaves the seat table and the anchor table agreeing with each
other, every polygon right, the statute gate green, 8 offices created and all 8 seated, and every
count balanced. The chain is the only thing that can see it, and it did, on all eight anchors.

⚠ **E WAS RETARGETED AFTER FIRING ON THE WRONG GATE.** It first moved **Houston County**, which is
District 2's anchor, and the run died on the earlier *"an anchor county is not assigned whole to
its district by the statute"* pre-gate — a correct failure, for a gate that was not under test.
Coffee County anchors nothing. **Twice in this file a control failed for the wrong reason**; both
times only reading the message said so.

## Measured on the live endpoint

`https://ev-accounts-api.onrender.com/api/essentials/address-search`, against **live production**,
after the migration and with no deploy — `X0003` was already in the deployed read path:

| address | returned |
| --- | --- |
| 600 Dexter Ave, Montgomery, AL | **State Board of Education Member, District 5 — Tonya Smith Chestnut**, `seat_status: held` |
| 308 Fountain Cir, Huntsville, AL | **State Board of Education Member, District 8 — Wayne Reynolds**, `seat_status: held` |

In the database the whole chain resolves for every point tried: Birmingham and Tuscaloosa →
District 4 → Yvette Richardson; Montgomery and Mobile → District 5 → Tonya Smith Chestnut;
Huntsville → District 8 → Wayne Reynolds. 🟢 Mobile city lands in District 5 and not District 1,
which is the right answer: District 5 is the Black Belt seat running from Mobile through Selma to
Montgomery, and District 1 takes Baldwin County and suburban Mobile County.

## Tier 3 after Alabama — 25 seats

**Blocked only on a composition** (the polygons are already in production, as unions of state
senate districts we hold): KS State Board of Education (5) and MA Governor's Council (8).
**Needs an imported polygon** (12): LA PSC (2), NE PSC (1), NE State Board of Education (3),
NE Regents (1), NH Executive Council (5), NM Public Education Commission (4).
⚠ **Nebraska is three separate bodies and we hold no Nebraska legislative-district geometry at
all** — leave it for last.

▶ **ALABAMA ADDS ONE LINE TO THE RECIPE ABOVE (§ "The recipe for the next imported
polygon"): when the state publishes its districts as statute
text, that text is a better anchor than anything on the map's own side** — it is independent of
the GIS, it was written first, and it covers the whole state instead of a handful of points.

# `CC_0371` — Louisiana's Public Service Commission, and a composition stated twice

Applied 2026-11-07. **1 chamber · 5 districts · 5 geofence polygons · 5 offices · 5 office_terms ·
2 races · 10 politicians · 5 candidacies (2 won).** State-level 2026 results go from **197 races /
202 winners** to **199 / 204**, still across 40 states.
🟢 **Occupancy baseline unchanged: 293 / 55 / 238.** Address reachability: nothing regressed
(BAD_GEOMETRY 4, DEAD_GEOGRAPHY 17, UNREACHABLE 7, all at baseline).

## 🟢🟢 THE COMPOSITION IS STATED TWICE, BY TWO OFFICIAL SOURCES THAT DO NOT DERIVE FROM EACH OTHER

Alabama anchored its map on one statute. Louisiana has **two** independent official statements of
the same thing, and `reconcile-la-psc-parishes.mjs` refuses to emit a parish table unless they
agree on all 64:

1. **The Legislature's block equivalency file** for Act 2 (HB2) of the 2022 First Extraordinary
   Session — **142,874 rows** of `<2020 census block GEOID> <district>`. A parish is WHOLE in a
   district when every one of its blocks maps to that district. This is the plan as enacted, at
   the finest grain there is.
2. **The commission's own five district pages**, `lpsc.louisiana.gov/District1..5`, each of which
   lists its parishes under "Commission District Geographical Area" and marks the divided ones
   with an asterisk, citing Act 2 by name.

They agree exactly: **54 parishes whole, 10 split** — Ascension 2/3, Assumption 2/3, East Baton
Rouge 2/3, Iberville 2/3, Jefferson 1/3, Livingston 1/2, Orleans 1/3, St. Charles 1/3, St. Martin
2/4, West Baton Rouge 2/3. The 74 parish mentions across the five pages minus the 10 repeats is
exactly 64, which is Louisiana's parish count, and no parish appears in three districts.

⚠ **Two names needed an alias and no more.** The commission writes "St. John Baptist" and
"DeSoto"; TIGER holds "St. John the Baptist Parish" and "De Soto Parish". Both are declared; a
third difference stops the script rather than being absorbed quietly.

Measured against production after the load:

| check | result |
| --- | --- |
| union against our TIGER Louisiana outline (`G4000` '22') | **99.743% covered** |
| worst pairwise overlap between two districts | **0.000000%** |
| the five districts' total area | **52,377 sq mi**, which is Louisiana's |
| the 54 parishes Act 2 assigns WHOLE | **all 100.0000%** inside their own district |
| the largest sliver leaking into any OTHER district | **none at all** |
| the 10 parishes it SPLITS | shared by exactly the districts named; **smallest true share 15.14%** (St. Martin in District 4) |
| Louisiana ZCTAs (`G6350`) resolving to exactly one district | **539 of 539** |

🟢 **Louisiana's parishes come out at a clean 100%, where Alabama's counties were 99.9966%.** The
difference is real and expected: Act 2 was drawn on census VTDs, which nest inside parishes, so
the plan's line work *is* TIGER's. Alabama's plan was digitised separately and disagrees with
TIGER by slivers. The same gate is used for both, with the same thresholds; it is the data that
differs, not the test.

## 🟢 THE SHAPEFILE HERE IS NOT A CRS TRAP, AND THAT WAS READ RATHER THAN ASSUMED

The Legislature publishes the plan as both a shapefile and a KML, exactly as Texas does.
`HB2_PSC_221ES.prj` reads:

```
GEOGCS["GCS_North_American_1983",DATUM["D_North_American_1983",
  SPHEROID["GRS_1980",6378137,298.257222101]],PRIMEM["Greenwich",0],
  UNIT["Degree",0.017453292519943295]]
```

Geographic degrees on NAD83 — **not** a projected plane. Texas's `PLANE2106.prj` in precisely this
role was Lambert Conformal Conic in **metres**, which loaded as 4326 is the Holladay failure.
▶ **Same kind of file, same position in the same kind of dataset, opposite answer. Read the `.prj`
every time; the previous state's answer is not evidence about this one.** The KML is used anyway,
because KML is WGS84 lon/lat by specification and leaves nothing to decide, and the parser
bounds-checks all 80,808 coordinate pairs against Louisiana.

⚠ The Legislature's own directory for this plan is spelled **"Commssion"**. That is their typo and
the URL only works with it.

## Which map, and how that was settled

Act 2 (HB2) of the 2022 First Extraordinary Session. ⚠ **Louisiana's 2026 Regular Session DID
redistrict** — SB121 by Sen. Jay Morris became Act 2 of 2026 — **but that is the congressional
map.** All nine redistricting bills filed that session were checked one by one on `legis.la.gov`
on 2026-11-07: SB116, SB117, SB121, SB130 and HB642 congressional; SB136 Senate; HB640, HB698 and
HB700 House. None touched the PSC. ▶ **"The state redistricted this year" is not an answer about
*this* map — read the bill subjects.**

## 🔴 LOUISIANA'S NOVEMBER TRAP IS REAL AND DOES NOT APPLY HERE, WHICH IS WHY IT IS WRITTEN DOWN

Louisiana's November contest has historically been a **majority-vote "jungle" primary**, so a
result under 50% means a runoff and not a loss. Ballotpedia's own page records the change:
*"Beginning in the 2026 elections, Louisiana elections for U.S. Congress, the Louisiana Supreme
Court, the Public Service Commission, and the Board of Elementary and Secondary Education use a
closed partisan primary and primary runoff system."* So November 2026 is a true general election
for this body.

That is a claim about the law, so the emitter does not rely on it: it **asserts the winner's share
is over 50%** in every recorded race, and stops otherwise. Hilferty took 58.9% and Atkins 59.2%,
so both races are decided under either system. The chamber's `election_rules` carries the change
and a gate asserts the text is there.

## 🔴 THE LAYER IS `X-ST-BOARD`, AND THESE SEATS ARE NOT LIVE YET — MEASURED, NOT ASSUMED

A Public Service Commission is not a board of education, so these districts are `STATE_BOARD` on
layer `X-ST-BOARD` — the pair `CC_0366` added to `districtQueries.ts` and `geoIdGuard.ts` for the
University of Colorado Regents. **That read-path line is on this branch and not yet deployed.**

Measured on `ev-accounts-api.onrender.com` after the migration: a Baton Rouge address and a
Shreveport address each return 43 rows and **no** Public Service Commissioner.
🟢 **And the positive control says that is the deploy and not this file.** The same live endpoint,
asked for `200 E Colfax Ave, Denver, CO`, returns *State Board of Education Member, District 1* and
*University of Colorado Regent, At-Large* but still **not** the districted CU Regent — the exact
state `CC_0366` recorded. One `X0003` seat shows and one `X-ST-BOARD` seat does not, from the same
address, in the same response. Both appear on the next backend deploy.

In the database the chain resolves now: New Orleans and Baton Rouge → District 3 → Davante Lewis;
Lafayette → District 2 → Jean-Paul Coussan; Lake Charles → District 4 → Mike Francis;
Shreveport → District 5 → Foster Campbell.

## 🔴 Neither winner is the holder, and the handover date comes from the commission itself

| district | holder today | 2026 |
| --- | --- | --- |
| 1 | Eric Skrmetta (in office since 2009-01-01) | 🏆 **Stephanie Hilferty** (R) won, over Connie Norris (D) and Chris Justin (unaffiliated) |
| 2 | Jean-Paul Coussan | not on the ballot — term ends 2030-12-31 |
| 3 | Davante Lewis | not on the ballot — term ends 2028-12-31 |
| 4 | Mike Francis | not on the ballot — term ends 2028-12-31 |
| 5 | Foster Campbell (in office since 2003-01-01) | 🏆 **John Atkins** (R) won, over James Green (D) |

Neither sitting commissioner was a candidate, so **no** candidacy carries the incumbent flag, and
a gate asserts that rather than leaving it to the generic cross-check.

▶ **2027-01-01 — SEAT HILFERTY IN DISTRICT 1 AND ATKINS IN DISTRICT 5.** Terms run whole calendar
years; the commission's own pages give Districts 1 and 5 as ending **December 31, 2026**. The
chamber's `inauguration_rules` carries that and a gate asserts the date is in it.

🔴 **No term start is invented.** The commission publishes each member's term *end*, not its start,
so every term is open-ended with `start_precision 'unknown'`. The 2009 and 2003 dates above are
what the pages say about *assuming office*, which is not the start of the current term, so they
stay in prose and out of `office_terms`.

## Identity

All 10 people are new. A sweep of all **91,748** politicians on both full name and (first, last)
returned nothing for any of them — including John Atkins, James Green, Chris Justin and Connie
Norris, which is why it was run. 🟢 The sweep is not blind: its positive control found Jeff Landry.

🔴 **A SECOND DISAMBIGUATION PAGE, IN A SECOND STATE.** `ballotpedia.org/Mike_Francis` returns
HTTP 200, contains "Mike Francis", and is a list of two different men — an Arizona one and a
Louisiana one. His page is `/Mike_Francis_(Louisiana)`. `CC_0370` found the same shape at
`/Allen_Long` the same day. ▶ **Two in two files is not a coincidence; a slug built from a name is
a guess.** Every one of the ten URLs was fetched and asserted to name the person, to mention the
Louisiana Public Service Commission, and not to be a disambiguation page.

## Controls

**On the loader** (`controls371-loader.mjs`):

| | fault planted | observed |
| --- | --- | --- |
| A | the real data reprojected to Web Mercator metres, relabelled 4326 | `psc:1 bbox -10123637,3357219 … is outside Louisiana — WRONG CRS` |
| B | District 3 dropped from the file | `expected 5 districts … found 4` |
| C | the geometry of Districts 4 and 5 swapped, numbers kept | `Act 2 puts these parishes wholly in one district and the map does not: Calcasieu Parish is only 0.0000% in D4; Caddo Parish is only 0.0000% in D5; …` (40 parishes) |
| D | the parish table claims St. Martin for districts 2 and **5** | `a parish Act 2 splits is shared with the wrong districts: St. Martin Parish -> 2,4, Act 2 says 2,5` |

🔴 **C is the one worth reading, and D exists because C is not enough.** With two districts'
labels swapped the map passes every structural test — five valid 4326 polygons inside Louisiana,
a union covering 99.743%, zero overlap, all 539 ZCTAs resolving to exactly one district. Only the
parish composition can tell. But C fires on the **whole-parish** arm, which runs first, and no
geometry tamper breaks a split while leaving all 54 whole parishes right, so the **split** arm
needs a tamper of its own. D picks St. Martin, the thinnest split in the plan (127 of its 1,672
blocks are in District 4).

**On the migration** (`controls371.mjs`):

| | fault planted | observed |
| --- | --- | --- |
| A | the seating **and** the every-office-is-seated gate removed | `the baseline moved to 243 — it was 238 and must never be raised` |
| B | the districts filed under layer `X0099` | `only 0 of the 5 districts meet a geofence row on (geo_id, mtfcc)` |
| C | Districts 1 and 5's **members** swapped in the seat table | `the anchor table and the seat table name different members: D1: anchor says Eric Skrmetta, seat says Foster Campbell; …` |
| D | the office-to-district join reversed (`md.d = 6 - s.d`) | `an anchor parish does not reach its commissioner: St. Tammany Parish -> Foster Campbell (expected Eric Skrmetta); …` |
| E | the plan table claims Lafourche Parish for District 5 | `Act 2 puts these parishes wholly in one district and the map does not: Lafourche Parish is only 0.0000% in D5` |
| F | the hyphen dropped from a hyphenated given name | `a seeded name does not match its own split: Jean-Paul Coussan splits to (Jean, Coussan)` |
| G | the District 1 winner marked as the incumbent | `an incumbent flag disagrees with the seat's holder: Stephanie Hilferty in D1` |

⚠ **D names only four of the five anchors**, because `6 - 3 = 3`: District 3 maps to itself under
the reversal and is the one seat the tamper leaves correct. That is the control reporting what it
found, not a gap in it.

⚠ **E is deliberately NOT an anchor parish.** `CC_0370`'s equivalent control first moved an anchor
county and died on the earlier *"an anchor is not assigned whole to its district"* pre-gate — a
correct failure, for a gate that was not under test. Lafourche is whole in District 2 and anchors
nothing.

⚠ The split defect makes its **eighth** appearance, and its first as a hyphenated *given* name
rather than a compound surname.

## Tier 3 after Louisiana — 23 seats

**Blocked only on a composition** (the polygons are already in production, as unions of state
senate districts we hold): KS State Board of Education (5) and MA Governor's Council (8).
**Needs an imported polygon** (10): NE PSC (1), NE State Board of Education (3), NE Regents (1),
NH Executive Council (5), NM Public Education Commission (4).
⚠ **Nebraska is three separate bodies and we hold no Nebraska legislative-district geometry at
all.** New Mexico's Public Education Commission is the next single-source body; New Hampshire's
executive councillor districts are defined as lists of towns and wards, and we hold `G4040`
county subdivisions for only 11 states, New Hampshire not among them.

# `CC_0372` — New Mexico's Public Education Commission, and the bill that was not the law

Applied 2026-11-07. **1 chamber · 10 districts · 10 geofence polygons · 10 offices · 10
office_terms · 4 races · 12 politicians · 5 candidacies (4 won).** State-level 2026 results go
from **199 races / 204 winners** to **203 / 208**, still across 40 states.
🟢 **Occupancy baseline unchanged: 293 / 55 / 238.** Address reachability: nothing regressed.

## 🔴🔴 THE FIRST BILL I READ WAS NOT THE LAW, AND ITS MAP WAS DIFFERENT

A search for New Mexico's PEC redistricting finds **HB 6** of the 2021 Second Special Session —
"RELATING TO REDISTRICTING OF THE PUBLIC EDUCATION COMMISSION", the 2021 Educational
Redistricting Act, ten districts defined precinct by precinct. It reads exactly like the answer,
and its county composition was fully parsed before anything checked its status line:

```
ActionText: Action Postponed Indefinitely
```

**HB 6 died. So did HB 7, the other PEC bill.** The act in force is **HB 9, Laws 2021 (2nd S.S.),
Chapter 3** — `PASSED/H (61-0) … PASSED/S (25-13) … SGND BY GOV (Dec. 17) Ch. 3`. Its lists are
not HB 6's: HB 6 would have put **Torrance county in District 8**, and HB 9 puts the whole of it
in **District 6**. Had the gate been built from HB 6, it would have refused a correct map and the
obvious next move would have been to loosen the gate.

▶ **A BILL PAGE IS NOT EVIDENCE THAT A BILL BECAME LAW. READ THE ACTION LINE.** The whole 2021
2nd-session slate is instructive: of the thirteen bills checked, only SB 1 (Congress, Ch. 2),
HB 9 (PEC, Ch. 3), HB 8 (House, Ch. 6) and SB 2 (Senate, Ch. 7) were signed.

⚠ **AND A BODY CAN BE ABOLISHED ON PAPER THREE TIMES AND STILL EXIST.** SJR 1 (2023), SJR 9
(2024) and SJR 3 (2025) each proposed replacing this commission with an elected state school
board — one of them with members "elected at the 2026 general election for staggered terms
beginning January 1, 2027", which is exactly the kind of sentence that would change what this
file records. All three **passed the Senate and died in the House**, and no such measure reached
the 2026 ballot. Checked one by one, because a half-read proposal is indistinguishable from a
law.

## 🟢 The statute says whole-or-partial outright, and a second source agrees

HB 9 writes each district as semicolon-separated clauses of two shapes:

```
Catron county;                        → the WHOLE county is in this district
Cibola county precincts 1, 7 and 15;  → only those precincts are
```

So the act classifies its own counties — **23 whole, 10 split** — and does not have to be
inferred. `parse-nm-pec-statute.mjs` reads that out of the enacted PDF and then **cross-checks it
against the Legislative Council Service's 2025 handbook page**, which lists each district's
counties independently. They agree on all ten districts.

⚠ **A PREDICATE READS THE SHAPE OF A VALUE, AND TWICE IT READ THE WRONG SHAPE.** The first
version matched only `"<X> county precincts"` and found **10 counties instead of 33**, because
every whole county is written without the word "precincts". The second matched only the plural
and read `"Bernalillo county precinct 31"` — District 5's single-precinct clause — as the whole
of Bernalillo. Both were caught by the count, not by reading: 10 ≠ 33, and "named whole in one
district and by precinct in another".

Measured against production after the load:

| check | result |
| --- | --- |
| union against our TIGER New Mexico outline (`G4000` '35') | **99.986% covered** |
| worst pairwise overlap between two districts | **0.000000%** |
| the ten districts' total area | **121,595 sq mi**, which is New Mexico's |
| the 23 counties HB 9 assigns WHOLE | **all ≥ 99.9992%** inside their own district |
| the 10 it SPLITS | shared by exactly the districts named |
| New Mexico ZCTAs (`G6350`) resolving to exactly one district | **372 of 372** |

## 🔴 The split floor is 0.05% here, not 0.5%, and that is a measurement not a preference

Alabama and Louisiana both used a 0.5% floor for "this county is really in that district". At
0.5% the New Mexico gate refused a correct map:

```
a county HB 9 splits is shared with the wrong districts: Otero County -> 9, HB 9 says 7,9
```

**Otero county's District 7 slice is a real 0.4962% of it** — the Chaparral end, next to Doña
Ana. Every *false* share in New Mexico is 0.000000% to six places, because this plan shares
TIGER's county line work exactly, so the floor could go an order of magnitude lower with room on
both sides. ▶ **A threshold carried over from another state is a guess. Measure the distribution,
then choose.**

## 🔴🔴 ONLY 6 OF THE 10 DISTRICTS CAN BE ANCHORED, AND THE HOLE IS RECORDED RATHER THAN HIDDEN

An anchor has to be a county the act assigns WHOLE to one district. Four districts have none:
**1, 2 and 3 lie entirely inside Bernalillo**, which HB 9 splits six ways, and **7 is made only
of parts of Doña Ana and Otero**, both split.

District 7 is still pinned, by the split arm: move its geometry anywhere else and Bernalillo or
Doña Ana stops being shared by exactly the districts the act names. **Districts 1, 2 and 3 are
not.** A permutation of those three leaves Bernalillo shared by exactly `{1,2,3,4,5,6}`, leaves
the coverage, overlap and ZCTA tests untouched, and passes everything this file can ask.

So the permutation is planted as **loader control D** and observed to pass. ▶ **A control that
passes and is written down is a measured limit; a control nobody ran is a surprise waiting for
the next pass.** Closing it needs evidence at precinct level, and production holds no New Mexico
precinct geometry.

## 🔴🔴 THE LOADER'S CONTROLS WENT VACUOUS THE MOMENT THE REAL POLYGONS WERE COMMITTED

The loaders end their INSERT with `ON CONFLICT (geo_id, mtfcc) DO NOTHING`, which is what makes a
real re-run idempotent. The first run of this body's controls happened **after** the correct
polygons had been loaded for real — and the CRS control and the label-swap control both reported:

```
inserted 0 row(s)
…
DRY RUN OK — rolled back
```

Nothing was inserted, so every gate was checking the **already-correct production rows**, and a
Web Mercator file and a map with two districts swapped both sailed through. The only sign was one
line of output, `inserted 0 row(s)`, above a wall of green.

All three loaders now refuse this outright:

```js
if (DRY_RUN && inserted !== 10) {
  fail(`a dry run inserted ${inserted} of 10 rows — the rest are already in the table, so the
        gates below would be checking those and not this file.`);
}
```

▶ **A DRY RUN IS A REHEARSAL OF THE INSERT, SO IT HAS TO ACTUALLY INSERT.** `CC_0370` and
`CC_0371` ran their controls before the real load and were never affected; the guard is added to
them anyway, because the ordering was luck and not design. With the rows deleted and the controls
re-run, every one of them fired.

## Roster, and one seat the handbook has wrong

| district | holder | 2026 |
| --- | --- | --- |
| 1 | Sam S. Obenshain (D) | not on the ballot — next up 2028 |
| 2 | Timothy Beck (R) | 🏆 **Ken Pascoe** (R) won the seat |
| 3 | Jacob Trujillo (D) | 🏆 re-elected, over Dennis Dinge (Forward Party) |
| 4 | Rebekka Burt (D) | 2028 |
| 5 | Sharon E. Clahchischilliage (R) | 🏆 re-elected |
| 6 | Stewart Ingham (R) | 🏆 re-elected |
| 7 | Patricia Gipson (D) | ⏳ on the ballot, **uncalled** |
| 8 | Michael Taylor (R) | 2028 |
| 9 | K.T. Manis (R) | 2028 |
| 10 | Steven Carrillo (D) | 2028 |

Five districts were on the ballot — **2, 3, 5, 6 and 7, exactly the five HB 9 Section 3C names** —
and District 7 is the one with no winner called: Frederick Parker (D) and John Foreman (R) ran and
Ballotpedia reports no result. Neither is seeded; it belongs to the uncalled pass.

▶ **2027-01-01 — SEAT KEN PASCOE IN DISTRICT 2.** HB 9 Section 3B: members are elected "for terms
commencing on January 1 next succeeding their election".

⚠ **A ROSTER CAN BE RIGHT ABOUT THE BODY AND OUT OF DATE ABOUT A SEAT.** The 2025 Legislative
Council handbook agrees with Ballotpedia on nine of the ten members and on every district's county
list, and gives District 3 as **Alan Lee Brauer Jr.** Ballotpedia's 2026 District 3 votebox calls
Jacob Trujillo the incumbent, so the handbook is simply older there — which is also why the
handbook is used for the composition and not for the roster.

All 12 people are new; the sweep over 91,758 politicians on full name and (first, last) returned
nothing, and its positive control found Michelle Lujan Grisham. All 12 Ballotpedia pages were
fetched and asserted to name the person, mention the commission, and not be disambiguation pages —
a check that has now caught two real cases in this series (`/Allen_Long`, `/Mike_Francis`).

## Controls

**On the loader** (`controls372-loader.mjs`), run with the table empty:

| | fault planted | observed |
| --- | --- | --- |
| A | the real data reprojected to NAD83 UTM 13N metres, relabelled 4326 | `pec:1 bbox 321425,3872860 … is outside New Mexico — WRONG CRS` |
| B | District 6 dropped from the file | `expected 10 districts … found 9` |
| C | the geometry of Districts 8 and 9 swapped | `HB 9 puts these counties wholly in one district and the map does not: Lea County is only 0.0000% in D9; …` |
| D | **Districts 1, 2 and 3 rotated** | **`DRY RUN OK` — passes, by design; see the anchoring hole above** |
| E | the county table claims Otero for districts 7 and **8** | `a county HB 9 splits is shared with the wrong districts: Otero County -> 7,9, HB 9 says 7,8` |

**On the migration** (`controls372.mjs`):

| | fault planted | observed |
| --- | --- | --- |
| A | the seating **and** the every-office-is-seated gate removed | `the baseline moved to 248 — it was 238 and must never be raised` |
| B | the districts filed under layer `X0099` | `only 0 of the 10 districts meet a geofence row on (geo_id, mtfcc)` |
| C | Districts 5 and 6's members swapped in the seat table | `the anchor table and the seat table name different members: D5: anchor says Sharon E. Clahchischilliage, seat says Stewart Ingham; …` |
| D | the office-to-district join reversed (`md.d = 11 - s.d`) | `an anchor county does not reach its commissioner: Los Alamos County -> Patricia Gipson (expected Rebekka Burt); …` |
| E | the plan table claims Luna County for District 9 | `HB 9 puts these counties wholly in one district and the map does not: Luna County is only 0.0000% in D9` |
| F | a middle initial dropped from a compound given name | `a seeded name does not match its own split: Sharon E. Clahchischilliage splits to (Sharon, Clahchischilliage)` |

⚠ E is deliberately **not** an anchor county — Catron is District 6's anchor, Luna is merely whole
in it — so the anchor pre-gate does not shadow the gate under test. That shadowing is the mistake
`CC_0370`'s control E made on its first run.
⚠ The split defect makes its **ninth** appearance.

## Measured on the live endpoint

`https://ev-accounts-api.onrender.com/api/essentials/address-search`, against live production,
with no deploy — `X0003` is already in the deployed read path because the Public Education
Commission *is* a state board of education:

| address | returned |
| --- | --- |
| 491 Old Santa Fe Trail, Santa Fe, NM | **Public Education Commissioner, District 10 — Steven Carrillo**, `seat_status: held` |
| 400 N Main St, Roswell, NM | **Public Education Commissioner, District 8 — Michael Taylor**, `seat_status: held` |

In the database the chain resolves for every point tried: Los Alamos → D4 → Rebekka Burt;
Farmington → D5 → Sharon E. Clahchischilliage; Las Cruces → D7 → Patricia Gipson; Roswell → D8 →
Michael Taylor; Santa Fe → D10 → Steven Carrillo.

## Tier 3 after New Mexico — 19 seats

**Blocked only on a composition** (the polygons are already in production, as unions of state
senate districts we hold): KS State Board of Education (5) and MA Governor's Council (8).
**Needs an imported polygon** (6): NE PSC (1), NE State Board of Education (3), NE Regents (1),
NH Executive Council (5).

🟢 **BOTH SOURCES ARE FOUND — neither state needs digitising, and New Hampshire does not need
county subdivisions after all.** Searched ArcGIS Online 2026-11-07:

- **Nebraska — one service covers all three bodies.** `gis.ne.gov`, the state's own GIS:
  `https://gis.ne.gov/Enterprise/rest/services/PoliticalBoundaries_2021/FeatureServer`
  — layer **3** "Public Service Commision 2021" (their spelling) and layer **6** "Board of
  Education 2021", each described as *"created in 2021 by the Legislative Research Office with
  input from the Nebraska Legislature Redistricting Committee"*. The Regents layer is in the same
  service; enumerate it rather than guessing the index.
  ▶ Three bodies, one fetch, one statute to read. Nebraska's districts are defined in LB 1 and
  LB 3 of the 2021 special session — **check which passed before building a gate from either**
  (the `CC_0372` lesson), and expect the composition to be stated by county, which Nebraska has
  93 of and production holds.
- **New Hampshire — NHGRANIT, the statewide GIS clearinghouse at UNH:**
  `https://nhgeodata.unh.edu/hosting/rest/services/Hosted/APB_ElectoralDistricts/FeatureServer/7`
  — "New Hampshire Executive Council District Boundaries - 2022".
  🔴 **The same service also publishes a 2012 version. Take the 2022 one**, and confirm no later
  plan exists: this is the "pick the plan still open" step, and here the two vintages sit side by
  side with nothing but the year in the title to tell them apart.
  ⚠ The councillor districts are defined by statute as lists of **towns and wards**, so the
  statute gate wants county subdivisions (`G4040`) — which production holds for only 11 states,
  New Hampshire not among them. Expect to anchor on **whole counties** instead: New Hampshire has
  10 and production holds them, and the five districts are large enough that several counties
  should fall wholly inside one.

# CC_0373–CC_0375 — Nebraska's three boards, and a composition with no statute behind it

21 seats in one state: the **Public Service Commission** (5), the **State Board of Education**
(8) and the **University of Nebraska Board of Regents** (8). All created whole, all seated,
eight 2026 results recorded. Baseline unchanged at 293 / 55 / 238; reachability unchanged.

## 🔴🔴 THE STATUTE GATE DOES NOT EXIST HERE, AND THAT IS THE WHOLE STORY

Alabama, Louisiana and New Mexico each define their board districts in statute as **lists of
counties or parishes**, and the loaders gated the geometry on that text. Nebraska does not.
LB 5, LB 7 and LB 8 of the 2021 First Special Session each "set the boundaries … **by the
adoption of maps by reference**", and `75-101.01`, `79-311` and `85-103.01` name no county at
all. The law is a set of map sheets filed with the Clerk of the Legislature, published only as
**raster PDFs with no text layer**.

▶ **So the composition came from the Secretary of State's certified canvass books.** A county
that cast votes in District 7's race is in District 7; a county split between two districts
casts votes in both. That is evidence from outside the map in the strongest sense available —
the election was administered on these boundaries by 93 county election officials and the
result was certified by the Board of State Canvassers.

Three canvasses cover all 21 districts, and the statute predicts exactly which:

| canvass | PSC | Board of Education | Regents |
| --- | --- | --- | --- |
| 2022 general | 4, 5 | 5, 6, 7, 8 | 6, 7 |
| 2024 general | 1, 3 | 1, 2, 3, 4 | 3, 4, 5, 8 |
| 2026 primary | 2 | 5, 6, 7, 8 | 1, 2, 4 |

🟢 **Five districts are read twice, from books four years apart, and the two readings must
agree.** They do. A parser that mis-assigns a column cannot produce the same wrong answer twice
from two differently laid out books.

🟢 **And the Regents' own website states the splits independently** — "District 1 & 5 Lancaster
County; District 2 and 5 Sarpy County; District 2, 4 & 8 Douglas County" — which is exactly
what the canvass gave. Three sources, one answer.

## 🔴🔴 THE SECTION IS BOUNDED BY THE BOOK'S OWN TABLE OF CONTENTS, NOT BY A LIST OF HEADINGS

The first version of the parser closed a body's section when it met a heading from a
hand-written blacklist. **A heading that is not on the list does not close anything** — it
silently keeps the section open and feeds another office's districts into this one. That is not
hypothetical: the 2024 book puts "Judge of the District Court", "District 3", "Lancaster" a few
pages after the Board of Regents, and a blacklist that had not thought of judges would have
recorded Lancaster as part of Regents District 3. **The number would have looked perfectly
plausible.** The parser now takes its page range and its stop heading from the book's own TOC,
so a heading nobody anticipated is outside the pages being read at all.

▶ **General form: when you must stop at "something else", take the boundary from the document's
own structure, not from your list of what else there might be.**

## 🔴🔴 THE FILE CALLED `reg_lb8_final.pdf` IS NOT THE ENACTED REGENTS PLAN

The second anchor is the **enacted plan's own population table** — the Legislative Research
Office prints a population and a deviation on each district's map sheet. Reading all 21 off the
sheets and checking them against the GIS attribute found a real disagreement on the Regents:

| district | `reg_lb8_final.pdf` | `reg_lb8_am41.pdf` | gis.ne.gov |
| --- | --- | --- | --- |
| 1 | 242,357 | **248,649** | 248,649 |
| 4 | 234,292 | **237,525** | 237,525 |
| 5 | 254,335 | **248,043** | 248,043 |
| 8 | 248,467 | **245,234** | 245,234 |

The "final" bundle was assembled on **2021-09-30**, after LB 8 passed — but its sheets carry the
date the GIS drew them, **2021-09-25**. The Legislature's own bill history for LB 8 reads
*"Sep 28, 2021 · Linehan · AM41 · adopted"* and *"Sep 30, 2021 · Passed on Final Reading with
Emergency Clause 46-2-1"*. **The sheets in the file named "final" predate the amendment that
passed.** `reg_lb8_am41.pdf` carries the enacted figures and the state's own GIS agrees with it
on all eight.

🔴 **And the statute cannot tell the two apart either.** LB 8 adopts the plan by the map NAME —
`REG21-39003-1` … `-8` — and AM41 did not change the name. Citing the map identifier proves
nothing about which version you have.

▶ **Read the date inside the map frame, not the file name, and check the bill history.** A sheet
titled "Final Reading" can be older than the amendment that was adopted.

## 🔴🔴 TWO BODIES SHARE ONE MTFCC IN ONE STATE — NEW, AND IT BREAKS THE USUAL QUERY

Louisiana's Public Service Commission and Colorado's Regents both live under `X-ST-BOARD`, but
in different states, so a query keyed on `(mtfcc, state)` could not mix them. Nebraska puts the
**Public Service Commission AND the Board of Regents** under `X-ST-BOARD` in state `31`.

Every geofence query in the loader and every pre-gate in the migrations is therefore scoped by
the **geo_id prefix** as well. Two controls prove it is load-bearing:
- a copy of the loader with the scoping removed from its row-count query reports **13 rows where
  8 are expected**, once the Commission is loaded;
- a copy of `CC_0375` with the scoping removed from its "does this body already exist" pre-gate
  refuses to run after `CC_0373`, naming the Commission's five districts.

⚠ The Board of Education is `X0003` / `STATE_BOARD_EDUCATION` and is unaffected. Nebraska is now
the first state in production holding two distinct bodies on one custom layer.

## 🔴 THE ZCTA GATE ASKED THE WRONG QUESTION FIRST

Three of the 586 Nebraska ZCTAs straddle a state line and `ST_PointOnSurface` lands on the far
side: **68327** points into Kansas below the 40th parallel, **69212** into South Dakota above the
43rd, and **68110** into **Carter Lake, Iowa** — the enclave the Missouri River left on the
Nebraska bank when it moved in 1877. Two read as holes in the district map and the third as a
district reaching outside the state. None of that is a fact about this map.

The fix is not an exclusion list. **The point is taken from the part of the ZCTA that is in
Nebraska**, so every ZCTA has a representative point genuinely inside the state, all 586 resolve
to exactly one district, and there is nothing to go stale.

## 🔴 THE THRESHOLDS, MEASURED HERE

| quantity | measured | threshold |
| --- | --- | --- |
| smallest TRUE split share | **1.876912%** (Burt County in Education 6) | `SHARE_FLOOR` 0.1% |
| largest FALSE share (a county grazing a district) | **0.006454%** | — |
| worst whole-county containment | **99.9932%** (Merrick in Education 6) | `WHOLE_FLOOR` 99.9% |
| worst leak out of a whole county | 0.006454% | `LEAK_CEILING` 0.01% |
| union coverage of the TIGER outline | **99.9019%** geodesic | 99.5% |
| worst pairwise overlap | **0%** | 0.001% |

⚠ **Coverage is 99.9019%, not the 99.9966% the planar measurement gave.** Those are two
different questions — a ratio of planar degree-areas against an `ST_Difference` in square metres
on the spheroid — and only one of them is the gate. **A threshold copied from a measurement made
another way is not a measured threshold.**

## 🟢 BURT AND CUMING ARE REALLY SPLIT, AND THE CANVASS SAID SO FIRST

The 2022 book records exactly **one vote** for each Board of Education District 6 candidate in
Burt County. That reads like a stray ballot filed under the wrong county, and the obvious move
is to drop it. It is real: Burt is **98.12%** in District 3 and **1.88%** in District 6, and
Cuming is **87.71% / 12.29%**. ▶ **A two-ballot county entry turned out to be a boundary.
Measure before dismissing.**

## 🔴 EIGHT SEATS WERE ON THE BALLOT, NOT FIVE

The inventory this programme carried said *NE PSC (1), NE State Board of Education (3), NE
Regents (1)*. The statute says otherwise, and so does the state. `32-509`, `32-510` and `32-511`
set the stagger **by district number**, and they predict exactly which districts appear in which
canvass — which is itself a third confirmation of the coverage table above. Counting from the
source's own list found **three more races** than the inventory had. This is the
"a tier looks finished when the races don't exist" rule in its other direction.

⚠ **Regents District 4 is a special election**, for the unexpired remainder of the term
Elizabeth O'Connor won in 2024 and resigned in January 2026 after being charged over a crash
that seriously injured a woman; Governor Pillen appointed Joel Makovicka on 2026-02-03 to serve
through 2027-01-07. **The only machine-readable sign of it** is that the Secretary of State's
contest heading carries no "Six Year Term" label.

## 🟢 THE TERM START IS DERIVED, THEN CHECKED TWICE

Neb. Const. Art. XVII-5: terms begin **on the first Thursday after the first Tuesday in January
next succeeding the election**. January 2027: first Tuesday the 5th, so **Thursday 7 January
2027**. The rule reproduces the date the Secretary of State printed for the previous cycle —
the 2024 canvass book gives "Term Start: January 9, 2025" — and the Governor's office used the
same date independently for Makovicka's appointment.

🔴 **No term start is invented for a sitting member.** The rosters publish when a member was
FIRST elected, which is a different fact, so every term written is open-ended with
`start_precision 'unknown'`.

## 🟢 AND THE BODY STILL EXISTS

`LR278CA` (2024) proposed a constitutional amendment cutting the State Board of Education to
**seven** members from the terms commencing in 2027, two of them appointed by the Governor. Its
history reads *"Apr 18, 2024 · Indefinitely postponed"*. It never reached a ballot and the board
remains eight elected members. ▶ The New Mexico habit of checking whether the body survives is
now a standing step, and it paid again.

## 🔴 A CONTROL THAT FAILS IS NOT THE SAME AS A CONTROL THAT FAILS WHERE YOU AIMED IT

The ballot/race control set one seat to "not on the ballot, race recorded" and the run stopped
at **"expected 1 seats on the ballot, found 0"** — an earlier gate. The gate under test was
never reached, so the control proved nothing about it. Moving the ballot flag to another
district at the same time keeps both counts right and lets the disagreement gate fire. Same
lesson as `CC_0370` control E, in a different file.

## ⚠ WHAT IS STILL OPEN, STATED RATHER THAN HIDDEN

Thirteen of the 21 districts have a whole-county anchor. Of the eight that do not, **six are
still pinned** because their county SET is unique — PSC 2 is the only Commission district whose
counties are exactly {Douglas}; Education 1 and Regents 1 are the only ones that are {Lancaster};
Regents 2 is the only {Douglas, Sarpy}.

🔴 **Exactly two pairs are not pinned by county: Education 4 with Education 8, and Regents 4
with Regents 8.** Each pair's county set is {Douglas} for both, so the canvass cannot separate
them. Only the enacted plan's population can — Education 4 holds 245,713 and Education 8 holds
246,703; Regents 4 holds 237,525 and Regents 8 holds 245,234 — and that separates a source that
has **mislabelled** two districts, because geometry and attributes move together. It does not
separate a geometry-only swap made inside our own pipeline, and loader control H plants exactly
that and is observed to **pass**.

⚠ What bounds the exposure: the fetcher asks the service for one district at a time and takes
that feature's geometry and population from the same response, so a number and a shape cannot
drift apart by accident. The swap has to be made deliberately in the intermediate file.

## Measured on the live endpoint

`https://ev-accounts-api.onrender.com/api/essentials/address-search`, against live production,
with no deploy — `X0003` is already in the deployed read path:

| address | returned |
| --- | --- |
| 1819 Farnam St, Omaha, NE | **State Board of Education District 4 — Liz Renner**, `held` |
| 1228 L St, Lincoln, NE | **State Board of Education District 1 — Kristin Christensen**, `held` |
| 1721 Broadway, Scottsbluff, NE | **State Board of Education District 7 — Elizabeth Tegtmeier**, `held` |
| 307 N Dewey St, North Platte, NE | **State Board of Education District 7 — Elizabeth Tegtmeier**, `held` |

⚠ **The Commission and the Regents do not answer an address yet**, for the same reason
Louisiana's commission does not: `(X-ST-BOARD, STATE_BOARD)` is added by `CC_0366` on this
branch and is not deployed. The chain resolves in the database — each migration's point-to-member
gate walks it for every anchored district — and the seats appear the moment the branch ships.

## ▶ Dated follow-ups

**2027-01-07** — the winners take office. Seat **Wendy DeBoer** (PSC 2), **Angie Eberspacher**
(Education 5), **Lou Ann Goding** (Education 8), **Brent Comstock** (Regents 1), **Elizabeth
Butler** (Regents 2) and **Justin Solomon** (Regents 4). Sherry Jones (Education 6) and
Elizabeth Tegtmeier (Education 7) were re-elected and stay.

⚠ Education District 8 was the closest of the eight at **1,517 votes (50.92% / 49.08%)**.
Nebraska's automatic recount threshold is one percent of the leading candidate's votes
(`32-1119`), which is 418 here, so no recount is triggered — but the Board of State Canvassers
does not certify the general until early December, and these results are recorded as `called`,
not certified.
