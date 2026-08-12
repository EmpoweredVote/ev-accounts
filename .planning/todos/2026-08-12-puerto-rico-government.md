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
- ~~**No headshots** for any of the 82~~ — **✅ CLOSED 2026-08-12, migration 1723. All 82 imported,
  a clean sweep**: Governor 1/1, `STATE_UPPER` 28/28, `STATE_LOWER` 53/53. Gate proved to fire, dry-run
  rolled back and confirmed reverted, applied, re-applied for idempotency (`INSERT 0 0 / UPDATE 0`).
  `check:occupancy` and `check:reachability` both green (DEAD_GEOGRAPHY even improved 20 → 19).
  See "How the sweep actually went" below.
- **No `term_end`.** PR terms run to 2029-01-01 (elections November 2028), but the seats are recorded
  open-ended, so the usual re-seating pass applies after the 2028 general.
- No other executive officers (Secretary of State — who is next in line for the governorship, PR
  having no Lieutenant Governor — Treasury, Justice, etc.).

## ✅ How the sweep actually went (migration 1723 — applied as 1722, renumbered after a
## parallel session collided on that number; see the file header, 2026-08-12)

**Sources — both answered a plain fetch, no browser needed.**
- **House:** `camara.pr.gov` is WordPress and exposes its roster as the custom post type
  `representantes_team` — `/wp-json/wp/v2/representantes_team?per_page=100` returns **exactly 53**
  with a `featured_media` id per member. Resolve those through `/wp-json/wp/v2/media?include=`.
  43 members' portraits are ~1900×2560; **10 are `overN.png` at a uniform 287×417** — that uniform
  size looks exactly like a template asset and is **not**: all 10 are genuine individual Capitol
  portraits, just downsized on upload. Checked by eye, do not re-litigate.
- **Senate:** `senado.pr.gov/senadores` (no trailing slash; `/index.cfm?module=senadores` is a 404).
  Cards carry `alt="foto de Hon. <formal name>"` — a free second factor. Files are 500×500 webp.
- **Governor:** **`fortaleza.pr.gov` publishes NO biography page** — that is a verified negative, not
  a crawler failure: the sitemap has 384 URLs of which only 20 are not press releases. Her portrait
  came from her service as Resident Commissioner: bioguide **G000582**, looked up in
  `congress-legislators` (never guessed), public domain, U.S. House Office of Photography.
  🔴 A Commons file `Jenniffer_González_Colon_Portrait.png` (4500×5625) is *current* and better, but
  is credited to user "PoliticsPR20" as **"own work"** — Chris ruled to take the verifiable
  U.S. House file instead. Revisit only if a real licence appears.

**🔴🔴 THE TWO-SURNAME WARNING BELOW IS REAL AND IT CAUGHT ME MID-SWEEP.** A token-overlap search of
the House media library for higher-res originals proposed `rep-roberto-lopez-roman` for **Wilson J.
Román López** and `rep-jose-aponte-hernandez` for **José Hernández Concepción**. All four are sitting
representatives; the surnames simply collide or reverse. Both were rejected on sight. **Any scoring
scheme that counts shared surname tokens will pair the wrong people in this cohort.** Only 2 of 4
proposed upgrades were genuine (Ricardo "Chino" Rey Ocasio, Ángel Morey Noble) — both confirmed by
putting the two images side by side, which is the only check that worked.

**Matching that did work:** require EVERY token of our name to appear in the roster entry, demand a
UNIQUE hit within the chamber, and check party independently. That resolved **74 of 81**. The other 7
are pure-nickname cases and were resolved individually on each member's own profile page:
| ours | roster | independent evidence |
|---|---|---|
| Gaby González | Héctor Gabriel González López | "Distrito de Arecibo" = SD 3 |
| Rafy Santos | Rafael Santos Ortiz | "Distrito de Guayama" = SD 6 |
| Wandy Soto | Wanda M. Soto Tolentino | "Distrito de Humacao" = SD 7 + nickname "Wandy" |
| Javy Hernández Ortiz | Luis Javier Hernández Ortiz | Por Acumulación + nickname "Javy" |
| María de Lourdes Santiago Negrón | María De L. Santiago Negrón | Por Acumulación |
| Josian Santiago Rivera | José A. Santiago Rivera | Por Acumulación |
| Cheíto Hernández | José Hernández Concepción | "Distrito: 3 - San Juan" |

