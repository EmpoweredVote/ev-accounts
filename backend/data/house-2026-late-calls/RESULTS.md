# The five House races AP called after `CC_0350`

Applied to production **2026-11-16** as **`CC_0447`**.

`CC_0350` recorded AP's House calls as they stood on 2026-11-04. AP kept calling. Measured
2026-11-17 03:00Z against AP's live feed: **AP had called 427 races, this database held 422.**

| district | winner | party | % | called | note |
| --- | --- | --- | --- | --- | --- |
| CA-04 | Eric Jones | Dem | 52.53 | 2026-11-14 01:25Z | beat incumbent Mike Thompson |
| CA-23 | Jay Obernolte | GOP | 50.83 | 2026-11-17 01:29Z | incumbent re-elected |
| CO-04 | Eileen Laubacher | Dem | 48.80 | 2026-11-13 19:53Z | beat incumbent Lauren Boebert |
| ME-02 | Paul LePage | GOP | 49.89 | 2026-11-12 18:31Z | **ranked choice**, beat Matthew Dunlap |
| NC-07 | David Rouzer | GOP | 49.87 | 2026-11-16 20:54Z | incumbent re-elected |

All five are `called`, never `certified` — AP reports `isCertified: false` for every one.

---

## 🔴 NOTHING WE RUN MEASURES THE GAP BETWEEN THE WIRE AND OUR ROWS

The transition tracker counts a race as recorded from **our own winner column**, so a page
refresh looks clean no matter how far behind AP we are. These five were found only by reading
AP's feed beside our uncalled list — a deliberate comparison, not a gate.

▶ **Check the wire against the file.** A file checked against itself always agrees.

The tracker's House note now says plainly that it shows our rows rather than the wire and can
lag by days.

## 🔴 A SUBSTRING TEST ASKS "IS THIS NAME ANYWHERE", WHICH IS NOT THE QUESTION

The gate originally asserted that each written row's `result_source` **contained** that row's
`full_name` — meant to stop a pin being repointed onto the wrong person in the same race.
**Control A passed against it**, and the control was right.

Every citation here also names the defeated incumbent (*"defeating incumbent Mike Thompson"*).
Repoint CA-04's pin consistently onto Thompson — `rc_id`, `full_name` and `last_name` all moved
— and the row's own name is still somewhere in the text, so the test was satisfied **by the
loser's name**. The pin agreed with itself, and assertion 3, which compares the winner against
the pin's own declared name, could never see it either.

The citations now carry an explicit **`WINNER=<name>;`** token and the gate tests that position.
Control A then fires: `1 row(s) carry a result_source that does not name the candidate it is
attached to: Mike Thompson`.

▶ **Name the field you mean.** This is the `CC_0445` lesson in another costume: a gate that
checks a vocabulary is not checking a pairing.

## 🔴 ME-02'S PERCENTAGE IS A FIRST-CHOICE SHARE, AND 49.89% BESIDE "won" READS LIKE AN ERROR

LePage's 49.89% is his share of **all 341,256 ballots cast, 6,021 of them blank**. Nobody
cleared 50% on first choices, so Maine ran its ranked-choice tabulation; AP's final round gives
**LePage 170,890 to Dunlap 165,432**. The citation records both, because the first-choice
figure alone invites someone to "fix" it later.

⚠ Excluding the blanks, LePage's first-choice share is 50.79% — over the line. **Which
denominator you use decides whether there were rounds at all.**

🔴 **THE SAME QUESTION IS LIVE AND UNRESOLVED IN ALASKA.** Its Senate race is still
`Too Early to Call`: Peltola has 49.98% of all 283,377 first-choice votes (**52 short** of a
majority) but 50.14% once the **874 aggregate write-ins** come out of the denominator
(**385 over**). Press reports of "50.1%" are that second number. State ranked-choice tabulation
starts **2026-11-18**, target certification **2026-11-25**, per the Division of Elections'
own site. **Do not record a winner off a published percentage.**

## 🟢 The twin-brother check passes here, and it was run

`CC_0350` withheld TX-22 because AP's winner (Trever Nehls, id 170023) shared a surname with the
incumbent (Troy Nehls, id 68186) and was a **different person**. Two of these five share a
surname with the incumbent — CA-23 Obernolte and NC-07 Rouzer — and in both, **AP's winner
`candidateID` equals AP's incumbent `candidateID`**. They are the sitting members re-elected.

▶ **Check the id, never the surname.** The detector is "surname matches AND id differs"; it
returns zero across these five.

## What this deliberately does not do

- **It records no losers.** A loser is recorded because AP's own ballot names them, never
  because they are not the winner (`CC_0351`; SC still carries Lindsey Graham, who died before
  the election and was not on the ballot). The other **8 rows in these five races stay NULL**,
  and assertion 8 fails if any of them gains a result.
  ⚠ CO-04's Luis Galvan carries `candidate_status = 'filed'`, not `active` — whether he reached
  the general ballot is an open question, and `lost` would be an unevidenced claim about a live
  candidacy. That is the shape of the work a losers pass owes.
- **It seats nobody.** These winners take office 2027-01-03 under US Const. amend. XX § 1, and
  assertion 9 fails if a term starts on that date against these offices.

## Still open on the House after this

AP has **8** races uncalled: **AK at-large** (awaiting ranked-choice results), **LA-05** and
**LA-06** (both `Runoff`), and **MN-01, NC-03, NC-05, NC-10, TN-04** (all too close).

🔴 **Louisiana's November contest is a nonpartisan primary, not a general.** Where nobody clears
50% the top two go to a December runoff, so the seat has **no winner at all** and the whole
November field still stands — 12 candidates in LA-05, 6 in LA-06. `lost` is wrong for every one
of them until the runoff resolves.

## Controls — six tampers, each watched going red

The builder (`mktamper.py`) compares the post-verify block byte-for-byte with the original and
refuses if a tamper edited the detector, refuses an unchanged file, and refuses anything under
8 KB — an empty migration passes every gate it does not contain.

| control | what it changes | result |
| --- | --- | --- |
| A | CA-04's pin repointed **consistently** onto the defeated incumbent | ✅ `1 row(s) carry a result_source that does not name the candidate it is attached to: Mike Thompson` — **only after the gate was fixed; see above** |
| B | CA-04's pin claims district 0605 | ✅ `4 of 5 pins resolved … Unresolved: 0605` |
| C | the UPDATE keys on the race, not the pinned row | ✅ `5 of the five races resolved more than one winner` |
| D | the rows claim `certified` | ✅ `only 0 of 5 rows cite their own AP race id with certainty called…` |
| E | ME-02 cites a TV broadcast instead of AP | ✅ `only 4 of 5 rows cite their own AP race id…` |
| F | a sixth row outside the five gets the marker | ✅ `6 row(s) repo-wide carry this migration's marker, expected exactly 5` |

⚠ **Control D fires on assertion 4, not assertion 5.** Assertion 4 requires `called` as part of
the same test, so it reaches the defect first and **assertion 5 is shadowed** — it has never been
watched failing. Recorded rather than papered over: an earlier gate catching the fault is not
evidence that the later one works.
