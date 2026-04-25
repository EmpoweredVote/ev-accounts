---
phase: 125
slug: tier-2-ux-polish-bundle
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-17
---

# Phase 125 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | vitest 1.x (frontend: essentials, CompassV2); existing vitest suite (backend: ev-accounts) |
| **Config file** | `essentials/vitest.config.*` (or default Vite-driven); `ev-accounts/backend` existing test config |
| **Quick run command** | `cd essentials && npx vitest run <file>` (per-file) |
| **Full suite command** | `cd essentials && npx vitest run` and `cd ev-accounts/backend && npm test` |
| **Estimated runtime** | ~30 seconds (frontend unit tests); backend SQL fix is verified at production curl gate |

---

## Sampling Rate

- **After every task commit:** Run the per-task `<automated>` command from the task definition
- **After every plan wave:** Run full suite for any test files touched in the wave; production smoke per D-09
- **Before `/gsd-verify-work`:** All automated commands green AND production verifications signed off
- **Max feedback latency:** ~30 seconds for unit tests; production verifies are human-gated (D-09)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 125-01-01 | 01 | 1 | UX-01 | — | N/A (verify-first checkpoint) | manual | `echo "human checkpoint — see acceptance_criteria above"` | ✅ | ⬜ pending |
| 125-01-02 | 01 | 1 | UX-01 | — | N/A (display-only) | unit | `cd essentials && (npm test --silent 2>/dev/null \|\| npx vitest run src/utils/address.test.js) && grep -q "toTitleCaseAddress(formattedAddress)" src/pages/Results.jsx` | ✅ | ⬜ pending |
| 125-01-03 | 01 | 1 | UX-01 | — | N/A (display-only) | unit + grep | `cd essentials && grep -n "electionsCandidateIds" src/pages/Results.jsx \| head -5 && grep -q "Also running" src/pages/Results.jsx && grep -q "if (!activeQuery) return" src/pages/Results.jsx` | ✅ | ⬜ pending |
| 125-01-04 | 01 | 1 | UX-01 | — | Production gate | manual | `echo "human checkpoint — see acceptance_criteria above"` | ✅ | ⬜ pending |
| 125-02-01 | 02 | 2 | UX-01 | — | SQL injection N/A (parameterized); empty-string fallthrough fix | typecheck + grep | `cd ev-accounts/backend && grep -q "NULLIF(p.photo_custom_url, '')" src/lib/compassService.ts && grep -q "NULLIF(p.photo_origin_url, '')" src/lib/compassService.ts && npm run typecheck && (npm test -- --run 2>&1 \| tail -20)` | ✅ | ⬜ pending |
| 125-02-02 | 02 | 2 | UX-01 | — | localStorage TTL 30 days, malformed JSON guarded | unit + grep | `cd essentials && (npm test --silent 2>/dev/null \|\| npx vitest run src/lib/compass.test.js) && grep -q "USER_ADDRESS_KEY" src/lib/compass.js && grep -q "saveUserAddress" src/pages/Results.jsx && cd ../CompassV2 && grep -q "evUserAddress" src/components/InlinePoliticianPicker.jsx` | ✅ | ⬜ pending |
| 125-02-03 | 02 | 2 | UX-01 | — | Production gate | manual | `echo "human checkpoint — see acceptance_criteria above"` | ✅ | ⬜ pending |
| 125-03-01 | 03 | 3 | UX-01 | — | N/A (static HTML title) | grep | `grep -q "Read & Rank — Empowered Vote" /Users/chrisandrews/Documents/GitHub/read-rank/index.html && ! grep -q "readrank-prototype" /Users/chrisandrews/Documents/GitHub/read-rank/index.html` | ✅ | ⬜ pending |
| 125-03-02 | 03 | 3 | UX-01 | — | N/A (display-only) | grep + build | `grep -q "Featured communities" /Users/chrisandrews/Documents/GitHub/treasury-tracker/src/components/AlphaLanding.tsx && grep -q "Other communities" /Users/chrisandrews/Documents/GitHub/treasury-tracker/src/components/AlphaLanding.tsx && grep -q "Latest available: FY" /Users/chrisandrews/Documents/GitHub/treasury-tracker/src/App.tsx && cd /Users/chrisandrews/Documents/GitHub/treasury-tracker && (npm run build 2>&1 \| tail -10)` | ✅ | ⬜ pending |
| 125-03-03 | 03 | 3 | UX-01 | — | Production gate | manual | `echo "human checkpoint — see acceptance_criteria above"` | ✅ | ⬜ pending |
| 125-04-01 | 04 | 3 | UX-01 | — | N/A (visualization labels) | build | `cd /Users/chrisandrews/Documents/GitHub/treasury-tracker && npm run build 2>&1 \| tail -10` | ✅ | ⬜ pending |
| 125-04-02 | 04 | 3 | UX-01 | — | Decision gate | manual | `echo "human checkpoint — see acceptance_criteria above"` | ✅ | ⬜ pending |
| 125-04-03 | 04 | 3 | UX-01 | — | N/A (Path B removal) | grep + build | `cd /Users/chrisandrews/Documents/GitHub/treasury-tracker && (! grep -r "BudgetSunburst" src/ 2>/dev/null) && npm run build 2>&1 \| tail -10` | ✅ | ⬜ pending |
| 125-04-04 | 04 | 3 | UX-01 | — | Final phase signoff | manual | `echo "human checkpoint — see acceptance_criteria above"` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. RESEARCH.md confirms: vitest already configured for `essentials` and `ev-accounts/backend`; no new framework install needed; no new test scaffolding required (per-task tests are added inline in tasks 125-01-02, 125-01-03, 125-02-01, 125-02-02).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Wave 1 production verification (G-114-001 verify, G-114-002 mixed-case header, G-114-004 cross-tab annotation) | UX-01 | D-09 mandates production verify between waves; visual confirmation of essentials.empowered.vote | See task 125-01-04 `<how-to-verify>`: load essentials.empowered.vote, search "200 W Kirkwood Ave, Bloomington, IN, 47404", inspect header case + Reps card annotation; capture screenshots to evidence/wave1/ |
| Wave 2 production verification — G-114-014 API smoke + UI | UX-01 | SQL change requires DB push; production curl is the authoritative pass condition | `curl -s https://api.empowered.vote/api/compass/politicians \| jq '.[] \| select(.last_name=="Pierce") \| .photo_origin_url'` → must return non-empty Supabase CDN URL; then load compass.empowered.vote compare picker, confirm Pierce headshot renders |
| Wave 2 production verification — G-114-011 cross-app geo-default | UX-01 | Requires Essentials → Compass cross-origin localStorage flow in real browser | Per task 125-02-03: incognito, search Kirkwood in Essentials, navigate to Compass compare picker, verify "IN" pre-selected; clear localStorage control to verify Tier 3 unfiltered fallback |
| Wave 3a production verification (G-114-020, G-114-021, G-114-023, G-114-024 verify) | UX-01 | Visual + per-entity behavior; G-114-024 is verify-only per RESEARCH (data already imported) | Per task 125-03-03: load readrank.empowered.vote (tab title), treasurytracker.empowered.vote (Featured section, Monroe County FY notice, Bloomington 2025 in YearSelector). Backup curl: `curl -s https://api.empowered.vote/api/treasury/cities \| jq '.[] \| select(.name=="Bloomington") \| [.available_datasets[].fiscal_year] \| unique \| sort'` → must include 2025 |
| Wave 3b + final phase verification (G-114-025 + 10-gap audit) | UX-01 | Path A vs Path B outcome; final phase signoff per D-09 | Per task 125-04-04: re-verify all 10 gaps in production, save evidence bundle, update STATE.md / ROADMAP.md / REQUIREMENTS.md |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (Wave 0 not needed; existing test infra covers)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (every plan has at least one unit/grep/typecheck task)
- [x] Wave 0 covers all MISSING references (none — no MISSING markers in plans)
- [x] No watch-mode flags (vitest invocations use `run` mode)
- [x] Feedback latency < 125s (unit tests complete in <30s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending production verification per wave
