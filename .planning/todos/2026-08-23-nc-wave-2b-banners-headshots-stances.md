# NC wave 2b — Durham banner, headshots, and local-scale stances

**Created** 2026-08-23 · **Status** decomposed and sequenced; sub-project 1 (Durham banner) designed
and approved, not yet built. Sub-projects 2 and 3 not started.
**Scope** Durham (15 seats), Asheville (7), Buncombe County (10) — 32 people total.

Waves 1–3 of the [NC deep seed](./2026-08-21-nc-durham-asheville-deep-seed.md) seated all 32 and
shipped Asheville's banner. Wave 2b is the follow-on that was deliberately deferred from waves 2 and
3: the visual and stance layers that attach to politician rows those waves created.

---

## 🔴 This is THREE independent workstreams, not one task

Each is independently shippable and independently verifiable. Do not plan them as one unit.

| # | Workstream | Size | Shape |
|---|---|---|---|
| 1 | Durham banner | small | bounded — the Asheville flow exists to read |
| 2 | Headshots, 32 people | medium | bounded per cohort, but yield is unknown until probed |
| 3 | Local-scale stances | **large** | open-ended; the piece most likely to stall |

**Order decided 2026-08-23 (Chris): banner → headshots → stances.** The first two are bounded and
independently shippable, so doing them first means wave 2b has delivered something even if stances
stall on evidence quality. A compass also reads badly beside a faceless card, so headshots want to
land before stances.

---

## Measured profile (2026-08-23 — re-verify, do not re-derive)

| Cohort | `external_id` band | People | Have photo | Have stances |
|---|---|---|---|---|
| Durham (wave 2) | `-3730001..-3730015` | 15 | **0** | **0** |
| Asheville city | `-3740001..-3740007` | 7 | **0** | **0** |
| Buncombe county | `-3740008..-3740017` | 10 | **0** | **0** |
| | | **32** | **0** | **0** |

Photo coverage was measured with the repo's own predicate, not by reading `photo_origin_url` —
`HAS_RENDERABLE_PHOTO_SQL` in `backend/src/lib/photoCoverage.ts`, which requires `p` bound to
`essentials.politicians` and `img` to a LEFT JOIN on `essentials.politician_images`. That column has
five read shapes and is polluted; do not hand-roll the check.

**Local scale is 22 topics** — `inform.compass_topic_roles WHERE role_scope='local'`, measured. The
four scopes are `federal`, `judicial`, `local`, `state`.

So the full wave is 1 banner, 32 headshots, and **up to 704 stance rows**. The stance ceiling is why
it is sequenced last.

---

## 🔴 Yield finding: an official page is not a usable photo

All 7 Buncombe commissioners have their own official portrait — `buncombenc.gov/directory.aspx?eid=`
160 and 162–166, each with a unique `documentID` (2788–2794) alongside two shared site images. On the
"does each person have their OWN page?" test this cohort scores 7/7.

**But the portraits are 200 × 279 px.** Measured on two of them. That is small enough to fail the
upscale gate, so this cohort may need local press *despite* looking fully covered.

**Consequence for sub-project 2: profile resolution, not just presence.** The existing rule is "rank a
cohort by whether each person has their own page"; this cohort shows that test passing while the
assets remain unusable. Probe dimensions during profiling and quote measured yield in usable
headshots, never in pages found.

Not yet probed: Asheville's 7, Durham's 15, and Buncombe's 3 row officers (Sheriff, Register of
Deeds, Clerk of Superior Court).

---

## Sub-project 1 — Durham banner (designed and approved 2026-08-23, not built)

Bounded. Mirrors the Asheville pass exactly; see `banner_review.md` in the essentials repo for that
entry and `docs/banner-asset-pipeline.md` for the runbook.

### 🔴 The subject constraint is now DOUBLED, and that is the whole design

Durham must differ from **two** existing banners:

| Tier | Banner | Composition to avoid |
|---|---|---|
| State, NC | Charlotte uptown skyline | close, ground-level, buildings filling the frame |
| City, sibling | Asheville — Beaucatcher Mountain | elevated view, mountains dominant |

**Both of the compositions one would otherwise reach for are spent.** A Durham downtown close-up
repeats Charlotte. An elevated-with-hills view repeats Asheville. Compare compositions in the band —
camera height, subject scale, what fills the frame — never subject nouns; that is the correction the
Asheville pass produced.

