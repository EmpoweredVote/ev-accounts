# Decision: do we take Civic Data Tech up on the CivicPatch API?

**Prepared for the operator, 2026-07-30. Not yet decided.**
All numbers below were measured directly (shallow clone of `CivicPatch/open-data` at 2026-07-30, plus
live calls to `civicpatch.org/api/v1` and prod SQL), not taken from their README — which is wrong in
one material respect, noted below.

---

## Recommendation in one line

**Take the data. Do not take a dependency on the API.** Import the CC0 dataset on our schedule, into
the slice we can actually use, and treat their service as a convenience for exploration rather than
something our surfacing calls at runtime.

Confidence: high on "take the data," high on "don't depend on the API," **moderate on the sizing** —
see Open Questions.

---

## What they actually have

| | |
|---|---|
| Scale | **19,737 officials**, 3,258 municipalities, 13 states (ca co id ma mi nc nd nh nj sc tn tx wa) |
| Tier | **Municipal only.** No county, no state officials. |
| License | **CC0 1.0** — public domain, no attribution obligation, no takedown exposure |
| Fields | name, office + OCD-ID, phone, email, url, image (CDN-hosted), source_urls, start/end date |
| Absent | party, candidates, stances, campaign finance, terms rigor |
| Coverage | 3,050 of 7,091 municipalities in those states = **43%**; "fresh" 37.8% |

🔴 **Their README claims county and state tiers. Those do not exist** — every file lives under
`data/<state>/local/`. Anything scoped on the README rather than the tree will be mis-scoped.

**Fill rates:** url 94%, email 72%, phone 64%, image 46%, end_date 37%, **start_date 23%**.

**Freshness is bimodal, not uniform.** TX 913/964 and MI 875/875 fresh — but **CO 0/120 and WA 1/196**.
A state-level import must gate on freshness per row, not trust the dataset as a whole.

---

## The case for

**1. Their strength is precisely our gap.** This is the most important line in this document. Across
seven migrations today I spent most of the risk budget shuttling scarce **contact rows** between
duplicate politician records — 33 in Utah's citywide merge, 24 in the council-district repair, 11 in
the mayor merge. Contacts are the thing we are thinnest on and the thing they have most of (72% email,
64% phone). Their CDN also serves working headshots, and our headshot backlog is ~340.

**2. Roster freshness genuinely beats aggregators.** Head-to-head test: their March-2026 scrape had
**Shun Thomas** in Plano Place 7 and **Ann Anderson** in Frisco Place 1, both from **Jan 31 2026
special elections**. Wikipedia still showed the departed Holmer and Keating. Scraping official
municipal rosters directly does outperform the aggregators we currently lean on.

**3. Parity where we overlap is exact.** Los Angeles is the only city we both cover: **16/16 names
match ours, 15/15 council districts correct, and their `ocd_id` strings are byte-identical to ours** —
so a join key already exists, no fuzzy matching needed.

**4. CC0 removes the usual friction.** No attribution plumbing, no licence review, no takedown risk.
Compare the care needed around headshot provenance elsewhere.

---

## The case against, and the real constraint

**1. 🔴 Only 13.6% of records identify a seat.** This is the binding constraint. `council_district` 6.9%
+ `ward` 6.6%; the other **86.4%** are place-level "Council Member" with no seat identity.

| state | seat-identified |
|---|---|
| ca | 79.0% |
| sc | 34.5% |
| co | 32.2% |
| tx | 15.3% |
| **mi** | **4.0%** |

Our surfacing is `office_id → districts.geo_id` + `ST_Covers`. A place-level row **cannot be seated**,
so 86% of the dataset cannot enter address search as a district seat. It can only land as an
unnumbered roster.

**2. Their geo endpoint does not work.** `/people/geo?lat&long` returns
`{"jurisdiction_ocdid":"","people":[]}` — verified at LA City Hall. There is no point-in-polygon
capability to lean on even if we wanted to.

