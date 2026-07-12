# MA/MD/ME/OR/VA House backlog headshot wave — pins + remainder (2026-07-12)

Wave complete: **42 imported, Chris-approved on the review board** (4 recrops per review:
Beck OR-02, Beckwith VA-10, A. Murphy VA-09, Register VA-05). These states use position_name
**'U.S. House XX-NN'** (pre-Wave-3 convention) — roster queries on 'U.S. Representative%' miss
them entirely. Wave was driven by the politician_context source-mine (campaign sites) + BP
api.php profile pulls + one Wikipedia (LePage) + one Blue Virginia news photo (Bhatti).

Verify query: active/filed race_candidates on 2026 races with position_name LIKE
'U.S. House %', politician_id set, no politician_images row → **33 remaining**
(16 searched pins below + 17 never-chased, no context sources — future BP race-page wave).

## 16 pinned skips (searched via context-mine 2026-07-12)

- **Tony Sabio VA-08** — campaign poster face is **AI-GENERATED** (irregular flag star field,
  painted skin, wobbly letterforms; AI case #3 after Stevens DE + Bueno CT). Site's real
  photos are all event candids w/ sunglasses/groups/backlit. Re-check for a real photo.
- Gary J. Grossi MA-03 — og:image is logo; garygrossi.org has no portrait.
- Tarik Samman MA-05 — site photos: bookstore side-profile + rally sign shot; no clear frontal.
- Craig Swallow MA-09 — site is logo-only (bird emblem).
- Dave Wallace MD-02 — site: logo + one 3-person group photo.
- Brian Jordan MD-05 — site: yard-sign photo + AI illustrations only.
- Cheryl Riley MD-08 — only tiny oval photo inside endorsement graphics.
- Nancy Wallace MD-08 — only a 240px full-body cutout; too small.
- Patrick Mosolf VA-02 — site has childhood/travel photos only.
- **Edwin Rivera VA-03** — site 403-walled to plain fetch — **retry with Playwright** next wave.
- Melanie Lucero VA-05 — og is a 613px postcard graphic; about-page imgs under 180px.
- Robert Tracinski VA-05 — Substack writer; only publication logos.
- Philip Harding VA-07 — site uses hand-drawn/collage art, no photo.
- Lorena Bruner VA-08 — low-res selfie only (held as fallback: bl2 selfie 768px).
- Joy Powers VA-09 — og is full-body field shot w/ sign, face too small (held as fallback).
- Julie Perry VA-10 — only source is an InsideNoVa article — not yet chased.

## 17 never-chased (zero politician_context sources; run BP race-page pass)

MA: Micah Quinney Jones MA-06 (Fox News + ussanews articles exist — chase those),
R. Tyler MacAllister MA-09, Robert Gerald Burke — IMPORTED, ignore.
Actual list = re-derive from verify query minus the 16 above; notables seen in roster:
MacAllister MA-09, M.Q. Jones MA-06, Kersey VA-04, Staten VA-02, Gaines VA-02,
Zeb Taylor VA-03, Suttles VA-10, B. Hall VA-09, Cook VA-09, M. Jackson VA-09,
Headrick VA-11, Crockett — IMPORTED, ignore. Re-derive before batching (don't trust this list).

## Method notes (this wave)

- **BP api.php profile pull is the richest bulk source** for these older states — 10 clean
  candidate-submitted portraits in one pass.
- **CDN transform-strip trick works on wsimg (GoDaddy) + base44**: drop `/:/rs=...` (wsimg)
  or `/v1/fill/...` (base44) to get the original — rescued Smithers VA-07 (og was
  head-cropped 1200×630 → original 3159×4748).
- Squarespace og:image is usually a logo/share-card; the real portrait lives in page <img>s.
- Wikimedia needs a descriptive UA (`EmpoweredVoteHeadshotBot/1.0 (chris@empowered.vote)`);
  plain Mozilla UA gets 429.
- VA primaries Aug-4: field culls after that will retire some of the 33 remaining.
