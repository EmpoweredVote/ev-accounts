# OR Bend / Deschutes — four missing candidates, one certified, and a race that renders empty

**Opened:** 2026-09-11 (during the OR reconciliation, migration 1858)
**Priority:** highest of the three missing-candidate todos from this phase. One of these people is
**certified to the ballot** for a mayoralty, and one race now displays no candidates at all.

## What is missing

| candidate | contest | status on the official list | in our data? |
|---|---|---|---|
| **Bernadette Strome** | Bend Mayor | "Eligible, Qualified & Certified for Ballot – will be on Nov. 3 ballot" | ❌ |
| Nic Tarter | Bend City Council #6 | "Eligible & Qualified" | ❌ |
| **Jana Cain** | Deschutes County Treasurer | filed in the 08/12–08/25 vacancy window | ❌ |
| **Cam Sparks** | Deschutes County Treasurer | filed in the same window | ❌ |

Sources, both the election officials for these contests, fetched 2026-09-11:
`deschutes.org/1593/November-3-2026-General-Election` (section "Filed Candidates (Nonpartisan
Positions)") and `bendoregon.gov/city-council/elections/`.

## Why it happened

Our field was seeded **2026-07-24**, and its own source string says so: "provisional -- pre-deadline
field (seeded 2026-07-24), cull >= 2026-08-29 (OR filing closed 2026-08-25 / 2026-08-18 elected
incumbents; withdrawals 2026-08-28)". Filing was open for another month after we read it. The
Treasurer contest did not even exist in its current form on 07-24 — it was reopened for a
**vacancy in nomination** under OAR 165-010-0110, with a filing window of 2026-08-12 to
2026-08-25, entirely after our snapshot.

So this is not a defect in the seeding; the seeding correctly labelled itself provisional and
named the date to come back. The defect is that nobody came back.

## ⚠ Deschutes County Treasurer now renders with no candidates

The only row we hold for that race is Robert Tintle, who **withdrew on 2026-08-05** and is culled
by 1858. Jana Cain and Cam Sparks are absent. An empty race beats a race whose one name has
withdrawn, but note the structural gap: **the staleness flag lives on candidate rows, so a race
with no live rows has no way to say "we are missing everyone."** Worth a schema thought — a
race-level provisional marker — if this recurs.

## The open status question

Three Bend candidates are listed "Eligible & Qualified" *without* the "Certified for Ballot"
clause the ballot-bound candidates carry: Dan Sorrells and Nic Tarter (#6), Ron (Rondo) Boozell
(Mayor). Filing closed 2026-08-25 and withdrawals closed 2026-08-28, so this is not a page that
simply has not caught up. The page never defines the difference, and Deschutes County defers to
the city for Bend contests rather than publishing its own list.

Our two rows in that state (Sorrells, Boozell) are **held**, not culled.

## How to close it

1. Ask the City of Bend Recorder what "Eligible & Qualified" means against "Certified for Ballot"
   — whether those three appear on the November 3 ballot. One email settles four rows.
2. Seed Strome, Tarter, Cain and Sparks (local nonpartisan races — no federal stance set needed,
   but they do need politician records and the usual identifiers).
3. Then clear `provisional_until` on Bend #6 and Bend Mayor, and re-check Deschutes Treasurer.