**3. "Human-verified" is aspirational.** `/leaderboard` totals **~470 records reviewed by 3–4 people**.
The vast majority of 19,737 rows are unreviewed scraper output. Name hygiene is genuinely good
(~0.7% defects, mostly false positives) — but this is scraped data, and our own standards apply.

**4. `start_date` is 23% filled.** Not a viable source for `office_terms`. Everything imported would be
`start_precision => 'unknown'`, which ADR 0002 permits but which adds no temporal value.

**5. Project maturity.** 5 GitHub stars, ~4 active reviewers, funded via Ko-fi. Fine for a data
source; thin for a runtime dependency.

---

## What "take the data" concretely means

Ordered by value per unit of risk:

1. **Contacts + images for cities we already hold.** Lowest risk — we are not creating politicians,
   only enriching existing ones on a byte-identical `ocd_id` join. Directly attacks our thinnest field
   and the headshot backlog. Start here.
2. **The ~2,700 seat-identified records** in fresh states (TX, CA, NJ). These can actually be seated,
   so they can reach address search. Requires our own dedupe discipline — see Risks.
3. **The 86% place-level remainder: don't import as seats.** At most a roster-level backfill for
   cities we have nothing for, explicitly flagged as unseated.
4. **`openstates/jurisdictions`: nothing to consume.** AGPL-3.0, and it is a *pipeline, not a dataset* —
   only 3 example YAMLs are committed, `jurisdictions/` does not exist. Worth watching, because a
   canonical OCD-ID ↔ GEOID ↔ population crosswalk is what our synthesized-slug problem needs.

---

## Risks specific to us, learned the hard way today

Seven migrations this session were all cleaning up **duplicate officeholder records created by
well-intentioned seeding**. An import of 19,737 municipal officials is that same risk at scale.
Non-negotiables for any importer:

- **Import into `office_terms`, never a "current" column.** Standing rule; the WI Supreme Court handoff
  flipping on its own date is the payoff.
- **Dedupe by structure, not by name.** Name matching failed twice today on real people —
  "Ben"/"Benjamin" Nadolski and "Erin"/"Erin J." Mendenhall. The reliable detector is
  `count(offices) > count(distinct occupants)` per seat, plus the end-to-end
  *"does a point in this district return a councilmember?"* probe now wired into CI.
- **Never write a place-level row as a district seat.** That is what produced Utah's 86%-analogue mess.
- **Run `npm run check:reachability` before and after every import batch.** The baseline is per
  `state|district_type`, so a bad import shows up as a new bucket immediately.
- **Do not trust their `name`/roster attributes as display truth.** Their upstream sources go stale —
  SLC's own GIS layer still names two departed councilmembers (migration 1500).

---

## Open questions I could not settle

1. **API rate limits / terms.** No rate-limit headers on public endpoints, no published quota. `/summary`,
   `/change_logs` and `/pipeline_runs/issues` require auth we do not have. If we want their **change
   feed** — the genuinely useful thing for incremental sync — we need to ask for a key and terms.
2. **How much of the seat-identified 2,700 overlaps cities we already hold?** Determines whether item 2
   is new coverage or duplicate risk. Needs a proper join, not the LA spot-check.
3. **What do they want in return?** They offered access; there is no stated expectation. Worth clarifying
   before we depend on anything, especially as we would be taking CC0 data and giving nothing back.

---

## Suggested decision

Approve **item 1 only** (contacts + images for cities we already hold), as a scoped batch with the
reachability gate run either side. Defer items 2–3 until questions 1 and 2 are answered. Ask Civic Data
Tech for an API key + terms specifically to evaluate `/change_logs`, since incremental sync is the only
part of their service worth a dependency — and even then, as an input to our importer, not a runtime
call from our surfacing.

Evidence trail: `project_civicpatch_open_data_assessment` in agent memory has the full measurement
detail, including the LA parity table and the Plano/Frisco freshness test.