### Candidates to source, in order

1. **American Tobacco Campus** — Lucky Strike water tower and smokestack. Unmistakably Durham,
   industrial heritage, reads as a horizontal band, resembles neither existing banner. First choice.
2. Durham Bull sculpture / Durham Athletic Park.
3. Carolina Theatre.
4. Duke Chapel — **framing only, never the subject.** The pipeline requires that for university
   cities: the city or downtown is the subject and the campus is foreground or framing.

### Method

Wikimedia Commons; verify author and licence **on each File page**, never from the filename or the
API summary — Treasury Tracker transcribes those lines into public credit, so a wrong author is
published. Process to 1700 × 540 with `scripts/banners/process_banner.py`. **Certify in the 6:1
desktop band (rows 128–412 of 540), never the full frame.** Publish a production-CSS comparison with
the rejected options and both existing NC banners as baselines. Chris picks. Then upload to
`cities/durham.jpg`, wire `CURATED_LOCAL` with `state: 'NC'`, add the attribution line, log in
`banner_review.md`, open the essentials PR.

### Scope call — city only, NO Durham County banner

El Paso County earned its own because its rural geography is genuinely distinct from Colorado
Springs. Durham County is small and dominated by the city, so a second Durham image would be an
arbitrary distinction, and it would surface only in browse mode because county offices carry NULL
`representing_city`. Leave it unset rather than invent one.

### Verification

351 essentials tests, plus a three-way lookup assertion: Durham/NC resolves; a wrong-state lookup
does **not**; and Charlotte/NC still returns the state panorama, so the control fires rather than the
whole lookup being dead. Then SHA-256 the served bytes against the local file on **both** the plain
and a cache-busted URL. `cities/durham.jpg` is a new key, so no `-v2` suffix is needed — the version
rule applies to overwrites.

---

## Sub-project 2 — Headshots, 32 people (not started)

Standing rules that apply and must not be re-litigated:

- **Press, official, or public-domain only. Never social media.** The credit line is the licence test.
  Campaign photos and official rosters are acceptable.
- **Approval is a batch contact-sheet artifact, never one dialog per person.** Do not ask per cohort.
- Crop roughly one ear-height above the hair.
- Skip monochrome, judicial portraits included.
- **The gate is the upscale factor**, not a pixel floor.
- **Try local press before declaring a cohort dead.**
- The headshot guard rejects a first-name mismatch and pre-1940 homonyms. Trust it.

Profile before sourcing, and quote yield in **usable** headshots. See the yield finding above.

---

## Sub-project 3 — Local-scale stances, 22 topics (not started)

**The bar: every stance needs a CHAIR the evidence names AND a source that supports it,
independently.** If two adjacent chairs both fit, skip the row. A blank spoke is correct. An empty
compass is honest; a confabulated one is a false statement about a real person.

- Chairs are five distinct stances, **not a polarity rating**. "The least extreme option the reasoning
  supports" is a tiebreaker, not evidence — reaching for it means the row is not yet evidenced.
- **Never assume polarity.** Read each ladder from `inform.compass_stances`. Chair 1 is usually
  maximum government action, but AI Oversight and Tariffs run the other way, and Residential Zoning,
  Growth and Development Pace and Government Deference are off-axis entirely.
- Validate each payload the moment it returns —
  `py backend/scripts/validate-stance-quotes.py <payload>`. A structural pass is **not** sufficient;
  hand-check quote attribution and `reasoning`.
- `reasoning` is **voter-facing** (essentials `Citations.jsx`).
- Run `node scripts/audit-chair-evidence.mjs --check <rollback.json>` before committing any migration
  that sets a chair.
- Deleting from `inform.politician_answers` obliges a `-- @context-decision:` line in the same
  migration.
- No party inference, ever. Party lives on `races.primary_party`.
- Cap concurrent stance research at 3; seed inline.

Re-verify the 22 topic UUIDs against prod before any push.

---

## Open questions for later sub-projects

- Do Asheville's 7, Durham's 15, and Buncombe's 3 row officers have usable-resolution portraits? Only
  Buncombe's commissioners have been probed, and they failed on size.
- Does the LOCAL scale still lack an elections / voting-rights topic? That gap was recorded during the
  Colorado Springs wave and would apply to all 32 people here.
