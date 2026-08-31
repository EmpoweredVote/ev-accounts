# Florida Legislature — verified roster (Knight program, wave FL-2)

**Retrieved and reconciled 2026-08-28.** Built by `scripts/build-fl-legislature-roster.mjs` into
`data/fl-legislature-roster.json`. Nothing downstream can be more correct than this file.

## Headline

| | Offices | People | Vacancies |
| --- | --- | --- | --- |
| House | 120 | **116** | **4** |
| Senate | 40 | **39** | **1** |
| **Total** | **160** | **155** | **5** |

🔴🔴 **FLORIDA DOES NOT HAVE 160 SITTING LEGISLATORS.** The FL-2 plan assumed 160 people for 160
offices. The measured answer is **155 people and 5 vacancies**. Every count in the structure and
occupancy migrations must use 160 offices / 155 seated, not 160/160.

## Sources

| Id | URL | Bytes | What it is authoritative for |
| --- | --- | --- | --- |
| S1 | `https://www.flhouse.gov/Representatives` | 266,835 | House identity, district, canonical name spelling, current term window, vacancy cards |
| S2 | `https://www.flsenate.gov/Senators/` | 84,387 | Senate identity, district, canonical name spelling, vacancy marker |
| S3 | `https://www.flhouse.gov/Sections/Representatives/details.aspx?MemberId=<id>` | ~20–58 k each | per-member "Legislative Service" line — the assumed-office date |
| S4 | `https://www.flsenate.gov/Senators/2024-2026/S<district>` | ~39–53 k each | per-member "Legislative Service" line, plus a compact "Elected M/D/YYYY" line on 4 of 40 |

All 155 member pages were fetched and cached to this directory (`_h-<memberId>.html`,
`_s-<district>.html`). They are the evidence and stay on disk for the length of the wave.

**Every one of the 155 member pages mentions its member's surname** (155/155). That is the
change-since-source check: the roster and the member's own page agree on who holds the seat.

## 🔴 Source defects found

### 1. The House roster is over-long, and four of the extra rows are vacancies

131 `team-box` cards = **127 member records + 4 "Pending Election" cards**.

The 127 member records cover 120 districts. Eleven records carry an **early term end** — the
discriminator for a departed member. Seven of those sit alongside a successor; **four have no
successor at all**, and the roster marks those districts with a separate card whose image alt text
reads *"District N is currently vacant."*

A parser requiring both a `MemberId` and an `<h5>` name **skips the Pending Election cards silently**,
because they have neither. The seat count then reads 120 members when the truth is 116 members plus 4
vacancies. This is the single most dangerous defect in the source.

### 2. The Senate marks a vacancy a completely different way

There is no card. **The roster row's name cell literally contains the word `Vacant`** (SD-39,
Miami-Dade). A parser that only knew the House's form would try to read `Vacant` as a surname-first
name. `parseSurnameFirst` throws on it, and there is a unit test asserting exactly that, because the
failure mode is seating a politician called "Vacant".

The Senate publishes **no date and no reason** for SD-39 — its member page contains only the word
`Vacant`. So `vacant_since` is genuinely **unknown** and is left unwritten, per CLAUDE.md.

### 3. The roster's start date is the CURRENT TERM, not continuous occupancy

120 of the 127 House records read `11/06/24`, the 2024 general election. Writing that as `term_start`
would misstate every re-elected member, because `term_start` is the start of continuous occupancy and
re-election does not end an occupancy. The date is taken from each member's own page instead.

### 4. The "Legislative Service" line has ELEVEN phrasings

Enumerated by scanning all 156 cached pages, not guessed. An unrecognised form silently degrades a
known date to `unknown` — which is exactly what happened to SD-11, SD-14 and SD-15 on the first run,
all three of which publish a **full date**.

| Count | Shape |
| --- | --- |
| 64 | `Elected to the Florida House of Representatives in YYYY, reelected subsequently` |
| 22 | *(no Legislative Service block — a first-term member)* |
| 20 | `Elected to the Senate in YYYY, reelected subsequently` |
| 19 | `Elected to the Florida House of Representatives in YYYY` |
| 12 | `Elected to the Senate in YYYY` |
| 7 | `Elected to the Florida House of Representatives on MONTH D, YYYY, reelected subsequently` |
| 5 | `Elected to the Florida House of Representatives on MONTH D, YYYY` |
| 3 | `Elected to the Senate on MONTH D, YYYY` |
| 2 | `Elected to the Senate MONTH D, YYYY, reelected subsequently` — **no "on"** |
| 1 | `Elected to the Senate in YYYY, prior Senate YYYY-YYYY` |
| 1 | `Elected to the Senate on MONTH D, YYYY, prior service YYYY-YYYY` |

### 5. `flhouse.gov` returns HTTP 200 for things that are not the page you asked for

Two distinct behaviours, both measured:

- **A path that cannot exist returns the full roster.** `myfloridahouse.gov/.../MemberList.pdf`
  returned 74,830 bytes of roster HTML with HTTP 200.
- **A valid path intermittently returns a ~244-byte stub with HTTP 200.**
  `details.aspx?MemberId=5063` returned 244 bytes on one call and 32,365 bytes on the next, seconds
  apart, same URL.

`fetchValidated()` therefore asserts a minimum byte count **and** a required marker string, and
retries. Never judge a Florida source by its status code.

### 6. The "Florida Senate Service" block is a term SELECTOR, not a service record

It looked like a continuous-service history and is not. Proven against the real pages:

- It repeats the current term as the selected value — SD-19 renders
  `2024-2026, 2022-2024, 2020-2022, 2018-2020, 2016-2018, 2024-2026`.
