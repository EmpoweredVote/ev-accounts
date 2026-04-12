# Milestone v2026.4.2 Requirements — CouncilScribe Speaker Identification via Essentials

**Goal:** Make CouncilScribe voice profiles first-class references to Empowered Vote politicians so same-person auto-match works reliably across meetings and rosters stay in sync with the essentials source of truth.

**Repos affected:** `ev-accounts` (backend endpoint), `CouncilScribe` (client, profile schema, identification).

**Foundation already landed this session (pre-milestone, not re-tested here):**

- WeSpeaker ResNet34 embedding model swap in `src/config.py` + `src/enroll.py` schema v1→v2 auto-discard. 26 profiles re-enrolled from 2026-02-04 and 2026-02-18 meetings via new `reenroll_profiles.py`.
- Cross-meeting A/B test (11 ground-truth pairs): same-pair ≥0.85 threshold pass rate 7/11 → 10/11, separation +0.746 → +0.795.

---

## Active Requirements

### ESSBODY — ev-accounts roster endpoint

- [ ] **ESSBODY-01**: Public `GET /api/essentials/bodies` endpoint returns a list of governing bodies matching a search query (name substring + optional state filter), deduplicated by `name_formal`, with member count per body.
- [ ] **ESSBODY-02**: Public `GET /api/essentials/bodies/:slug/roster` endpoint returns the current roster of active members for a body, including each member's `politician_slug`, `politician_id`, `full_name`, `preferred_name`, office `title`, `chamber_name`, `district_label`, and `photo_url`.
- [ ] **ESSBODY-03**: Body slug is generated from `name_formal` as a URL-safe lowercase kebab string (e.g. "Bloomington Common Council" → `bloomington-common-council`), stable across queries so the same URL always resolves to the same body.
- [ ] **ESSBODY-04**: Roster endpoint filters to active members only (`politicians.is_active = true` and `offices.is_vacant = false`), and never returns party affiliation (antipartisan enforcement).
- [ ] **ESSBODY-05**: Both endpoints respond in under 500ms for Bloomington Common Council payload size under typical production load, and return structured JSON errors (404 for unknown slug, 400 for invalid query).

### CSROSTER — CouncilScribe roster client

- [ ] **CSROSTER-01**: A `src/essentials_client.py` HTTP client calls the `ESSBODY-*` endpoints with configurable base URL (`EV_ACCOUNTS_URL` env var, default `https://accounts.empowered.vote`) and handles offline/network-failure gracefully.
- [ ] **CSROSTER-02**: A `refresh_roster.py` CLI fetches a named body's roster and writes `~/CouncilScribe/config/rosters/{body_slug}.json` — an extended `Roster` JSON with `body_key`, `body_slug`, `politicians[]` (each with politician_slug, full_name, aliases[], title, district_label).
- [ ] **CSROSTER-03**: `refresh_roster.py` auto-generates aliases for each politician from `[full_name, last_name, first_name + last_name, preferred_name + last_name, "Title LastName"]` with duplicates removed, so pattern matching catches Whisper misspellings of surnames.
- [ ] **CSROSTER-04**: `src/roster.py` `load_roster()` prefers per-body rosters under `~/CouncilScribe/config/rosters/` when a body slug is specified, falling back to the legacy `council_roster.json` when no slug is present (backward compatible).
- [ ] **CSROSTER-05**: A fetched roster carries a `fetched_at` timestamp and the client warns (non-blocking) when reusing a cached roster older than 30 days, so users know when to re-run `refresh_roster.py`.

### CSMEETING — Per-meeting body tagging

- [ ] **CSMEETING-01**: Meeting metadata accepts a `body_slug` field (stored in `pipeline_state.json` or a new `meeting_meta.json`) identifying which governing body the meeting belongs to.
- [ ] **CSMEETING-02**: `run_local.py` accepts a `--body` flag that records the body_slug on first run and reads it from metadata on subsequent runs; pipeline fails fast with a clear error if the slug doesn't resolve to a cached roster.
- [ ] **CSMEETING-03**: Stage 4 (speaker identification) loads the body-specific roster and passes it to `correct_speaker_name`, `apply_pattern_matching`, and the LLM prompt — no code path still reads the legacy global roster when a body is tagged.

### CSPROFILE — Profile schema v3, keyed by politician slug

- [ ] **CSPROFILE-01**: `ProfileDB` schema bumped v2→v3. `StoredProfile` gains `politician_slug` (essentials identifier, nullable) and `politician_id` (uuid, nullable) fields. `load_profiles()` auto-discards v2 profiles on mismatch (same pattern as v1→v2 bump).
- [ ] **CSPROFILE-02**: When enrolling a speaker whose confirmed name resolves to a roster member, the profile key becomes `essentials:<politician_slug>` and `politician_slug` / `politician_id` are populated from the roster.
- [ ] **CSPROFILE-03**: Non-roster speakers (public commenters, staff, unknown members) continue to enroll under local auto-generated slugs — roster-keyed and local-keyed profiles coexist in the same DB.
- [ ] **CSPROFILE-04**: `reenroll_profiles.py` is updated to: (a) load per-body rosters from the cache, (b) match each `transcript_named.json` speaker name to the roster for that meeting's body, (c) promote matches to `essentials:<politician_slug>` keys during re-enrollment.
- [ ] **CSPROFILE-05**: A voice profile keyed by `politician_slug` accumulates embeddings across every meeting that politician speaks in, regardless of which specific chamber or meeting (portability across chamber boundaries).

