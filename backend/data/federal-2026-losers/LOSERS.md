# 2026-11-03 US Senate and US House — the losers pass

**Status as of 2026-11-04: 599 candidate rows recorded as `lost` (`CC_0351`) — 76 Senate, 523 House.**
Each carries `result_certainty = 'called'`. Nothing is certified. Nothing is seated.

This is the pass that `CC_0339` (Senate winners) and `CC_0350` (House winners) each deferred,
and both deferred it for the same reason, written down here as the rule it became.

## 🔴 The rule: a loser is recorded because AP's ballot names them

> "Everyone in a called race who is not the winner lost" is the inference both winners passes
> refused.

Our `race_candidates` still carries **Lindsey Graham**, who died in office on 2026-07-11 and was
not on the November ballot. AP's own South Carolina list has four candidates and he is not among
them. A blanket rule would have recorded that a dead man lost an election he was not in.

So every row here was matched, one at a time, against **AP's own candidate list for that race**.
A row of ours that AP does not list is left exactly as it was.

### 🟢 South Carolina is now the worked proof rather than the warning

| Our row | AP's SC ballot | What was written |
|---|---|---|
| Darline Graham | listed, 46.65% | `lost` |
| Lindsey Graham | **not listed** | nothing — row untouched |

Two candidates, one surname, one race, opposite outcomes. `CC_0351`'s gate re-asserts that
Lindsey Graham's row is still NULL after the migration runs.

### 🔴 And the exclusion was proved to be *caused by* AP's ballot, not by luck

A control added Lindsey Graham to AP's SC list and re-ran the matcher. He was recorded as a
loser and the count went 599 → 600. Removing the tamper drops him again. **A control that has
only ever passed proves nothing** — this one was watched failing first.

| Control | Expected | Observed |
|---|---|---|
| Lindsey Graham added to AP's SC ballot | he becomes a loser | 600 losers, his row among them |
| An AL-01 loser renamed to an unmatchable string | matcher drops it | 598 losers, row moved to the gaps bucket |
| One pinned `rc_id` broken in the migration | resolve gate raises | `598 row(s) resolved, expected 599` |
| Lindsey Graham's `rc_id` added to the migration | named guard raises | `Lindsey Graham now carries result lost` |
| A loser pinned in a race AP has not called | orphan-race gate raises | `2 race(s) carry a loser with no winner` |
| The prior-citation append removed | citation gate raises | `104 row(s) lost the ballot-qualification citation` |

Each tamper was asserted present in its file before the run, because a tamper that did not apply
is a control that proved nothing.

## 🔴 TX-22 gets a loser while its winner is still withheld

`CC_0350` withheld the TX-22 winner because AP's winner (Trever Nehls) is not a person this
database holds — our row is his twin brother Troy Nehls, the retiring incumbent.

**Marquette Greene-Scott is a different question.** AP's TX-22 ballot lists her, she took 48.18%,
and she lost. That fact does not depend on the Nehls confusion, so it is recorded. Withholding a
loss we can prove, in order to keep the race tidy, would be a silence rather than a precaution.

TX-22 is therefore the **only** race in the programme with a recorded loser and no recorded
winner. A gate asserts it is the only one, so the anomaly is visible rather than incidental, and
Troy Nehls' own row stays NULL under its own named guard.

## The one distinction a regex gets wrong

AP's ballots carry two kinds of "write-in" and only one is a person:

| Kind | n | `first` | `last` | Treated as |
|---|---|---|---|---|
| Aggregate | 71 | `null` | exactly `"Total Write-ins"` | **not a person** — excluded from matching and from the gap count |
| Named write-in | 11 | a real first name | e.g. `"Parkman (write-in)"` | **a person** — matched like any other, suffix stripped |

A predicate on the words "write in" merges the two. The discriminator is the exact string.

## What makes the match safe at this size

- **Zero AP ballots contain two candidates with the same surname**, measured across all 411
  called races — so no AP candidate can match two of our rows.
- **Three of our own races do**: FL-11 (Daniel / Royal Webster), MI-11 (Ethan / Stu Baker) and
  SC (Darline / Lindsey Graham). All three resolved on the first name with no ambiguity, and in
  each case the right row was taken and the other left alone.
