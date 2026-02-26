---
phase: 46-research-infrastructure-state-officials
verified: 2026-02-26T16:46:03Z
status: human_needed
score: 5/5 must-haves verified
human_verification:
  - test: "Confirm votesmart.org/candidate/evaluations/ URLs are not relied upon as the sole basis for any Braun stance value"
    expected: "Each Braun row with a votesmart evaluations URL has at least one additional specific source (vote record, news article, official statement) that independently substantiates the assigned stance value"
    why_human: "The plan explicitly forbids advocacy group ratings as sources. VoteSmart /evaluations/ pages aggregate scores from advocacy organizations. Automated check confirmed that 8 Braun rows list this URL as source_url_1 (primary), but all 8 also have specific sources in other columns. A human must confirm the stance values were derived from the specific sources rather than inferred from the advocacy aggregate."
  - test: "Confirm Newsom social-security source_url_1 references a real document"
    expected: "The URL https://www.govtrack.us/congress/bills/browse either resolves to a specific bill/vote or the row's substance is adequately supported by the LA Times article in source_url_2"
    why_human: "govtrack.us/congress/bills/browse is a generic browse page — a state governor would not appear in federal congressional records anyway. This URL does not point to a specific document. The LA Times article in source_url_2 appears to be the actual substantive source. A human should confirm the assigned value=2 is supported by the LA Times article alone, and optionally update source_url_1 to something more specific."
  - test: "Spot-check 3-5 source URLs by opening them in a browser"
    expected: "Each URL resolves to a real article, vote record, or official statement — not a 404, paywall-blocked page, or homepage"
    why_human: "URL validity (HTTP 200, correct content) cannot be verified programmatically without making network requests. Given that several URLs use a consistent pattern (e.g., apnews.com URLs with article slugs), a human should open a sample to confirm they resolve."
---

# Phase 46: Research Infrastructure & State Officials Verification Report

**Phase Goal:** Create stance research CSV infrastructure and populate with sourced stance data for CA and IN state officials (Governor + Lt. Governor)
**Verified:** 2026-02-26T16:46:03Z
**Status:** human_needed (all automated checks passed; 3 items need human review)
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (from ROADMAP.md Success Criteria)

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | A stance data CSV exists with politician name, topic_key, stance value (1-5), and source URL columns | VERIFIED | `EV-Backend/data/stance_research.csv` exists, header = `full_name,external_id,topic_key,value,source_url_1,source_url_2,source_url_3` |
| 2  | Governor Newsom has stance values and source URLs for all applicable compass topics | VERIFIED | 21 rows, all 21 topic_keys covered, values 1-3, all rows have source_url_1 |
| 3  | Lt. Governor Kounalakis has stance values and source URLs for all applicable compass topics | VERIFIED | 10 rows for topics with documented positions; 11 topics appropriately omitted per plan guidelines |
| 4  | Governor Braun has stance values and source URLs for all applicable compass topics | VERIFIED | 21 rows, all 21 topic_keys covered, values 1-5, all rows have source_url_1 |
| 5  | Lt. Governor Beckwith has stance values and source URLs for all applicable compass topics | VERIFIED | 13 rows for topics with documented positions; 8 topics appropriately omitted per plan guidelines |

**Score:** 5/5 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `EV-Backend/data/stance_research.csv` | Stance research data for all 4 CA and IN state officials with defined schema | VERIFIED | 66 lines total (1 header + 65 data rows); 21 Newsom, 10 Kounalakis, 21 Braun, 13 Beckwith |

**Artifact Level 1 (Exists):** File present at `EV-Backend/data/stance_research.csv`.

**Artifact Level 2 (Substantive):** 65 data rows across 4 politicians. Python validation confirmed: all 21 topic_keys valid against defined set, all values are integers 1-5, every row has a non-empty `source_url_1`.

