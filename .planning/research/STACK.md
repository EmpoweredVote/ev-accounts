# Stack Research — Data Sources & Tooling for 2026 US House Coverage (Wave 1)

**Domain:** Civic-data sourcing — 2026 Nov-3 US House general-election field (CA/TX/FL/NY = 144 districts)
**Researched:** 2026-06-27
**Confidence:** HIGH (primary calendar + source behavior verified live this session)

> This is a **data-sourcing** milestone, not a code-stack milestone. The "stack" here is the
> set of authoritative sources + fetch tooling used to (1) build the general-election candidate
> field per district, (2) get headshots, (3) find campaign sites for stance research, and
> (4) pull FEC IDs. The stance-research pipeline, find-headshots conventions, TIGER geofencing,
> and chairs-not-polarity methodology are **already built and out of scope** (see milestone_context).

---

## TL;DR — Per-State Field Readiness (the most important output)

| State | Districts | Primary date(s) | Status as of 2026-06-27 | Action |
|-------|-----------|-----------------|--------------------------|--------|
| **CA** | 52 | **June 2, 2026** (top-two) | ✅ **DECIDED** — primary past | Seed the **top-two** advancers per district now. No re-check needed. |
| **TX** | 38 | **March 3** + **May 26 runoff** | ✅ **DECIDED** — primary + runoff past | Seed both nominees per district now. No re-check needed. |
| **NY** | 26 | **June 23, 2026** | ✅ **DECIDED** — primary 4 days ago | Seed nominees now from June-23 results. Spot-check NBC/AP for any uncalled close race. |
| **FL** | 28 | **August 18, 2026** | ⏳ **PENDING** — primary not yet held | Seed the **qualified field** now (FL federal qualifying CLOSED — candidate list is final); **re-check after Aug 18** to drop primary losers. |

**Bottom line:** 3 of 4 states (CA, TX, NY = 116 districts) have a fully decided general-election field **right now**. Only **FL (28 districts)** needs a post-primary re-check (after **Aug 18, 2026**) — but FL's qualified-candidate list is already final and downloadable, so you can seed the full field immediately and prune losers in one pass after Aug 18.

> CA is **top-two (jungle)**: the two highest vote-getters advance regardless of party — a district can have D-vs-D or R-vs-R. Do NOT assume one D + one R. Confirm both advancers from results.
> TX/FL/NY are **partisan primaries**: one nominee per party + ballot-qualified independents/minor parties.

---

## Recommended Stack (Data Sources, in priority order)

### Core Sources

| Source | URL | Purpose | Why Recommended |
|--------|-----|---------|-----------------|
| **Wikipedia per-state House pages** | `en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_{California\|Texas\|Florida\|New_York}` | Authoritative-enough, **fetchable** roll-up of the general-election field per district (advanced / eliminated / withdrawn / independents) | Free, no fetch-wall, updated within hours of results, structured by district. **The primary field-discovery source.** ⚠️ WebFetch returns only the TOC for these long pages (see Fetch-Walls) — read section anchors or use Playwright/raw wikitext. |
| **FEC OpenFEC API** | `https://api.open.fec.gov/v1/candidates/?office=H&state={ST}&election_year=2026` | **Authoritative FEC candidate IDs + finance**; filer-of-record list per state/district | Machine-readable JSON, returns `candidate_id` (e.g. `H6CA12209`), `party_full`, `incumbent_challenge`, `candidate_status`. Feeds both the field AND the existing FEC finance ingestion. **Verified working this session.** |
| **FL Division of Elections candidate download** | `https://dos.elections.myflorida.com/candidates/downloadcanlist.asp` (tab-delimited) + `CanList.asp?elecid=20261103-GEN&OfficeCode=USR` | The **official, final** FL candidate field — FL federal qualifying period has CLOSED | Government source of truth for the one pending state. Tab-delimited bulk download = scriptable. Includes candidate photos + contact info. ⚠️ ASP site — test fetch; use Playwright if walled. |
| **NBC News 2026 primary results** | `nbcnews.com/politics/2026-primary-elections/{state}-house-results` + per-district pages | Confirming **NY June-23** (and any uncalled-race) nominees | Free, fetchable, per-district result pages with called/uncalled status. AP/Politico/NYT are equivalent backups. |

