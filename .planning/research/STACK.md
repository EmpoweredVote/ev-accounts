# Technology Stack

**Project:** v2026.4.3 Indiana Primary Election Readiness Audit
**Researched:** 2026-04-11
**Overall confidence:** HIGH for Indiana data sources (verified accessible); HIGH for scripting approach (matches existing codebase patterns); MEDIUM for competitor site coverage (requires live spot-check to confirm)

---

## Context: What Is and Is Not New

This document covers **only what is new for v2026.4.3**. Existing stack (React 19, Vite, Tailwind 4, Express/TypeScript, Supabase PostgreSQL, PostGIS, ev-ui) is unchanged and should not be re-researched.

This milestone is an **audit milestone, not a feature build.** The output is a tiered gap report, not deployable code. Stack additions must remain lightweight — a handful of scripts, no new infrastructure.

**What this milestone produces:**
- Competitor benchmarking data (BallotReady/VoteSmart/Vote411/Ballotpedia vs Empowered Vote for Monroe County)
- Data completeness audit (races, candidates, stances, quotes)
- UX gap log (Essentials voter journey for a Monroe County address)
- Tiered gap report (before primary vs future)
- Prioritized execution backlog for filling gaps

---

## Indiana Election Data Sources

### Primary: Indiana Secretary of State — Excel Candidate Lists
**Access:** Direct download, no auth, no API key
**URL pattern:** `https://www.in.gov/sos/elections/files/Primary-Candidate-List-[date].xlsx`
**Verified:** URL confirmed live as of 2026-04-11 (Primary-Candidate-List-3.25.26.xlsx exists)
**Format:** Excel (.xlsx), contains candidate names, office/race, county, party
**Covers:** State legislative races (House, Senate), congressional, statewide offices
**Gap:** Does NOT include local races (township trustee, school board, judges) — those come from county clerk

**Why this source:** Already used for prior Monroe County imports (see `importElectionData.ts`, `discover-indiana-candidates.ts`). The `.xlsx` parsing is already wired via the `xlsx ^0.18.5` package already in `ev-accounts/backend/package.json`. No new library needed.

### Secondary: Monroe County Clerk — Certified Candidate PDF
**Access:** Public, no auth
**URL:** Monroe County Clerk website / mcpl.info sample ballot PDFs
**Verified:** `mcpl.info/files/inline-files/rep._2026_primary_sample_ballots.pdf` confirmed accessible
**Format:** PDF (may require manual extraction) or HTML table
**Covers:** All local races — township trustee, township board, town council, county offices, judicial seats
**Gap:** Not machine-readable; manual extraction required

**Why this source:** The `seed-monroe-county-2026-primary.sql` already represents the full Monroe County race/candidate list sourced from this document. The audit script will query the DB against this baseline, not re-parse the PDF.

### Cross-check: Indiana Voter Portal (indianavoters.in.gov)
**Access:** Public web UI, no programmatic API confirmed
**Coverage:** Address-based ballot lookup ("Who's On My Ballot?")
**Use case in audit:** Manual spot-check only — enter a Bloomington address and verify race count matches what Empowered Vote surfaces
**Confidence:** MEDIUM — no confirmed API; scraping this portal is not needed (manual check suffices for audit)

### Federal: Congress.gov / LegiScan (already wired)
**Status:** Already integrated in ev-accounts. No new tooling needed for federal races in the audit — the existing `confirm-indiana.ts` and related scripts cover federal candidate verification.

---

## Competitor Benchmarking Sources

### BallotReady
**Access:** Live voter guide at `ballotready.org/us/in-monroe-county`
**Coverage confirmed:** Has Monroe County voter guide for May 5, 2026 primary
**API:** Exists (`organizations.ballotready.org/ballotready-api`) but requires paid org account — NOT needed for this audit
**Approach:** Manual spot-check against a Monroe County address. Document: which races appear, candidate count per race, what candidate data fields are populated (bio, stance, photo, contact)
**Scraping policy:** Automated scraping for commercial purposes prohibited by ToS
**Recommendation:** Manual benchmark only. One researcher, one address, 30-minute spot-check across all 4 competitors. Document findings in a structured markdown table.