**Artifact Level 3 (Wired):** CSV is a data artifact, not code. Wiring to `compass.topics.topic_key` is via topic_key column values — all 21 keys (`healthcare`, `abortion`, `tariffs`, `taxes`, `same-sex-marriage`, `religious-freedom`, `trans-athletes`, `ukraine-support`, `medicare`, `fossil-fuels`, `voting-rights`, `deportation`, `social-security`, `ai-regulation`, `climate-change`, `civil-rights`, `housing`, `campaign-finance`, `immigration`, `misinformation`, `redistricting`) present and match the defined set exactly.

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `EV-Backend/data/stance_research.csv` | `compass.topics.topic_key` | `topic_key` column values | VERIFIED | All topic_key values in the CSV exactly match the 21 defined keys; no extra, misspelled, or missing keys present |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| STANCE-01 | 46-01-PLAN.md | Stance data CSV exists with politician name, topic_key, stance value (1-5), and source URL columns | SATISFIED | File exists with correct schema: `full_name,external_id,topic_key,value,source_url_1,source_url_2,source_url_3` |
| STANCE-02 | 46-01-PLAN.md | Each stance is supported by multiple reputable sources where possible (news sites, campaign websites, voting records, bills sponsored/signed/vetoed) | SATISFIED (with caveat) | Most rows have 2-3 sources; primary sources include gov.ca.gov, in.gov, congress.gov, apnews.com, latimes.com, indystar.com — see votesmart note below |
| STANCE-03 | 46-01-PLAN.md | CA state officials researched — Governor Newsom, Lt. Governor Kounalakis | SATISFIED | Newsom: 21 rows; Kounalakis: 10 rows |
| STANCE-04 | 46-02-PLAN.md | IN state officials researched — Governor Braun, Lt. Governor Beckwith | SATISFIED | Braun: 21 rows; Beckwith: 13 rows |

**Orphaned requirements:** None. STANCE-05 through STANCE-10 are mapped to Phases 47-48 in REQUIREMENTS.md and are not part of Phase 46.

---

### Anti-Patterns Found

| File | Location | Pattern | Severity | Impact |
|------|----------|---------|----------|--------|
| `EV-Backend/data/stance_research.csv` | Row 14 (Newsom, social-security) | `source_url_1` = `https://www.govtrack.us/congress/bills/browse` — generic bills browse page, not a specific document | Warning | A governor would not appear in federal congressional records. URL does not point to any specific bill or vote. Row is still substantiated by `source_url_2` (LA Times article). |
| `EV-Backend/data/stance_research.csv` | Braun rows 38, 41, 45, 46, 48, 49, 50, 52 | `source_url_1` = `https://www.votesmart.org/candidate/evaluations/172441/mike-braun` — VoteSmart evaluations aggregator page | Warning | VoteSmart `/evaluations/` shows aggregated scores from advocacy organizations, which the plan explicitly bars. However, every affected row also has specific sources (AP News, IndyStar, congress.gov votes) in other columns. No row uses this as its sole source. |

**Severity notes:**

- Neither pattern is a blocker. The CSV data integrity checks all pass.
- The govtrack generic URL in Newsom's social-security row is the most clear-cut issue: a state governor has no congressional bills browse page. The substantive source is the LA Times article in `source_url_2`.
- The VoteSmart evaluations URLs require human judgment to determine whether they violate the plan's "no advocacy group ratings" rule given they are always secondary to specific sources.

---

### Commit Verification

All 4 documented commits exist in the EV-Backend repository and are valid:

| Commit | Description | Verified |
|--------|-------------|---------|
| `326ed3a` | feat(46-01): create stance research CSV with Governor Newsom stances | VERIFIED |
| `732e973` | feat(46-01): append Lt. Governor Kounalakis stance research to CSV | VERIFIED |
| `6bfee84` | feat(46-02): append Governor Braun stance research to CSV | VERIFIED |
| `a7a3f50` | feat(46-02): append Lt. Governor Beckwith stance research to CSV | VERIFIED |

---

### Row Count Summary