- **No row written here was previously `won`, `not_nominated` or `withdrew`.** That last is worth
  stating: not one person AP lists on a general-election ballot is recorded by us as having
  failed to be nominated. It is a real consistency check on both datasets at once.
- Every row is **pinned by `race_candidates.id`**, and the gate re-asserts that the pin sits in
  the stated race and carries the stated surname.

### The 94 rows where AP's spelling and ours differ

Read by hand. The other 505 agree on first and last name after folding. Two needed confirming
from outside AP, because neither first name is derivable from the other — and both are one
person:

- **NV-01** AP "Afzal Khan" / ours "Bobby Khan" → **Afzal "Bobby" Khan**
  ([Ballotpedia](https://ballotpedia.org/United_States_House_of_Representatives_elections_in_Nevada,_2026))
- **VA-02** AP "Geral Staten" / ours "Bishop Staten" → **Geral "Bishop" Staten**
  ([VPM candidate survey](https://www.vpm.org/elections/2026-09-24/va02-baker-kiggans-luria-staten-candidate-survey/))

| Seat | AP | Ours |
|---|---|---|
| AZ-09 | G. Hatch (write-in) | G. Seville Hatch |
| CA-16 | Peter Soulé | Peter Sundin Soulé |
| CA-38 | Pedro Casas | Pedro Antonio Casas |
| CA-51 | Ricardo Cabrera | Richardo Cabrera |
| CO-06 | Samir Witta | Samir Ezzeldin Witta |
| CO-07 | Lawrence Clark | Lawrence Kyle Clark |
| CT-01 | Mary Sanders | Mary L. Sanders |
| FL-04 | LaShonda Holloway | LaShonda L.J. Holloway |
| FL-24 | Te Brown | Mayonna Te Brown |
| GA-07 | Tony Kozycki | Anthony Kozycki |
| IA-03 | Zach Nunn | Zachary Nunn |
| ID-02 | Ellie Gilbreath | Elinor Gilbreath |
| IL-02 | Michael Noack | Mike Noack |
| IN-09 | Brad Meyer | Bradley Meyer |
| KY-02 | Thomas Loecken | Thomas A. Loecken |
| KY-03 | Maria Rodriguez | Maria Teresa Rodriguez |
| KY-04 | Melissa Strange | Melissa Claire Strange |
| KY-06 | Jay Bowman | Jay J Bowman |
| MA-03 | Gary Grossi | Gary J. Grossi |
| MA-06 | Micah Jones | Micah Quinney Jones |
| MA-08 | Robert Burke | Robert Gerald Burke |
| MA-09 | R. Macallister | R. Tyler MacAllister |
| MI-05 | Jim Bronke | James Bronke |
| MI-08 | Thomas Smith | Thomas J. Smith |
| MI-12 | James Hooper | James D. Hooper |
| MN-05 | DeVelle Jackson | DeVelle L. Jackson |
| MO-02 | Brandon Daugherty | Brandon Coulter Daugherty |
| MO-08 | Chris Reichard | Christopher Reichard |
| NC-02 | Eugene Douglass | Gene Douglass |
| NC-02 | Matthew Laszacs | Matt Laszacs |
| NC-04 | Mahesh Ganorkar | Max Ganorkar |
| NJ-03 | Ryan Kelly | Ryan Michael Kelly |
| NJ-07 | Thomas Kean | Thomas H. Kean, Jr. |
| NM-01 | Ndidiamaka Okpareke | Didi Okpareke |
| NM-02 | Gregory Cunningham | Greg Cunningham |
| NV-01 | Carrie Buck | Carrie Ann Buck |
| NV-01 | Afzal Khan | Bobby Khan |
| NY-03 | Michael LiPetri | Mike LiPetri |
| NY-09 | Joel Azumah | Joel Anabilah-Azumah |
| NY-11 | Mike DeCillis | Michael DeCillis |
| NY-13 | Jomo Williams | Jomo M. Williams |
| NY-18 | Jackie Auringer | Jacqueline Auringer |
| OH-02 | Jen Mazzuckelli | Jennifer Mazzuckelli |
| OH-07 | Max Miller | Max L. Miller |
| OK-05 | Robert Henri | Robert P. Henri |
| PA-01 | Brian Fitzpatrick | Brian K. Fitzpatrick |
| PA-05 | Nick Manganaro | Nicholas Manganaro |
| PA-08 | Rob Bresnahan | Robert P. Bresnahan, Jr. |
| PA-14 | Alan Bradstock | David Alan Bradstock |
| SD-00 | Nicole Gronli | Nikki Gronli |
| TN-01 | Joshua Ashburn | Joshua Ray Ashburn |
| TN-01 | Richard Baker | Richard G. Baker |
| TN-01 | Tyler McClain | Tyler Brice Mitchell McClain |
| TN-03 | Rodney King | Rodney Joe King |
| TN-03 | Donnie Ownby | Donnie Lynn Ownby |
| TN-03 | Edward Roland | Edward John Roland |
| TN-05 | James Johnson | James A. Johnson |
| TN-05 | Micheál O'Leary | Micheál (Me-Haul) O'Leary |
| TN-06 | Christopher Monday | Christopher B. Monday |
| TN-08 | Pamela Moses | Pamela Jeanine "P." Moses |
| TN-08 | Adam Austill | Adam D. Austill |
| TN-08 | Henry Ward | Henry J. Ward, III |
| UT-01 | Elias Montgomery | Elias Henry Montgomery |
| UT-03 | Michael Stoddard | Michael R. Stoddard |
| VA-02 | Geral Staten | Bishop Staten |
| VA-04 | Robert Murray | Robert P. "Family Man" Murray, Jr. |
| VA-04 | Joan Bell | Joan E. "Andrews" Bell |
| VA-07 | Taner Lopez | Taner E. Demirci Lopez |
| VA-07 | Joshua Ertle | Joshua E. Ertle |
| VT-00 | Ryan Walton | Ryan P. Walton |
| VT-00 | Phoenix Altair | Phoenix K. Altair |
| WA-02 | Edwin Feller | Edwin H. Feller |
| WA-10 | Chris Chung | Chris D. Chung |
| WI-03 | Alexander Kent | Alexander Valiensi Kent |
| WI-06 | Mike Thurow | Michael Thurow |
| WY-00 | Jeffrey Haggit | Jeffrey A. Haggit |
| Senate CO | Bob Chew | Robert Chew |
| Senate FL | Neil Gillespie | Neil J. Gillespie |
| Senate ID | Natalie Fleming | Natalie M Fleming |
| Senate KS | David Graham | David C. Graham |
| Senate ME | Susan Collins | Susan M. Collins |
| Senate MI | Douglas Marsh | Douglas P. Marsh |
| Senate MI | Walter Kristy | Walter P. Kristy |
| Senate NC | Shannon Bray | Shannon W. Bray |
| Senate NM | Larry Marker | Larry E. Marker |
| Senate OH | William Redpath | William B. Redpath |
| Senate OR | David Smith | David Brock Smith |
| Senate SD | Brian Bengs | Brian L Bengs |
| Senate TN | Catherine Whitson | Catherine Barcel Whitson |
| Senate TN | Jeremy Hearn | Jeremy Dean Hearn |
| Senate TN | Yoshi Matthews | Yoshi D. Matthews |
| Senate TN | James Macon | James William Macon III |
| Senate WV | Rachel Anderson | Rachel Fetty Anderson |
| Senate WV | S. Wilson | S. Marshall Wilson |

## 🔴 8 of our ballot rows share a surname with an incumbent AP's ballot does not list

Left untouched. This is the stale-field signature, and it is a seeding problem, not a results
problem.

| Seat | AP's incumbent | Our ballot row | Its result |
|---|---|---|---|
| CT-01 | John Larson | John B. Larson | not_nominated |
| FL-11 | Daniel Webster | Daniel Webster | — |
| FL-11 | Daniel Webster | Royal Webster | — |
| FL-20 | Sheila Cherfilus-McCormick | Sheila Cherfilus-McCormick | — |
| MI-13 | Shri Thanedar | Shri Thanedar | — |
| NC-11 | Chuck Edwards | Chuck Edwards | — |
| TN-05 | Andy Ogles | Andrew Ogles | not_nominated |
| SC | Darline Graham | Lindsey Graham | — |

⚠ **The detector matches on surname, so read the rows rather than the count.** FL-11's "Royal
Webster" is a different person who shares Daniel Webster's surname and is here only because of
that. Two more are already `not_nominated` and are therefore correct. What is left is rows
saying a sitting member is on a ballot AP says they are not on.
▶ Read each against the state's own candidate list before the next pass.

## What is not written, and why

### 106 candidates AP lists that we do not hold

We cannot mark a loss against a row that does not exist. Mostly minor parties and named
write-ins (Grn 18 · Oth 17 · Lib 16 · Ind 14 · WCP 7 · GOP 6 · UST 6 · NPA 5 · Dem 4 · Unr 2 · AFi 2 · NWk 2 · NLP 1 · NP 1 · Con 1 · PAG 1 · CST 1 · Una 1 · Prg 1). 10 took over 5% and are real contenders missing from our field:

| Seat | Candidate | Party | Share | Votes |
|---|---|---|---|---|
| NC-11 | Jennifer Balkcom | GOP | 41.3% | 141,427 |
| LA-01 | Lauren Jewett | Dem | 33.95% | 89,428 |
| VA-11 | Arthur Purves | GOP | 24.38% | 81,357 |
| GA-04 | Jim Duffie | GOP | 17.36% | 45,619 |
| LA-02 | Peter Williams | GOP | 15.12% | 36,367 |
| NY-15 | Andre Easton | Oth | 8.71% | 10,647 |
| MT-02 | Michael Eisenhauer | Ind | 7.8% | 17,003 |
| LA-03 | Priscilla Gonzalez | Dem | 7.16% | 16,828 |
| LA-03 | Kate Cotten | GOP | 6.66% | 15,661 |
| PA-03 | Dennis Mahoney | Ind | 6.41% | 17,298 |

### 406 of our rows in called races that AP's ballot does not list

Untouched.

| Their current result | n | Reading |
|---|---|---|
| `not_nominated` | 190 | Primary losers, correctly absent from a general ballot. The strongest evidence this match does what it claims. |
| none | 215 | Either unflagged primary losers or minor general candidates AP omits — **AP cannot tell those apart**. Separating them needs the state's own ballot. |
| `withdrew` | 1 | Left as it is. |

## 🔴 104 rows had a value overwritten

104 of the 599 losers already carried `result = 'advanced'` with `result_certainty = NULL`, each
sourced to a state candidate list proving ballot qualification. There is no history table, so an
`UPDATE` is final.

    OLD VALUE, ALL 104 ROWS:  result = 'advanced',  result_certainty = NULL
    NEW VALUE:                  result = 'lost',      result_certainty = 'called'

As in `CC_0350`, the old citation is not discarded: the AP call is written and the previous
source appended verbatim in the same column. A gate fails if any row lost it, and the tamper
above proved that gate can fail. The before-values are in `before-values.json` beside this file.

## What is left

| Item | Shape |
|---|---|
| 59 uncalled races | 2 Senate (AK ranked choice, MS) and 57 House. No winner, so no losers either. |
| LA-05 | A Louisiana nonpartisan general that went to a runoff. Its candidates are neither winners nor losers yet. |
| TX-22 | Seed Trever Nehls, correct Troy Nehls' row, then record the winner. |
| 10 missing contenders | Seed them, then their losses can be recorded. |
| The 215 unresolved rows | Need each state's own ballot to tell a primary loser from a minor candidate AP omits. |
| `certified` | A later pass, per state, against that state's own canvass. |

## Files beside this one

| File | What it is |
|---|---|
| `ap-ballots-2026-11-04.json` | AP's **full** candidate list for all 470 federal races — every candidate, not just the winner. |
| `losers-2026-11-04.json` | The 599 matches, with both spellings, the tier, and the prior result. |
| `spelling-review-2026-11-04.json` | The 94 rows where the spellings differ — the review set. |
| `seeding-gaps-2026-11-04.json` | The 106 AP candidates we hold no row for. |
| `our-rows-ap-omits-2026-11-04.json` | The 406 rows of ours AP's ballots do not list. |
| `incumbent-not-on-ballot.json` | The 8 stale-field cases. |
| `before-values.json` | The 104 rows' values before `CC_0351` ran. |
| `match-losers.mjs` | The matcher, so the match can be re-derived and re-tampered. |
