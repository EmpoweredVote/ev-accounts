# PICKUP — start here after a context clear

Written 2026-11-23. **Read `REGISTER.md` first** (the queue, the recipe, Rulings A and B), then
this. `SOURCING.md` is the handbook and the host table; `DATES.md` is the per-state ledger.

---

## Where the pass stands

**64 bodies · 922 offices still to do.** Nothing is overdue. Five states are fully written:

| state | dated | people | seated |
|---|---|---|---|
| WI | `CC_0445` | — | `CC_0462` (121) |
| IN — House | `CC_0463` | — | `CC_0464` (3) |
| **NV** | `CC_0465` (52) | `CC_0466` (12 created, 1 linked) | `CC_0467` (52, **2026-11-04**) |
| **HI** | `CC_0469` (5) | — | `CC_0470` (2 OHA, **2026-11-03**) · `CC_0471` (Gov + Lt Gov, **2026-12-07**) |
| **ME** | `CC_0473` (184) | `CC_0474` (59 created, 18 linked) | `CC_0475` (183, **2026-12-01**) · `CC_0476` (Governor, **2027-01-06**) |

Plus `CC_0472`, a one-off: it widened `office_swearing_in_after_election` from `>` to `>=`,
because Hawaii's OHA trustees' terms begin **on election day** and the schema forbade recording
that. 🔴 **That file is DDL and `ev_api` cannot run it** — DDL goes through the owner connection
(the Supabase MCP), and both the apply tool and the chain rehearser fail it with *"must be owner
of table office_swearing_in"*.

**Next slot to reserve: after `CC_0476`.** Always ask the allocator
(`npm run steward --prefix backend -- slot CC --purpose "..."`), never count.

---

## 🔴 NEXT: CALIFORNIA — 99 offices, already sourced, two dates

`DATES.md` § CA has the full write-up, sourced 2026-11-22. **Do not re-source it.** (I wasted a
run re-deriving Maine because the register's `no date` column counts *rows in the database*, not
research done — **"sourced" is not "dated"**, and `SOURCING.md` says so in bold.)

| body | offices | start date | authority |
|---|---|---|---|
| State Assembly | 75 | **2026-12-07** (Mon) | `Cal. Const. art. IV, § 2(a)(3)` |
| State Senate | 17 | **2026-12-07** (Mon) | `art. IV, § 2(a)(3)` |
| Governor · Lt. Governor · Attorney General · Controller · Secretary of State · Treasurer | 6 | **2027-01-04** (Mon) | `art. II, § 20` |
| Board of Equalization, District 3 | 1 | **2027-01-04** (Mon) | `art. II, § 20` |

**Measured 2026-11-23:** 99 winner rows · 99 offices · 71 re-elections · 28 new holders ·
called 99 / certified 0 · digest `b81d9ec8944420db99f8a38bfcd888dd` (whole state; it will differ
once you split the waves).

### 🟢 Nobody needs creating

**There are no `winner_no_record` blockers.** California is the first big state in the pass that
skips step 4 entirely. All 99 winners already have a `politicians` row.

### 🔴🔴 THE TWO BLOCKERS ARE `flagged_vacant`, AND CLEARING THEM EARLY IS THE MISTAKE

    Assembly District 3      flagged is_vacant
    State Senate District 10 flagged is_vacant

`seat_officeholder` writes `office_terms` and **never touches `essentials.offices`**, so from
2026-12-07 each of these will read **held AND vacant at the same time**. Every seating file in
this pass asserts (`P6`) that nothing in its selection is flagged, precisely so this decision is
made rather than absorbed — so **a California seating file copied from `CC_0475` will refuse to
run until you deal with these two.**

▶ **Clear the flag ON the handover day, in its own file, NOT in the seating migration.** The
reason is recorded on the live transition tracker and is not obvious: each of these is the only
office in its district, so clearing early yields
`offices > 0 AND active_holders = 0 AND vacant_offices = 0` — verbatim `DEAD_GEOGRAPHY` in a
**master-only** gate, which then fails on somebody else's PR. The federal pair (TX-23, FL-20) has
the same shape and `CC_0455` clears them on 2027-01-03.

### The shape of the work

Four files, in this order. Nothing here needs a browser or new sourcing.

1. **dates** — 99 `office_swearing_in` rows, two dates. Copy `CC_0473` (Maine, two dates, with a
   SQL control that evaluates the clause for a year the file does not write).
2. **vacancy** — settle `AD3` and `SD10`. Dated for 2026-12-07; read the tracker note above first.
3. **seating, 2026-12-07** — 92 legislative seats, FUTURE-dated. Copy `CC_0475`.
4. **seating, 2027-01-04** — the 6 executives + Board of Equalization D3. Copy `CC_0476`.

🔴 **Two dates in one `(state, district_type)` row is two waves** — `classifyWave` raises
`date_disagrees`. California, Hawaii, South Dakota and Maine all ship this way.

---

## The traps this pass has paid for, in one screen

**On dates**

- 🔴🔴 **THE DATE EVERY SOURCE PUBLISHES IS OFTEN THE CONVENING, NOT THE TERM START.** Maine's
  term begins 2026-12-01 and the Legislature convenes 2026-12-02. One day, 183 seats. The seating
  file must **read** the date from `office_swearing_in`; a literal agrees with itself however
  wrong it is, and the tamper that proves it is pinning the file to the wrong day and watching
  `P4` abort.
- 🔴 **A TERM CAN BEGIN ON ELECTION DAY** (`HRS § 13D-5`) or the day after (`Nev. Const. art. 4
  §§ 3, 4`; `Ind. Const. art. 4 § 3`). "The date is in the future" is an assumption.
