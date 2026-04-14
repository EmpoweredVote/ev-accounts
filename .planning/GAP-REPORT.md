# Gap Report — Monroe County IN Primary Readiness (v2026.4.3)

**Generated:** 2026-04-14
**Milestone:** v2026.4.3 Indiana Primary Election Readiness Audit
**Tier 1 cutoff:** May 1, 2026 (4 days before May 5 primary)
**Sources:** Phase 112 (data audit), Phase 113 (benchmark), Phase 114 (UX walkthrough)

---

## Executive Summary

The v2026.4.3 audit examined Empowered Vote's readiness to serve Monroe County Indiana voters ahead of the May 5, 2026 primary. Three parallel audit tracks — a data completeness audit (Phase 112), a competitive benchmark against BallotReady, Vote411, VoteSmart, and Ballotpedia (Phase 113), and a full UX walkthrough of all five apps (Phase 114) — produced 31 UX gaps (G-114-001..031), 9 data audit findings (AUDIT-01..AUDIT-08, with AUDIT-05 split into 05a/05b), and 4 cross-cutting patterns (PATTERN-001..PATTERN-004). This report classifies each finding as Tier 1 (must ship by May 1, 2026) or Tier 2 (future milestone), closing requirements GAP-01 (tiered classification) and GAP-02 (separates data, feature, and intentional omissions). Requirement GAP-03 (execution backlog) is closed by the companion `.planning/BACKLOG.md`.

Across the 31 UX gaps, 10 are classified Tier 1 and 21 are Tier 2. Among the data audit findings, 5 entries (AUDIT-02, AUDIT-03, AUDIT-04, AUDIT-05a, AUDIT-06 contested subset) are Tier 1 via inheritance from their UX counterparts; 4 entries (AUDIT-01, AUDIT-05b, AUDIT-07, AUDIT-08) are Tier 2. The four cross-cutting patterns add PATTERN-001 (Tier 1 conditional) and PATTERN-004 (Tier 1 definite) alongside PATTERN-002 and PATTERN-003 (both Tier 2).

The highest-impact Tier 1 cluster is PATTERN-001 (Challenger Data Desert): 30 stub candidates with no politician records drive simultaneous failures in Essentials profile pages (G-114-010), the Compass compare picker (G-114-012), and Read & Rank quote display (G-114-018). All three apps fail at the same contested county races — County Prosecuting Attorney, County Clerk, County Assessor — because the underlying politician records simply do not exist. This is severity=blocker for all three constituent gaps, making PATTERN-001 the single most impactful fix in the Tier 1 set. However, PATTERN-001 carries a May 1 feasibility uncertainty per D-02: sourcing minimum data (name, office, photo, 1-line bio) for ~30 county-level candidates requires a data-collection step before any code work begins. The v2026.4.4 stub-resolution phase must address data sourcing as a first-order dependency.

The largest non-intentional benchmark gap is PATTERN-003 (App-Wide Bio Gap): 0/51 linked candidates have bio_text in the DB, giving EV a hard score of 0 on benchmark Dimension 3 (Candidate Bio) while VoteSmart and Ballotpedia each score 3. The UX walkthrough first observed this as a single-candidate issue (G-114-007: Pierce has no bio), but Phase 112 confirmed it is universal across all 51 linked candidates — every politician profile renders a generic chamber description instead of a personal biography. PATTERN-003 is Tier 2 overall (universal bio authoring for 51 candidates cannot land by May 1), but the contested-race subset (Pierce and the D-61 primary candidates) is already captured as the Tier 1 elevation in G-114-007.

