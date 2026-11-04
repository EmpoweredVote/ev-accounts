# 2026-11-03 US Senate — results research

**Status as of 2026-11-04: 0 of 35 races recorded. Nothing has been written to production.**

This file is the reviewed artifact. `results.json` is generated to match it, and the seating
migration is generated from `results.json`. Nothing is seated that is not written down here
first, with a source that NAMES the person.

## The rules this file is held to

Each one is in CLAUDE.md because a real seat was got wrong without it.

- 🔴 **A CERTIFIED RESULT IS NOT A FACT ABOUT WHO HOLDS THE SEAT.** It records who won an
  election. Taking office is a separate, later event. These winners are seated with
  `term_start = 2027-01-03`, which is the day they take office, not the day they won.
- 🔴 **THE STATE'S OWN RETURN OUTRANKS EVERY AGGREGATOR, AND THEY DO DISAGREE.** A media call
  is a lead. On 2026-11-04 outlets already disagreed with each other on Kansas (two spellings
  of the winner's name), and Mississippi stood at 48.95% / 48.94%.
- 🔴 **`WebFetch` FABRICATES NAMES AND DATES AND FORMATS THEM AS QUOTATIONS.** Use it to locate
  a document. Never source a name, a date or a count from it.
- 🔴 **A WAF REJECTION CAN BE HTTP 200.** Never judge a fetch by `r.ok`. Government hosts reject
  Node's `fetch` on its TLS fingerprint and answer 200 with a challenge body.
- A race that is not called gets **no row**. It stays at seat state 1. That is correct, not a
  gap, and the tracker shows it as outstanding.

## Why nothing is recorded yet

Checked on 2026-11-04, the day after the election:

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
