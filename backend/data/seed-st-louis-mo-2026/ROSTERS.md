# St. Louis, Missouri — rosters and their sources

Harvested 2026-09-28. Spec: [`.planning/todos/2026-09-28-st-louis-mo-deep-seed.md`](../../../.planning/todos/2026-09-28-st-louis-mo-deep-seed.md).

🔴 **Read this before seeding anything.** Every trap below was measured, not assumed.

## Files

| File | Source | Rows |
|---|---|---|
| `mo-house-roster-2026-09-28.json` | `house.mo.gov/MemberDetails.aspx?district=NNN&year=2026&code=R`, all 163 fetched, 0 errors | 163 |
| `mo-senate-roster-2026-09-28.json` | `senate.mo.gov/senators/` member cards | 33 |

## What each source is good for, and what it is not

- **The House member grid and detail pages are authoritative for WHO HOLDS THE SEAT TODAY.** They
  are not authoritative for when the term began: they publish `Elected:` (an election year) and
  `Years Served:` (a count of years in the chamber). See the spec for the seven rows that prove
  neither can be turned into a date.
- 🔴 **`house.mo.gov/DistrictInfo.aspx` — the address lookup — is AUTHORITATIVE FOR GEOGRAPHY AND
  STALE FOR OCCUPANCY.** It returns **Ian Mackey** for HD-99, which the member grid reports as
  **Vacant**. Use it to date the map; never to name an officeholder.
- **The term-start document is the House Journal**, `documents.house.mo.gov/billtracking/bills251/jrnpdf/jrn001.pdf`,
  which states *"FIRST DAY, WEDNESDAY, JANUARY 8, 2025"* and lists every member who *"advanced to
  the bar and subscribed to the oath of office"*.

## Homonyms — three of them are live in prod right now

| Missouri member | A DIFFERENT person of the same name already holds a seat in |
|---|---|
| Chad Perkins (HD-40) | Maine |
| Michael Johnson (HD-23) | South Carolina |
| Mike Jones (HD-12) | Pennsylvania |

And inside Missouri's own chamber, the House Journal itself disambiguates `Brown 149`/`Brown 16`,
`Jones 12`/`Jones 88`, `Smith 46`/`Smith 68`/`Smith 74`, `Taylor 48`/`Taylor 84` — and lists
⚠ **`Sharp 37` and `Sharpe 4`**, two different people one letter apart.

## Vacancies — 9 seats. Do not seat anyone on these

House **29, 95, 99, 110, 114, 149, 159, 160** · Senate **10**.

Set `offices.is_vacant`. Per CLAUDE.md, do **not** write a vacancy span whose start date is unknown.

## City of St. Louis

🔴 **The city's own "All Elected Officials" page is incomplete** — Sheriff, Public Administrator,
Circuit Clerk and Assessor appear **zero** times on it, and the city does elect at least the first
two. Take the office list from the ballot, not from that page.

Sources used: `stlouis-mo.gov/government/elected-officials.cfm`,
`stlouis-mo.gov/government/departments/aldermen/representation/index.cfm`, and the Board of Election
Commissioners' certified results PDFs.

## St. Louis County

⚠ **`curl` gets HTTP 403 from `stlouiscountymo.gov` even with a browser user agent. Use Playwright.**

🔴 **The seven council district pages do not name their members** — contact details only. An email
prefix is not a name.
