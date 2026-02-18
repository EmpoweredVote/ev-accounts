# Requirements: Empowered Vote — Quality & Consolidation

**Defined:** 2026-02-17
**Core Value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## v1 Requirements

Requirements for this milestone. Each maps to roadmap phases.

### Auth & Guest Flow

- [x] **AUTH-01**: Audit current cookie/session configuration to ensure guest-first auth changes don't break existing login flow across current domains (Netlify + Render/AWS)
- [x] **AUTH-02**: User can take full compass quiz without logging in
- [x] **AUTH-03**: Guest answers persist in localStorage across browser sessions
- [x] **AUTH-04**: Post-completion save prompt appears after quiz completion, not before
- [x] **AUTH-05**: Guest localStorage state merges to server on account creation (server-wins strategy)
- [x] **AUTH-06**: Clear compass is admin-only, accessible from profile dropdown

### Compass Quiz UX

- [x] **QUIZ-01**: Issue cards show question/prompt instead of category title
- [x] **QUIZ-02**: Compare page shows question/prompt above politician stances
- [x] **QUIZ-03**: Clicking issue card on library page opens popup with question, stances, and user's current selection (editable in-place)
- [x] **QUIZ-04**: Compass visualization fits on page without scrolling (except screens smaller than mobile breakpoint)
- [x] **QUIZ-05**: Compass title cutoff fixed — long titles no longer push chart left or get clipped
- [x] **QUIZ-06**: Dashed/solid line visual distinction removed from inverted spokes (inversion logic preserved)
- [x] **QUIZ-07**: Help box updated to remove dashed/solid line references
- [x] **QUIZ-08**: Stance order randomly inverted per user, permanent per issue (direction flip preserving spectrum)
- [x] **QUIZ-09**: Federal/state/local level indicators shown on issue cards

### Essentials Data & Display

- [x] **ESST-01**: Candidates appear in Essentials results with opt-in toggle (default: officials only)
- [x] **ESST-02**: Candidates visually differentiated from elected officials via badge or label
- [x] **ESST-03**: Election date shown on candidate cards
- [x] **ESST-04**: Building images shown for federal/state/local sections (U.S. Capitol, state capitols, courthouses for LA and Bloomington)
- [x] **ESST-05**: Federal section reordered — U.S. Senate and U.S. House shown before executive branch officials
- [x] **ESST-06**: Position start date and end date shown on politician profile card

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Compass Enhancements

- **COMP-01**: Issue importance weighting per user (affects match quality)
- **COMP-02**: Shareable result links encoding quiz seed in URL
- **COMP-03**: Separate federal/state/local compass views
- **COMP-04**: State and local issue content for compass topics

### Infrastructure & Structure

- **INFR-01**: Monorepo migration with npm workspaces (ev-ui as local dependency)
- **INFR-02**: Infrastructure decision — AWS vs Netlify vs Render for production hosting
- **INFR-03**: Cookie domain configuration for `.empowered.vote` when domain is active
- **INFR-04**: Unified app consolidation (single SPA with shared navigation)

### Essentials Enhancements

- **ESST-07**: Candidate grouping with incumbent they are challenging
- **ESST-08**: "Upcoming election" banner on sections with active races
- **ESST-09**: Supabase politician image proxy (if BallotReady CDN URLs prove unstable)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Mobile app | Web-first; mobile later |
| Real-time chat | High complexity, not core to civic engagement value |
| New prototype features | Focus on polishing existing ones this milestone |
| Data import automation | Manual processes acceptable for now |
| Full monorepo migration | Developer tooling improvement deferred; current structure works for demo |
| Infrastructure migration | Research only for v2; keep current hosting |
| OAuth login (Google, GitHub) | Email/password sufficient for current user base |
| TypeScript migration | Introduces overhead disproportionate to team size |
| Vite version reconciliation | Unnecessary risk mid-milestone (CompassV2 on 6.x, essentials on 7.x) |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 1 | Complete |
| AUTH-02 | Phase 2 | Complete |
| AUTH-03 | Phase 2 | Complete |
| AUTH-04 | Phase 2 | Complete |
| AUTH-05 | Phase 6 | Complete |
| AUTH-06 | Phase 2 | Complete |
| QUIZ-01 | Phase 6 | Complete |
| QUIZ-02 | Phase 4 | Complete |
| QUIZ-03 | Phase 4 | Complete |
| QUIZ-04 | Phase 3 | Complete |
| QUIZ-05 | Phase 3 | Complete |
| QUIZ-06 | Phase 3 | Complete |
| QUIZ-07 | Phase 3 | Complete |
| QUIZ-08 | Phase 4 | Complete |
| QUIZ-09 | Phase 4 | Complete |
| ESST-01 | Phase 5 | Complete |
| ESST-02 | Phase 5 | Complete |
| ESST-03 | Phase 5 | Complete |
| ESST-04 | Phase 5 | Complete |
| ESST-05 | Phase 5 | Complete |
| ESST-06 | Phase 5 | Complete |

**Coverage:**
- v1 requirements: 21 total
- Mapped to phases: 21
- Unmapped: 0

---
*Requirements defined: 2026-02-17*
*Last updated: 2026-02-18 after milestone audit — gap closure Phase 6 added*