**The camara profile pages state `Distrito: N - Municipio` and the senado ones state
`Distrito de <Municipio>` or `Por Acumulación`** — a district oracle for the whole chamber. All 81
were re-verified against it: 78/81 clean, the 3 misses were my own regex (`ü` missing from a
character class; "Distrito Humacao" without the "de"). **Senatorial districts are named by their head
municipality:** 1 San Juan, 2 Bayamón, 3 Arecibo, 4 Mayagüez-Aguadilla, 5 Ponce, 6 Guayama,
7 Humacao, 8 Carolina.

**🔴 CROPPING: "largest face wins" IS WRONG and shipped two bad crops before the contact sheet caught
them.** Haar's biggest box was a false hit on Ensol Rodríguez's clasped hands (926px, cy/h=0.59) and
on the flag behind Estrella Martínez Soto (cx/w=0.85). In a posed portrait the head is upper-centre —
**score position as well as size** and let a smaller, better-placed box win. Second bug in the same
pass: when the ideal crop runs off an edge, **shrink the box, never clamp its position** — clamping
slides the face off its mark. After both fixes, face-height/frame-height across all 82 measures a
median 0.333 with no outliers.

**✅ Wandy Soto's party — FIXED 2026-08-12, migration 1725** (found here, fixed separately: a party is
a factual claim about a real person and does not belong in a photo import). She was `Partido Popular
Democrático`, she is **`Partido Nuevo Progresista`**. Four agreeing sources: the senado.pr.gov roster
card; her profile page (states PNP twice, zero PPD); the **2024 general result for senatorial district
VII — Wanda Soto Tolentino (PNP) 60,403, re-elected alongside Luis Daniel Colón La Santa (PNP) 59,032**,
so the district genuinely returns two PNP senators; and her bio's "entró en Minoría" in 2020, which is
consistent with PNP under that term's PPD majority.

**The aggregate is what made it certain.** The 28th Senate was elected **PNP 19 / PPD 5 / PIP 2 /
Proyecto Dignidad 1 / independent 1**. We held PNP 18 / PPD 6 — this one row reconciles both exactly.
The House was already clean (PNP 36 / PPD 13 / PIP 3 / PD 1 = 53, matching the camara taxonomy).

**🔴 THE REMAINING DIFFERENCE IS NOT AN ERROR — DO NOT "FIX" IT.** We hold **two** senators as
`Independent` (Joanne M. Rodríguez Veve, Eliezer Molina Pérez) where the election result says PD 1 +
Ind 1. Rodríguez Veve was **elected under Proyecto Dignidad but sits as an independent**:
senado.pr.gov says "Senadora por Acumulación Independiente" twice on her page with no mention of
Dignidad, and her Wikipedia article gives her current status in this Senate as Independent. That is
**party-elected-under vs current affiliation**, and our column holds the latter. Both values are right.

## 🔴 Guard notes for this cohort (kept — still true)

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

## Still open after 1723

- **The 78 municipios and their mayors** — unchanged, and still the big remaining piece. See the
  sourcing caveat above: no non-partisan roster was found, and a wrong mayor is a false statement
  about a real person.
- ~~**Wandy Soto's party**~~ — ✅ fixed, migration 1725 (see above).
- **No `term_end`** on any of the 82; the re-seating pass is still due after the November 2028 general.

## Unrelated finding, checked and closed

`roster-diff` flagged **TX HD-93 (Nate Schatzline)** as "we hold someone they do not list". The
chamber's own roster still lists him and all 150 TX districts have a member, so **Open States is stale
and we are correct**. No action. This is the mirror of the Birdwell case and the reason the tool prints
findings as a reading queue rather than a verdict.
