# PICKUP — start here after a context clear

Rewritten 2026-11-23, after California and Massachusetts. **Read `REGISTER.md` first** (the queue, the recipe, the
five template corrections, Rulings A and B), then this. `SOURCING.md` is the handbook and the
host table; `DATES.md` is the per-state ledger.

---

## Where the pass stands

**57 bodies · 619 offices still to do.** Nothing is overdue. Seven states are fully written:

| state | dated | people | seated |
|---|---|---|---|
| WI | `CC_0445` | — | `CC_0462` (121) |
| IN — House | `CC_0463` | — | `CC_0464` (3) |
| NV | `CC_0465` (52) | `CC_0466` (12 created, 1 linked) | `CC_0467` (52, **2026-11-04**) |
| HI | `CC_0469` (5) | — | `CC_0470` (2 OHA, **2026-11-03**) · `CC_0471` (Gov + Lt Gov, **2026-12-07**) |
| ME | `CC_0473` (184) | `CC_0474` (59 created, 18 linked) | `CC_0475` (183, **2026-12-01**) · `CC_0476` (Governor, **2027-01-06**) |
| CA | `CC_0477` (99) | — none needed | `CC_0478` (92, **2026-12-07**) · `CC_0479` (7, **2027-01-04**) |
| **MA** | `CC_0481` (204) | `CC_0482` (18 created, 3 linked) | `CC_0483` (199, **2027-01-06**) · `CC_0484` (2, **2027-01-07**) · `CC_0485` (3, **2027-01-20**) |

Plus `CC_0472`, a one-off that widened `office_swearing_in_after_election` from `>` to `>=`.
🔴 **That file is DDL and `ev_api` cannot run it** — DDL goes through the owner connection (the
Supabase MCP), and both the apply tool and the chain rehearser fail it with *"must be owner of
table office_swearing_in"*.

**Next slot to reserve: after `CC_0486`.** Always ask the allocator
(`npm run steward --prefix backend -- slot CC --purpose "..."`), never count.

---

## 🔴🔴 TWO FILES ARE WRITTEN AND NOT APPLIED. EACH COMES DUE ON ITS OWN DAY.

Both are committed and rehearsed; **neither is applied, and each refuses to run early.**

| file | what it does | due |
|---|---|---|
| `CC_0480` | clear `is_vacant` on CA Assembly District 3 and State Senate District 10 | **2026-12-07** |
| `CC_0486` | clear `is_vacant` on MA 1st Franklin District and 17th Middlesex District | **2027-01-06** |

- **Why they wait:** each of those four seats is genuinely empty, and each is the only office in
  its district. Clearing the flag before the winner is seated makes the district read
  `offices > 0 AND active_holders = 0 AND vacant_offices = 0` — verbatim `DEAD_GEOGRAPHY` in a
  **master-only** gate, which would then fail on somebody else's pull request. The seating files
  therefore seat the winners and leave the flag alone.
- **They cannot be applied early.** Each one's P3 refuses unless the office already has a term
  covering *today*, which becomes true on the handover day by itself. It is an interlock, not a
  reminder.
- ▶ **ON THE DAY: rehearse, then apply.**

      cd backend && node scripts/rehearse-migration-chain.mjs migrations/<the file>
      node scripts/apply-migration-file.mjs migrations/<the file>

- ⚠ **The positive path of each is unrehearsable before its day by construction** — P3 wants a
  term covering today and P4 wants that term to start on the handover date, and only on the day
  are both true. Each body was rehearsed with `CURRENT_DATE` read as the handover date and passed
  assertions 1–5; **assertion 6 reads `office_current_holder`, whose own clock is out of reach, so
  it runs for the first time on the day.**
- The federal pair (TX-23, FL-20) is the same shape and `CC_0455` clears them on 2027-01-03.

---

## 🔴🔴 READ THIS BEFORE PINNING ANY SELECTION: THE DIGEST CAN COVER FEWER ROWS THAN IT CLAIMS

Two states have now paid for this, and **the second one showed it can appear late.**

`is_reelection` as `scripts/lib/seating-wave.mjs` publishes it is **NULL**, not false, on a seat
with no current holder — `och` is LEFT JOINed and `true AND NULL` is NULL. Then `'…' || NULL` is
NULL and **`string_agg` skips it**, so the in-SQL digest covers only the rows that had a holder,
while every count still reads the full number.

    California, 92 seats    as published 8f11f4f3… (90 rows)   fixed 3c5becfe… (92 rows)
    Massachusetts, 199      as published 2169c36f… (197 rows)  fixed ae5a2429… (199 rows)