### Supporting Sources

| Source | URL pattern | Purpose | When to Use |
|--------|-------------|---------|-------------|
| **Ballotpedia per-district pages** | `ballotpedia.org/{State}'s_{N}th_Congressional_District_election,_2026` | Richest single-district candidate detail (declared/withdrawn/qualified, campaign-site links, issue summaries) | When Wikipedia is thin on a district. **Fetch-walled → Playwright or Ballotpedia API only** (see Fetch-Walls). |
| **State SoS / elections sites** | CA: `sos.ca.gov`; TX: `sos.state.tx.us`; NY: `elections.ny.gov`; FL: `dos.fl.gov/elections` | Official certified candidate lists per state | Tie-breaker / verification when Wikipedia and Ballotpedia disagree. ⚠️ Often JS-SPA or ASP — frequently fetch-walled, use Playwright. |
| **VOTE411 (LWV) candidate guides** | `vote411.org/ballot`, `onyourballot.vote411.org` | Candidate-supplied issue questionnaires — **gold for stance research** when present | Stance-sourcing only. Coverage varies wildly by state/district; not a field-discovery source. |
| **Candidate campaign websites** | discovered via Ballotpedia/Wikipedia infobox external links + Google | Primary source for **issue statements** (stance research) | Per-candidate stance research. Many challengers have thin/"launching soon" sites (Senate-coverage lesson) → expect honest-skips. |
| **Politics1** | `politics1.com/fl.htm` etc. | Quick human-curated per-state candidate roll-up incl. minor-party/independents | Cross-check for ballot-qualified independents Wikipedia may omit. Fetchable. |

---

## Per-Source Procedure

```text
1. FIELD DISCOVERY (who's on the Nov-3 ballot per district)
   CA/TX/NY → Wikipedia state House page (read per-district sections) → cross-check FEC candidate list
   FL       → FL DoE downloadcanlist.asp (final qualified field) → re-prune after Aug 18
   Independents/minor party → confirm against Politics1 + Ballotpedia (Wikipedia sometimes omits)

2. FEC IDs + FINANCE (feeds existing finance ingestion)
   FEC OpenFEC /v1/candidates/?office=H&state={ST}&election_year=2026  (paginate; cache JSON)
   Match by normalized "LAST, FIRST" surname -> candidate_id; honor name-mismatch queue lessons

3. HEADSHOTS (find-headshots conventions — already built)
   Incumbents: already have congress.gov / unitedstates.github.io photos (reuse)
   New challengers: Ballotpedia thumb (200x300, press_use fallback) -> campaign-site portrait
   -> process 600x750 4:5, upload politician_photos/<id>/default.jpg, insert politician_images row

4. STANCE SOURCES (research pipeline — already built)
   Campaign site issues page (primary) + VOTE411 questionnaire + local-news candidate Q&A
   FEDERAL 24-topic set (_TOPIC_SCALE_FULL.txt); chairs-not-polarity; honest-skip if no evidence
```

---

## Fetch-Walls & Workarounds (CRITICAL — verified this session)