### Vote411 (League of Women Voters)
**Access:** `vote411.org/ballot` — enter address to get personalized ballot
**Coverage:** Confirmed present for Indiana 2026 at `vote411.org/upcoming/37/events`
**API:** No public API — data contributed by League of Women Voters chapters
**Approach:** Manual spot-check. Note what races appear, whether candidate Q&A responses are populated for Monroe County candidates (Vote411's distinguishing feature is candidate-submitted Q&A answers)

### VoteSmart
**Access:** `votesmart.org` — public web + API at `api.votesmart.org`
**API:** Free tier available; API key required (request via votesmart.org/share/api)
**Coverage:** 40,000+ political leaders at federal, state, local levels; Indiana elections confirmed present
**Data available via API:** CandidateBio, Candidates, District, Election, Officials, Votes, Rating, Committee
**Approach for audit:** Manual spot-check for Monroe County candidates. API key acquisition is a one-time 5-minute form — worth getting if deeper data comparison is needed, but manual is sufficient for the benchmark table
**Confidence:** MEDIUM — local race coverage (township trustee level) likely sparse; verify manually

### Ballotpedia
**Access:** `ballotpedia.org/Monroe_County,_Indiana,_elections,_2026` — confirmed live
**API:** Paid subscription required (`ballotpedia.org/Ballotpedia:Buy_Political_Data`); automated scraping prohibited
**Coverage:** Monroe County 2026 elections page exists with race/candidate data
**Approach:** Manual spot-check only. Note race completeness vs Empowered Vote.

### Summary: Competitor Benchmark Approach
All four competitors are accessible via public web UI. No API access is needed or advisable for this audit (paid gating or ToS restrictions). A structured manual spot-check with a single Monroe County address (e.g., 401 N Morton St, Bloomington IN 47404) against each site produces the benchmark table in ~2 hours total.

---

## Audit Scripting Stack

### Already Available — No New Installs

| Tool | Already In | Use in Audit |
|------|-----------|--------------|
| `tsx` | `ev-accounts/backend` devDep | Run audit scripts without compile step |
| `pg` | `ev-accounts/backend` dep | Query Supabase directly |
| `csv-parse ^6.2.1` | `ev-accounts/backend` dep | Parse any CSV outputs |
| `xlsx ^0.18.5` | `ev-accounts/backend` dep | Parse Indiana SoS Excel files |
| `node-html-parser ^7.1.0` | `ev-accounts/backend` dep | Parse HTML if needed for scrapers |

**Pattern:** All audit scripts follow the established `backend/scripts/*.ts` pattern (dotenv + pg Pool + tsx). The `auditHeadshots.ts` and `confirm-indiana.ts` scripts are the closest existing templates.

### New: SheetJS is already wired for Excel parsing
The `xlsx ^0.18.5` package in the existing `package.json` handles the Indiana SoS `.xlsx` files. No upgrade needed — SheetJS Community Edition is sufficient for reading (not writing) spreadsheet data.

**Confidence:** HIGH — package confirmed in package.json.

### Data Completeness Audit Script (to be written — no new deps)
The audit script queries the DB directly against a known race/candidate baseline:

```typescript
// Pattern: query DB, compare against expected set, output gap report
const { rows: races } = await pool.query(`
  SELECT r.position_name, r.primary_party, COUNT(rc.id) as candidate_count,
         COUNT(rc.politician_id) as linked_count,
         COUNT(pa.id) as stance_count,
         COUNT(q.id) as quote_count
  FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
  LEFT JOIN inform.politician_answers pa ON pa.politician_id = rc.politician_id
  LEFT JOIN essentials.quotes q ON q.politician_id = rc.politician_id
  WHERE e.state = 'IN' AND e.election_date = '2026-05-05'
  GROUP BY r.id, r.position_name, r.primary_party
  ORDER BY r.position_name
`);
```

Output: CSV or markdown table with columns: race, candidate_count, linked_to_politician, has_headshot, stance_count, quote_count, gap_severity.

---

## What NOT to Add

| Temptation | Why to Skip |
|------------|-------------|
| Playwright/Puppeteer for automated competitor scraping | ToS prohibitions on BallotReady and Ballotpedia; manual spot-check is sufficient and faster for a one-time audit |
| VoteSmart API integration | API key + code wiring for a benchmark table that can be done manually in 20 minutes |
| New npm packages for report generation | Markdown output from tsx scripts is sufficient; no PDF/HTML report library needed |
| New database tables for audit results | Audit findings live in markdown/CSV files, not the DB; no schema migrations needed |
| Automated PDF parsing of Monroe County Clerk documents | The `seed-monroe-county-2026-primary.sql` already represents the ground truth; audit queries the DB |
| React dashboard for gap report | Gap report is a markdown document for internal use; no frontend needed |

---

## Sources

- Indiana SoS candidate list confirmed: https://www.in.gov/sos/elections/candidate-information/
- Indiana SoS Excel file URL: `https://www.in.gov/sos/elections/files/Primary-Candidate-List-3.25.26.xlsx`
- Monroe County primary date confirmed (May 5, 2026): https://indianacitizen.org/2026-indiana-primary-candidate-list/
- Monroe County sample ballot PDF: https://mcpl.info/files/inline-files/rep._2026_primary_sample_ballots.pdf
- BallotReady Monroe County guide: https://www.ballotready.org/us/in-monroe-county
- BallotReady API (org/paid): https://organizations.ballotready.org/ballotready-api
- Vote411 Indiana: https://www.vote411.org/upcoming/37/events
- VoteSmart API: https://www.votesmart.org/votesmart-api
- Ballotpedia Monroe County 2026: https://ballotpedia.org/Monroe_County,_Indiana,_elections,_2026
- Ballotpedia data purchasing: https://ballotpedia.org/Ballotpedia:Buy_Political_Data
- Bloomington Chamber 2026 candidates: https://www.chamberbloomington.org/2026-election-candidates.html
- BSquare Bulletin Monroe County race coverage: https://bsquarebulletin.com/election-2026-contested-local-primaries-some-november-matchups-take-shape-across-monroe-county/
