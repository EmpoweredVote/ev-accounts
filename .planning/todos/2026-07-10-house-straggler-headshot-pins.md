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

## 27 new pinned skips (agent trails in session outputs)

- **MN (6)**: Alex Eaton MN-1 (site is logo-only), Gregory Goetzman MN-1 (greggoetzman.com
  403-walled — retry later), Christopher Mosel MN-2, Abbey Zieska MN-5, DeVelle Jackson MN-5,
  Chris Corey MN-6. Re-check after Aug-11 primary culls the field.
- **AK (3)**: David Richey (Sitka indie; no photo in coverage), John B. Williams (see hazard
  above), Yaquelin Reynoso (Lawrence MA filer; unverifiable FB only). AK pamphlet re-check
  pre-Aug-18 alongside the Senate pins.
- **WY (3)**: Daniel Workman, Elena Del Real (WyoFile explicitly non-participant.png),
  Shawn Johnson (Libertarian atty; only group collage exists; lpwy.org bio 410-gone).
- **KS (4)**: Curwick + Solomon (see flags), Jordan Mitchell KS-4 (site 404, FEC-confirmed),
  Paul Catanese KS-4 (agent-reported campaign-site URL resolved to a sunset landscape —
  re-check paulforkansas.com for a real headshot).
- **CA/NV (2)**: Jeff Frese CA-10 (iVoterGuide 404 fallback confirmed no upload),
  William Johnson NV-4 (bare filing-only BP entry, name too common to attribute anything).
- **CT (1)**: Luz Helena Bueno CT-4 — own site's only photo is AI-generated (literal
  "ChatGPT Image Apr 26 2026" filename in Wayback). Second AI-headshot case after
  Stevens DE. Re-check for a real photo later.
- **WV (2)**: Isaiah Rucker WV-1 (Dallas motivational-speaker homonym trap documented),
  Pat Carney WV-2 ("Friends of Cousin Pat"; FB avatar is default silhouette).
- **OK (2)**: Rocco Bonacci OK-4 (FB page JS-walled — retry with browser), Austin Nieves OK-5
  (dancer/entertainer; linktree avatar is a logo).
- **MT (1)**: Nick Sheedy MT-1 — MTFP guide portrait exists but is B&W/desaturated (hard rule).
- **NC (1)**: Steven Swinton NC-13 (BP links socials: FB og:image is old text-logo,
  IG avatar is 2-person selfie).
- **MS (1)**: Johnny Baucom MS-1 (BP infobox but no photo, $0 campaign, zero coverage).
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
