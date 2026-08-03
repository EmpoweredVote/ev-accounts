# `office_terms.term_start` — what can be populated, and why it does not unlock the non-federal slice

The handoff frames this as the upstream fix: *"office_terms.term_start is 69 rows of 82,351 — until
that's populated, the pre-tenure defect is unmeasurable for the 11,312 non-federal rows, which are most
of the corpus."* Two things are wrong with that framing, and one migration comes out of it.

Migration **applied 2026-08-02** on operator approval: `backend/migrations/1536_federal_office_term_starts.sql`
— `office_terms.term_start` went **69 → 598** (529 from this migration, day precision).
Generator: `scripts/_tmp-gen-federal-termstart.mjs`.

## 🔴 "69 of 82,351" has a misleading denominator

**77,034 of the 82,351 rows have no government link at all** — no chamber, no government — and only
**28** of those belong to a politician who has stances. `essentials.politicians` is populated with
FEC-derived committee records (`CORREA FOR ATTORNEY GENERAL 2026; LOU`, `COMMITTEE TO ELECT …`), and
ADR 0002 phase 2 gave every one of them an `office_terms` row.

Stance-relevant office_terms rows, by government type:

| gov_type | rows | for stance politicians | term_start set |
|---|---|---|---|
| (none) | 77,034 | 28 | 0 |
| STATE | 1,794 | 1,481 | 8 |
| LOCAL | 1,663 | 585 | 0 |
| NATIONAL | 696 | 574 | 0 |
| County | 462 | 83 | 39 |
| City | 344 | 107 | 21 |
| others (School District, Village, Township, Town, federal) | 358 | 57 | 1 |

So the real target is roughly **2,900 rows**, not 82,351 — and the gap is genuine but an order of
magnitude smaller than the headline.

## 🔴 NULL is policy, not neglect

ADR 0002 makes `term_start` nullable *on purpose* (`NULL = unbounded/unknown start`) and adds
`start_precision` specifically so imprecision can be recorded honestly rather than invented: *"Racine
County's own court page says '2017 to Present'. Migration 1454 left `date_seated` NULL rather than
invent `2017-01-01`."* Existing populated rows each cite a specific fetched source. A bulk backfill
that guesses would violate the table's whole design intent.

## 🔴 `politicians.valid_from` is NOT the salvage source the ADR hoped for

ADR 0002 lists its 701 text rows as *"un-migrated `text` history worth salvaging into `office_terms` as
a separate data task."* 684 of them sit on rows with a NULL `term_start`, 190 of those for stance
politicians. But the values are dominated by placeholders:

| value | rows |
|---|---|
| `2023-01-01` | 151 |
| `2025-01-01` | 126 |
| `2024-05-01` | 79 |
| `2026-05-01` | 27 |
| `2025-05-01` | 26 |
| `` (empty string) | 9 |

January-1st and May-1st clusters at that density are conventions, not observed dates. Migrating them as
`start_precision='day'` would manufacture exact dates that were never published anywhere — the same
class of error as the composed citations. **Any salvage must assign `'year'`/`'month'` precision and be
scoped per cohort by hand.** Not done here, deliberately.

## What migration 1536 does

**529 of 705** federal office_terms rows get a day-precision `term_start` from
unitedstates/congress-legislators (fetched 2026-08-02).

- `term_start` = first day of the member's **current unbroken run in this seat's chamber**, so
  consecutive re-elections collapse into one open-ended tenure, matching ADR 0002's "`term_end IS NULL`
  means current".
- Chamber comes from **our** office row, never from the legislator record. This is what makes Shelley
  Moore Capito resolve to **2015-01-06** (Senate) rather than 2001 (House), and what separates the two
  Robert Menendezes.
- `how_started` is left untouched — the dataset says when service began, not whether the member was
  elected, appointed to a vacancy, or succeeded.
- The migration opens with a guard that aborts if any target already has a `term_start`, and closes by
  asserting the post-state count.

**Skipped, all deliberately (176 rows):** 52 candidate seats, 52 no-surname-match, 35 seats whose
chamber is not identifiable (cabinet secretaries and the Vice President — not legislators), 33
no-firstname-match, 3 state-conflict, 1 service ended 2026-07-11.

