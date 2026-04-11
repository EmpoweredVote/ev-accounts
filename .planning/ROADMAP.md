# Roadmap — v2026.4.2 CouncilScribe Speaker Identification via Essentials

**Milestone goal:** Make CouncilScribe voice profiles first-class references to Empowered Vote politicians so same-person auto-match works reliably across meetings and rosters stay in sync with the essentials source of truth.

**Granularity:** standard
**Total phases:** 5 (Phase 107 — Phase 111)
**Requirements covered:** 22/22
**Repos affected:** `ev-accounts`, `CouncilScribe`

---

## Phases

- [x] **Phase 107: Essentials body roster endpoint** — Public ev-accounts API surfaces body search and roster fetch (completed 2026-04-11)
- [x] **Phase 108: CouncilScribe roster client + CLI** — HTTP client and `refresh_roster.py` cache per-body rosters locally (completed 2026-04-11)
- [ ] **Phase 109: Per-meeting body tagging** — Meetings record a `body_slug` and pipeline plumbs it through Stage 4
- [ ] **Phase 110: Profile schema v3 + re-enrollment** — Voice profiles keyed by `politician_slug`, v2 profiles auto-discarded, re-enrollment resolves names against rosters
- [ ] **Phase 111: Live roster drives identification** — Pattern matcher and LLM prompt consume the fetched roster; `politician_slug` carried end-to-end

---

## Phase Details

### Phase 107: Essentials body roster endpoint
**Goal**: Operators can fetch a governing body's current active roster from a public ev-accounts endpoint by a stable slug computed from `chambers.name_formal`.
**Depends on**: Nothing (foundation — existing `essentials.chambers` / `offices` / `politicians` tables are sufficient)
**Requirements**: ESSBODY-01, ESSBODY-02, ESSBODY-03, ESSBODY-04, ESSBODY-05
**Success Criteria** (what must be TRUE):
  1. `GET /api/essentials/bodies?q=bloomington` returns deduplicated bodies matching by `name_formal` substring with member counts, no auth required.
  2. `GET /api/essentials/bodies/bloomington-common-council/roster` returns the 9 current active members with `politician_slug`, `politician_id`, `full_name`, `preferred_name`, `title`, `chamber_name`, `district_label`, and `photo_url`.
  3. Slug derivation is deterministic — the same body resolves to the same kebab-case URL on every call — and the same slug input always returns the same roster.
  4. Vacant seats, inactive politicians, and any party affiliation are absent from the response; unknown slugs return 404 JSON and invalid queries return 400 JSON.
  5. Bloomington Common Council roster responds in under 500ms under typical production load.
**Plans**: 3 plans
- [x] 107-01-PLAN.md — Migration 059: chambers.slug generated column + join indexes
- [x] 107-02-PLAN.md — essentialsBodiesService + essentialsBodies route + antipartisan grep
- [x] 107-03-PLAN.md — Vitest integration suite with DB-optional pattern and <500ms perf assertion

### Phase 108: CouncilScribe roster client + CLI
**Goal**: CouncilScribe can fetch and cache any body's roster locally with auto-generated aliases, with graceful offline behavior and staleness warnings.
**Depends on**: Phase 107
**Requirements**: CSROSTER-01, CSROSTER-02, CSROSTER-03, CSROSTER-04, CSROSTER-05
**Success Criteria** (what must be TRUE):
  1. Running `refresh_roster.py --body bloomington-common-council` writes `~/CouncilScribe/config/rosters/bloomington-common-council.json` containing `body_key`, `body_slug`, `fetched_at`, and `politicians[]` with slug, full name, aliases, title, and district label.
  2. Each politician in the cached roster has an alias list covering full name, surname, first+last, preferred+last, and "Title LastName" variants, deduplicated.
  3. With the network disabled, the client fails with a clear error but never crashes or corrupts an existing cached roster.
  4. `roster.load_roster()` returns a per-body roster when a slug is provided, and falls back to the legacy `council_roster.json` when no slug is set (existing meetings keep working).
  5. Reusing a cached roster older than 30 days emits a non-blocking staleness warning on stdout/log.
**Plans**: 1 plan
- [x] 108-01-PLAN.md — Roster HTTP client, alias generator, refresh_roster CLI, load_roster slug path + staleness

