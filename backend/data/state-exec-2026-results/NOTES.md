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
