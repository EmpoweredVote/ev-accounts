# The six remaining finance splits — adjudicated 2026-10-09

Follow-on from `CC_0211` / `CC_0212`. Those two retired 11 archived duplicate rows and recovered the
campaign finance stranded on them (Jehlen 3,649 contributions, DiDomenico 8,598, Decker 6,926,
Rogers 2,783). The sweep behind them found **170 inactive rows sharing a first and last name with an
active row, 9 of which hold contributions.** Four are done. These are the remaining six.

**Status 2026-10-09, after `CC_0213` and `CC_0214`:** attribution is fixed on all seven affected rows,
and **Hurtado, Dutra and Dixon now hold their own confirmed finance on their canonical rows.** Their
duplicate rows are deliberately **kept, not retired** — they still hold the disputed buckets.
**John Fleming is the only one still needing a decision, and that decision is now one answer wide**
(see the measured overlap below). The two Indiana leads stay unruled.

## 🔴🔴 THE HEADLINE: FIVE OF THE SIX MUST NOT BE MERGED

**Merging them would have published other people's donations on a real politician's page.** The
money on those rows does not belong to the person named on them.

`confirm-cal-access.ts` matched CAL-ACCESS committees to politicians **by surname**, and attached
every same-surname committee it found to one row. The rows became surname buckets. Measured, with
the committee's own appended forename against the row's forename:

| Row (all `is_active = false`) | Committee name says | Contributions | Dollars |
|---|---|---|---|
| Gil Hurtado | **MELISSA**, ESMERALDA | 476 | $3,441,162 |
| David Patterson | **JOE** ×3 | 1,418 | $2,337,165 |
| Arthur Dixon | **DIANE** ×5, RONDA | 1,746 | $1,885,399 |
| Fernando Dutra | **JOHN** | 1,631 | $1,599,020 |
| John M. Erickson | BRIAN | 323 | $120,037 |
| Angie Reyes English | KEN | 167 | $93,652 |
| Bryan "Bubba" Fish | JONATHAN | 9 | $34,649 |

Melissa Hurtado, Joe Patterson, Diane Dixon and John Dutra are all real California legislators.
**Every one of these is marked `confirmed_by: confirm-cal-access.ts`, not `--ambiguous`.**

