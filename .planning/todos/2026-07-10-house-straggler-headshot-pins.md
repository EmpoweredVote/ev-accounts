# House 2026 straggler headshot wave — pins + data flags (2026-07-10)

Wave complete: **302/357 imported** (88 incumbents via bioguide direct + 182 BP race-page
challengers + 32 agent finds), all challenger imports Chris-approved on the review board.
Remaining 55 = 28 prior-wave carryovers (TN 12, FL 5, MO 4 incl. Vivio/Conner withdrawn-culls,
Marsh NY-5 + Smullen NY-21, Ellis SC-1, Burks WI-4 sepia-rule, Latza MI-1, Kincaid WA-1,
Long LA-1 withdrawn — all already pinned/culled in their own todos) + 27 new pins below.

## DATA FLAGS (field verification, not photo work)

- **Gavin Solomon KS-03 — LIKELY ERRONEOUS SEED.** NY-based serial multi-state filer
  (FEC: NY-12/TX-26/FL-27); NO KS-03 FEC filing; absent from BP's KS-03 field
  (Davids/Preu/LaPorte/Stanley). Verify vs KS SOS and cull if unsupported.
- **Braeden Curwick KS-02 — possible WITHDRAWAL** (one BP render flags withdrawn; June news
  still active). Re-check before Aug-4 primary. Only photo anywhere is B&W (hard-rule skip).
- **James Duffe GA-04 — name likely misspelled**; filed name is James R. "Jim" **Duffie**
  (Vote-USA id GADuffieJim, BP concurs). Photo imported; consider name fix.
- **John B. Williams AK-AL — WRONG-PHOTO PRESS HAZARD**: Must Read Alaska originally ran a
  different John (D.) Williams' photo (UAF fisheries specialist); candidate disavowed on FB
  (corrective on The Alaska Current). Aggregators still repeat the wrong bio/photo — never
  import a "John Williams" AK photo without his own confirmation.
- Brian Lambert FL-14 judge-homonym pin RESOLVED: BP race page now carries a fresh
  candidate-submitted photo (s3 file `headshot-under-2MB_20260710_...`); imported in this wave.

## 2026-07-12 politician_context source-mine cross-check (post-stance-wave)

Verify query re-run: 55 → **53 remaining** after this pass. Mined inform.politician_context +
politician_context_evidence URLs for all 55 pids; 13 had stance-wave sources, 10 leads chased:

- **IMPORTED (2, Chris-approved)**: Jordan Mitchell KS-4 (cutout headshot recovered from
  Wayback snapshot of his 404'd campaign site — Squarespace CDN still serves assets after
  domain death, a reusable trick) + Shawn Johnson WY-AL (Cowboy State Daily 5/31/26
  nomination-article solo color portrait, 4800×2700, face-centered 4:5 crop).
- Dead ends (dated notes inline below): Eaton (smarter.vote profile has zero images),
  Goetzman (site loads fine in Playwright — 403 was curl-only — but is an unfilled WP
  template, ALL images Unsplash stock), Rucker (integrityindex.us profile = site logo only),
  Catanese (see note), Curwick (site photo = the known B&W), Sheedy (BP personal page =
  SubmitPhoto placeholder), Kincaid carryover (site is text-only, zero imgs), Burks carryover
  (site re-checked: same sepia IMG_0514, no new photo).

## 27 new pinned skips (agent trails in session outputs)

- **MN (6)**: Alex Eaton MN-1 (site is logo-only; 2026-07-12: smarter.vote profile also has
  zero images), Gregory Goetzman MN-1 (2026-07-12: site loads in Playwright — 403 was
  curl-only — but is an unfilled WP template, every image Unsplash stock; no real photo),
  Christopher Mosel MN-2, Abbey Zieska MN-5, DeVelle Jackson MN-5,
  Chris Corey MN-6 (2026-07-12: his only context source, a hometownsource letter-to-editor,
  carries no author photo). Re-check after Aug-11 primary culls the field.
- **AK (3)**: David Richey (Sitka indie; no photo in coverage), John B. Williams (see hazard
  above), Yaquelin Reynoso (Lawrence MA filer; unverifiable FB only). AK pamphlet re-check
  pre-Aug-18 alongside the Senate pins.
- **WY (3→2)**: Daniel Workman, Elena Del Real (WyoFile explicitly non-participant.png).
  ~~Shawn Johnson~~ — PIN LIFTED 2026-07-12: imported from Cowboy State Daily 5/31/26
  nomination article (stance-wave source).
- **KS (4→3)**: Curwick + Solomon (see flags; Curwick 2026-07-12: letsgobraeden.com's only
  photo is the same B&W portrait — pin stands),
  Paul Catanese KS-4 (2026-07-12: paulforkansas.com now has a June-2026 photo IMG_E5303 but
  it's a full-body stage shot under magenta club lighting, face too small — still no headshot).
  ~~Jordan Mitchell KS-4~~ — PIN LIFTED 2026-07-12: site is 404 but its Oct-2025 Wayback
  snapshot exposes the Squarespace-CDN cutout headshot (still live); imported.
- **CA/NV (2)**: Jeff Frese CA-10 (iVoterGuide 404 fallback confirmed no upload),
  William Johnson NV-4 (bare filing-only BP entry, name too common to attribute anything).
- **CT (1)**: Luz Helena Bueno CT-4 — own site's only photo is AI-generated (literal
  "ChatGPT Image Apr 26 2026" filename in Wayback). Second AI-headshot case after
  Stevens DE. Re-check for a real photo later.
- **WV (2)**: Isaiah Rucker WV-1 (Dallas motivational-speaker homonym trap documented;
  2026-07-12: integrityindex.us FEC-keyed profile checked — no candidate photo, logo only),
  Pat Carney WV-2 ("Friends of Cousin Pat"; FB avatar is default silhouette).
- **OK (2)**: Rocco Bonacci OK-4 (FB page JS-walled — retry with browser), Austin Nieves OK-5
  (dancer/entertainer; linktree avatar is a logo).
- **MT (1)**: Nick Sheedy MT-1 — MTFP guide portrait exists but is B&W/desaturated (hard rule).
  2026-07-12: ballotpedia.org/Nick_Sheedy personal page checked — SubmitPhoto placeholder only.
- **NC (1)**: Steven Swinton NC-13 (BP links socials: FB og:image is old text-logo,
  IG avatar is 2-person selfie).
- **MS (1)**: Johnny Baucom MS-1 (BP infobox but no photo, $0 campaign, zero coverage).
  2026-07-12: BP race page re-checked for a fresh upload (Lambert-FL-14 pattern) — still
  silhouette placeholder.
- **KY (1)**: Mohammad Wael Ahmad KY-4 — only photo (LINK nky) is a side/back-profile shot at
  a monitor, face not identifiable; re-check as campaign develops.

## Verify query

Active/filed race_candidates on 2026 'U.S. Representative%' races with politician_id set and
no politician_images row → returns exactly 55 (28 carryovers + 27 above).

## Method notes (this wave)

- AK at-large BP page title = "United States House of Representatives election in Alaska, 2026"
  (NOT the <State>'s At-Large pattern).
- Subagents share the session scratchpad — one wave's index JSONs got clobbered mid-run;
  re-derive state from the DB, keep master lists re-exportable.
- NEW proven sources: NPR-affiliate voter guides (KCUR/KUNM), WyoFile guide portraits,
  democratsworkforamerica.org roster (NC), official campaign YouTube avatars.
- AI-generated campaign headshots are now a recurring failure class (Stevens DE, Bueno CT):
  check filenames + Meta-AI watermarks before trusting campaign-site photos.