### Phase 109: Per-meeting body tagging
**Goal**: Every meeting run declares which governing body it belongs to, and that slug flows through the pipeline so identification consumes the right roster.
**Depends on**: Phase 108
**Requirements**: CSMEETING-01, CSMEETING-02, CSMEETING-03
**Success Criteria** (what must be TRUE):
  1. A meeting tagged with `--body bloomington-common-council` persists that slug to pipeline metadata and reads it back on every subsequent stage invocation without re-specifying the flag.
  2. Launching a meeting with a body slug that has no cached roster fails fast with a clear error message telling the operator to run `refresh_roster.py`.
  3. Stage 4 identification uses the body-specific roster for `correct_speaker_name`, pattern matching, and the LLM prompt — no code path falls back to the legacy global roster when a body_slug is present.
**Plans**: TBD

### Phase 110: Profile schema v3 + re-enrollment
**Goal**: Voice profiles are keyed by essentials `politician_slug` when they correspond to a known politician, coexisting with local-slug profiles for non-roster speakers, and existing v2 profiles can be promoted via re-enrollment.
**Depends on**: Phase 109
**Requirements**: CSPROFILE-01, CSPROFILE-02, CSPROFILE-03, CSPROFILE-04, CSPROFILE-05
**Success Criteria** (what must be TRUE):
  1. Opening a v2 profile DB with the v3 code auto-discards incompatible entries (same pattern as v1→v2) and rebuilds cleanly on next enroll.
  2. Re-running `reenroll_profiles.py` against a Bloomington Common Council meeting produces at least one profile keyed `essentials:<politician_slug>` (e.g. `essentials:isabel-piedmont-smith`) populated from the cached roster.
  3. Public commenters and other non-roster speakers enroll under locally-generated slugs in the same DB and are never accidentally promoted to politician keys.
  4. A politician-slug-keyed profile accumulates embeddings across multiple meetings — re-enrolling against a second meeting with the same speaker adds to the existing profile rather than creating a duplicate.
  5. `StoredProfile` records carry `politician_slug` and `politician_id` fields (nullable for local profiles), round-tripping through save/load.
**Plans**: TBD

### Phase 111: Live roster drives identification
**Goal**: Speaker identification on a real Bloomington Common Council meeting returns only roster-backed names, with `politician_slug` carried end-to-end into `transcript_named.json`, and phantom names disappear.
**Depends on**: Phase 110
**Requirements**: CSIDENT-01, CSIDENT-02, CSIDENT-03, CSIDENT-04
**Success Criteria** (what must be TRUE):
  1. On a previously-processed Bloomington Common Council meeting, identified speaker names all appear in the fetched roster — zero references to "Councilmember Piafra" or any other phantom not present in the live roster.
  2. Whisper hallucinations on uncommon surnames are rejected by the Layer 2 pattern matcher when they fail a fuzzy match against active roster members above the configured threshold.
  3. The Layer 3 LLM prompt observably includes the live roster (names + district labels for disambiguation) instead of a hand-coded global hint.
  4. When a speaker is confidently matched, the `SpeakerMapping` and downstream `transcript_named.json` record both `speaker_name` and the essentials `politician_slug`.
**Plans**: TBD

---

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 107. Essentials body roster endpoint | 3/3 | Complete   | 2026-04-11 |
| 108. CouncilScribe roster client + CLI | 1/1 | Complete    | 2026-04-11 |
| 109. Per-meeting body tagging | 0/? | Not started | - |
| 110. Profile schema v3 + re-enrollment | 0/? | Not started | - |
| 111. Live roster drives identification | 0/? | Not started | - |

---

## Coverage

**Requirements mapped:** 22/22

| REQ-ID | Phase |
|--------|-------|
| ESSBODY-01 | 107 |
| ESSBODY-02 | 107 |
| ESSBODY-03 | 107 |
| ESSBODY-04 | 107 |
| ESSBODY-05 | 107 |
| CSROSTER-01 | 108 |
| CSROSTER-02 | 108 |
| CSROSTER-03 | 108 |
| CSROSTER-04 | 108 |
| CSROSTER-05 | 108 |
| CSMEETING-01 | 109 |
| CSMEETING-02 | 109 |
| CSMEETING-03 | 109 |
| CSPROFILE-01 | 110 |
| CSPROFILE-02 | 110 |
| CSPROFILE-03 | 110 |
| CSPROFILE-04 | 110 |
| CSPROFILE-05 | 110 |
| CSIDENT-01 | 111 |
| CSIDENT-02 | 111 |
| CSIDENT-03 | 111 |
| CSIDENT-04 | 111 |

No orphaned requirements. No duplicates.