- It lists every term in which the member served **any part**, not when they took the seat. Lori
  Berman (SD-26) won a special election on 2018-04-10 inside the 2016-2018 term, so the block reaches
  back to 2016 while her occupancy began in 2018. Rosalind Osgood (SD-32) is the same shape.
- **It does not show a gap.** Debbie Mayfield (SD-19) served 2016-2024, left, and returned on
  2025-06-10 — the block still runs unbroken, because she served part of the 2024-2026 term.

A `continuousRunStart()` helper was written against the false assumption, produced three wrong dates,
and has been **deleted with a do-not-reinvent note** in the script. The block is still captured into
the JSON as `_senateTermSelector`, marked evidence-only.

### 7. Names carry six irregular shapes

Found by scanning all 172 roster names. Both chambers render names **surname-first with a comma**,
which is a *cleaner* split than "First Last" — `Bracy Davis, LaVon` is unambiguous here, where a
space-split would have guessed wrong.

| Shape | Count | Example | Handling |
| --- | --- | --- | --- |
| Quoted nickname | 22 | `Alvarez, Daniel Antonio "Danny"` | kept in `full_name` (NC precedent), also surfaced as a preferred name |
| Suffix on the **surname** side | 6 | `Brannan III, Robert Charles "Chuck"` | moved to `name_suffix` |
| Leading honorific | 2 | `Eskamani, Dr. Anna V.` | **stripped** from `full_name`, recorded separately |
| Non-ASCII | 3 | `Basabe, Fabián` | preserved byte-for-byte |
| Suffix after a **second** comma | 1 | `Massullo, Ralph E., Jr.` | moved to `name_suffix` |
| Leading `*` marker | 1 | `* Casello, Joe` | stripped (marks a deceased member; he is a departed record) |

The honorific is stripped because **`full_name` is a matching key downstream** — the headshot import
guard joins on it, and `Dr. Anna V. Eskamani` would fail to match `Anna V. Eskamani` everywhere else.

## Vacancies

| Seat | Vacant since | Predecessor and last day | Evidence |
| --- | --- | --- | --- |
| HD-55 | 2026-08-06 | Kevin M. Steele, 2026-08-05 | Pending Election card |
| HD-78 | 2026-05-21 | Jenna Persons-Mulicka, 2026-05-20 | Pending Election card |
| HD-113 | 2025-11-19 | Vicki L. Lopez, 2025-11-18 | Pending Election card |
| HD-116 | 2026-08-22 | Daniel Perez, 2026-08-21 | Pending Election card |
| SD-39 | **unknown** | not published | roster row and member page read only `Vacant` |

The four House dates are the **day after** the departed member's published last day, which is what
`offices.vacant_since` means. SD-39's start is not published, so it is left NULL — CLAUDE.md: do not
write a vacancy span whose start date you do not know.

**These 4 + 1 seats get an office with `is_vacant = true` and no `office_terms` row.** That is
load-bearing, not cosmetic: `check-address-reachability.mjs` classifies `DEAD_GEOGRAPHY` as
`reachable AND offices > 0 AND active_holders = 0 AND vacant_offices = 0`. An office created without
the flag would fire a **new `fl|STATE_LOWER` bucket** and fail the gate.

## The seven contested House districts

Each lists a departed member alongside the sitting one. All seven resolve on the term-end
discriminator; none needed the tie-break rules.

| District | Kept | Dropped (departed) |
| --- | --- | --- |
| 3 | Nathan Boyles (from 06/10/25) | Joel Rudman, left 01/01/25 |
| 32 | Brian Hodgers (from 06/10/25) | Debbie Mayfield, left 06/09/25 |
| 40 | RaShon Young (from 09/02/25) | LaVon Bracy Davis, left 09/01/25 |
| 51 | Hilary Holley (from 03/24/26) | Josie Tomkow, left 03/17/26 |
| 52 | Samantha Scott (from 03/24/26) | John Paul Temple, left 09/18/25 |
| 87 | Emily Gregory (from 03/24/26) | Michael A. "Mike" Caruso, left 08/18/25 |
| 90 | Rob Long (from 12/09/25) | Joe Casello, left 07/18/25 |

Two of the departed moved to the **Senate**, which the data confirms internally:
**LaVon Bracy Davis** left HD-40 on 2025-09-01 and took SD-15 on 2025-09-02; **Debbie Mayfield** left
HD-32 on 2025-06-09 and took SD-19 on 2025-06-10. Consecutive days in both cases.

## Rulings

**`how_started` is `'elected'` for all 155.** Florida fills legislative vacancies by **special
election**, not by appointment — Fla. Const. art. III, s. 15(d) and ch. 100, F.S. This is stated
rather than left to the default, because `essentials.seat_officeholder()` defaults `p_how_started` to
`'elected'` and a silent default is not evidence. No seat is recorded as `'appointed'`.

**Date precision: day 39, year 116, unknown 0.** A year-only source is stored `YYYY-01-01` with
`start_precision = 'year'`, so month and day are explicitly not claimed. No date was invented.

**Four Senate dates are independently confirmed** by a second line on the same page
(`Elected M/D/YYYY`), with **zero conflicts**.

**No party affiliation** is recorded on any person or office, per repo convention.

## Counts a reviewer should be able to reproduce

```
House team-box cards            131  = 127 member records + 4 Pending Election
House records, normal term end  116
House records, early term end    11  (7 with a successor, 4 without)
House districts covered         120  = 116 seated + 4 vacant
Senate rows                      40  = 39 seated + 1 vacant
Offices                         160
People                          155
Vacancies                         5
```