| Source | Behavior | Workaround |
|--------|----------|------------|
| **Ballotpedia** | WebFetch returns **blank/empty** content (confirmed: `United_States_House_of_Representatives_elections_in_New_York,_2026` returned nothing). Cloudflare/bot block. | **Playwright** (headless browser) to render, OR the **Ballotpedia API** if available, OR pull the same facts from Wikipedia. Same wall the Senate-coverage + LA-illuminator work hit (403/blank). |
| **Wikipedia (long election pages)** | WebFetch returns **only the table of contents**, not the per-district candidate prose (confirmed for CA + FL pages). The data IS there in the rendered page. | Use the **raw wikitext API** (`en.wikipedia.org/w/index.php?title=...&action=raw`) or the REST `…/api/rest_v1/page/html/…`, OR **Playwright**, OR fetch a specific **section anchor** (`#District_12`). Do NOT conclude "no data" from a TOC-only WebFetch. |
| **State SoS sites** | CA/NY = JS-SPA; TX/FL = ASP (`*.asp`). Frequently fetch-wall or return shell HTML. | **Playwright** for the SPAs; for **FL specifically use the tab-delimited bulk download** (`downloadcanlist.asp`) which is plain text and scriptable — bypasses the SPA entirely. |
| **FEC API (DEMO_KEY)** | **Rate-limited to 10 req/hour** (confirmed: `X-Ratelimit-Limit: 10, Remaining: 0` after a few calls). Will stall a 144-district pull. | **Register a free FEC API key** at `api.data.gov/signup` -> **1,000 req/hour**. Pass as `?api_key=<KEY>`. Store in `backend/.env`. Cache responses (state-level pull returns the whole delegation in a few paginated calls — pull once per state, not per district). |
| **VOTE411 / onyourballot** | JS app; address-gated. | Playwright with an address in-district, or skip — it's a stance-enrichment bonus, not load-bearing. |

**Playwright is the universal workaround** and is already an established tool in this project (Elections page verified via Playwright in Phase 99; primary-source verification passes in quick-023). For any walled source: render with Playwright, extract text, then treat as a normal source.

---

## Installation / Setup

