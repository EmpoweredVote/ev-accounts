---
gsd_state_version: 1.0
milestone: v2026.4
milestone_name: State Data Completion & Image Coverage
status: in_progress
stopped_at: Completed 64-01-PLAN.md — upload_manifest_headshots.py created, dry-run confirms 175-180/246 downloads succeed
last_updated: "2026-03-06T18:10:39.696Z"
last_activity: 2026-03-06 — 64-01 complete; upload_manifest_headshots.py created (432 lines), dry-run run with 175-180 ok / 66-71 failed (CivicPlus 403 blocks)
progress:
  total_phases: 7
  completed_phases: 6
  total_plans: 21
  completed_plans: 20
  percent: 95
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-05)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** Phase 63 COMPLETE — Phase 64 (Headshot Upload Pipeline) is next

## Current Position

Phase: 64 of 64+ (Headshot Upload & Coverage Validation — IN PROGRESS)
Plan: 01 complete — 1 of 3 plans done in Phase 64
Status: Phase 64 Plan 01 complete — upload_manifest_headshots.py created; dry-run confirms 175-180/246 URLs downloadable; 66-71 CivicPlus/government CDN 403 failures documented. Ready for Plan 02 real upload run.
Last activity: 2026-03-06 — 64-01 complete; upload_manifest_headshots.py created (432 lines), dry-run run with 175-180 ok / 66-71 failed (CivicPlus 403 blocks)

Progress: [██████████] 100% (19/19 plans complete across active phases)

## Performance Metrics

**Velocity (v2026.3):** 6 phases, 19 plans
**Velocity (v1.9):** 3 phases, 6 plans
**Velocity (v1.8):** 6 phases, 28 plans

*Updated after each plan completion*

## Accumulated Context

### Key Context for Phase 62 (COMPLETE)

- 62-01 complete: state_legislative_config.json created as single source of truth for IN/CA session years.
- IN: current_year_start=2026, previous_year_start=2025, committee_source=iga, legislative_source=legiscan.
- CA: current_year_start=2025, previous_year_start=2023, committee_source=openstates, legislative_source=legiscan.
- Both import scripts (import_state_legislative.py, import_state_committees.py) now read from config JSON; exit 1 with clear message if missing.
- fetch_all_iga_data() session_year parameter is now required (no default) — must be passed from config.
- verify_state_api.py created: hits Go API to test all 4 endpoints for Rodric Bray (IN) and Lisa Calderon (CA).
- Session year updates for new legislative years require editing only state_legislative_config.json.
- 62-02 complete: EV-Backend/scripts/README.md expanded with complete State Legislative Imports section (STATE-05 satisfied).
- README covers: shared prerequisites, 5 scripts with usage/flags/expected output, 8-step new session playbook, 4 tracking files, 6 troubleshooting items.
- New session playbook uses --dry-run-first discipline (always dry run before writing to DB).

### Key Context for Phase 61 (COMPLETE)

- Phase 61 complete: IN and CA state legislative data verified against live DB.
- Indiana 2026 Regular Session: 935 bills, 6,069 votes, 17/18 legislators active, bridge coverage 94.4% PASS.
- California 2025-2026 Session: 4,746 bills, 92,492 votes, 35/37 legislators active, bridge coverage 94.6% PASS.
- validate_state_legislative.py exits 0 — both states pass all thresholds (80% bridge, ≤10% zero-activity).
- Missing legiscan bridges: Robert Johnson (IN), Blanca Pachecco and Suzette Valladares (CA) — no legiscan bridge = zero activity, documented not fixed.
- Unsponsored bills (83% IN, 71% CA) are expected: our roster is a geofence-filtered subset of the full legislature.
- LegiScan getDatasetList does NOT include bill_count — confirmed via live API call. Sessions confirmed present by hash.
- Table naming: legislative_bills, legislative_votes, legislative_bill_cosponsors (legislative_ prefix).
- Session lookup: use is_current=true (no year_start column in legislative_sessions).
- Audit report: .planning/phases/61-state-data-verification-gap-fill/61-STATE-LEGISLATIVE-AUDIT.md