Gil Hurtado's row is the clearest case: **24 committees belonging to at least seven different
Hurtados** — Melissa (state senator), Esmeralda, Jewel, G. Sylvia, Ricky, Jaime and Gil — of which
Melissa's three Senate committees hold 2,044 of the 2,061 contributions. Arthur Dixon's row holds 43,
including committees named for the **city** of Dixon ("DIXON CITY COUNCIL", "DIXON UNIFIED SCHOOL
DISTRICT", "BOGUE FOR DIXON CITY COUNCIL") — the surname is also a place name.

🟢 **No voter sees any of this today: all seven affected rows are inactive.** The harm would have been
created by the merge, not by the bug. That is the whole point.

### ⚠ TWO FALSE TRAILS, BOTH WORTH KEEPING

1. **"The politician's forename does not appear in the committee name" is a USELESS predicate.** Most
   CAL-ACCESS committees are named `SURNAME FOR OFFICE YEAR` with no forename at all, so that test
   flags **"NEWSOM FOR CALIFORNIA GOVERNOR 2018" on Gavin Newsom** — and ~$13M of other perfectly
   correct attributions (Muratsuchi, Strickland, Gipson, Irwin, Caloza, Lackey, Bryan, Solache…).
   ▶ The only reliable signal is an **explicit forename that CONFLICTS**, taken from the `;`/`,` tail.
2. **A middle name in `full_name` fakes a conflict.** `KAREN` against "Karen Ruth" Bass, `JOHN`
   against "John M." Erickson, `AMY` against "Amy Thomas" Howorth, `HOLLY` against "Holly J."
   Mitchell, `JANET` against "Janet Keo" Conklin — all five correct, all five flagged until the
   comparison allowed a leading-forename match.

An earlier draft of this note reported 2,614 disagreements corpus-wide. **That number is wrong** and
came from predicate (1); the defensible figure is the table above.

## ▶ THE ONE GENUINE MERGE: JOHN FLEMING — needs a decision, not a migration

| | `a750bce8` (active) | `8be7e981` (inactive) |
|---|---|---|
| seat | **Treasurer, Louisiana** (open term) | Candidate for U.S. Senate — Louisiana, `2024-12-13 .. 2026-06-27` |
| stance answers | **15** across 2 seasons | **20** across 2 seasons |
| finance | none | `fec_senate:S6LA00318` |
| photo origin | none | `unitedstates.github.io/images/congress/225` (a congressional portrait) |

**Identity is settled, two sources.** `treasury.la.gov/about/meet-the-treasurer` names "John Fleming,
MD" as Treasurer; Ballotpedia's "John Fleming (Louisiana)" records the Treasurer tenure (2024–),
the 4th Congressional District service, and that **he lost the Republican Senate primary runoff on
2026-06-27** — which is exactly the `term_end` on our inactive row. One man: US Rep → Senate
candidate → State Treasurer.

🔴 **This is NOT the CC_0211/CC_0212 shape and must not be done the same way.** Those retired rows
held *nothing*. This one holds **20 stance answers across two seasons**, against an active row that
holds 15. A merge has to decide what happens where both rows answer the same topic in the same
season, and Season 1 is closed — `inform.closed_season_is_immutable()` will refuse, and the
`inform.allow_closed_season_write` hatch is legitimate only for re-pointing `politician_id` without
touching content ([[reference_duplicate_name_guard_predicate]], the `CC_0186` precedent).

**Open question for the operator: what happens to an overlapping (topic, season) pair?** Nothing
should be guessed here.

### ✅ THE OVERLAP IS MEASURED (2026-10-09) — the decision is one row, not fifteen

The two rows overlap on **15 (topic, season) pairs — every answer the active row holds.** The active
row adds nothing the inactive row lacks. **10 agree. 5 disagree:**

| Season | Topic | Active (Treasurer) | Inactive (Senate candidate) |
|---|---|---|---|
| 1 (closed) | `deportation` | 5 | 4 |
| 1 (closed) | `misinformation` | 4 | 5 |
| 1 (closed) | `same-sex-marriage` | 4 | 5 |
| 1 (closed) | `school-vouchers` | 4 | 5 |
| **2 (open)** | `same-sex-marriage` | **4** | **5** |

🟢 **14 of the 15 overlaps sit in CLOSED Season 1, so they are not editable anyway** — the active
row keeps those values and Season 1 keeps asserting what it was evidenced against. **Exactly ONE
contested pair is in an open season:** Season 2 `same-sex-marriage`, 4 against 5.

The inactive row also holds **5 answers the active row does not**: `campaign-finance`, `childcare`,
`housing`, `tariffs` (Season 1) and `housing` (Season 2).

▶ **So the operator question reduces to two small ones:**
1. Season 2 `same-sex-marriage` — keep the Treasurer row's **4**, or take the Senate-candidate row's **5**?
2. Carry the 5 inactive-only answers across, or leave them behind?

⚠ No value is `0`, so no blank is involved and the `@zero-scope` question does not arise here.

## The two Indiana leads — weak, left alone

- **Michael Thompson** `b01acc58` — `indiana:8112`, committee "Patriots for Mike Thompson",
  33 contributions / $13,035. The active namesake holds no seat and 23 contributions of its own.
  An extremely common name; no evidence either way. **Not ruled.**
- **Jessica Mccormick** `2f1440e0` — `indiana:7997`, committee "McCormick for Indiana",
  2 contributions / $1,594. The active namesake is Councilor, District 16. "McCormick for Indiana"
  reads like a statewide committee, which a district councillor is not. **Not ruled.**

## ✅ ATTRIBUTION FIXED — `CC_0213`, applied 2026-10-09

Detached 159 cal_access sources from the seven buckets and repointed 9 to their real owners.
Published contributions now: Gil Hurtado **0** · David Patterson **0** · Dutra **0** · English **0** ·
Fish **0** · Dixon **11** (`fec_house:H6CA34302` only, out of scope) · Erickson **981** (his own) ·
**Melissa Hurtado 1,577** · **Joe Patterson 1,418**.

The detach is `research_status = 'disputed'`, which `campaignFinanceService.ts:37` excludes from every
read. No contribution row was touched; one `UPDATE` back to `'confirmed'` reverts it.

🟢 **The harm is gone either way now.** Those rows publish nothing, so leaving them unmerged costs a
voter nothing. The merge is tidiness; the attribution was the harm.

## ✅ IDENTITY SETTLED FOR ALL THREE — `CC_0214`, applied 2026-10-09

The section this replaces said the three merges were blocked on **thin identity**, and told the next
session to read the CA SoS roster PDF. The PDF was read. **It was needed for one of the three, and
the other two were already settled inside this database.**

| Pair | What settled it | Needed the PDF? |
|---|---|---|
| Gil Hurtado `1a6190c0` → `75f11f44` | Roster lists `Council: Gil Hurtado, Al Rios, Maria del Pilar Avalos` under **City of South Gate**; the canonical row holds that exact seat (geo_id `0673080`) | **Yes** — and it was corroborated, see below |
| Fernando Dutra `bf91e362` → `99929a73` | **`CA_0185`, 2026-09-23**, already wrote on the inactive row: *"inactive scraped twin of 99929a73 … former Whittier D4 member, left 2026-04-28"* | **No** |
| Arthur Dixon `b8e3727a` → `76d1140a` | FEC candidate `H6CA34302` reads `candidate_first_name = ARTHUR`, `candidate_last_name = DIXON`, HOUSE, California **district 34**, committee **ARTHUR DIXON FOR CONGRESS** (`C00903773`); `ballotpedia.org/Arthur_Dixon` — the canonical row's own origin — records the same candidacy, lost primary 2026-06-02 | **No** |

### 🔴🔴 THE IDENTITY EVIDENCE WAS ALREADY IN THE ROW, ONE TABLE OVER

This note asserted that the inactive rows came from a **statewide** roster and so "name no city".
They each carry an `essentials.politician_contacts` row of `contact_type = city_website`:

- Gil Hurtado's inactive row → `https://www.cityofsouthgate.org`
- Fernando Dutra's inactive row → `https://www.cityofwhittier.org`

▶ **Before sourcing an external document to identify a row, read every table that already points at
it.** The city was in `politician_contacts` the whole time, and a 5.6 MB PDF was fetched to learn it.

### 🔴 TWO CLAIMS IN THIS FILE WERE WRONG ABOUT DIXON

1. *"It cannot settle Dixon — his inactive row never cited the roster, or any source."* Its `source`
   column reads `federal_2026_bulk_seed`, and it holds a `confirmed` FEC source.
2. *"his 11 remaining contributions come from an FEC CA-34 committee whose attribution is itself
   unverified."* The attribution is an **FEC candidate-ID match that names him in full** — the
   strongest evidence of the three, not the weakest. Dixon was the easy one.

⚠ **THE ROSTER IS AUTHORITATIVE FOR THE CITY AND STALE FOR THE SEAT.** The 2025 edition still lists
Fernando Dutra on the Whittier council. He lost on 2026-04-14 to Aida Susie Macedo. `CA_0185` hit the
same trap with George Dotson and says so. Read the edition date before treating the roster as current.

### What `CC_0214` did, and what it deliberately did not do

Re-pointed the **8 `confirmed` finance sources** to the canonical rows — Hurtado 4, Dutra 3, Dixon 1.
Every one names its owner in full (`HURTADO FOR CITY COUNCIL 2020; GIL`, `DUTRA FOR CITY COUNCIL
2026; FERNANDO`, `ARTHUR DIXON FOR CONGRESS`).

🔴 **THE PRIZE WAS MUCH SMALLER THAN THIS FILE IMPLIED. Measured before the migration:**

| Canonical row | Confirmed sources moved | Contributions they carry |
|---|---|---|
| Gil Hurtado | 4 | **0** |
| Fernando Dutra | 3 | **0** |
| Arthur Dixon | 1 | **11 — $12,750** |

Two of the three merges move **no money at all**: those people's own committees hold no contribution
rows in this database. ▶ **A $12.2M "split" figure was a LEAD about a bucket, never a loss figure for
the person.** The $12,750 on Dixon is the whole voter-facing gain.

🔴 **THE THREE INACTIVE ROWS WERE KEPT, NOT RETIRED** — against the `CC_0211` / `CC_0212` pattern.
They still hold **72 `disputed` sources** (15 / 14 / 43). `politician_sources.essentials_politician_id`
is NOT NULL and `filed_report_summaries` holds a RESTRICT FK, so deleting a row forces its sources
either **onto a live politician** — re-creating the exact harm `CC_0213` removed — or **out of
existence**, which destroys `CC_0213`'s one-UPDATE revert path. Nothing is gained by the delete: an
inactive row publishes nothing. ▶ Retire them once the disputed buckets are themselves adjudicated.

🟢 All five CASCADE / SET NULL FKs measured **zero** on all six rows, and the migration asserts it, so
a later session inherits a measured zero instead of an assumption.

🟢 **A NEGATIVE CONTROL WAS RUN BEFORE APPLYING.** One `disputed` bucket source was shoved onto the
live Dixon row inside a transaction; the gate raised *"1 non-confirmed sources reached a LIVE
politician"* and the tamper rolled back. The guard that matters was watched failing first.

## ▶ WHAT IS STILL OPEN

1. **John Fleming** — the one genuine merge. Blocked on the operator's season decision; the overlap is
   now measured, see that section above.
2. **The disputed buckets themselves** (72 sources across the three rows, plus the other four rows
   `CC_0213` touched). Adjudicating them is what unblocks a real retirement.
3. **Hurtado's and Dutra's own contributions were never ingested.** Their committees exist as sources
   and hold zero rows. That is a CAL-ACCESS ingestion gap, not a merge problem.
4. The two Indiana leads, still unruled.

### ⚠ One item from the old "recommended order" is already done

It said the real defect is in `confirm-cal-access.ts` and should be fixed. **That script no longer
exists** — it was deleted on 2026-09-23. A CI job guards its return:
`backend/scripts/check-cal-access-predicate.mjs`, wired as **"cal-access predicate tripwire"** at
`.github/workflows/ci.yml:340`, which fails if the file comes back without a replaced predicate.
The rest of that order still holds: **fix attribution first, merge second** — detaching is reversible
and invisible, publishing is neither.
