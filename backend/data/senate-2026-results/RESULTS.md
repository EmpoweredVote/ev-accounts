# 2026-11-03 US Senate — results research

**Status as of 2026-11-04: 33 of 35 races recorded as `called` (`CC_0339`, applied).**
Alaska and Mississippi are uncalled and correctly have no row. Nothing is `certified` — not one
of the 35 races is certified in AP's own metadata, and the state canvasses run for weeks.

> ## 🔴 This file was wrong for a day, and the rule below is why
>
> It said *"a media call is not a state return … those calls are leads for where to look; they
> are not what gets written here"*, and so recorded nothing while every wire in the country
> carried the results.
>
> **That misreads the operator's ruling**, which is: *"AP for called races, then state SoS to
> confirm certified — we should label each so we know what's been called and what's been
> certified."*
>
> `result_certainty` exists **because** a call and a canvass are different things. Refusing to
> record a call until the state certifies throws away the very distinction the column was added
> to carry, and leaves the site showing 35 departing senators as though nothing had happened.
>
> The repo rule it borrowed — *"the chamber's own roster outranks every aggregator"* — is about
> **officeholder rosters**, not election night. A roster is a claim about who holds a seat today,
> where the body itself is the authority. A race call is a claim about who won, where AP is a
> competent source the operator named. ▶ **Check which question a rule answers before applying
> it to a different one.**

This file is the reviewed artifact. `results.json` is generated to match it, and the seating
migration is generated from `results.json`. Nothing is seated that is not written down here
first, with a source that NAMES the person.

## The rules this file is held to

Each one is in CLAUDE.md because a real seat was got wrong without it.

- 🔴 **A CERTIFIED RESULT IS NOT A FACT ABOUT WHO HOLDS THE SEAT.** It records who won an
  election. Taking office is a separate, later event. These winners are seated with
  `term_start = 2027-01-03`, which is the day they take office, not the day they won.
- 🔴 **A CALL AND A CANVASS ARE TWO FACTS, AND EACH GETS ITS OWN LABEL.** AP's race call is
  what `result_certainty = 'called'` records; the state's own canvass is what upgrades it to
  `'certified'`. The state return outranks the call **when they disagree about the certified
  result** — it does not mean a call is unrecordable. On 2026-11-04 outlets disagreed on the
  spelling of the Kansas winner's name and Mississippi stood at 48.95% / 48.94%; Mississippi is
  still uncalled and therefore still has no row.
- 🔴 **SOURCE THE CALL FROM AP'S OWN DATA, NOT FROM A HEADLINE OR A SEARCH SUMMARY.** The calls
  here come from `interactives.apelections.org/election-results/data-live/2026-11-03/`, AP's own
  feed, read with a browser: `metadata.json` for the race and its `raceCallStatus`/`isCertified`,
  `progress.json` for the candidate carrying `winner: "X"` and its `calledAt`.
- 🔴 **`WebFetch` FABRICATES NAMES AND DATES AND FORMATS THEM AS QUOTATIONS.** Use it to locate
  a document. Never source a name, a date or a count from it.
- 🔴 **A WAF REJECTION CAN BE HTTP 200.** Never judge a fetch by `r.ok`. Government hosts reject
  Node's `fetch` on its TLS fingerprint and answer 200 with a challenge body.
- A race that is not called gets **no row**. It stays at seat state 1. That is correct, not a
  gap, and the tracker shows it as outstanding.

## What is recorded, and the two that are not

**33 called, 0 certified, 2 uncalled.** Each recorded row's `result_source` names the person,
the party, the percentage, the vote count, AP's race id and the `calledAt` timestamp, and says
in words that it is a call and not the state canvass.

| Not recorded | Why |
|---|---|
| **AK** | `Too Early to Call`, and `rankedChoice: true` in AP's metadata. Tabulation runs for weeks. |
| **MS** | `Too Early to Call`. |

A race with no call gets no row and stays at seat state 1. That is the correct answer, not a gap.

### 🔴 Matching AP's name to ours is where this goes wrong

Six of the 33 are spelled differently by AP (`Jim`/`James` Risch, `Edward`/`Edward J.` Markey,
`Troy`/`Troy D.` Jackson, `John`/`Jack` Reed, `Shelley`/`Shelley Moore` Capito,
`Harriet`/`Harriet M.` Hageman) and **one cannot be matched on text at all**: AP writes `Lujan`,
we hold `Luján`, and `unaccent` is not installed on production.

A last-name match therefore returned **32 of 33**, silently. **The count is what caught it** —
the join just came back smaller, with no error, exactly as the NULL did in `CC_0347`. New Mexico
is pinned by `race_candidates.id`, and the migration's gate re-asserts 33 and one-winner-per-race
at apply time.

### 🔴 Why only winners, and what South Carolina has to do with it

The obvious next step — *everyone in a called race who is not the winner lost* — would mark
**Lindsey Graham** as having lost the November election. He died in office on 2026-07-11 and was
**not on the ballot**: AP's own South Carolina race lists four candidates and he is not among
them, though our `race_candidates` still carries him.

Losers want a per-candidate match against AP's own candidate list, which is its own pass.
Asserting a result about a dead man from a blanket rule is not.

