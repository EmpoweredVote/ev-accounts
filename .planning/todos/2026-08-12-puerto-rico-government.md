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
- **No headshots** for any of the 82 — verified, not assumed: `STATE_EXEC` 0/1, `STATE_UPPER` 0/28,
  `STATE_LOWER` 0/53. Only the Resident Commissioner has one (Bioguide, migration 1719). This is now
  the single largest headshot gap in the database. See the sweep notes below before starting it.
- **No `term_end`.** PR terms run to 2029-01-01 (elections November 2028), but the seats are recorded
  open-ended, so the usual re-seating pass applies after the 2028 general.
- No other executive officers (Secretary of State — who is next in line for the governorship, PR
  having no Lieutenant Governor — Treasury, Justice, etc.).

## 🔴 Before running the headshot sweep on these 82

Read this first; the existing sweep's guards are tuned for a population these people are not.

- **NONE of the federal shortcuts apply.** These are not members of Congress, so
  `bioguide.congress.gov/photo/{id}.jpg` does not exist for them — that worked only for the six
  territorial delegates in migration 1719. Sources are the chambers' own sites (`senado.pr.gov`,
  `camara.pr.gov`) and `fortaleza.pr.gov` for the Governor. Render-vs-fetch is per-site.
- **🔴 THE FIRST-NAME GUARD IS WEAK AGAINST SPANISH NAMING.** These names carry two surnames
  (paternal + maternal). `María de Lourdes Santiago Negrón` and `Josian Santiago Rivera` are two
  different senators who share "Santiago"; `Adrián González Costa`, `Gaby González` and the Governor
  `Jenniffer González-Colón` are three different people sharing "González". A guard that compares a
  single surname, or that treats the last token as *the* family name, will pair the wrong people.
  Assert on the FULL name and build a contact sheet — this is the highest wrong-face-risk cohort in
  the database, and the contact sheet has caught something in every wave including a wrong person.
- **Diacritics: NFD combining marks must be DELETED, not replaced with a space**, or `Muñoz` becomes
  `mun oz`. This bit once already in `roster-diff.mjs`; the fix and reasoning are in that file.
- Resolve people by `external_id` (band `-72xxxxx`: Governor `-7200001`, senators `-721xxxx`,
  representatives `-722xxxx`) or by `office_current_holder`, **never by name** — searching these
  surnames returns large volumes of FEC ALLCAPS committee junk.
- All 82 already have `politicians.is_vacant = false`, so they are visible to the headshot worklist
  (the NULL defect from migration 1715 is not repeated here).

## Unrelated finding, checked and closed

`roster-diff` flagged **TX HD-93 (Nate Schatzline)** as "we hold someone they do not list". The
chamber's own roster still lists him and all 150 TX districts have a member, so **Open States is stale
and we are correct**. No action. This is the mirror of the Birdwell case and the reason the tool prints
findings as a reading queue rather than a verdict.