### Key Context for Phase 60 (COMPLETE)

- Phase 60 complete: IN and CA committee memberships imported and human-verified on profile pages.
- Indiana: 46 standing committees, 61 memberships, 16/18 legislators = 88.9% coverage (PASS)
- California: 1,900 committees processed, 213 memberships, 31/37 legislators = 83.8% coverage (PASS)
- validate_committee_coverage.py exits 0 — both states pass 80% threshold.
- DB reconnect fix: import_state_committees.py reconnects after Open States API fetch (avoids Supabase idle connection timeout on ~15-min CA pagination).
- Open States CA jurisdiction returns multi-state committees — 23,913 "no match" entries are expected, not errors.
- committee_import_tracker.json at ~/.ev-backend/ tracks both IN and CA run metadata.

### Key Context for Phase 64 (IN PROGRESS)

- 64-01 complete: upload_manifest_headshots.py created (432 lines) in EV-Backend/scripts/.
- Script copies download_image, make_storage_path, upsert_politician_image, get_connection verbatim from scrape_city_headshots.py (not import — avoids Playwright dep).
- Adds content_type_to_ext() and get_photo_license() as standalone helpers.
- CLI: --manifest (default: headshot_research_manifest.csv), --dry-run flag.
- Dry-run results: 175-180 ok, 66-71 failed (results vary per run due to Wayback Machine instability).
- Failure breakdown: ~18 domains blocked, mostly CivicPlus/Akamai government CDNs (pomonaca.gov: 6, pvestates.org: 5, torranceca.gov: 5, hermosabeach.gov: 5, etc.) + 4-8 Wayback Machine transient timeouts.
- Download failures are systematic 403 blocks — the browser research found images but direct requests can't replicate the browser session. download_image() already retries with Referer on 403; these persist.
- Coverage math: ~84 pre-existing + ~175 new = ~259/391 = ~66% — below 80% PHOTO-05 threshold.
- Plan 02 will proceed with real upload of the ~175-180 successful downloads. Plan 03 coverage validation will confirm PHOTO-05 status and determine if manual intervention is needed for the 66 failing URLs.
- Commit 4dfac0a in EV-Backend repo.

### Key Context for Phase 63

