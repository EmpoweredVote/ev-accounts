# Waltham's mayor was a fabricated person — migration 1566

**Date:** 2026-08-06 · **Migration:** `1566_waltham_roster_fabricated_mayor_donahue_out_mccarthy_in.sql`
**Found by:** the roster pre-check on the post-1564/1565 re-research queue (the 1546 rule — verify the
roster before re-researching anyone on it).

---

## The finding

`essentials.politicians` seated **"Arthur Donahue"** as **Mayor of Waltham, MA**
(`external_id = -2572600001`, created 2026-06-15). He is not a Waltham officeholder. He does not appear
to be a Waltham anything.

The real mayor, **Jeannette A. McCarthy** — in office since 2004 — was **not in the database at all**.

Migration 1564 had already retired Donahue's single stance row as a fabricated citation. Its reasoning:

> "Mayor Donahue led Waltham's compliance effort with the MBTA Communities Act in 2024, submitting a
> zoning amendment plan to create a multi-family overl[ay]…"

cited to `walthampatch.com/posts/waltham-mbta-communities-zoning-compliance-2024` — a host already on the
dead-cited-hosts queue (`2026-08-04-dead-host-findings.md`).

### 🔴 Why this is a new defect class

Every prior finding in this audit is a fabricated **source**: an invented outlet, a composed path, an
article that never existed. The *subject* of the row was always a real person. Here the generation pass
invented the **officeholder** and seeded him into a top seat, then wrote a stance for him and cited it to
an invented article.

🔑 **Retiring a fabricated citation does not necessarily repair the row's subject.** A politician who
exists only because a fabricated source said so is invisible to every sweep built in this workstream,
because all of them evaluate CITATIONS against pages and never SUBJECTS against rosters. Nothing in the
citation-level tooling could have found this. Only the roster pre-check did.

---

## Evidence (fetched and read 2026-08-06, not recalled)

| Source | What it shows |
|---|---|
| <https://www.city.waltham.ma.us/1714/Mayors-Office> | Staff table lists exactly one name: "Jeannette A. McCarthy \| Mayor \| 781-314-3100". `Donahue` appears **0** times. |
| <https://www.city.waltham.ma.us/1715/About-Mayor-Jeannette-A-McCarthy> | City's own biography: "Mayor Jeannette A. McCarthy is a lifelong resident of Waltham… became Mayor of Waltham in 2004." |
| <https://www.city.waltham.ma.us/1341/City-Council> | All 15 councillors enumerated (6 at-large, 9 ward). `Donahue` occurs **0** times in the raw HTML. |
| Web search, `"Arthur Donahue" Waltham Massachusetts` | Census records, obituaries, unrelated Donahues. No officeholder, no candidate, no coverage. |

**The rest of Waltham's roster is correct and current.** All 15 councillor rows match the city page name
for name: at-large Bradley-MacArthur, Brasco, King, LeBlanc, Tzioumis, Vidal; wards LaFauci, Dunn,
Hanley, McLaughlin, LaCava, Durkee, Katz, Harris, Logan. Only the Mayor seat was wrong.

