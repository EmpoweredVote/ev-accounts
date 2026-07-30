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
2. ~~How much overlaps cities we already hold?~~ **ANSWERED 2026-07-30 — see the scoped work order
   below.**
3. ~~What do they want in return?~~ **ANSWERED via correspondence 2026-07-30: they said both GitHub
   repos will be free "for as long as they could keep them up."** No fee, no expectation stated.

   🔴 **That phrasing is a requirement, not just reassurance.** "As long as we can keep them up" is an
   explicit statement that continuity is not guaranteed — a small project on Ko-fi funding. It cuts both
   ways and both ways point the same direction:
   - It **strengthens** "take the data, don't take a dependency." CC0 means anything we have already
     imported is ours permanently and cannot be rescinded. That is the durable half.
   - It means we must **VENDOR the dataset, not fetch it on demand.** Snapshot the clone into our own
     storage with the commit SHA recorded, and have the importer read the snapshot. Any pipeline that
     resolves `github.com/CivicPatch/open-data` or `cdn.civicpatch.org` at run time inherits their
     uptime. That applies especially to images: rule 4 below (copy into our Storage, never hotlink) is
     now non-negotiable rather than merely preferable.
   - It also means **grab a full snapshot sooner rather than later**, even ahead of importing, since the
     cost of doing so is a shallow clone and the cost of not having one is the whole dataset.

---

## Suggested decision

Approve **item 1 only** (contacts + images for cities we already hold), as a scoped batch with the
reachability gate run either side. Defer items 2–3 until questions 1 and 2 are answered. Ask Civic Data
Tech for an API key + terms specifically to evaluate `/change_logs`, since incremental sync is the only
part of their service worth a dependency — and even then, as an input to our importer, not a runtime
call from our surfacing.

Evidence trail: `project_civicpatch_open_data_assessment` in agent memory has the full measurement
detail, including the LA parity table and the Plano/Frisco freshness test.

---

# APPROVED SCOPE — contacts + images only (operator, 2026-07-30)

Approved: enrich politicians **we already hold** with their contacts and images. Explicitly **NOT**
approved: creating politicians, creating offices, or importing the place-level 86%.

## Measured overlap — the actual job

Our municipal footprint in their 13 states is **CA, MA, TX only** (their tiers vs our coverage states).
Keyed on `districts.ocd_id` we hold **~145 places** across those three — note an earlier figure of
"LA plus two counties" was wrong, it came from the sparse `districts.city` column.

**44 cities intersect. 319 of their records: 276 with email, 223 with phone, 264 with image.**

| cluster | cities | their recs | notes |
|---|---|---|---|
| TX (Collin County belt: Plano, Frisco, McKinney, Allen, Princeton, Prosper, Celina, Anna, Lucas, Melissa, Murphy, Richardson, Fairview, Van Alstyne, Longview, Parker, Nevada, Josephine, Farmersville, Lavon, Weston, Blue Ridge, Lowry Crossing) | 23 | ~155 | **FRESH — scraped 2026-03/04** |
| CA (LA basin + SF/SJ/SD/Sac/Berkeley/Fremont/Long Beach/Pasadena …) | 20 | ~150 | 🔴 **STALE — every CA row scraped 2025-07-17/18, ~12 months old** |
| MA Springfield | 1 | 14 | **FRESH — 2026-07-11**, 13 email / 14 phone / 14 image |

🔴 **The CA half is a year old, and that is the whole risk.** Contacts are mostly office-attached
(a council email survives a member change) but a 12-month-old roster will name departed members —
exactly the SLC failure in migration 1500, where the upstream layer still listed two people who left
in January. **Do not import a CA contact/image without confirming the person still holds the seat.**
TX and MA Springfield are recent enough to import on the row's own `updated_at`.

## Execution rules for the importer

1. **Enrichment only.** Match their record to an EXISTING `essentials.politicians` row; if no match,
   skip and log. Never insert a politician or an office. A no-match is a finding, not a prompt to seed.
2. **Match on (place `ocd_id`, normalised name).** Their `jurisdiction_ocdid` / `office.division_ocdid`
   are byte-identical to our `ocd_id` where they overlap — verified on LA (16/16 names, 15/15 districts).
   🔴 But **normalised-name matching failed twice today on real people** ("Ben"/"Benjamin" Nadolski,
   "Erin"/"Erin J." Mendenhall), so a name miss must **skip and report**, never guess.
3. **Additive only, never overwrite.** Insert a `politician_contacts` row only where we have none of
   that `contact_type`; insert a `politician_images` row only where the politician has no image.
   Their data is unreviewed scraper output (~470 of 19,737 records human-checked) — it is a
   backfill for gaps, not a source of truth that displaces ours.
4. **Images: copy, don't hotlink.** Their CDN (`cdn.civicpatch.org`) is live and fetchable, but a
   third-party URL in `politician_images.url` is an availability dependency. Pull into our Storage
   bucket like every other headshot. Their licence field reads `press_use`; dataset is CC0.
   The correct-person guard still applies — it rejects first-name mismatches, and it should.
5. **Gate either side with `npm run check:reachability`** (from `backend/`, needs `DATABASE_URL`). The
   baseline is per `state|district_type`, so any accidental office/district churn shows immediately.
6. **Batch per city, not one big transaction**, so a bad city is contained and re-runnable.

## Realistic yield

Ceiling is 319 records, but after (a) dropping stale CA rows that fail a still-in-office check,
(b) skipping name misses, and (c) additive-only filtering where we already have a contact or image,
expect materially less. **TX + MA Springfield (~169 records) is the clean first batch** — fresh, and
the TX belt is where our own contact coverage is thinnest. Do CA second, behind an incumbency check.

Not started: sizing was the last open question and this answers it. The importer itself is the next
session's work.

---

## Snapshot: FULL, decided by operator 2026-07-30

"We should take a full snapshot when we take it." Agreed — snapshot everything, not just the 44
overlapping cities, since the marginal cost is small and the downside is losing a dataset that is
explicitly only guaranteed "as long as they could keep them up."

**Two halves with very different cost, and they should be handled differently:**

| half | size | where | when |
|---|---|---|---|
| **YAML + commit SHA** | 3,258 files, ~6,222 objects, small enough to clone in seconds | version it, or a tarball in object storage — record the source commit SHA either way | **now**, ahead of any import |
| **Images** | ~9,094 records carry one (46% of 19,737); LA sample was 26.6 KB, so on the order of **200–250 MB** | Supabase Storage bucket, **not git** | with the import batches; full mirror optional |

🟢 **The YAML half is the irreplaceable part, and it is the cheap one.** Their records carry BOTH
`image` (the original municipal URL, e.g. `lacity.gov/...`) and `cdn_image` (their CDN copy). So a
YAML-only snapshot preserves the ability to re-fetch headshots from the source municipality even if
`cdn.civicpatch.org` disappears. Take it first; it is minutes of work and removes most of the risk.

Do not put ~250 MB of images in the repo. For the approved batches we only need the 264 images across
the 44 overlapping cities, which is trivial; a bulk mirror of the remaining ~8,800 is insurance that
can wait and does not block anything.