- headshot_research_manifest.csv: 304 rows, 12 columns, updated in 63-01 with politician_id and research tracking columns.
- Batch 1 (63-02) complete: 66 rows researched, 60 found, 6 not_found, 0 pending.
- Batch 2 (63-03) complete: 48 rows researched, 43 found, 5 not_found, 0 pending. Checkpoint approved 2026-03-05.
- Batch 3 (63-04) complete: 48 rows researched, 44 found, 4 not_found, 0 pending. Checkpoint approved 2026-03-05.
- Batch 4 (63-05) complete: 48 rows researched, 34 found, 14 not_found, 0 pending. Checkpoint approved 2026-03-06.
- Walnut, Bell Gardens, Bradbury: no individual headshot photos on official city websites — all 4 members each marked not_found. Cities with roster-only table layouts.
- Claremont, Paramount, South El Monte (failed-status): manual navigation succeeded — headshots found on individual profile sub-pages.
- Signal Hill: 2/4 found; 2 newer members lack photos on city site.
- Batch 5 (63-06) complete: 44 rows researched, 33 found, 11 not_found, 0 pending. Checkpoint approved 2026-03-06.
- Batch 6 (63-07) complete: 33 rows researched, 24 found, 9 not_found, 0 pending.
- Cumulative: 287/304 researched (94%), ~229 found (~80% hit rate).
- Research approach: HTTP scraping (requests+bs4) for accessible sites; Wayback Machine for 403-blocked CivicPlus/Cloudflare/Akamai sites.
- Wayback Machine image URLs work for Glendora (site blocks direct requests but wb cached images serve fine).
- Lynwood correct URL: lynwoodca.gov (not lynwood.ca.us from manifest).
- CivicPlus sites (Pomona, Torrance, Hermosa Beach, Palos Verdes, Glendora) all 403 to bots — use Wayback Machine.
- Akamai-blocked sites (Hawthorne, West Hollywood, Commerce, Rolling Hills Estates) — use Wayback Machine.
- Rolling Hills Estates correct domain: rollinghillsestates.gov (manifest URL rolling-hills-estates.org is unresolvable).
- San Marino: actual council page is /government/mayor___city_council_/index.php (manifest URL /government/elected-officials/city-council is placeholder).
- Rolling Hills (equestrian city): website has NO headshots — roster table only, all 4 members not_found.
- Haidar Awad (Hawthorne): new council member post-Dec 2025, no archived profile page, marked not_found.
- Commerce correct domain: commerceca.gov (old ci.commerce.ca.us redirects to same Akamai-blocked site).
- RPV: council pages discoverable via /sitemap.xml (navigation search failed).
- Former council members (Santa Monica, Santa Fe Springs) marked not_found since they're no longer on official pages.
- Automated batch scraper (1,247 lines) hit ceiling at Cloudflare/CivicPlus-blocked cities — HTTP scraping is the intended approach for 63.
- Supabase Storage CDN upload pipeline already exists from v1.7 — reuse it in Phase 64.
- Current coverage: target 80%+ of 391 politicians.
- Manifest: ~17 politicians still pending (non-Batch-1/2/3/4/5/6 cities) — Batch 7 is the final batch.
- 3 Burbank politicians included (headshot_status=blocked) — may need alternative research approach.
- Decision: politician_id is UUID primary key from essentials.politicians — enables direct upsert in Phase 64 without fuzzy name matching.
- Monrovia (monroviaca.gov): website has NO individual headshots — text bios only, all 4 members not_found.
- South Gate (cityofsouthgate.org): entire site 403-blocked; used Wayback im_ URLs for all 4 members.
- Vernon (cityofvernonca.gov): site 403-blocked; Wayback has HTML but ShowPublishedImage not archived; recorded original city URLs as found_url.
- Lawndale photos: appear on /contact_information sub-page (CivicLive pattern), not main /city_council page.
- La Verne correct council URL: /351/City-Council (manifest had stale /government/city_council/).
- Temple City correct council URL: /116/City-Council (manifest had stale /government/city-council).
- Agoura Hills (FAILED): bus-directory/City Council/{Name}.jpg pattern (Revize CMS) — 4/4 found.
- Westlake Village: CivicPlus mainSectionTS img scoping finds headshot in /NNN/Name individual pages.
- Los Alamitos, Beverly Hills: fr-dib class with alt=name on main council page maps names to ImageRepository IDs.
- Hawaiian Gardens: Wayback showpublishedimage per-member pages (2019-2023 era); first main-content image = headshot.
- Whittier: Angular SPA + Cloudflare — fully blocked, no Wayback. Mark not_found.
- Rosemead (FAILED): Revize CMS with JS-only content rendering — no static HTML or Wayback. Mark not_found.
- La Habra Heights (FAILED): lahabraheights.com is parked domain (synergytech), not city website. Mark not_found.
- Sierra Madre (FAILED): cityofsmca.com unresolvable, no Wayback. Mark not_found.
- Lancaster: Cloudflare + no Wayback snapshots. Mark not_found.
- South Pasadena Omari Ferguson: not in 2024 Wayback snapshot (different council era). Mark not_found.
- Batch 6 (63-07) new discoveries: Bell correct domain is cityofbell.gov (not cityofbell.org); San Fernando correct domain is sanfernando.gov; San Dimas correct domain is sandimasca.gov.
- CivicPlus directory.aspx?EID pattern: individual member pages at /directory.aspx?EID={id} often have photos not shown on main council page.
- George Dotson (Inglewood): former council member replaced by Gloria Gray in District 1 — marked not_found.
- La Puente: lapuentehome.org returns corrupted binary content — all 3 members not_found.
- Downey: downeyca.org Akamai-blocked, no Wayback CDX snapshots — both members not_found.
- Carson: site completely unreachable (timeout), no Wayback archives — FAILED status confirmed, both members not_found.
- Manhattan Beach: Wayback 20250211 snapshot served photos for all 3 members (VisionInternet showpublishedimage IDs: 24271, 44029, 44027).
- Batch 7 (63-08) complete: 17 politicians researched, 16 found, 1 not_found (Duarte/Garcia).
- Burbank NOT Cloudflare-blocked — manifest had wrong URL. Correct URL is burbankca.gov/web/city-council-office; all 3 members (Perez, Anthony, Mullins) found.
- Culver City correct domain: culvercity.gov (not .org which is Incapsula-blocked). Used Playwright to access .gov.
- David Torres (Montebello) is former member — not on current council page. Found via Wayback Oct 2022.
- Duarte (Cesar Garcia): accessduarte.com fully 403-blocked, no Wayback archives — not_found.
- PHASE 63 FINAL: 304/304 researched (100%), 246 found (80%), 58 not_found (19%), 0 pending. headshot_research_manifest.csv ready for Phase 64 upload pipeline.

