# WA 147-legislator stance sweep — tooling

Research tools for seating Washington state legislators on compass ladders from their legislative
record. Written during the sweep that began 2026-08-15; they encode a number of failures that are
cheap to repeat.

Run the Python from anywhere with `py`; run the `.mjs` from `backend/` so `pg` resolves:

```bash
cd backend && set -a && source .env && set +a && node --dns-result-order=verbatim scripts/wa-sweep/wa_next.mjs
```

## The loop

1. **`wa_next.mjs`** — ranks every instrument by how many STILL-UNCOVERED seated legislators it would
   unlock, querying coverage live so it never goes stale.
   ⚠ It ranks by **reach, not evidentiary quality**. SB 5558 topped it once and turned out to move
   only comprehensive-plan update deadlines — it reaches no chair at all. Rank to choose where to
   look; always read the instrument.
2. **`wa_profile.py "Ed Orcutt"`** — one legislator's primary sponsorships in full (strongest single
   evidence) plus co-sponsorships bucketed by topic.
3. Read the bill text. Session law if enacted:
   `https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/{House,Senate}/<n>.SL.pdf`
   (substitutes are `<n>-S.SL.pdf`; introduced bills are under `House%20Bills`/`Senate%20Bills`;
   joint resolutions under `Senate%20Joint%20Resolutions`). Read the **enacted text**, never the title.
4. **`wa_cohort.py "HB 1217"`** — everyone among the seated 147 who sponsored it, by member ID.
5. **`wa_screen_cohort.py "HB 1217" rent`** — per-member screen for a DIFFERENT instrument that would
   evidence a different chair. Required before any cohort write.
6. **`wa_audit_sponsors.py "SB 6346:Senate%20Bills/6346.pdf"`** — compare the web service's sponsor
   list against the list printed on the bill. Run it before every cohort write. The service is the
   index's only source and it **under-reported SB 6346 by one member** (the enrolled act names 27
   sponsors, the service returned 26), which cost Adrian Cortes his row until migration 1776.
7. Generate the migration from the cache rather than hand-typing rows. `_example_generator.py` is a
   working template (migration 1769): pre-checks, split cohorts, content guards, gate invariants.

## Caches

`%TEMP%/ev-stance-cache/wa-leg/` — `sponsorship-index-full.json` (3,411 bills), `member-link.json`
(147/147 linked, 0 ambiguous), `bills/*.json`, `year-*.xml`, `passed.xml`.
**Survives /clear. Do not rebuild** — the full index takes ~20 minutes.
Rebuild only with `wa_sponsor_index_full.py`, then `wa_link_members.mjs` to relink.

## Lessons these tools encode

- **Identity is the member ID, never a surname.** The DB holds an *Elizabeth* Fitzgibbon with her own
  answers alongside Joe. And linkage matches on **name only, never name+chamber** — Emily Alvarado
  sponsored EHB 1217 from the House and sits in the Senate now, so a chamber-keyed match silently
  drops the bill's prime sponsor.
- **Every first-cut keyword over-fires.** Five confirmed: `rent` matched pa**rent**al and
  pa**rent**ing; `lease` matched re**lease**; `reparation` matched p**reparation** (twice, making a
  chair look reachable when it is not); `inclusionary` matched special-education "inclusionary
  practices". Anchor with `\b` before believing any hit.
- **Index introduced bills, not just enacted ones.** Enacted-only gives a median of 13 sponsorships
  for everyone and leaves minority-party members near-empty for reasons unrelated to their records.
  The full index gives D median 166 / R median 78.
- **Instrument choice silently biases coverage.** After two instruments the corpus was 35 D / 0 R;
  after three it was 60 House / 1 Senate. Neither was about research quality. Check party and chamber
  spread before picking the next one.
- **Escape apostrophes in generated SQL.** `T'wina Nobles` terminated a `RAISE EXCEPTION` literal and
  failed a whole migration to parse.
- **Leadership is unresearchable this way.** Jinkins (Speaker) has 26 sponsorships, all procedural;
  Stokesbary (Minority Leader) has 2. They need a different source class entirely.

## Related

- `backend/data/stance-research/COMPASS-LADDER-TROUBLE-SPOTS.md` — where the ladders could not be
  used as written, with the exact clause and what was in the record.
- `backend/data/stance-research/compass-topics-reference.md` — the generated, authoritative ladder
  text. Regenerate with `scripts/gen-compass-topics-reference.mjs`; never hand-edit.