Six additional definite Tier 1 items are highly feasible within the May 1 window: G-114-006 (wrong election date "May 4" on all profiles — 1-line fix), G-114-026 (SiteHeader nav links pointing to retired Netlify URL — ev-ui URL update + auto-bump), G-114-003 (default Representatives tab hides all primary challengers — tab default logic change), G-114-029 (Read & Rank verdict badges absent from Pierce's profile despite 10 quotes in DB — requires debugging PoliticianProfile.jsx render), G-114-009 (Young has no headshot — single image upload), and PATTERN-004 (County Council D1→D4 geofence binding bug — single polygon repair). The v2026.4.4 milestone must ship all Tier 1 items before May 1, 2026 to give Monroe County voters a trustworthy and complete experience for the primary.

---

## Tiering Methodology

Tiering applies the following locked decisions from `.planning/phases/115-gap-report-synthesis/115-CONTEXT.md`:

- **D-01 — Severity-first:** All 8 UX gaps tagged `severity=blocker` are Tier 1 candidates. `confusing` and `minor` gaps default to Tier 2 unless they represent data gaps with race-coverage impact.
- **D-02 — May 1 feasibility ceiling:** Any fix that cannot plausibly land in production by May 1, 2026 is Tier 2 even if severity=blocker. Applied AFTER severity screening, not before.
- **D-03 — Audit inheritance:** Phase 112 data audit rows have no pre-assigned severity. They inherit from their G-114-NNN counterpart if one exists; otherwise default to Tier 2.

Tier 1 = must ship by May 1, 2026. Tier 2 = future improvement (v2026.4.4 or later).

---

## Tier 1 Summary

- **G-114-003** — essentials, ux-friction — Default Representatives tab hides primary challengers → Section 1
- **G-114-006** — essentials, content — Profile page shows wrong election date "May 4, 2026" → Section 1
- **G-114-007** — essentials, data — Matt Pierce profile has no personal biography (contested D-61 race) → Section 1
- **G-114-009** — essentials, data — Lilliana Young has no headshot (contested D-61 race) → Section 1
- **G-114-010** — essentials, data — 4 of May 5 candidates are DB stubs with empty profile pages [PATTERN-001 conditional] → Section 1
- **G-114-012** — compass, data — Primary challengers absent from Compass compare picker [PATTERN-001 conditional] → Section 1
- **G-114-016** — read-rank, feature — Both location filter mechanisms are non-functional → Section 1
- **G-114-018** — read-rank, data — IN-9 D primary challengers and county-race candidates have zero quotes [PATTERN-001 conditional] → Section 1
- **G-114-026** — cross-app, feature — SiteHeader Treasury/Badges nav links point to retired Netlify URL → Section 1
- **G-114-029** — cross-app, feature — Read & Rank verdict badges absent from politician profile → Section 1
- **AUDIT-02** — data — 30 stub candidates with no politician records (inherits from G-114-010) → Section 2
- **AUDIT-03** — data — Stance coverage 5/51 linked candidates (inherits from G-114-012) → Section 2
- **AUDIT-04** — data — Quote coverage 4/51 linked candidates (inherits from G-114-018) → Section 2
- **AUDIT-05a** — data — Headshot missing for contested-race candidates including Young (inherits from G-114-009) → Section 2
- **AUDIT-06** — data — 0/51 linked candidates have bio (contested-race subset inherits from G-114-007) → Section 2
- **PATTERN-001** — synthesis, data — Challenger Data Desert: 30 stubs drive failure across all three apps [Tier 1 conditional on data sourcing feasibility per D-02] → Section 3
- **PATTERN-004** — synthesis, data — County Council D1→D4 geofence binding bug (benchmark-derived gap per D-06) → Section 3

---

## Tier 2 Summary

### Tier 2 — Section 1 (UX Gaps)
G-114-001, G-114-002, G-114-004, G-114-005, G-114-008, G-114-011, G-114-013, G-114-014, G-114-015, G-114-017, G-114-019, G-114-020, G-114-021, G-114-022, G-114-023, G-114-024, G-114-025, G-114-027, G-114-028, G-114-030, G-114-031

### Tier 2 — Section 2 (Data Audit Findings)
AUDIT-01, AUDIT-05b, AUDIT-07, AUDIT-08

### Tier 2 — Section 3 (Cross-Cutting Patterns)
PATTERN-002, PATTERN-003

---

## Section 1: UX Gaps (Phase 114 — G-114-001..031)

Source: `.planning/research/ux-walkthrough/GAPS.md` (31 entries)

### Tier 1

### G-114-003 — Default Representatives tab hides primary challengers
- **Tier:** 1
- **App:** essentials
- **Severity:** blocker
- **Type:** ux-friction
- **Source:** G-114-003 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/essentials/03-results-all.png — Federal tier shows only Erin Houchin, no Graham/Meyer/Peck/Roark challengers; State tier shows only Matt Pierce, no Lilliana Young
- **Tier rationale:** D-01 — severity=blocker auto-promotes to Tier 1. D-02 feasibility: S (hours) — tab default logic change in essentials Results.jsx, single conditional determining which tab renders on mount. The data IS present on the Elections tab; this is a navigation default change only.
- **Benchmark context:** n/a — not a Core-10 dimension in MATRIX.md directly, but the absence of challengers from the default view exacerbates the MATRIX.md Dim 1 (race coverage) voter experience.
- **Fix sketch:** Change the default active tab in Results.jsx from "Representatives" to "Elections" in April–May primary season, or show challengers inline in the Representatives tab via a "running for X — see Elections" callout.

### G-114-006 — Profile page header shows wrong election date "May 4, 2026"
- **Tier:** 1
- **App:** essentials
- **Severity:** blocker
- **Type:** content
- **Source:** G-114-006 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/essentials/05-pierce-profile.png, screenshots/essentials/06-young-profile.png, screenshots/essentials/07-arrington-empty-profile.png — all three profiles render "Election: May 4, 2026"
- **Tier rationale:** D-01 — severity=blocker; voters trust date labels and could arrive at the polls on the wrong day. D-02 feasibility: S (hours) — single date string or template fix, confirmed app-wide across 3 different profiles. The correct date is May 5, 2026 per BALLOT-BASELINE-2026-05-05.md.
- **Benchmark context:** n/a — not a Core-10 dimension, but data freshness/accuracy is MATRIX.md Dim 9 context. Wrong date on every profile is a critical trust gap.
- **Fix sketch:** Locate the date string/template in the candidate profile component and correct "May 4" to "May 5". Confirm the results-page badges (which correctly show "May 5") use a different source so both are aligned.

### G-114-007 — Matt Pierce profile has no personal biography paragraph
- **Tier:** 1
- **App:** essentials
- **Severity:** confusing
- **Type:** data
- **Source:** G-114-007 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/essentials/05-pierce-profile.png — body paragraph describes what a state rep does generically, no Pierce-specific bio
- **Tier rationale:** D-01 — severity=confusing, but this is a data gap with direct race-coverage impact: Pierce is in the contested D-61 primary, one of the two most relevant state races on the Kirkwood voter's ballot. A voter making a head-to-head decision between Pierce and Young needs biographical context. D-02 feasibility: S (hours) — manually author 1 bio paragraph for Pierce and enter via staging workflow or direct DB insert.
- **Benchmark context:** MATRIX.md Dim 3 — Candidate Bio: EV=0 vs VoteSmart=3, Ballotpedia=3. Pierce is specifically the contested-race candidate the walkthrough focused on; his missing bio is the voter-facing manifestation of EV's worst Core-10 deficit.
- **Fix sketch:** Author a 2-4 sentence biography for Matt Pierce (from public record: IU faculty, Monroe County Democratic politician, district boundaries, legislative focus areas) and insert into essentials.politicians.bio_text. This is a data entry task, not a code task.

### G-114-009 — Lilliana Young has no headshot — initials placeholder only
- **Tier:** 1
- **App:** essentials
- **Severity:** confusing
- **Type:** data
- **Source:** G-114-009 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/essentials/06-young-profile.png — "LY" initials square where headshot should be
- **Tier rationale:** D-01 — severity=confusing, but data gap with race-coverage impact: Young is Pierce's opponent in the contested D-61 primary. In a head-to-head comparison, Pierce having a photo and Young showing initials creates visual bias. AUDIT-REPORT-112.md AUDIT-05 confirms photo_source=none for Young. D-02 feasibility: S (hours) — source one photo from Young's public campaign materials or LinkedIn, upload to Supabase CDN.
- **Benchmark context:** MATRIX.md Dim 2 — Candidate Photos: EV=1. Young's missing photo contributes to EV's below-median photo score. For the single most contested state race, fixing this is the highest-ROI photo upload.
- **Fix sketch:** Locate a Creative Commons or campaign-permission photo of Lilliana Young; upload to Supabase Storage under politician_photos/{politician_id}/default.jpg and insert/update essentials.politician_images record.

### G-114-010 — 4 of the May 5 primary candidates at this address are DB stubs with empty profile pages
- **Tier:** 1 (conditional — see PATTERN-001 feasibility note)
- **App:** essentials
- **Severity:** blocker
- **Type:** data
- **Source:** G-114-010 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/essentials/07-arrington-empty-profile.png — Benjamin T. Arrington profile is literally a single name card: header, office label, wrong election date, and nothing else
- **Tier rationale:** D-01 — severity=blocker; the contested Monroe County Prosecutor and Clerk primaries are undecidable inside the app because one side of each race has zero content. D-02 feasibility: L — requires creating politician records + data import for ~30 stubs. **Tier 1 contingent on PATTERN-001 stub resolution feasibility — see PATTERN-001 in Section 3. If data sourcing for 30 stub candidates cannot complete by May 1, this becomes Tier 2.**
- **Benchmark context:** MATRIX.md Dim 3 (bio EV=0), Dim 5 (stances EV=1), Dim 6 (quotes EV=1) all trace to this missing-records problem at the stub layer. AUDIT-02 confirms 30 stubs across multiple contested county races.
- **Fix sketch:** Create politician records for the ~30 stub candidates (minimum: name, office, district, party from election records). Once records exist, content (photos, bios, stances) can be entered via staging workflow. Data sourcing must precede code work.

### G-114-012 — Primary challengers absent from Compass compare picker — contested May 5 races undecidable
- **Tier:** 1 (conditional — see PATTERN-001 feasibility note)
- **App:** compass
- **Severity:** blocker
- **Type:** data
- **Source:** G-114-012 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/compass/07-indiana-picker-filtered.png — Indiana filter shows 9 sitting officials; zero primary challengers (Graham/Meyer/Peck/Roark for IN-9 D primary; Arrington/Oliphant for Prosecutor; Branham/Davis/Lucas/Hays for Clerk absent)
- **Tier rationale:** D-01 — severity=blocker; the compare feature is useful for exactly 1 of 8 May 5 ballot races (IN HD-61 Pierce vs Young) and completely dark for the most contested federal race (IN-9 D primary). Root cause: no stance data exists for challengers who are DB stubs. D-02 feasibility: L — same root cause as G-114-010. **Tier 1 contingent on PATTERN-001 stub resolution feasibility — see PATTERN-001 in Section 3.**
- **Benchmark context:** MATRIX.md Dim 5 — Stance/issue data: EV=1 vs VoteSmart=3. The challenger absence in the Compass picker is the direct voter-facing consequence of EV's sub-benchmark stance coverage metric.
- **Fix sketch:** Once PATTERN-001 stub resolution creates politician records, enter minimum stance data (even 1-2 topics per candidate) to make challengers appear in the Compass picker. The picker queries essentials.politicians — records must exist before stances can be attached.

### G-114-016 — Both location filter mechanisms are non-functional
- **Tier:** 1
- **App:** read-rank
- **Severity:** blocker
- **Type:** feature
- **Source:** G-114-016 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/read-rank/03-address-filter-no-change.png — address "200 W Kirkwood Ave, Bloomington, IN 47404" typed + Enter; topic list identical before and after. Browse Location dropdown contains only a "State" placeholder option.
- **Tier rationale:** D-01 — severity=blocker; both mechanisms (address text entry and Browse Location dropdown) fail, leaving the voter unable to filter to local candidates without completing all 26 topics (~100+ quote interactions). D-02 feasibility: M (1-3 plans) — geocoding wiring for address filter, actual state list for dropdown. Feasible by May 1.
- **Benchmark context:** n/a — location-aware filtering is not a Core-10 dimension. But the broken filter directly prevents the feature from being useful for a Monroe County voter trying to focus on their primary candidates.
- **Fix sketch:** Investigate why address entry fires no geocode request (likely missing event handler or API call). Fix Browse Location dropdown to populate with actual state options from the DB or hardcoded list. Wire state selection to filter topics by candidates from that state.

### G-114-018 — IN-9 D primary challengers and contested county-race candidates have zero Read & Rank quotes
- **Tier:** 1 (conditional — see PATTERN-001 feasibility note)
- **App:** read-rank
- **Severity:** blocker
- **Type:** data
- **Source:** G-114-018 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** Voting Rights reveal (screenshots/read-rank/06-reveal-who-said-it.png) — no Graham, Meyer, Peck, or Roark appear; AUDIT-REPORT-112.md confirms IN-9 challengers and county candidates are stubs with no politician records.
- **Tier rationale:** D-01 — severity=blocker; zero quotes available for any candidate in the most contested races on the May 5 Monroe County primary ballot. Same root cause as G-114-010 and G-114-012. D-02 feasibility: L — quote import requires politician records first. **Tier 1 contingent on PATTERN-001 stub resolution feasibility — see PATTERN-001 in Section 3.**
- **Benchmark context:** MATRIX.md Dim 6 — Candidate quotes/Q&A: EV=1 vs Vote411=2, VoteSmart=2, Ballotpedia=2. The zero-quotes-for-challengers problem directly prevents Read & Rank from being useful for the most consequential primary races.
- **Fix sketch:** Once PATTERN-001 stub resolution creates politician records, source 3-5 verbatim public statements per challenger from campaign websites, news interviews, or public meeting recordings. Import via existing import-quotes Go CLI.

### G-114-026 — SiteHeader "Treasury Tracker" and "Empowered Badges" nav links point to retired Netlify prototype URL
- **Tier:** 1
- **App:** cross-app
- **Severity:** blocker
- **Type:** feature
- **Source:** G-114-026 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/cross-app/00-essentials-landing-baseline.png — "Treasury Tracker" href resolves to `https://ev-prototypes.netlify.app/treasury-tracker/dist`; "Empowered Badges" href resolves to `https://ev-prototypes.netlify.app/empowered-badges/dist`
- **Tier rationale:** D-01 — severity=blocker; cross-app nav is the voter's primary mechanism to discover all four apps, and two of the four links are broken. D-02 feasibility: S (hours) — URL string update in ev-ui SiteHeader component, publish new ev-ui patch version, auto-bump pipeline deploys to all consumers.
- **Benchmark context:** n/a — cross-app navigation is unique to EV (no competitor is a multi-app suite). But broken navigation undermines the platform value proposition entirely.
- **Fix sketch:** Update ev-ui/src/SiteHeader with correct production URLs (treasurytracker.empowered.vote and badges.empowered.vote). Run `npm version patch && git push origin main --follow-tags`. Auto-bump pipeline distributes to all consumers.

### G-114-029 — Read & Rank verdict badges absent from politician profile despite 10 sourced quotes in DB
- **Tier:** 1
- **App:** cross-app
- **Severity:** blocker
- **Type:** feature
- **Source:** G-114-029 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/cross-app/05-profile-stanceaccordion-readrank-badges.png and screenshots/cross-app/13-pierce-profile-bottom-scroll.png — full-page scroll of Pierce profile shows no Read & Rank section, no StanceAccordion, no verdict badges anywhere
- **Tier rationale:** D-01 — severity=blocker; a voter who completed Read & Rank quote evaluations for Pierce gets no visible payoff on the Essentials profile — the cross-app loop is broken at the profile side. AUDIT-04 confirms 10 sourced quotes exist in DB. D-02 feasibility: M (1-3 plans) — requires debugging PoliticianProfile.jsx render path; likely a component prop wiring issue, feature flag, or CSS regression rather than a new feature build.
- **Benchmark context:** MATRIX.md Dim 6 — EV=1. The verdict badge system is EV's unique differentiator (no competitor has voter-authored verdict overlays on profiles); its absence in production means EV is scoring worse than its actual capability.
- **Fix sketch:** Investigate PoliticianProfile.jsx in ev-ui: confirm `verdictsByQuote` prop is wired, StanceAccordion renders the Read & Rank section, and the Essentials Profile page is passing verdict data correctly. This is a debugging task.

---

### Tier 2

### G-114-001 — Address field has no autocomplete dropdown during typing
- **Tier:** 2
- **App:** essentials
- **Severity:** confusing
- **Type:** ux-friction
- **Source:** G-114-001 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/essentials/02-address-typed.png — voter types address and gets no live confirmation the address is recognized before clicking Search
- **Tier rationale:** Severity is `confusing` per D-01; no race-coverage data impact. The backend geocoder accepts the address string correctly; the autocomplete absence is a confidence/polish gap. Not needed to surface correct race results.
- **Benchmark context:** n/a
- **Fix sketch:** Verify Google Maps Places autocomplete is properly initialized on the landing page input; may require re-enabling the Places autocomplete script that was present in earlier versions.

### G-114-002 — Address rendered in ALL CAPS in results header regardless of input case
- **Tier:** 2
- **App:** essentials
- **Severity:** minor
- **Type:** content
- **Source:** G-114-002 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/essentials/03-results-all.png — "Showing representatives for 200 W KIRKWOOD AVE, BLOOMINGTON, IN, 47404"
- **Tier rationale:** Severity is `minor` per D-01; no data or flow impact. Polish-only issue.
- **Benchmark context:** n/a
- **Fix sketch:** Apply `.toLowerCase()` or `.toTitleCase()` normalization to the displayed address string in the results header.

### G-114-004 — Same candidate surfaces under different offices on Representatives vs Elections tabs
- **Tier:** 2
- **App:** essentials
- **Severity:** confusing
- **Type:** content
- **Source:** G-114-004 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/essentials/03-results-all.png (Representatives: Deckard/Henry under Council At Large) + screenshots/essentials/04-elections-tab.png (Elections: Deckard/Henry under Monroe County Commissioner District 1)
- **Tier rationale:** Severity is `confusing` per D-01; no race-coverage data impact (both representations are accurate). The dual appearance is technically correct; the cross-reference callout is a UX improvement.
- **Benchmark context:** n/a
- **Fix sketch:** Add "(running for Commissioner District 1 — see Elections tab)" annotation to the Representatives card for candidates who also appear in the Elections tab.

### G-114-005 — `Representatives` is the wrong default tab in the month before a primary
- **Tier:** 2
- **App:** essentials
- **Severity:** confusing
- **Type:** ux-friction
- **Source:** G-114-005 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/essentials/03-results-all.png (default Representatives view) + screenshots/essentials/04-elections-tab.png (Elections view with full ballot)
- **Tier rationale:** Severity is `confusing` per D-01. Note: G-114-003 (Tier 1) addresses the more acute symptom (challengers hidden); this entry covers the broader default-tab policy. Tier 2 because the policy decision about when to default to Elections requires product discussion, and G-114-003's fix (showing challengers inline or switching tab) partially addresses the same voter pain.
- **Benchmark context:** n/a
- **Fix sketch:** Consider a time-based tab default: if an election date is within 60 days, default to Elections tab for the voter's address.

### G-114-008 — Matt Pierce profile has no visible Read & Rank section despite 10 quotes in DB
- **Tier:** 2
- **App:** essentials
- **Severity:** confusing
- **Type:** feature
- **Source:** G-114-008 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/essentials/05-pierce-profile.png — profile renders Compass section and Committee/Voting sections, but no Read & Rank / Quotes heading
- **Tier rationale:** Severity is `confusing` per D-01. Note: G-114-029 (Tier 1) captures the more severe cross-app consequence (verdict badges completely absent). G-114-008 may be the same underlying bug — once G-114-029 is fixed, this entry may be resolved. Keeping as separate Tier 2 entry pending investigation.
- **Benchmark context:** MATRIX.md Dim 6 — EV=1. Fixing G-114-029 (Tier 1) should address this simultaneously.
- **Fix sketch:** Resolved by G-114-029 fix — verify after that task.

### G-114-011 — Compare picker defaults to all-states, no location-aware prioritization
- **Tier:** 2
- **App:** compass
- **Severity:** confusing
- **Type:** ux-friction
- **Source:** G-114-011 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/compass/06-compare-picker.png — "State" dropdown defaults to unfiltered; first result is Julia Brownley (CA-26), an irrelevant California rep
- **Tier rationale:** Severity is `confusing` per D-01; no race-coverage data impact. A user can manually filter to Indiana; the geo-default is a UX quality improvement.
- **Benchmark context:** n/a
- **Fix sketch:** Use Essentials cross-app address context or browser geolocation to pre-select the state filter in the Compass compare picker.

### G-114-013 — 4-step onboarding tooltip fires on first comparison and blocks the radar view
- **Tier:** 2
- **App:** compass
- **Severity:** confusing
- **Type:** ux-friction
- **Source:** G-114-013 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/compass/08-compare-pierce-overlay.png — fixed-overlay tooltip "1 of 4: Search for any politician to compare..." renders over the dual-radar, blocking interaction
- **Tier rationale:** Severity is `confusing` per D-01; the tooltip content is useful but the timing interrupts the payoff moment. No race-coverage data impact.
- **Benchmark context:** n/a
- **Fix sketch:** Convert to non-blocking inline hints or delay the tour until the user has interacted with the comparison result at least once.

### G-114-014 — Matt Pierce headshot missing in Compass compare panel despite headshot existing in Essentials
- **Tier:** 2
- **App:** compass
- **Severity:** confusing
- **Type:** feature
- **Source:** G-114-014 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/compass/09-compare-clean.png — Matt Pierce shows grey silhouette avatar in compare panel
- **Tier rationale:** Severity is `confusing` per D-01; no race-coverage data impact. Cross-app data inconsistency between Compass and Essentials headshot sources requires investigation.
- **Benchmark context:** MATRIX.md Dim 2 — EV=1 for photos. Cross-app inconsistency is secondary to the raw coverage gap.
- **Fix sketch:** Investigate whether Compass compare panel sources headshots from essentials.politician_images (same as Essentials) or a separate table. Align to single source.

### G-114-015 — Religious Freedom question appears to repeat in the 33-question calibration
- **Tier:** 2
- **App:** compass
- **Severity:** minor
- **Type:** content
- **Source:** G-114-015 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** Auto-advance JS loop observation — Religious Freedom appeared at approximately Q4 and Q20; not screenshot-verified
- **Tier rationale:** Severity is `minor` per D-01; flagged as unverified (rapid JS auto-advance). Requires a human re-run to confirm duplication.
- **Benchmark context:** n/a
- **Fix sketch:** Run the 33-question quiz carefully reading each question. If confirmed duplicate, remove the redundant topic from the quiz seed data.

### G-114-017 — No candidate-level navigation — topic-centric structure buries local candidates across 26 mixed topics
- **Tier:** 2
- **App:** read-rank
- **Severity:** confusing
- **Type:** ux-friction
- **Source:** G-114-017 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/read-rank/02-topic-list.png — all 26 topics shown; no "Candidates in your area" or "Filter by candidate" path visible
- **Tier rationale:** Severity is `confusing` per D-01; no race-coverage data impact. This is a product architecture question (topic-centric vs candidate-centric) requiring longer discussion.
- **Benchmark context:** n/a
- **Fix sketch:** Add a "By Candidate" view toggle that groups quotes by politician, allowing a voter to evaluate all quotes from a specific candidate in sequence.

### G-114-019 — "Your verdicts appear on candidate profiles in Essentials" has no link or CTA
- **Tier:** 2
- **App:** read-rank
- **Severity:** confusing
- **Type:** ux-friction
- **Source:** G-114-019 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** Accessibility snapshot line 818 — `paragraph: Your verdicts appear on candidate profiles in Essentials.` — plain text, no hyperlink
- **Tier rationale:** Severity is `confusing` per D-01; no race-coverage data impact. The per-politician "View on Essentials" links in reveal DO work; this is a dead-end in the topic completion state only.
- **Benchmark context:** n/a
- **Fix sketch:** Convert the plain text "Your verdicts appear on candidate profiles in Essentials" to a hyperlink pointing to `https://essentials.empowered.vote`.

### G-114-020 — App page title is "readrank-prototype" — prototype label visible in browser tab in production
- **Tier:** 2
- **App:** read-rank
- **Severity:** minor
- **Type:** content
- **Source:** G-114-020 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** `<title>readrank-prototype</title>` — browser tab shows "readrank-prototype" on all pages
- **Tier rationale:** Severity is `minor` per D-01; no data or flow impact. Pure polish gap.
- **Benchmark context:** n/a
- **Fix sketch:** Update `<title>` in index.html (or Vite config) to "Read & Rank — Empowered Vote".

### G-114-021 — Landing page has no geo-personalization — Indiana municipalities buried in California-heavy list
- **Tier:** 2
- **App:** treasury
- **Severity:** confusing
- **Type:** ux-friction
- **Source:** G-114-021 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/treasury/01-landing-full.png — California cities above the fold; Bloomington IN and Monroe County IN are only discoverable by scrolling
- **Tier rationale:** Severity is `confusing` per D-01; no race-coverage data impact. Treasury is supplementary to the primary election experience.
- **Benchmark context:** n/a
- **Fix sketch:** Add geo-detection or a static "Featured: Bloomington IN, Monroe County IN" section at the top of the municipality grid.

### G-114-022 — Budget-vs-actual comparison data absent from both Bloomington and Monroe County budget pages
- **Tier:** 2
- **App:** treasury
- **Severity:** confusing
- **Type:** feature
- **Source:** G-114-022 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/treasury/03-bloomington-budget-overview.png — "Money In" card is blank; screenshots/treasury/04-category-drilldown.png — only approved/budgeted amounts shown, no actuals
- **Tier rationale:** Severity is `confusing` per D-01; no race-coverage data impact. Budget-vs-actual is a secondary Treasury feature. Note: AUDIT-08 cross-references this entry — PATTERN-004 elevates geofence hardening (D-06 exception), but this specific budget feature gap has no D-06 dual evidence.
- **Benchmark context:** n/a
- **Fix sketch:** Investigate whether actual_amount data exists in DB (CLAUDE.md says it is stored); if data exists, wire the UI toggle to display it. If data is missing, requires data import step.

### G-114-023 — Monroe County budget shows FY 2025 while Bloomington shows FY 2026 — inconsistent fiscal year coverage
- **Tier:** 2
- **App:** treasury
- **Severity:** minor
- **Type:** data
- **Source:** G-114-023 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/treasury/07-monroe-county-budget.png — Monroe County shows "In 2025"; screenshots/treasury/03-bloomington-budget-overview.png — Bloomington shows "In 2026"
- **Tier rationale:** Severity is `minor` per D-01; labeled by year and not misleading, just inconsistent.
- **Benchmark context:** n/a
- **Fix sketch:** Import FY2026 Monroe County budget data (if available) or add a "Latest available: FY2025" notice on the Monroe County page.

### G-114-024 — Bloomington year selector skips 2025 — gap year in historical budget continuity
- **Tier:** 2
- **App:** treasury
- **Severity:** minor
- **Type:** data
- **Source:** G-114-024 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/treasury/09-year-selector-open.png — Bloomington year dropdown shows: 2026, 2024, 2023, 2022, 2021, 2020 — 2025 is absent
- **Tier rationale:** Severity is `minor` per D-01; year-over-year trend is a secondary use case.
- **Benchmark context:** n/a
- **Fix sketch:** Import FY2025 Bloomington budget data using the existing importBudgetHierarchy.ts script.

### G-114-025 — Sunburst chart labels unreadable without hover — static view shows unlabeled color segments
- **Tier:** 2
- **App:** treasury
- **Severity:** minor
- **Type:** ux-friction
- **Source:** G-114-025 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/treasury/10-sunburst-view.png — radial partition chart with unlabeled segments
- **Tier rationale:** Severity is `minor` per D-01; sunburst is a secondary visualization, bar chart is default.
- **Benchmark context:** n/a
- **Fix sketch:** Add permanent segment labels for top-level budget categories on the sunburst chart, or remove the sunburst toggle in favor of the labeled bar chart.

### G-114-027 — No auth state relay between apps — logged-in session lost on cross-app navigation
- **Tier:** 2
- **App:** cross-app
- **Severity:** confusing
- **Type:** ux-friction
- **Source:** G-114-027 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/cross-app/02-siteheader-essentials-to-readrank.png — "Sign in" link visible in Read & Rank SiteHeader despite navigating from Essentials
- **Tier rationale:** Severity is `confusing` per D-01; for the pre-May-5 voter context (primarily guest), this is not a blocker. Cookie domain .empowered.vote was fixed in v2026.3.2 — the session relay regression may be deployment-specific.
- **Benchmark context:** n/a (no competitor is a multi-app suite with shared auth)
- **Fix sketch:** Verify .empowered.vote cookie domain is set correctly on production for all apps; confirm each app reads the shared cookie on mount.

### G-114-028 — Profile CompassCard always shows "Calibrate your compass" prompt — no result displayed for already-calibrated visitors
- **Tier:** 2
- **App:** cross-app
- **Severity:** confusing
- **Type:** ux-friction
- **Source:** G-114-028 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/cross-app/04-profile-compasscard.png — "Calibrate your compass to see how you align with Matt Pierce" CTA regardless of visitor state
- **Tier rationale:** Severity is `confusing` per D-01; the forward trip (calibrate → compare) works correctly. Rendering an inline comparison result for returning visitors is a quality improvement, not a primary-readiness blocker. Related to PATTERN-002 cross-app loop.
- **Benchmark context:** n/a
- **Fix sketch:** CompassCard in PoliticianProfile.jsx should check localStorage for existing calibration result; if present, render the comparison overlay directly instead of the calibration CTA.

### G-114-030 — Compass compare panel has no "View profile in Essentials" link — picker is a dead end for candidate exploration
- **Tier:** 2
- **App:** cross-app
- **Severity:** confusing
- **Type:** feature
- **Source:** G-114-030 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/cross-app/06-compass-picker-to-candidate.png — no Essentials deep-links found on the results page
- **Tier rationale:** Severity is `confusing` per D-01; the voter CAN complete the cross-app journey manually. Related to PATTERN-002 cross-app loop repair cluster.
- **Benchmark context:** n/a
- **Fix sketch:** Add a "View full profile →" link on the comparison panel in CompassV2 that deep-links to the politician's Essentials profile URL.

### G-114-031 — No contextual Essentials → Treasury hand-off link in results or profile flow
- **Tier:** 2
- **App:** cross-app
- **Severity:** confusing
- **Type:** feature
- **Source:** G-114-031 (Phase 114 UX Walkthrough — GAPS.md)
- **Evidence:** screenshots/cross-app/07-essentials-to-treasury-handoff.png — no Treasury Tracker link on the Essentials results page other than SiteHeader nav
- **Tier rationale:** Severity is `confusing` per D-01; no race-coverage data impact. The cross-app hand-off is an editorial enrichment feature.
- **Benchmark context:** n/a
- **Fix sketch:** Add a contextual "Explore Bloomington's $224.7M budget → Treasury Tracker" CTA in the local-tier section of the Essentials results page for addresses in municipalities with Treasury data.

---

## Section 2: Data Audit Findings (Phase 112 — AUDIT-REPORT-112)

Source: `.planning/research/AUDIT-REPORT-112.md`

### Tier 1

### AUDIT-02 — Candidate Linkage (30 stubs, 51 linked)
- **Tier:** 1
- **Source:** AUDIT-REPORT-112.md (Phase 112 — AUDIT-02)
- **Key metric:** 81 total candidates: 51 linked to politician records, 30 stubs with no politician record and no content possible
- **UX counterpart:** G-114-010 (Tier 1 blocker, stub profiles empty)
- **Tier rationale:** D-03 inheritance — G-114-010 is Tier 1 (blocker, race-coverage impact). AUDIT-02 inherits Tier 1. The 30 stub candidates include Benjamin T. Arrington, Bob Nyquist, Joe Davis, Tanner Dale Branham, Julie M. Hays, Tree Martin Lucas, and others in contested county primaries (Prosecuting Attorney, Assessor, Clerk).
- **Cross-reference:** PATTERN-001 (Challenger Data Desert)

### AUDIT-03 — Stance Coverage (5/51)
- **Tier:** 1
- **Source:** AUDIT-REPORT-112.md (Phase 112 — AUDIT-03)
- **Key metric:** 5/51 linked candidates have any stance data (9.8%): Houchin 80.8%, Pierce 73.1%, Young 57.7%, Deckard 38.5%, Henry 34.6%. All 46 other linked candidates and all 30 stubs at 0%.
- **UX counterpart:** G-114-012 (Tier 1 blocker, challengers missing from Compass picker)
- **Tier rationale:** D-03 inheritance — G-114-012 is Tier 1. AUDIT-03 inherits Tier 1. The 5-candidate coverage works for the most prominent officials but leaves the entire contested-race challenger set dark in the Compass compare picker.
- **Cross-reference:** PATTERN-001 (Challenger Data Desert)

### AUDIT-04 — Quote Coverage (4/51)
- **Tier:** 1
- **Source:** AUDIT-REPORT-112.md (Phase 112 — AUDIT-04)
- **Key metric:** 4/51 linked candidates have any quotes: Henry 22, Deckard 16, Pierce 10, Young 6. All other linked candidates and all stubs at 0.
- **UX counterpart:** G-114-018 (Tier 1 blocker, zero quotes for challengers)
- **Tier rationale:** D-03 inheritance — G-114-018 is Tier 1. AUDIT-04 inherits Tier 1. The 4-candidate quote coverage is entirely concentrated in the Commissioner District 1 and HD-61 races; the IN-9 D primary challengers and all county-wide race candidates have zero quotes.
- **Cross-reference:** PATTERN-001 (Challenger Data Desert)

### AUDIT-05a — Headshot Coverage (Contested Races Subset)
- **Tier:** 1
- **Source:** AUDIT-REPORT-112.md (Phase 112 — AUDIT-05, contested-race subset)
- **Key metric:** Lilliana Young (HD-61 D primary): photo_source=none. Of 81 total candidates, 19 have CDN photos, 62 have none (23.5% overall coverage). This entry covers the contested-race subset specifically.
- **UX counterpart:** G-114-009 (Tier 1, Young no headshot, contested D-61 race)
- **Tier rationale:** D-03 inheritance — G-114-009 is Tier 1 (confusing, race-coverage impact). AUDIT-05a inherits Tier 1 for the contested-race subset only. The broader 62-candidate photo gap is covered in AUDIT-05b (Tier 2).
- **Cross-reference:** PATTERN-001 (photo sourcing for stubs is part of the stub resolution work)

### AUDIT-06 — Profile Completeness (0/51 bios)
- **Tier:** 1 (contested-race subset); Tier 2 (full 51-candidate scope) — see PATTERN-003
- **Source:** AUDIT-REPORT-112.md (Phase 112 — AUDIT-06)
- **Key metric:** 0/51 linked candidates have bio_text. Every linked candidate profile renders a generic chamber description. Education, experience, and contact data is unevenly present (avg 1.2 contacts/candidate) but bios are universally absent.
- **UX counterpart:** G-114-007 (Tier 1, Pierce bio missing, contested D-61 race)
- **Tier rationale:** D-03 inheritance — G-114-007 is Tier 1 for the contested-race subset. AUDIT-06 inherits Tier 1 for Pierce (D-61 primary) and the key contested candidates. The universal 0/51 bio gap is the basis for PATTERN-003 (Tier 2) — app-wide bio authoring for all 51 candidates cannot land by May 1 per D-02.
- **Cross-reference:** PATTERN-003 (App-Wide Bio Gap)

---

### Tier 2

### AUDIT-01 — Race Coverage (46 races)
- **Tier:** 2
- **Source:** AUDIT-REPORT-112.md (Phase 112 — AUDIT-01)
- **Key metric:** 46 races in DB (baseline: ~43 from BALLOT-BASELINE-2026-05-05.md). All 46 races are linked to geofences (Y). Race-level coverage is complete for the Kirkwood voter's relevant races.
- **UX counterpart:** G-114-021 (May 5 race count, confusing, Tier 2)
- **Tier rationale:** D-03 — G-114-021 is Tier 2 (confusing, no race-coverage data impact). AUDIT-01 inherits Tier 2. Race-level coverage is the strongest data dimension; the audit confirms this is not a gap.
- **Cross-reference:** n/a

### AUDIT-05b — Headshot Coverage (Broader Photo Gap)
- **Tier:** 2
- **Source:** AUDIT-REPORT-112.md (Phase 112 — AUDIT-05, broader scope)
- **Key metric:** 62/81 candidates have no photo (76.5% missing). 30 stubs have no photo (photo sourcing impossible until politician records are created). 32 linked candidates have no CDN photo.
- **UX counterpart:** G-114-009 (Tier 1, Young specifically) — but the broader 62-candidate photo gap has no Tier 1 UX counterpart beyond Young.
- **Tier rationale:** D-03 — the broader photo gap beyond the contested-race subset has no Tier 1 UX counterpart. Universal photo sourcing for 62 candidates cannot land by May 1 per D-02. Tier 2.
- **Cross-reference:** PATTERN-001 (photo sourcing for stubs is part of stub resolution)

### AUDIT-07 — Ballot Baseline
- **Tier:** 2
- **Source:** AUDIT-REPORT-112.md (Phase 112 — AUDIT-07 — BALLOT-BASELINE-2026-05-05.md)
- **Key metric:** 43 race slots documented, authoritative denominator established for Monroe County May 5, 2026 primary
- **UX counterpart:** none
- **Tier rationale:** D-03 — infrastructure deliverable, not a gap. The ballot baseline is a reference document, not a findable deficiency. Tier 2 (no action needed).
- **Cross-reference:** n/a

### AUDIT-08 — Geofence Smoke Test
- **Tier:** 2
- **Source:** AUDIT-REPORT-112.md (Phase 112 — AUDIT-08)
- **Key metric:** Kirkwood address resolves correctly to Bloomington Township + HD 61. County Council D1→D4 binding bug observed (voter in CC D1 sees CC D4 candidate). Mt Tabor Rd fails to geocode.
- **UX counterpart:** G-114-022 (CC D1→D4 binding bug noted as confusing, Tier 2)
- **Tier rationale:** D-03 — G-114-022 is Tier 2. However, note that PATTERN-004 elevates the CC D1→D4 geofence bug to Tier 1 via D-06 benchmark-derived gap exception (dual evidence: MATRIX.md Dim 1 footnote + this AUDIT-08 row). AUDIT-08 as a whole remains Tier 2, but the specific CC D1→D4 finding is elevated by PATTERN-004.
- **Cross-reference:** PATTERN-004 (County Council D1→D4 Geofence Binding Bug — Tier 1)

---

## Section 3: Cross-Cutting Patterns (PATTERN-NNN — synthesis)

Per D-07, the synthesis surfaces root-cause patterns spanning multiple G-114 and audit findings.

### Tier 1

### PATTERN-001 — Challenger Data Desert
- **Tier:** 1 (contingent on data sourcing feasibility per D-02 — see Tier rationale)
- **Type:** cross-cutting pattern (data)
- **Root cause:** 30 stub candidates have no politician records in the DB. This single root cause drives failures in Essentials profile pages, Compass picker, and Read & Rank quote display.
- **Constituent gaps:** G-114-010, G-114-012, G-114-018, AUDIT-02, AUDIT-03, AUDIT-04
- **Benchmark context:** MATRIX.md Dim 3 (bio EV=0), Dim 5 (stances EV=1), Dim 6 (quotes EV=1) all trace to this missing-records problem at the stub layer.
- **Tier rationale:** Severity-driven Tier 1 per D-01 (constituent G-114 entries are blockers). D-02 feasibility uncertainty: requires sourcing minimum data (name, office, photo, 1-line bio) for ~30 county-level candidates by May 1, 2026. If data sourcing cannot complete in time, the pattern degrades to Tier 2 even though severity is blocker. The v2026.4.4 stub-resolution phase MUST include a data-sourcing step before code work.
- **Affected races:** County Prosecutor (Arrington vs Oliphant), County Clerk (Branham/Davis/Lucas/Hays), County Assessor (Nyquist vs Sharp), and other contested county races per BALLOT-BASELINE-2026-05-05.md.

### PATTERN-004 — County Council D1→D4 Geofence Binding Bug (benchmark-derived gap per D-06)
- **Tier:** 1
- **Type:** cross-cutting pattern (data — geofence binding)
- **Root cause:** A Kirkwood Bloomington address that should resolve to County Council District 1 returns District 4 instead. The geofence row exists (per AUDIT-01 race table linking CC D1) but the polygon binding is incorrect.
- **Constituent gaps:** MATRIX.md Dim 1 footnote (concrete falsifiable miss), AUDIT-08 (geofence resolution test) implicit support
- **Benchmark context:** Dual evidence per D-06 — MATRIX.md Dim 1 cell observed the wrong district returned for the canonical Kirkwood test address ("EV's one detectable miss is structurally different from the other two: a failure to bind the voter to the correct County Council district, not a failure to include the race"), AND AUDIT-REPORT-112 AUDIT-08 row confirms CC D1→D4 binding bug observed. This satisfies the D-06 benchmark-derived gap exception (evidenced by both MATRIX.md AND AUDIT row).
- **Tier rationale:** Severity = blocker (voter is shown the wrong race — they see the CC D4 candidate when they should see the CC D1 candidate). Feasibility = S/M — single geofence polygon repair, possibly a coordinate/MTFCC issue in the TIGER 2024 import. Tier 1 per D-01 + D-02.
- **Note:** This is a NEW finding created by the synthesis per D-06. It was not identified in any single audit phase output as a named gap.

---

### Tier 2

### PATTERN-002 — Cross-App Loop Broken
- **Tier:** 2 (no constituent gap is a blocker; all are confusing/feature regressions — except G-114-029 which is already Tier 1 in Section 1)
- **Type:** cross-cutting pattern (feature)
- **Root cause:** The voter journey Compass → Read & Rank → Essentials is architecturally implemented but broken at multiple integration points in production.
- **Constituent gaps:** G-114-027, G-114-028, G-114-029 (Tier 1 — this blocker is already captured in Section 1 Tier 1), G-114-030, G-114-031
- **Benchmark context:** n/a — this is an internal integration concern; no Core-10 dimension applies.
- **Tier rationale:** Mixed severity — G-114-029 alone is a blocker (badges missing despite quotes in DB); the rest are confusing/minor regressions. Pattern is logged Tier 2 because as a unit it represents incremental polish; the individual blocker (G-114-029) remains Tier 1 in Section 1.
- **Note:** The v2026.4.4 cross-app repair phase should fix G-114-029 first (Tier 1) and pick up the other 4 entries opportunistically.

### PATTERN-003 — App-Wide Bio Gap
- **Tier:** 2 (universal scope makes Tier 1 infeasible; Tier 1 subset already covered by G-114-007)
- **Type:** cross-cutting pattern (data)
- **Root cause:** 0/51 linked candidates have bio_text. Every politician profile renders a generic chamber description instead of a personal biography.
- **Constituent gaps:** G-114-007, AUDIT-06 (full row, all 51 linked candidates)
- **Benchmark context:** MATRIX.md Dim 3 — Candidate Bio: EV=0 vs VoteSmart=3, Ballotpedia=3, Vote411=2. This is EV's largest non-intentional gap against the competitive set.
- **Tier rationale:** Universal app-wide bio authoring for 51 candidates cannot land by May 1 (D-02 feasibility ceiling). The Tier 1 subset is already captured as G-114-007 (Pierce, contested D-61 race) and in AUDIT-06 (contested-race subset). v2026.4.4 should ship Tier 1 contested-race bios first; the broader 51-candidate bio program is Tier 2.

---

## Intentional Omissions

Per D-10 — these are NOT gaps. They are deliberate antipartisan choices documented to prevent future contributors from re-filing them as gaps in v2026.4.4 or later milestones.

**Sources cited:** `.planning/research/ux-walkthrough/METHODOLOGY.md` §8, `.planning/research/benchmark/MATRIX.md` "Intentional omissions" section, `.planning/PROJECT.md` "Antipartisan principle".

### Antipartisan choices (deliberately omitted)

1. **Party labels (D / R / I) on candidate cards, search results, or profile pages.** Empowered Vote does not display party affiliation on individual candidates. Party labels appear ONLY on Elections-tab race-group headers as a structural necessity for closed-primary display. Source: METHODOLOGY.md §8, MATRIX.md Dim 10, PROJECT.md "Out of Scope: Party affiliation display".

2. **Newspaper / political-committee / advocacy-group endorsements.** EV does not aggregate endorsements. Competitors Ballotpedia (score=3) and VoteSmart (score=2) display endorsements; this is a deliberate choice not a gap. Source: METHODOLOGY.md §8, MATRIX.md "E2 — Explicit endorsements aggregation", PROJECT.md "Out of Scope: Endorsement tracking".

3. **Interest-group ratings / scorecards** (NRA scores, Sierra Club scores, Chamber of Commerce ratings, any third-party advocacy scorecard). Competitor VoteSmart (score=3) ships these; EV deliberately does not. Source: METHODOLOGY.md §8, MATRIX.md "E1 — Interest-group ratings / scorecards", PROJECT.md "Out of Scope: Interest group ratings".

4. **Third-party partisan race ratings** (Cook Political Report, Sabato's Crystal Ball, etc.). Competitor Ballotpedia (score=3) embeds these; EV deliberately does not. Source: MATRIX.md "E3 — Third-party partisan race ratings".

5. **Donor / fundraising breakdowns beyond raw FEC totals.** EV ships only the raw FEC total (no industry breakdowns, no top-donors leaderboards). Source: MATRIX.md intentional omissions list.

6. **Partisan color associations** (red/blue framing of candidates or races in UI). EV's design system uses `ev-coral`, `ev-muted-blue`, `ev-light-blue`, and `ev-yellow` — not partisan red/blue. Source: METHODOLOGY.md §8.

### Why this section exists

These omissions consistently surface in any benchmark or feature-comparison exercise as "gaps" because competitors ship them. They are not gaps. They are a positioning choice that defines Empowered Vote against the partisan-information-gap problem in civic engagement. Future contributors who attempt to "close" any item in this list should be redirected to PROJECT.md and a milestone-level discussion, not file a gap entry.

---

## Methodology Notes

- **Source traceability:** Every entry cites its original ID (G-114-NNN, AUDIT-NN, or PATTERN-NNN). No re-IDing.
- **Benchmark role:** MATRIX.md scores appear as context/rationale within Tier 1 elevation notes per D-05. Standalone benchmark-derived gaps appear only in Section 3 per D-06 (must be evidenced by both MATRIX.md and AUDIT-REPORT-112). Only PATTERN-004 qualifies for this exception.
- **Closes requirements:** GAP-01 (tiered classification), GAP-02 (separates data/feature/intentional omissions). GAP-03 closed by companion `.planning/BACKLOG.md`.
- **D-01, D-02, D-03, D-04, D-05, D-06, D-07, D-10** applied throughout. All decisions sourced from `.planning/phases/115-gap-report-synthesis/115-CONTEXT.md`.