🔴🔴 **IN MASSACHUSETTS THE DEFECT DID NOT EXIST UNTIL THE PEOPLE FILE RAN.** Both flagged seats
were won by people `CC_0482` creates. Before that file the WINNER id is NULL too, the first
conjunct is FALSE, and `false AND NULL` is **FALSE** — no NULL. After it, `true AND NULL` is NULL.
▶ **A digest captured before the people file would have been right and would have silently become
wrong.** Capture the pin by rehearsing `dates + people + a probe that prints the digest` in one
rolled-back transaction, and pin what the probe prints.

⚠ `derive-seating-wave.mjs` prints the FIXED digest, because its JS renders a NULL boolean as
'false'. **The script and the migration disagree for exactly this row shape** — that disagreement
is how California found it.

▶ **Copy `CC_0483`, not `CC_0475`.** It carries the fixed selection and a P1 gate that counts how
many rows the digest expression actually evaluated.

---

## 🔴 NEXT: WASHINGTON — 118 offices, already sourced, ONE date, NOBODY to create

`DATES.md` § WA has the full write-up, sourced 2026-11-22. **Do not re-source it.** ("Sourced" is
not "dated" — the register's `no date` column counts *rows in the database*, not research done.)

| body | offices | start date | authority |
|---|---|---|---|
| House of Representatives | 95 pending (of 98) | **2027-01-11** (Mon) | `RCW 44.04.021` |
| Senate | 23 pending (of 49) | **2027-01-11** (Mon) | `RCW 44.04.021` |

🟢 **WASHINGTON IS THE EASIEST STATE LEFT.** One date, one citation, no people to create, no
flagged-vacant seat, no multi-member race. After Maryland's 85 missing people and Massachusetts'
three dates, this is a two-file state: dates, then seating.

🔴 **THE CITATION IS A STATUTE, NOT THE CONSTITUTION, AND THAT IS THE TRAP.** Wash. Const. Art. II
§§ 5 and 6 fix the **length** of a legislative term and never its start. ⚠ Art. III, § 4 DOES name
a commencement — *"the second Monday in January after their election"* — **for the executives, not
the legislature**. It is the same day, which is exactly what makes it dangerous: citing Art. III
§ 4 for a legislator gives the right answer from the wrong provision. Read `DATES.md` § WA before
writing the `authority` text.

⚠ **95 of 98 House seats and 23 of 49 Senate seats are pending.** The Senate is staggered, so 23
of 49 is correct; the 3 missing House seats are the results-programme class — a race with no
recorded result is as invisible as no race. Assert both exclusions, the way `CC_0481` asserted
2nd Plymouth District.

### The shape of the work

1. **dates** — 118 `office_swearing_in` rows, one date. Copy `CC_0477` (California) for the
   single-clause shape, or `CC_0481` if you want the anchor-and-offset pattern.
2. **seating, 2027-01-11** — 118 seats. Copy `CC_0483`.

⚠ **Maryland (114 offices) is the alternative and it is much harder**: 85 winners with no person
record, and 38 multi-winner Delegate offices that need Ruling A's equality gate per race.

---

## The traps this pass has paid for, in one screen

**On dates**

- 🔴🔴 **THE DATE EVERY SOURCE PUBLISHES IS OFTEN THE CONVENING, NOT THE TERM START.** Maine's
  term begins 2026-12-01 and the Legislature convenes 2026-12-02. One day, 183 seats. ⚠ **AND THE
  OPPOSITE IS ALSO TRUE** — California convenes at noon on the same Monday the terms begin
  (art. IV, § 3(a) and § 2(a)(3)), so "the convening date is wrong" is not a rule either. Read
  what the source's date is a date OF. The seating file must **read** the date from
  `office_swearing_in`; a literal agrees with itself however wrong it is.
- 🔴 **A TERM CAN BEGIN ON ELECTION DAY** (`HRS § 13D-5`) or the day after (`Nev. Const. art. 4
  §§ 3, 4`; `Ind. Const. art. 4 § 3`). "The date is in the future" is an assumption.
- 🔴 **READ THE PREPOSITION.** Nevada and Indiana count forward — *"the day next **after** their
  election"*. Maine counts back — *"the day next **preceding** the first Wednesday in December"*.
- 🔴🔴 **LOOK FOR THE CONSTITUTION'S GENERAL TERM-COMMENCEMENT CLAUSE BEFORE CONCLUDING AN OFFICE
  HAS NONE.** California's `art. II, § 20` dates all seven of its statewide offices and lives in
  the **voting** article — reading articles IV, V and XIII in order never reaches it, and
  art. XIII, § 17 names no commencement at all. Without it the Board of Equalization would have
  been refused the way Maryland's Comptroller was.
- 🔴 **A FORMULA THAT AGREES THIS CYCLE CAN DIFFER NEXT.** "The Monday after January 1" ≠ "the
  first Monday of January" whenever 1 January is a Monday (2024: the 8th against the 1st). They
  agree for 2027. Evaluate the clause **as written**, in SQL, for a year the file does not write,
  and check it against a term already in the database from an unrelated source.
  ⚠ `chambers.inauguration_rules` carries the WRONG one of those two for three California
  executives, uncited, and agrees this cycle. **A rule row earns its way in by its own citation.**
- 🔴 **WHERE THE LAW SAYS QUALIFICATION, THE TERM START IS THE OATH** and there may be no date at
  all — Nevada's six executives are refused with a sourced `window_end_date` of 2027-01-04.

**On people**

- 🔴🔴 **`winner_no_record` MEANS "NO RECORD IN THIS RACE", NEVER "NO RECORD ANYWHERE".** Nevada:
  1 of 13. Maine: **18 of 77**, because term limits push members between chambers every cycle.
  **Sweep the whole `politicians` table before creating anybody.**
- 🔴🔴 **A NAME THAT MATCHES IS NOT A PERSON THAT MATCHES — PRINT THE FIELD THAT DISCRIMINATES.**
  Two active "Chad Perkins" rows; one holds **Missouri** House District 40, one holds **Maine**
  House District 31.
- 🔴 **ASK WHAT A DOCUMENT IS FOR BEFORE LETTING IT OVERRULE A NAME.** Nevada's published member
  page outranked AP on `Dávila`. Maine's *orientation agenda* did not — it misspelt four names the
  Secretary of State's filing record gets right.
- ⚠ **PEOPLE MOVE BETWEEN SEATS, AND ONE PERSON CAN BE BOTH A WINNER AND A PREDECESSOR IN THE
  SAME FILE.** California: Soria and Connolly move Assembly → Senate; Ma and Kounalakis **exchange**
  Treasurer and Lieutenant Governor. The incumbency guard's scope must be a UNION of winners and
  predecessors, and an exchange needs an assertion measured **from the people's side** — one term
  closing, one opening, two distinct offices — because no per-office count can see somebody left
  holding two seats.
- ⚠ **A GAP BETWEEN TWO OFFICES IS NOT A DEFECT.** Mike Gipson's Assembly term closes 2026-12-06
  and his Board of Equalization term opens 2027-01-04. Two clauses, two days, 28 days out of
  office. Do not "fix" it by moving either date.
- ✅ **`party` IS NOT A GAP TO FILL.** Ruling, 2026-11-23: *"Parties are not something we celebrate
  anywhere on our platform."* A NULL party is finished work.

**On vacancies**

- 🔴🔴 **A CORRECT `is_vacant` FLAG IS NOT A BLOCKER, AND CLEARING IT EARLY IS THE MISTAKE.**
  `derive-seating-wave.mjs` reports it as one and `CC_0475`'s P6 refuses any flag at all — the
  right default and the wrong rule for a seat that really is empty. Name the expected flags in P6,
  refuse a third, seat the winner future-dated, and clear the flag **on the handover day** in its
  own file with a data interlock (`CC_0480`).
- 🔴 **THE REASON IS A MASTER-ONLY GATE.** One office in its district, flag cleared while empty,
  and the district reads `offices > 0 AND active_holders = 0 AND vacant_offices = 0` —
  `DEAD_GEOGRAPHY`, failing on the next innocent pull request.
- 🟢 **A vacancy renders correctly meanwhile.** Measured through the deployed API 2026-11-23:
  Assembly District 3 answers `seat_status=vacant, incoming=Dom Belza, on=2026-12-07`.

**On the register's blind spots**

- 🔴🔴 **AN OFFICE WITH A RACE AND NO RECORDED RESULT IS EXACTLY AS INVISIBLE AS AN OFFICE WITH NO
  RACE.** `office_pending_winner` cannot tell them apart and the seat count looks complete either
  way. Found so far: NV Assembly District 22; ME State House 86, 96 and State Senate 18; **CA's
  five un-raced Assembly districts, Superintendent of Public Instruction and Commissioner of
  Insurance**. 🔴 Those last two would NOT take California's statewide date if they were added —
  the Superintendent has its own clause and the Insurance Commissioner is **statutory**, so
  "provided for by this Constitution" does not reach it. **These belong to the results programme.**
- 🔴 **A CHAMBER CAN HOLD SEATS ITS CONSTITUTION'S MEMBERSHIP NUMBER DOES NOT COUNT.** Maine: 154
  House offices against a constitutional 151, because three are tribal seats filled by their
  nations. Read as a defect that is Connecticut's *fabricated* missing-office finding; the
  identical reading in South Dakota was a *real* one.
- 🔴 **AN INNER JOIN TO `essentials.chambers` DROPS A `STATE_BOARD` SEAT**, whose `chamber_id` is
  NULL. California read as 98 offices instead of 99 that way. Join chambers LEFT, or not at all.

**On the tooling**

- 🔴🔴 **THE DIGEST CAN COVER FEWER ROWS THAN THE COUNTS CLAIM** — see the section above. Count
  what went into `string_agg`, not just what came out.
- 🟢 **`scripts/rehearse-migration-chain.mjs`** runs several migrations in ONE transaction against
  prod and always rolls back. 🔴 **Rehearsing a chain file-by-file proves nothing and fails in the
  direction that reads as success** — a seating file alone aborts at `P4` for want of the dates
  file.
- ⚠ It drops temp tables between files to stand in for the COMMIT that would have. Faithful only
  because every temp table in these migrations is `ON COMMIT DROP`, which Postgres records nowhere
  a query can read — so it prints what it dropped.
- 🔴 **A FILE THAT PINS ITS SELECTION BY DIGEST MAKES ITS LATER NAMED GATES UNREACHABLE BY ANY
  REALISTIC TAMPER.** Every selection tamper is caught by the digest, two gates before the one it
  was aimed at. `CC_0471`'s assertion 4, `CC_0473`'s 4–6, `CC_0474`'s P5 and **`CC_0479`'s P8 and
  assertion 6** are recorded as **backstops, not tested gates**. Do not count green controls as
  tested assertions.
- 🔴 **A TAMPER CAN BE STOPPED BY AN EARLIER FILE, NOT JUST AN EARLIER GATE.** Changing
  `CC_0477`'s date to reach `CC_0478`'s P4 was stopped by `CC_0477`'s own clause check. To reach a
  later file's gate, tamper the later file.
- ⚠ **Put `P2` (already applied?) ABOVE the row-count checks.** On a second run the seats have
  left `office_pending_winner`, so a count check fires first and blames the data.
- ⚠ **Capture the predecessor pre-image, and expect it to be SMALLER than the seat count when a
  seat is vacant.** California: 92 seats, **90** predecessors. `seat_officeholder` closes each
  predecessor with an unguarded `UPDATE … SET term_end = p_term_start - 1` and records nothing.
- ⚠ **A STATE-WIDE COUNT OF CLOSURES CAN PICK UP ANOTHER PROGRAMME'S ROW.** California's
  2027-01-03 closures read 8, not 7; the eighth was a Santa Cruz County supervisor closed by
  `CC_0405`. The migration's own assertion counted its pre-image and was right. **Measure what the
  file touched, not what the day holds.**

---

## Housekeeping

- **Worktree:** `/c/ev-accounts-seating`, branch `feat/state-seating`, PR #1578. Commit with an
  explicit pathspec.
- **Env:** the worktree has no `.env`. Prefix commands with
  `set -a && . /c/EV-Accounts/backend/.env >/dev/null 2>&1; set +a`.
- **Steward:** jurisdiction leases are 24h and expire on their own; `state:ca` and `state:ma`
  were held for this work and lapse on 2026-11-24. **Claim `state:wa` before starting
  Washington.**
- **Live tracker artifact:** `https://claude.ai/artifact/68XRWM6MpNd2W6Phit4QNo` — refresh it as
  part of finishing each state (`node scripts/build-transition-dataset.mjs`, upload the three
  CSVs, update the three `datasets/*` docs **in place**, and re-read the hand-kept `assignments`
  file against them). ✅ **Refreshed for California and Massachusetts, 2026-11-23**, all four dataset docs.
  🟢 **THE "waves 4 and 5 SAY Blocked" WARNING IS STALE AND IS RETIRED HERE.** It was true on
  2026-11-16 and fixed before the 11-19 refresh. Re-read 2026-11-23: the five status words are
  `In progress` ×4 and `Barely started`, none matches the page's `/block/i` regex, and `blocked`
  is 0 in every wave. ⚠ **Re-read it anyway at every refresh** — it is the only dataset the
  builder does not compute, so it goes stale on its own, and the status word is the operator's
  to change. ⚠ Wave 4's `next_action` text still predates California.
- **Step 9 is not done until a real address goes through `api.empowered.vote`.** Reasoning about a
  read path is not measuring it. Pick an address in a seat that CHANGES HANDS, and one in a seat
  that is vacant if the state has one — a re-election renders the same whether the file worked or
  not.