### Key Context for Phase 65 (COMPLETE)

- Phase 65 complete: Compass page refresh losing onboarding state fixed.
- CompassContext now exposes topicsLoaded, topicsError, retryLoadTopics.
- Compass.jsx has a loading gate (after all hooks) showing EV coral spinner until topics load; error state with Retry on API failure.
- CalibrationOverlay: localStorage check is now FIRST in getInitialState() so saved progress wins on refresh; resume-mode sessions now persist to calibration_progress key; init effect always waits for topics.length > 0.
- Celebration screen edge case: useEffect in Compass.jsx clears calibration_progress if all pickedTopics already answered on mount (skip celebration, go straight to compass).
- Commits: 657c4fc (feat: topicsLoaded gate), 05f6bc7 (fix: CalibrationOverlay persistence).
- Requirements REFRESH-01, REFRESH-02, REFRESH-03 marked complete.

### Key Context for Phase 66 (COMPLETE)

- 66-01 complete: CoachMark.jsx created — portal overlay (z-60+), SVG mask spotlight cutout, auto-positioning tooltip, tour mode (Next/Skip All) + hint mode (Got it), Framer Motion fade+slide animations.
- useCoachMark hook exported from CoachMark.jsx — localStorage-persisted dismiss with storageKey pattern (matches onboarding_spokeFlip pattern).
- CalibrationOverlay welcome step simplified: calibration-demo.gif removed; inline SVG compass (ev-coral user polygon, ev-light-blue comparison polygon, ev-yellow dots); 4-bullet ul replaced with single p tag (~18 words).
- Commits in CompassV2 repo: 5b89692 (CoachMark), 414ef75 (CalibrationOverlay welcome).
- Requirements ONBOARD-01, ONBOARD-04 marked complete.
- SVG mask chosen over CSS clip-path for spotlight — cleaner rounded hole without polygon math.
- 66-02 complete: SpokeHint removed; 4-step post-cal tour added to Compass.jsx (spokeRef/compareRef/backToLibRef/helpBtnRef targets); tour triggers on onComplete with 500ms delay; persists via onboarding_postCalTour; helpBtnRef resolved via document.querySelector('[aria-label="Help"]') on step 3 (Layout.jsx button outside Compass tree).
- CalibrationOverlay: 3-second auto-dismiss removed from complete step (manual "View My Compass" only); write-in awareness hint added (currentIndex===0, !writeInHintShown, !showWriteIn); dismissed on advance past first question or "Write your own..." click; persists via onboarding_writeInHint.
- Layout.jsx handleClearCompass: clears onboarding_postCalTour and onboarding_writeInHint.
- Commits: 01f6700 (Compass.jsx tour), f2c978e (CalibrationOverlay hint + Layout cleanup).
- Requirements ONBOARD-02, ONBOARD-05 marked complete.
- 66-03 complete: Library.jsx 2-step tour (step 1: + button via callback ref, step 2: Full Calibration CTA); Compass.jsx Compare 4-step tour (politician picker DOM query, topic-dropdown id, chartContainerRef for overlay/spoke steps); persists via onboarding_libraryTour/onboarding_compareTour.
- Commits: 748ef45 (Library tour), 4b59914 (Compare tour).
- Requirements ONBOARD-03, ONBOARD-06 marked complete.
- Pattern: callback ref for first loop element; DOM query for child component internals without modifying ComparePanel.jsx.
- 66-04 complete: All 5 onboarding flags confirmed in handleClearCompass (no code change needed). End-to-end user testing surfaced two issues — both fixed: (1) post-cal tour reduced from 4 to 3 steps (help button step removed — too subtle, awkward spotlight); (2) compare button spotlight fixed with callback ref prop instead of document.querySelector. Topic picker subtitle updated to "Pick the issues that matter most to you when you vote". Commits: 087a1a8 (subtitle), 6431e6b (tour fix). Phase 66 complete: all ONBOARD-01 through ONBOARD-06 requirements satisfied.

