---
name: LA County Supervisors — Source Reference
description: Reliable sources and URL patterns for LA County Board of Supervisors research
type: reference
---

## Official Supervisor Pages

Each supervisor has an official page at `https://[firstname]horvath.lacounty.gov` or similar. Confirmed working patterns:
- Lindsey Horvath: `https://lindseyhorvath.lacounty.gov` (verified 2026-04-14)
- Hilda Solis: `https://hildalsolis.org` (official supervisor site — use `/housing-and-homelessness/`, `/justice-reimagined/`, `/immigration/`, `/transportation/`, `/digital-equity/`, `/motions-solis/`; `supervisorhildasolis.com` ECONNREFUSED; Ballotpedia page returns blank)
- Janice Hahn: `https://hahn.lacounty.gov`
- Kathryn Barger: `https://kathrynbarger.lacounty.gov`

## Horvath Site Structure

Key policy pages at `lindseyhorvath.lacounty.gov/`:
- `/sustainability-and-the-environment/` — climate, fossil fuels, clean energy
- `/homelessness-and-housing/` — housing, homelessness, eviction protections
- `/health-and-wellbeing/` — healthcare, reproductive rights, mental health, food security
- `/public-safety-justice-reform/` — criminal justice, jail, Measure J
- `/governance-ethics-reform/` — Measure G, redistricting, ethics commission
- `/protecting-our-communities/` — immigration, LGBTQ+, reproductive rights, civil rights
- `/immigration/` — immigration emergency declaration, immigrant resources
- `/lgbtq/` — LGBTQ+ Commission, gender-affirming care
- `/meet-lindsey/` — biography and issue summary
- `/newsroom/` — press releases (only ~6 show at once, no deep pagination)
- `/transportation-and-metro/` — transit policy

## Ballotpedia

`https://ballotpedia.org/Lindsey_Horvath` and `https://ballotpedia.org/Lindsey_P._Horvath` both returned empty content (not 404, just blank) as of 2026-04-14. Wikipedia was the reliable fallback.

## OnTheIssues

`https://www.ontheissues.org/CA/Lindsey_Horvath.htm` — 404 as of 2026-04-14. Horvath has no congressional record so no OTI profile.

## Notes

- lacounty.gov subdomain URLs (e.g., `bos.lacounty.gov/board-member/...`) 404d repeatedly. Use supervisor-specific subdomains directly.
- `horvath.lacounty.gov` returns ECONNREFUSED. Correct URL is `lindseyhorvath.lacounty.gov`.
- Sitemap at `lindseyhorvath.lacounty.gov/page-sitemap.xml` lists all page URLs — fetch this first to find policy pages.
