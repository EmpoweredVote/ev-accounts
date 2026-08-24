# NC wave 2b — Durham banner, headshots, and local-scale stances

**Created** 2026-08-23 · **Status** sub-project 1 (Durham banner) shipped, essentials #101 merged.
**Sub-project 2 (headshots) DONE 2026-08-23 — 31 of 32 imported and verified.** Sub-project 3
(local-scale stances) not started.
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

Correction, measured 2026-08-23: the directory range is `eid=160–166` **inclusive — seven entries**,
not "160 and 162–166". Every one of the seven measures 200 × 279, and two positive controls confirm
that is the asset rather than a server-side transform: the shared images on the same pages return
350 × 100 and an SVG, and the same CMS serves 800 × 800 news photos.

## Sub-project 2 RESULT — 31 of 32 imported (2026-08-23)

**The gate is the upscale factor on the FACE crop, not the frame** — `600 / crop_width` after the
4:5 crop that ships. The frame figure overstates quality on any environmental shot. Two Buncombe
sheriff photos prove it: a 2500 × 1479 parade photo scores ×0.51 on the frame and is unusable (he is
handing out candy, looking down), and an 800 × 724 full-body shot in front of flags scores ×1.04
with a face barely 100px wide. The face-crop figure was worse than the frame figure for all 32.

| Cohort | People | Source that worked | Face-crop gate |
|---|---|---|---|
| Durham county commissioners | 5 | `dconc.gov/Images/DCo-<Name>-*.jpg`, **drop `?Medium`** | ×0.90 – ×1.16 |
| Asheville city council | 7 | `ashevillenc.gov` `<Name>_1000x500.jpg` | ×1.50 |
| Durham city council | 7 | `durhamnc.gov` `ImageRepository?documentId=` | ×1.50 – ×1.81 |
| Buncombe commissioners | 7 | **`buncombedems.org/elected-officials`** | ×0.69 – ×1.23 |
| Row officers | 5 | five different hosts, see below | ×0.56 – ×1.95 |
| Refused on licence | 1 | Sharon A. Davis — see open items | — |

Row officers, one host each: Birkhead `durhamsheriff.com` ×0.59 · Miller **`ncsheriffs.org`** ×0.56 ·
Christy `christyforclerk.com` ×0.84 · Reisinger `drewfordeeds.org` ×0.76 · Thompson
**Ballotpedia raw path** ×1.95.

### Reusable findings

- 🔴 **A county-party roster can beat the county's own site.** `buncombedems.org/elected-officials`
  serves a name-captioned portrait per commissioner at 800 × 1115 — four times the county's
  200 × 279 — and converted a cohort already written off as press-only into seven clean rows. Try the
  county-party roster **before** local press in any county wave. Caveat: it exists because this board
  is all-Democrat, so it is not a general source and it introduces the same asymmetry as a
  challenger-photo gap.
- 🔴 **Ballotpedia serves the ORIGINAL, not only the 200 × 300 thumb.** Drop `thumbs/200/300/` from
  `s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/<Name>.jpg` for the raw upload — Sharon
  Davis 200 × 300 → **5533 × 8300**. This corrects the older note that the thumb was all that existed.
  Intermediate sizes still 404, so it is the thumb or the original, nothing between.
- 🔴 **A Ballotpedia homonym hides behind the bare title.** `/Amanda_Edwards` is a different person
  and never mentions North Carolina. The real page is
  `/Amanda_Edwards_(Buncombe_County_Board_of_Commissioners_Chair,_North_Carolina,_candidate_2024)`.
  Search for the disambiguated title, and test the page text for the state and county before use.
  BP holds no portrait for any of the seven commissioners, disambiguated or not.
- 🔴 **`ncsheriffs.org/people/<slug>` carries an official studio portrait per NC sheriff.** Strip the
  `img.nmcdn.io/e1/w:500,h:500,v:1/` transform for the WordPress original. Miller is 2048 × 2560
  there while his own office site has no portrait of him at all. Sheriffs recur in every county wave.
- 🔴 **A face-first scan beats reading filenames.** Reisinger was wrongly written off after opening
  only one of the two large images on his Wix site (the other was stock photography of a law book).
  Download every image, keep only single-large-face frames, and report the face width — that pass
  found the portrait immediately. Script: `facescan.py` in the session scratchpad.
- `durhamsheriff.com` returns **HTTP 403 with an HTML body** to any plain fetch, referer included, so
  those bytes need a real browser. Ballotpedia's `api.php` now answers with HTML, not JSON, so
  profile pages must be read as pages.
- Guessed paths 404 as usual (`/94/City-Council`, `Sharon-A.-Davis.png`, `sheriff-09-scaled.webp`);
  every nav-crawled or search-found URL resolved.
- Durham county's roster page shows only a **group photo of all five** commissioners. A
  presence-based check would have scored that cohort as covered.

### Import mechanics used

Uploaded to `politician_photos` as `<pid>-headshot.jpg` (600 × 750, 4:5, Lanczos, q90). The insert
joins on **`external_id` AND `full_name`**, so a wrong `politician_id` drops the row rather than
seating the wrong face; both batches were dry-run `BEGIN … ROLLBACK` first and the rollback was
confirmed reverted. 31 of 31 verified on the CDN at 600 × 750 with a SHA-256 matching the local
render. 18 rows carry `REPLACE` in `photo_license`, findable with `photo_license ILIKE '%REPLACE%'`.

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

## Sub-project 2 — Headshots, 32 people (DONE 2026-08-23 — see RESULT above)

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

## Open items

- **Sharon A. Davis, Durham Register of Deeds — the one person with no usable source.** Ballotpedia's
  raw path holds a 5533 × 8300 studio portrait, ×0.14, the best asset in the wave, but it carries a
  **photographer copyright watermark** ("© C.PS. 2024") in the corner. Refused on Chris's ruling
  (2026-08-23) under the credit-line rule rather than imported and mislabelled. Durham has no
  county-party roster equivalent to Buncombe's, and the county's own Register of Deeds page carries
  office signage, not a portrait. Next: Durham local press (INDY Week, The 9th Street Journal,
  Durham's own newsroom), credit line tested on each.
- ✅ **Martin Moore occupancy — CHECKED 2026-08-23, no correction needed.** He did not resign; he ran
  for DA *instead of seeking re-election*, and the county's elected-officials PDF states his District 2
  expiry as **(2026)** against Wells' (2028). His seat is on the November 2026 ballot, so occupancy
  changes at the December swearing-in. Dated follow-up:
  [`2026-12-01-buncombe-d2-moore-term-ends.md`](./2026-12-01-buncombe-d2-moore-term-ends.md), which
  also records why `term_end` was not written from a published expiry year —
  `office_terms` has `start_precision` but **no `end_precision`**.
- 18 of the 31 rows are flagged `REPLACE`. The two worth revisiting first are Aminah M. Thompson
  (×1.95) and Jennifer Horton (×1.23); the Asheville seven are frame-limited at ×1.50 by the
  1000 × 502 banner the city publishes, so they only improve if the city publishes a taller asset.
- Does the LOCAL scale still lack an elections / voting-rights topic? That gap was recorded during the
  Colorado Springs wave and would apply to all 32 people here.