### CSIDENT — Live roster drives identification

- [x] **CSIDENT-01**: `correct_speaker_name` uses the live (fetched) roster's politician names and aliases — phantoms like "Councilmember Piafra" disappear from identification output because they're never in the live roster.
- [x] **CSIDENT-02**: The Layer 2 pattern matcher rejects name matches whose surname doesn't fuzzy-match any active roster member (above a configurable threshold), suppressing false positives from Whisper hallucinations on uncommon words.
- [x] **CSIDENT-03**: The Layer 3 LLM prompt (`llm_identify_speakers`) receives the live roster as context (including district labels for disambiguation), replacing the hand-coded global roster hint.
- [x] **CSIDENT-04**: When a speaker is confidently matched to a politician (any layer), the resulting `SpeakerMapping` records `politician_slug` alongside `speaker_name` — downstream `transcript_named.json` output carries essentials linkage end-to-end.

---

## Success Criteria (Milestone-Level)

This milestone is done when **all of the following are true**, verified end-to-end on a real Bloomington Common Council meeting:

1. `curl https://accounts.empowered.vote/api/essentials/bodies/bloomington-common-council/roster` returns the 9 current active members with politician slugs.
2. `refresh_roster.py --body bloomington-common-council` writes a local roster JSON with auto-generated aliases.
3. `run_local.py --body bloomington-common-council --meeting-id <id>` tags the meeting and uses the fetched roster during identification.
4. Re-enrollment against a meeting from Bloomington Common Council produces at least one profile keyed by `essentials:<politician_slug>` (e.g. `essentials:isabel-piedmont-smith`).
5. On a previously-processed meeting, the identified speakers' `politician_slug` values match the ground-truth essentials roster — zero references to "Councilmember Piafra" or any other phantom.

---

## Future Requirements (Deferred)

- **[Phase E]** Writeback loop: when a voice profile confidently matches a politician across N meetings, publish verified meeting attendance (timestamped speech records) back to essentials as structured data. This unlocks civic-engagement value — sourced, biometrically-verified public speech — and warrants its own milestone after v2026.4.2 proves the identification loop.
- Cross-body profile matching dashboard / admin view (explore which profiles have been matched to which politicians, audit false matches, manual merge UI).
- Multi-jurisdiction support beyond Bloomington — add governing bodies for LA County, state legislatures, etc., as CouncilScribe expands geographic coverage.
- Stronger embedding model (3D-Speaker ERes2NetV2) if WeSpeaker + profile accumulation still leaves individual speakers (like "Ruff" at 0.802 sim) below the 2-meeting returning threshold.
- Profile merge tooling driven by essentials identity (e.g. auto-merging local-slug profiles into politician-slug profiles when names match).

---

## Out of Scope

- **Diarization pipeline changes** — the 9-speaker vs. actual-9-member discrepancy and pyannote over-clustering are real but addressed by passing `num_speakers` as a zero-cost tune, not architectural work this milestone.
- **WhisperX transcription** — A/B tested this session, reverted due to overlap-region content loss and false-positive pattern matches. Revisit only if transcription quality becomes the dominant identification bottleneck after CSPROFILE lands.
- **Reverb Diarize / NVIDIA Sortformer evaluation** — deferred; embedding improvements are the higher-leverage change based on this session's ground-truth data.
- **Direct Supabase SQL from CouncilScribe** — rejected in favor of the public ev-accounts endpoint for cleaner separation and Colab compatibility.
- **New `essentials.bodies` table / `chambers.slug` migration** — unnecessary: `essentials.chambers.name_formal` + `essentials.government_bodies.body_key` already canonicalize the body concept. Slug is computed from `name_formal` in the API layer.
- **Face recognition** — text/audio only for this milestone; no visual identity crosslinking.

---

## Traceability

Maps each REQ-ID to exactly one phase. All 22 requirements covered.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ESSBODY-01 | Phase 107 | Pending |
| ESSBODY-02 | Phase 107 | Pending |
| ESSBODY-03 | Phase 107 | Pending |
| ESSBODY-04 | Phase 107 | Pending |
| ESSBODY-05 | Phase 107 | Pending |
| CSROSTER-01 | Phase 108 | Pending |
| CSROSTER-02 | Phase 108 | Pending |
| CSROSTER-03 | Phase 108 | Pending |
| CSROSTER-04 | Phase 108 | Pending |
| CSROSTER-05 | Phase 108 | Pending |
| CSMEETING-01 | Phase 109 | Pending |
| CSMEETING-02 | Phase 109 | Pending |
| CSMEETING-03 | Phase 109 | Pending |
| CSPROFILE-01 | Phase 110 | Pending |
| CSPROFILE-02 | Phase 110 | Pending |
| CSPROFILE-03 | Phase 110 | Pending |
| CSPROFILE-04 | Phase 110 | Pending |
| CSPROFILE-05 | Phase 110 | Pending |
| CSIDENT-01 | Phase 111 | Complete |
| CSIDENT-02 | Phase 111 | Complete |
| CSIDENT-03 | Phase 111 | Complete |
| CSIDENT-04 | Phase 111 | Complete |