```bash
# FEC free API key (required — DEMO_KEY caps at 10/hr, too low for 144 districts)
#   1. Visit https://api.data.gov/signup  (instant email key)
#   2. Add to backend/.env:
#        FEC_API_KEY=<key>          # 1000 req/hr
# (project already ingests FEC finance — reuse existing FEC plumbing + name-match queue)

# Playwright (already used in-project for Elections verification; install if not present)
npm install -D playwright
npx playwright install chromium

# No new runtime deps. Stance pipeline / find-headshots / push scripts already exist:
#   backend/data/stance-research/quick-candidates-2026/  (_TOPIC_SCALE_FULL.txt, _push*.ts)
```

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **WebFetch on Ballotpedia** | Returns blank (Cloudflare bot-block) — silently yields "no data" | Playwright, or Wikipedia for the same facts |
| **Concluding "no candidates" from a TOC-only Wikipedia WebFetch** | The long election pages return only the TOC to WebFetch; the data is present in the full render | Raw wikitext API / section anchors / Playwright |
| **DEMO_KEY for the FEC bulk pull** | 10 req/hr — will stall mid-state and return 429 | Registered free key (1000/hr), cache per-state |
| **FEC `/candidates/search/?q=` with short/empty `q`** | 422 "keyword must be ≥3 chars" (confirmed) | Use `/v1/candidates/?office=H&state=&district=&election_year=2026` (structured filters, no `q`) |
| **Per-district FEC calls (144 of them)** | Wastes rate budget; risks throttle | One paginated **per-state** call (`state=CA` returns all 52 districts' filers) |
| **Inferring the general field from party registration / "safe seat" assumptions** | Top-two CA can be D-vs-D; incumbents lose primaries (NY-10 Goldman, NY-13 Espaillat both LOST 6/23) | Confirm every advancer from results — same chairs-not-polarity discipline as stances |
| **Seeding FL nominees before Aug 18 as if decided** | FL primary is the one PENDING race; primary losers must not appear as general nominees | Seed FL **qualified field** now (it's final/closed), mark provisional, prune losers after Aug 18 |
| **Trusting a single results outlet on uncalled races** | Close NY races may still be uncalled days after 6/23 | Cross-check NBC + AP/Politico; leave genuinely-uncalled races for a brief re-check |

---

## Field-Discovery Variants by State

**CA (top-two / jungle primary):**
- The **two** highest June-2 vote-getters advance, party-agnostic. Expect some same-party generals.
- Discover both advancers from Wikipedia "advanced to general" subsection + FEC for IDs.

**TX (partisan primary + May-26 runoff):**
- One nominee per party where settled in March; runoff races (39 statewide had runoffs) resolved May 26 — both now final.
- Watch for runoff-decided House nominees; Wikipedia reflects the runoff winner.

**NY (partisan primary, June 23 — just held):**
- Nominees set 6/23. Notable incumbent upsets (Goldman NY-10, Espaillat NY-13 lost) — **do not assume incumbent = nominee**.
- Open seats: NY-7 (Velázquez ret. -> Valdez), NY-12 (Nadler ret. -> Lasher). Confirm GOP/minor-party opponents too.

**FL (partisan primary, Aug 18 — PENDING):**
- Federal qualifying CLOSED -> the **candidate universe is final**; Aug 18 only narrows each party to one nominee.
- Seed-now strategy: ingest the full qualified field from FL DoE download, flag as `pending_primary`, then a single prune pass after Aug 18.

---

## Version / Currency Compatibility

| Source | Currency check | Notes |
|--------|----------------|-------|
| Wikipedia state pages | Updated within hours of results | Re-pull FL page after Aug 18 |
| FEC API | `election_year=2026`, `candidate_status` C=statutory candidate, N=newly-filed | `incumbent_challenge` I/C/O distinguishes incumbent vs challenger vs open |
| FL DoE download | `elecid=20261103-GEN` for the general | Re-download after Aug 18 to capture final nominees |
| NBC results | Live during/after 6/23 | For NY confirmation only |

---

## Sources

- [CA SoS — Primary June 2, 2026](https://www.sos.ca.gov/elections/upcoming-elections/primary-election-june-2-2026) — CA primary date verified (HIGH)
- [TX SoS — Mar 3 primary + May 26 runoff law calendar](https://www.sos.state.tx.us/elections/laws/advisory2025-17-mar-3-2026-primary-elec-law-cal-and-may-26-2026-primary-runoff-elec-law-cal.shtml) — TX dates verified (HIGH)
- [FL Division of Elections — Election Dates (Aug 18 primary)](https://dos.fl.gov/elections/for-voters/election-dates/) — FL primary date verified (HIGH)
- [FL DoE Candidate Tracking + download](https://dos.elections.myflorida.com/candidates/downloadcanlist.asp) — official FL candidate field, tab-delimited (HIGH)
- [NY BallotReady / NYC Votes — June 23, 2026 primary](https://www.nycvotes.org/whats-on-the-ballot/) — NY primary date verified (HIGH)
- [NBC News — NY House primary 2026 results](https://www.nbcnews.com/politics/2026-primary-elections/new-york-house-results) — NY nominee confirmation, fetchable (HIGH)
- [Wikipedia — 2026 US House elections in CA](https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California) — field discovery; TOC-only via WebFetch (MEDIUM — needs Playwright/raw wikitext)
- [Wikipedia — 2026 US House elections in FL](https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Florida) — same fetch caveat
- [FEC OpenFEC /v1/candidates](https://api.open.fec.gov/v1/candidates/) — verified live; DEMO_KEY 10/hr, registered 1000/hr (HIGH)
- [api.data.gov/signup](https://api.data.gov/signup) — free FEC key registration (HIGH)
- [Ballotpedia NY 2026 House](https://ballotpedia.org/United_States_House_of_Representatives_elections_in_New_York,_2026) — confirmed fetch-walled (blank via WebFetch) -> Playwright (HIGH on the wall behavior)
- [Politics1 FL](https://politics1.com/fl.htm) — minor-party/independent cross-check (LOW, human-curated)

---
*Data-sourcing research for: 2026 US House Wave-1 candidate coverage (CA/TX/FL/NY)*
*Researched: 2026-06-27*