- 🔴 **READ THE PREPOSITION.** Nevada and Indiana count forward — *"the day next **after** their
  election"*. Maine counts back — *"the day next **preceding** the first Wednesday in December"*.
- 🔴 **A FORMULA THAT AGREES THIS CYCLE CAN DIFFER NEXT.** "The first Wednesday after the first
  Tuesday of January" ≠ "the first Wednesday of January" whenever 1 January is a Wednesday.
  Evaluate the clause **as written**, in SQL, for a year the file does not write, and check it
  against a term already in the database from an unrelated source.
- 🔴 **WHERE THE LAW SAYS QUALIFICATION, THE TERM START IS THE OATH** and there may be no date at
  all — Nevada's six executives are refused with a sourced `window_end_date` of 2027-01-04.

**On people**

- 🔴🔴 **`winner_no_record` MEANS "NO RECORD IN THIS RACE", NEVER "NO RECORD ANYWHERE".** Nevada:
  1 of 13. Maine: **18 of 77**, because term limits push members between chambers every cycle.
  **Sweep the whole `politicians` table before creating anybody.**
- 🔴🔴 **A NAME THAT MATCHES IS NOT A PERSON THAT MATCHES — PRINT THE FIELD THAT DISCRIMINATES.**
  Two active "Chad Perkins" rows; one holds **Missouri** House District 40, one holds **Maine**
  House District 31. Printed without the state they look like one person's two terms under two
  maps, and Maine really did redistrict in 2021.
- 🔴 **ASK WHAT A DOCUMENT IS FOR BEFORE LETTING IT OVERRULE A NAME.** Nevada's published member
  page outranked AP on `Dávila`. Maine's *orientation agenda* did not — it misspelt four names the
  Secretary of State's filing record gets right. Authoritative about **who**, unreliable about
  **how they spell it**.
- ✅ **`party` IS NOT A GAP TO FILL.** Ruling, 2026-11-23: *"Parties are not something we celebrate
  anywhere on our platform."* A NULL party is finished work. Record one only where a **one-party
  primary** makes it load-bearing for the election itself.

**On the register's blind spots**

- 🔴🔴 **AN OFFICE WITH A RACE AND NO RECORDED RESULT IS EXACTLY AS INVISIBLE AS AN OFFICE WITH NO
  RACE.** `office_pending_winner` cannot tell them apart and the seat count looks complete either
  way. Found so far: NV Assembly District 22; ME State House 86, State House 96, State Senate 18
  (the Legislature's own roster names all three winners). **These belong to the results programme.**
- 🔴 **A CHAMBER CAN HOLD SEATS ITS CONSTITUTION'S MEMBERSHIP NUMBER DOES NOT COUNT.** Maine: 154
  House offices against a constitutional 151, because three are tribal seats filled by their
  nations under Joint Rules 206(3) and 316. Read as a defect that is Connecticut's *fabricated*
  missing-office finding; the identical reading in South Dakota was a *real* one.

**On the tooling**

- 🟢 **`scripts/rehearse-migration-chain.mjs`** runs several migrations in ONE transaction against
  prod and always rolls back. 🔴 **Rehearsing a chain file-by-file proves nothing and fails in the
  direction that reads as success** — a seating file alone aborts at `P4` for want of the dates
  file, and its digest is computed over ids the people file has not created yet. That is also why
  the people files write **explicit UUIDs**.
- ⚠ It drops temp tables between files to stand in for the COMMIT that would have. Faithful only
  because every temp table in these migrations is `ON COMMIT DROP`, which Postgres records nowhere
  a query can read — so it prints what it dropped.
- 🔴 **A FILE THAT PINS ITS SELECTION BY COUNT AND BY STRUCTURE MAKES ITS LATER NAMED GATES
  UNREACHABLE BY ANY REALISTIC TAMPER.** `CC_0471`'s assertion 4, `CC_0473`'s 4–6 and `CC_0474`'s
  P5 all have no control of their own and are recorded as **backstops, not tested gates**. Do not
  count green controls as tested assertions.
- ⚠ **Put `P2` (already applied?) ABOVE the row-count checks.** On a second run the seats have
  left `office_pending_winner`, so a count check fires first and blames the data.
- ⚠ **Capture the predecessor pre-image.** `seat_officeholder` closes each predecessor with an
  unguarded `UPDATE … SET term_end = p_term_start - 1` and records nothing, so the closures are
  recoverable from no file unless the migration writes them down.

---

## Housekeeping

- **Worktree:** `/c/ev-accounts-seating`, branch `feat/state-seating`, PR #1578. Commit with an
  explicit pathspec.
- **Env:** the worktree has no `.env`. Prefix commands with
  `set -a && . /c/EV-Accounts/backend/.env >/dev/null 2>&1; set +a`.
- **Steward:** jurisdiction leases are 24h and expire on their own; `state:ca` was held for the
  sourcing pass and may need re-claiming.
- **Live tracker artifact:** `https://claude.ai/artifact/68XRWM6MpNd2W6Phit4QNo` — refresh it as
  part of finishing each state (`node scripts/build-transition-dataset.mjs`, upload the three
  CSVs, update the three `datasets/*` docs **in place**). 🔴 **Its owners file is stale in four of
  its five rows and the status word is the operator's to change** — waves 4 and 5 say "Blocked"
  and blocked is 0, so the page paints two healthy waves red.
- **Step 9 is not done until a real address goes through `api.empowered.vote`.** Reasoning about a
  read path is not measuring it.
