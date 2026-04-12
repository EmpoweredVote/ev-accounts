---
phase: 111
slug: live-roster-drives-identification
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-12
---

# Phase 111 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest >= 8 |
| **Config file** | `CouncilScribe/pytest.ini` |
| **Quick run command** | `cd CouncilScribe && python3.13 -m pytest tests/test_identification.py -x -q` |
| **Full suite command** | `cd CouncilScribe && python3.13 -m pytest tests/ -x -q` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd CouncilScribe && python3.13 -m pytest tests/test_identification.py -x -q`
- **After every plan wave:** Run `cd CouncilScribe && python3.13 -m pytest tests/ -x -q`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 111-01-01 | 01 | 1 | CSIDENT-01 | — | N/A | unit | `python3.13 -m pytest tests/test_identification.py -k "correct_speaker_name" -x -q` | ❌ W0 | ⬜ pending |
| 111-01-02 | 01 | 1 | CSIDENT-02 | — | bounded processing on Whisper input | unit | `python3.13 -m pytest tests/test_identification.py -k "pattern_matcher_roster" -x -q` | ❌ W0 | ⬜ pending |
| 111-01-03 | 01 | 1 | CSIDENT-03 | — | N/A | unit | `python3.13 -m pytest tests/test_identification.py -k "roster_names_for_prompt" -x -q` | ❌ W0 | ⬜ pending |
| 111-01-04 | 01 | 1 | CSIDENT-04 | — | N/A | unit | `python3.13 -m pytest tests/test_identification.py -k "SpeakerMapping" -x -q` | ❌ W0 | ⬜ pending |
| 111-01-05 | 01 | 1 | CSIDENT-04 | — | N/A | unit | `python3.13 -m pytest tests/test_identification.py -k "correct_mappings" -x -q` | ❌ W0 | ⬜ pending |
| 111-01-06 | 01 | 1 | CSIDENT-01/02 | — | N/A | integration | `python3.13 -m pytest tests/test_identification.py -k "identify_speakers_phantom" -x -q` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/test_identification.py` — new test file covering all CSIDENT-* behaviors
- No new fixtures needed — `conftest.py` already provides `fake_roster_cache` and `tagged_meeting_dir`

*Existing infrastructure covers framework; only test stubs are missing.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| End-to-end on real meeting audio | CSIDENT-01 | Requires actual Whisper transcription + local LLM | Run `python run_local.py` on a previously-processed meeting and inspect `transcript_named.json` for phantom names |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