⚠ **The city migrated Drupal → CivicPlus.** The older `/city-council/pages/…` and `/sites/g/files/…`
URLs now 404, including the ones surfaced by web search. That 404 is a platform migration, **not
absence** — the live pages are the numeric CivicPlus paths. Classified before being read as evidence
(rule #2: classify every non-200).

---

## Negative control — the blast radius is one row

All **55** negatively-seeded `Mayor` office_terms nationally were listed and checked by name. Donahue is
the only unrecognisable one.

⚠ The one other that looked wrong — Brockton's **"Moises M. Rodrigues"**, who I remembered as a 2019
*interim* mayor — is **CORRECT**: he won in Nov 2025 and was sworn in 2026-01-05, Brockton's first
elected mayor of colour. **Seventeenth time a first-cut suspicion over-fired on this workstream.**
See `detector_first_cut_overfires`.

The other four cities in the same re-research queue were verified roster-complete against their own
official sites, name by name:

| City | Seats | Result |
|---|---|---|
| Carson CA | 5 | ✅ exact match, incl. Jim Dear (District 2) — genuinely seated, my suspicion was wrong |
| Alhambra CA | 5 | ✅ exact match (rotational mayor currently Maloney) |
| Lynn MA | 12 | ✅ exact match, 11 councillors + Mayor Nicholson |
| Somerville MA | 11 + mayor | ✅ exact match, incl. Mayor Jake Wilson |

⚠ `lynnma.gov` sits behind **Cloudflare on `civiclive.com`** — a plain fetch of some paths returns a
"Sorry, you have been blocked" interstitial. That is a bot block, never absence. The councillor listing
reads fine at `/city_government/citycouncil/councilors` with a browser UA.

---

## What migration 1566 does

1. **Deletes** Donahue's `office_term` (`327a6e08-9721-4f9a-bc06-653fecdb25a0`), unseating him.
2. **Deactivates** the politician row — `is_active = false`, `is_incumbent = false`, and appends an
   explanatory entry to `notes` (which is `text[]`, not `text`). **Operator ruling 2026-08-06: deactivate,
   do not hard-delete** — the row is the evidence that a fabricated person reached production.
3. **Inserts** Jeannette A. McCarthy (`external_id = -2572600017`, the next free in Waltham's scheme).
4. **Seats** her on the office Donahue vacated, with `term_start`/`term_end` **NULL**, matching all 16
   other Waltham `office_terms`. She was re-elected Nov 2023 to a four-year term, but no primary source
   for the swearing-in date was fetched, and this workstream does not assert dates it has not read.
   NULL `term_end` + `is_incumbent` = seated under the two-gate occupancy model.

Assertions: Donahue holds **zero** answers and **zero** context rows before he is touched (if that ever
fires, a fabricated person has acquired voter-facing stances and they must be retired first); the Waltham
Mayor office is singular; `-2572600017` is free; no Jeannette McCarthy already exists. Post: the Mayor
seat has exactly one occupant and it is McCarthy; Donahue holds no office anywhere; Waltham totals 16
office_terms; no stance rows created or destroyed.

**Dry run (`scripts/dry-run-migration.mjs`) passed against prod, all assertions green, rolled back.**

---

## ROLLBACK

```sql
BEGIN;

-- Unseat McCarthy and remove her.
DELETE FROM essentials.office_terms
 WHERE office_id = '34f1b48f-5689-4828-94b0-f7cb5b5abc1b'
   AND politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2572600017);
DELETE FROM essentials.politicians WHERE external_id = -2572600017;

-- Reactivate Donahue and drop the note appended by 1566.
UPDATE essentials.politicians
   SET is_active = true,
       is_incumbent = true,
       notes = NULL                      -- prior value was NULL
 WHERE id = '3eab65f7-083a-49c6-9944-1a20a5373538';

-- Re-seat him. NOTE: the office_term uuid is regenerated; the original was
-- 327a6e08-9721-4f9a-bc06-653fecdb25a0.
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, source)
VALUES ('34f1b48f-5689-4828-94b0-f7cb5b5abc1b',
        '3eab65f7-083a-49c6-9944-1a20a5373538',
        NULL, NULL,
        'backfill from essentials.offices.politician_id (ADR 0002 phase 2, migration 1459)');

COMMIT;
```

Values replaced, verbatim, for the record:

| Field | Prior value |
|---|---|
| `office_terms.id` | `327a6e08-9721-4f9a-bc06-653fecdb25a0` |
| `office_terms.office_id` | `34f1b48f-5689-4828-94b0-f7cb5b5abc1b` |
| `office_terms.politician_id` | `3eab65f7-083a-49c6-9944-1a20a5373538` |
| `office_terms.term_start` / `term_end` | `NULL` / `NULL` |
| `office_terms.source` | `backfill from essentials.offices.politician_id (ADR 0002 phase 2, migration 1459)` |
| `politicians.is_active` | `true` |
| `politicians.is_incumbent` | `true` |
| `politicians.notes` | `NULL` |

---

## Consequences for the re-research queue

* **Waltham drops from 5 emptied politicians to 4.** Donahue's owed topic (Affordable Housing,
  `669cac97-66a6-4087-b036-936fbe62efb3`) is **void, not pending** — you cannot re-research a person who
  does not exist. The 151-pair worklist becomes **150**.
* Waltham's `hasContext` chip is already `false` (flipped by 1564); this changes nothing there.
* McCarthy enters the corpus with zero answers and a NULL `last_stances_researched_at` — correctly
  reading as "nobody has looked yet" under the 1494 rule.

## Queue this opens

**A subject-level sweep has never been run.** Citation sweeps cannot see an invented person. The bounded
version — all 55 seeded mayors — is done and clean. The unbounded version, verifying every negatively
seeded councillor nationally against its city's official roster, has **not** been run and is the only
thing that would find Donahue's peers in non-mayoral seats. Operator deferred it 2026-08-06.
