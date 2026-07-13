# VA HD-67 Hillary Pugh Kent — stance pin (honest skip)

**Created:** 2026-07-12
**Status:** pinned skip; retry when a reliable individual-vote source appears

Hillary Pugh Kent (R, HD-67 Northern Neck; politician_id
982ad606-8fc5-4d99-9275-c24b09c65c0c) is the ONLY VA state legislator with
zero stances after the 2026-07-12 retry wave (Senate 40/40, House 98/99).

**Search trail (per no-pin-without-written-trail rule):**
- VPAP via r.jina.ai proxy: fetches returned internally INCONSISTENT vote data
  across re-fetches of the same URL (hallucinated-proxy failure mode) — all her
  individual vote data was discarded as unreliable rather than risk fabricated
  evidence.
- Campaign site (hillarypughkentva.com): bio only ("Wife, Mother, Businesswoman
  & Republican"), no issue statements.
- Ballotpedia: no Candidate Connection survey (2023 or 2025); page 403-walled.
- News search: no independently attributable policy statements found.

**Party note:** DB said Democrat — FIXED to Republican in mig 1329 (verified
VPAP + own site + Ballotpedia).

**Retry hooks:** Playwright-rendered VPAP per-legislator vote page
(vpap.org/legislators/288244-hillary-pugh-kent/), official House Clerk roll-call
PDFs, or her 2027 re-election campaign materials.

**Proxy lesson (applies wave-wide):** only trust VPAP-via-r.jina.ai vote data
when tallies cross-check against known roll-call totals or repeat identically
on re-fetch.