🔴 **A candidate seat is not a tenure.** `office_terms` carries `Candidate for U.S. Senate — Alabama`
rows beside real seats, and a sitting senator seeking re-election has **both**. The chamber gate happens
to catch today's cases (a sitting Rep running for Senate skips as `no-sen-service`), but that is luck: a
sitting *senator's* candidate row would match their own Senate service and be handed a `term_start` for
an office they do not yet hold again. Now excluded explicitly.

Validated read-only against production before writing: all **705** federal rows currently have
`term_start IS NULL`, **0** are already set, and **0** sit on a seat with more than one term row — so
the `office_terms_no_overlap` exclusion constraint cannot fire.

## 🔴 And it still does not make the non-federal rows measurable

This is the part worth being blunt about. The federal slice was **already** measurable — every detector
in this workstream reads congress-legislators directly. 1536 moves that knowledge into our own database,
which is worth having, but it adds **no new detection power**.

The 11,312 non-federal year-bearing stance rows remain unmeasurable, and no migration fixes that,
because **there is no term-start authority for state and local officeholders** — not in our data, and
not in any single public dataset. Closing it means per-state sourcing (legislature member directories,
county clerk rosters, municipal sites), i.e. the same per-jurisdiction work as a deep seed, at the scale
of every jurisdiction already in the corpus.

## The cheaper approximation — built, and it reports ZERO

The idea was that term data is not needed to catch this defect: a state or local officeholder cannot
have voted on H.R. anything, so flagging *any* non-federal politician credited with a federal-measure
vote should cover all 11,312 rows with no calendar at all. Built as
`scripts/_tmp-nonfederal-fedvote.mjs`; artifact `2026-08-02-nonfederal-fedvote.json`.

🔴 **The premise was too clean, and the first cut over-fired 69 → 2.** Two corrections it needed:

1. **Our own office links are incomplete.** 46 of the first 69 findings were *sitting members of
   Congress* — Tony Cardenas, Nanette Barragán, Linda T. Sánchez, Gilbert Cisneros, Celeste Maloy —
   whose `gov_type`, `chamber` and `office_title` are **all NULL**, so no government-based gate can
   tell they are federal.
2. **A non-federal officeholder may be a FORMER member of Congress.** Mike Braun is Indiana's Governor
   now and was a US Senator 2019–2025, so *"he voted against the Inflation Reduction Act (2022)"* is
   simply true. Thirteen more were governors and lieutenant governors in the same position. This is the
   mirror image of the bug that bit the term-start detector's first cut (surname matching bound LA city
   councilmembers to former members of Congress); the fix runs the other way — **any** name match
   against congress-legislators, current or historical, must ABSTAIN.

**Final: 2 candidates, and both are false positives on hand review.**

- **Jonathan D. Zlotnik** — *"voted for the Police Reform Act (H.4011/S.2820, 2020)"*. ⚠ Those are
  **Massachusetts** bill numbers. MA numbers its bills `H.nnnn` / `S.nnnn`, which is **format-identical
  to federal** `H.R. nnnn` / `S. nnnn`. No regex can separate them; only the jurisdiction can.
- **Justin Filip** — *"**Hoyle's** vote for HR 2925 … and **her** past support for Jordan Cove"* — a
  challenger's profile discussing the incumbent's record. A bare-surname possessive subject, which the
  contrastive-subject test does not catch.

**So the honest result is a negative one, and it is worth having: the impossible-vote defect appears
confined to federal legislators' own profiles.** Every one of the 39 rows in the pre-tenure queue
belongs to a member of Congress. Nothing suggests it spread into state and local rows.

⚠ **But the negative is bounded by a very generous abstain: 6,645 of 14,191 non-federal rows were
skipped** because the politician's surname matches one of ~12,700 current-or-historical members of
Congress. Precision was bought with recall. Tightening that (first name + state, rather than surname
alone) is the obvious follow-up, and until it is done "zero" means *zero among the 7,546 rows this
could judge*.
