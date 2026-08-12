# Puerto Rico government ✅ governor + legislature (2026-08-12, migration 1720)

Follows migration 1719, which gave PR its Resident Commissioner in Congress. **This is the territory's
own government** — the part that actually governs day to day, and none of it was in the database.

| | Seats | Composition |
|---|---|---|
| Governor | 1 | Jenniffer González-Colón (PNP), took office 2025-01-02 |
| Senate | **28** | 8 senatorial districts × 2 + **12 at-large** |
| House | **53** | 40 representative districts × 1 + **13 at-large** |

**A San Juan address now returns 30 officials** end-to-end: 2 district senators, 12 at-large senators,
1 district representative, 13 at-large representatives, the Governor and the Resident Commissioner.
That is genuinely how Puerto Rico is represented — it is not duplication.
`roster-diff.mjs pr` reads **28 v 28 and 53 v 53, zero findings**. All CI gates green,
`check:reachability` at baseline.

## 🔴 Things that will bite whoever touches this next

1. **The chambers are 28 and 53, NOT 27 and 51.** The Constitution sets 27 and 51, but the
   minority-representation guarantee adds seats ("por adición") when one party wins too large a share.
   Anyone "correcting" the counts to the constitutional minimums deletes two real legislators. The
   generator refuses to run if the structural invariants stop holding.
2. **SLDU and SLDL share geo_ids.** `72001` is simultaneously Senate District 1 and House District 1.
   This is the documented collision `MTFCC_DISTRICT_TYPE_GUARD` exists for — G5210 resolves only to
   STATE_UPPER, G5220 only to STATE_LOWER. **Never join districts to boundaries on geo_id alone for
   PR.** PR adds 8 more collisions to the 1,159 already tracked.
3. **`72000` is a SYNTHESIZED geo_id for the at-large seats**, carrying the whole-territory polygon
   under both G5210 and G5220. TIGER has no at-large polygon and numbers PR districts from 001. 25 of
   81 legislators are elected island-wide and genuinely represent every resident, so leaving them
   geometry-less would hide a third of the legislature from the people they serve. Synthesized ids are
   sticky — if Census ever publishes one, migrate.
4. **TIGER returns `72ZZZ` ("districts not defined") in both legislative layers.** It is a
   water/unassigned artifact, excluded explicitly by the loader. Loading it would create a district
   nobody lives in that still answers address queries.
5. **Parties are stored verbatim in Spanish** — Partido Nuevo Progresista, Partido Popular
   Democrático, Partido Independentista Puertorriqueño, Proyecto Dignidad, Independent. They do **not**
   map onto the U.S. two-party split (PNP and PPD each contain both national parties), and the
   migration's post-verify **fails** if any PR member ends up labelled Democrat/Republican.

## Deliberately NOT done

- **The 78 municipios and their mayors.** This is the big remaining piece and it needs a sourced pass,
  not a drive-by. Wikipedia's `List_of_municipalities_in_Puerto_Rico` carries **no mayor data at all**;
  the available rosters are the two *partisan* mayors' associations (Asociación de Alcaldes for PPD,
  Federación de Alcaldes for PNP), which would have to be stitched and could not be trusted without
  cross-checking against CEE results. A wrong mayor is a false statement about a real person.
  Municipio *polygons* are easy when wanted — TIGER county-equivalents, FIPS `72xxx`.
- **No headshots** for any of the 82. The Senate and House of PR publish member photos on their own
  sites; that is a normal headshot-sweep target now that the people exist.
- **No `term_end`.** PR terms run to 2029-01-01 (elections November 2028), but the seats are recorded
  open-ended, so the usual re-seating pass applies after the 2028 general.
- No other executive officers (Secretary of State — who is next in line for the governorship, PR
  having no Lieutenant Governor — Treasury, Justice, etc.).

## Unrelated finding, checked and closed

`roster-diff` flagged **TX HD-93 (Nate Schatzline)** as "we hold someone they do not list". The
chamber's own roster still lists him and all 150 TX districts have a member, so **Open States is stale
and we are correct**. No action. This is the mirror of the Birdwell case and the reason the tool prints
findings as a reading queue rather than a verdict.