### Roadmap Evolution

- Phase 65 added: Fix Compass page refresh losing onboarding state
- Phase 65 complete: 2026-03-06
- Phase 66 added: Improve onboarding flow with guided hints and UX clarity

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 2 | Move Compare button closer to compass chart | 2026-03-05 | `005c970` | [2-move-compare-button-closer-to-compass-ch](./quick/2-move-compare-button-closer-to-compass-ch/) |
| 3 | Animate politician compass polygon on spoke inversion | 2026-03-06 | `288aa22` (ev-ui), `e561a74` (CompassV2) | [3-animate-politician-compass-spoke-inversi](./quick/3-animate-politician-compass-spoke-inversi/) |
| Phase 65-fix-compass-page-refresh-losing-onboarding-state P02 | 3 | 2 tasks | 3 files |
| Phase 65-fix-compass-page-refresh-losing-onboarding-state P01 | 4 | 2 tasks | 3 files |
| Phase 63 P06 | 45 | 1 tasks | 1 files |
| Phase 66-improve-onboarding-flow-with-guided-hints-and-ux-clarity P01 | 2 | 2 tasks | 2 files |
| Phase 66-improve-onboarding-flow-with-guided-hints-and-ux-clarity P03 | 336 | 2 tasks | 3 files |
| Phase 66-improve-onboarding-flow-with-guided-hints-and-ux-clarity P02 | 366 | 2 tasks | 3 files |
| Phase 66-improve-onboarding-flow-with-guided-hints-and-ux-clarity P04 | 45 | 2 tasks | 3 files |
| Phase 63 P07 | 90 | 1 tasks | 1 files |
| Phase 63-headshot-research-sprint P08 | 65 | 1 tasks | 1 files |

### Tech Debt Carried Forward

- Dead `ballotready/` package preserved for historical reference (from v1.5)
- Orphaned `checkCacheStatus` in essentials `api.jsx` (from v1.5)
- 5 district-election cities treated as at-large (from v1.6)
- `fetchPoliticiansOnce` and `fetchPoliticiansProgressive` deprecated but not deleted in essentials `api.jsx` (from v1.9)
- `leg_data_fetched_at` column unused (from v2026.3)
- Topic tags placeholder div in LegislativeInlineSummary (from v2026.3)

### Pending Todos

- 12 politicians have no Read & Rank quotes (carried from v1.8)
- Future: Census ZCTA-to-Place ZIP mapping for city council politicians

## Session Continuity

Last session: 2026-03-06T18:10:39.691Z
Stopped at: Completed 64-01-PLAN.md — upload_manifest_headshots.py created, dry-run confirms 175-180/246 downloads succeed
Resume: Run `/gsd:execute-phase 64` (Plan 02 — real upload run). upload_manifest_headshots.py ready; ~175-180 downloads will succeed.