⚠ **South Carolina is also the overwrite**: Annie Andrews beat the appointed incumbent, so the
seating migration rewrites Darline Graham's `term_end` from 2027-01-03 to 2027-01-02 and must
record the old value in its own header.

## What the state returns looked like on day one

Checked on 2026-11-04, the day after the election. This is the evidence for why the **importer**
(piece 2) is the largest item in the programme — not a reason to record nothing:

| What was checked | Finding |
|---|---|
| Georgia `results.sos.ga.gov` | HTTP 200, Angular SPA shell. Data behind a JS bundle; needs a browser. |
| Georgia Clarity mirror | **HTTP 403** |
| South Dakota `electionresults.sd.gov` | HTTP 200, live and current — *"Unofficial Results, General Election November 3, 2026. Results last updated: 11/4/2026 10:55 AM CT"* — but a SPA shell; the contest data needs a browser. |
| Maine `maine.gov/sos/cec/elec/results` | HTTP 200, but the index still lists only the **June 2026 primary**. The November general is not posted. |
| North Carolina `er.ncsbe.gov` bulk export | **HTTP 404** — no `20261103` dataset published yet. |

So: state returns exist, are being updated hourly, and are mostly behind per-state JS
applications — while some states have not posted the general at all one day out. This is the
same finding the design records as the reason piece 2 (the importer) is the largest item in the
program and why **wave 1 is hand entry**: there is no single feed, and 35 seats span 35 systems.

🔴 **A media call is not a state return.** Several races were widely called on election night.
Those calls are leads for where to look; they are not what gets written here.

## Per-race research log

`results.json` carries the machine-readable copy of this table, keyed by `raceId` so the
seating migration never has to re-derive an office.

| State | Current holder | Holder term ends | Live cands | Research status |
|---|---|---|---|---|
| AK | Dan Sullivan | — | 4 | not researched — ⚠ **ranked choice; tabulation runs for weeks** |
| AL | Tommy Tuberville | — | 2 | not researched |
| AR | Tom Cotton | — | 3 | not researched |
| CO | John Hickenlooper | — | 9 | not researched |
| DE | Chris Coons | — | 2 | not researched |
| FL | Ashley Moody | — | 3 | not researched |
| GA | Jon Ossoff | — | 2 | not researched |
| IA | Joni Ernst | — | 3 | not researched |
| ID | James Risch | — | 5 | not researched |
| IL | Richard Durbin | — | 4 | not researched |
| KS | Roger Marshall | — | 3 | not researched — ⚠ **outlets disagreed on the winner's name** |
| KY | Mitch McConnell | — | 3 | not researched |
| LA | Bill Cassidy | — | 2 | not researched |
| MA | Edward J. Markey | — | 5 | not researched |
| ME | Susan M. Collins | — | 3 | not researched — state has not posted the general |
| MI | Gary Peters | — | 6 | not researched |
| MN | Tina Smith | — | 4 | not researched |
| MS | Cindy Hyde-Smith | — | 3 | not researched — ⚠ **48.95 / 48.94 reported; recount territory** |
| MT | Steve Daines | — | 4 | not researched |
| NC | Thom Tillis | — | 4 | not researched |
| NE | Pete Ricketts | — | 4 | not researched |
| NH | Jeanne Shaheen | — | 3 | not researched |
| NJ | Cory Booker | — | 2 | not researched |
| NM | Ben Ray Luján | — | 2 | not researched |
| OH | Jon Husted | — | 3 | not researched |
| OK | Alan Armstrong | — | 5 | not researched |
| OR | Jeff Merkley | — | 2 | not researched |
| RI | Jack Reed | — | 3 | not researched |
| SC | Darline Graham | **2027-01-03** | 5 | not researched — 🔴 see the overwrite note below |
| SD | Mike Rounds | — | 3 | not researched |
| TN | Bill Hagerty | — | 10 | not researched |
| TX | John Cornyn | — | 6 | not researched |
| VA | Mark Warner | — | 2 | not researched |
| WV | Shelley Moore Capito | — | 3 | not researched |
| WY | Cynthia Lummis | — | 2 | not researched |

## 🔴 South Carolina carries an overwrite that must be recorded when it is seated

Lindsey Graham died in office 2026-07-11. Darline Graham was appointed, took the oath
2026-07-14, and **her term already carries `term_end = 2027-01-03`** (senate.gov and the
Governor's release, written by `CA_0325`).

Seating her successor at 2027-01-03 rewrites that end date to **2027-01-02**. Measured against
production inside a rolled-back transaction on 2026-11-04. The repo requires a migration that
overwrites a value to record the overwritten value in its own header:

> **SC Senate outgoing holder term_end: `2027-01-03` → `2027-01-02`.**

It is the only one of the 35 with an existing end date.

## 🔴 Re-election is the majority case and needs an explicit flag

Of the 2,078 races on 2026-11-03 whose office has a current holder, **1,088 (52%) have that
holder on their own ballot — 378 of 468 federal seats (81%)**. For those,
`seat_officeholder(..., p_allow_reelection => true)` is required; without it the call now RAISES
rather than silently doing nothing (`CC_0338`). Check each winner against the current holder
above before generating the migration.