| Politician | State | Role | Rows | Topics |
|------------|-------|------|------|--------|
| Gavin Newsom | CA | Governor | 21 | All 21 (100%) |
| Eleni Kounalakis | CA | Lt. Governor | 10 | 10/21 (48%) — 11 omitted per plan |
| Mike Braun | IN | Governor | 21 | All 21 (100%) |
| Micah Beckwith | IN | Lt. Governor | 13 | 13/21 (62%) — 8 omitted per plan |
| **Total** | | | **65** | |

---

### Human Verification Required

#### 1. VoteSmart Evaluations URL — Not a Standalone Source

**Test:** Open `https://www.votesmart.org/candidate/evaluations/172441/mike-braun` and review what data it contains. Then check the specific Braun rows where it appears as `source_url_1`: `religious-freedom`, `medicare`, `social-security`, `ai-regulation`, `civil-rights`, `housing`, `campaign-finance`, `misinformation`.

**Expected:** For each of those rows, the stance value is independently corroborated by the specific source in `source_url_2` or `source_url_3` (all present). The VoteSmart evaluations page should be treated as supplementary context at most, not as the primary evidence for the assigned value.

**Why human:** The plan rule "Advocacy group ratings are NOT valid sources" is clear. VoteSmart's `/evaluations/` page aggregates third-party organizational ratings. However, every affected row has at least one legitimate specific source alongside it. A human must judge whether these rows satisfy the spirit of the rule — the question is whether the specific sources actually justify the values assigned, regardless of the VoteSmart URL's presence.

#### 2. Newsom Social-Security — Generic Primary Source URL

**Test:** Check row 14 (Newsom, social-security, value=2). The `source_url_1` is `https://www.govtrack.us/congress/bills/browse` — a generic browse page. The `source_url_2` is `https://www.latimes.com/politics/story/2024-10-15/newsom-supports-social-security-expansion-presidential-ambitions`.

**Expected:** The LA Times article in `source_url_2` substantiates the stance value (2 = expand Social Security). The govtrack URL is effectively a dead link for this purpose and should ideally be replaced or removed.

**Why human:** Source URL quality is a judgment call. The row passes the automated "non-empty source_url_1" check, but the govtrack browse page provides no actual evidence. A human should confirm the value is justified by the LA Times article and optionally clean up the govtrack URL.

#### 3. Sample URL Resolution Check

**Test:** Open 5 source URLs from different politicians and topics — suggested sample:
- Row 3 (Newsom abortion): `https://www.gov.ca.gov/2022/09/27/governor-newsom-signs-13-bills-to-protect-expand-and-strengthen-abortion-rights-in-california/`
- Row 37 (Braun same-sex-marriage): `https://www.politico.com/news/2022/03/22/braun-roe-wade-same-sex-marriage-00019377`
- Row 54 (Beckwith abortion): `https://apnews.com/article/indiana-beckwith-lt-governor-pro-life-pastor-2024`
- Row 26 (Kounalakis immigration): `https://ltgov.ca.gov/2023/04/20/lt-governor-kounalakis-chairs-california-mexico-commission-meeting-on-border-communities/`
- Row 40 (Braun ukraine-support): `https://www.congress.gov/vote/118th-congress/senate/54`

**Expected:** Each URL resolves to a real, accessible article or record that directly supports the assigned stance value.

**Why human:** URL resolution requires network access. Several URLs use specific article slug patterns that may or may not still exist (news archives, government pages can move). A human should spot-check that the primary sources are real and accessible.

---

### Gaps Summary

No gaps blocking goal achievement. All 5 observable truths are verified. The phase delivered exactly what was specified: a CSV with the correct schema, data for all 4 target officials (Newsom, Kounalakis, Braun, Beckwith), integer values 1-5, and source URLs on every row.

The 3 human verification items are quality concerns, not functional blockers. The phase goal is achieved; the human checks are due-diligence on source quality.

---

_Verified: 2026-02-26T16:46:03Z_
_Verifier: Claude (gsd-verifier)_
