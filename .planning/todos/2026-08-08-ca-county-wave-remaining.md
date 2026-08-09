# CA county wave — remaining work (as of 2026-08-08)

Shipped: migrations 1629, 1630, 1631, 1633 (seeds), 1635 (LA repair).
**8 counties, 38 seats, 17.19M residents.** LA repaired. San Francisco confirmed already complete.

## Standing rules for this wave (do not relax these)

1. **Roster first, office second.** Never create an office without a verified holder seated in the
   same migration. An office with no `office_terms` row is invisible everywhere and nothing errors.
2. **Read the primary document.** Search summarised Fresno's roster table **off by one row** —
   every name paired with the next office, two offices dropped. The identity gate cannot catch this
   (it compares the seated name to what you *intended*). See migration 1633's header.
3. **Office sets are 3–6 and differ per county.** Never template them.
4. `term_start` is **occupancy start**, not current-term start. Use `how_started`
   ('elected'/'appointed') and `start_precision` ('day'/'month'/'year'). Never invent a day.
5. `external_id` from the reserved band `-(62000000 + <3-digit county FIPS> * 1000 + seq)`.
   Keep the pre-flight collision gate — a collision silently seats the wrong person.
6. Scope every `geo_id` predicate by `district_type` (1,159 collisions exist corpus-wide).

## Tooling already sitting in the tree

- **`backend/.tmp-q.ts`** (untracked) — one-off read-only SQL runner:
  `cd /c/EV-Accounts/backend && npx tsx .tmp-q.ts <path/to/query.sql>`. Uses `DATABASE_URL`, prints
  JSON. Used for every verification query in this wave. Delete it whenever; it is not load-bearing.
- Apply migrations with `npx tsx scripts/_apply-file.ts migrations/NNNN_*.sql` (pure DML works as
  `ev_api`). Dry-run first: `sed 's/^COMMIT;/ROLLBACK;/'` into a temp file, run it, then CONFIRM the
  rollback actually reverted before applying for real.
- 🔴 `cd /c/EV-Accounts/backend &&` in the SAME command — cwd resets between Bash calls.

## Retrieval technique for bot-walled county sites

Several counties 403 both `curl` and WebFetch. What works:
- Navigate to the site in Playwright, then run a **same-origin `fetch()`** inside the page (it
  carries the site's cookies), return base64, decode to a file, and `Read` the PDF as a binary.
  Used for Fresno's ROV roster. LA County's tenure PDF downloads with plain `curl`.
- **Best source class: the Registrar of Voters "index/list of elected officials"** document.
  Fresno's even prints term dates (but those are the CURRENT TERM, not occupancy).

---

## ✅ Contra Costa — SEEDED (migration 1637). Kept below as the worked example.

## Contra Costa County (06013, pop 1,155,025) — DONE

District id `<look up by geo_id 06013>`. Six countywide elected offices. Titles taken from the
county's own org chart (`contracosta.ca.gov/DocumentCenter/View/39121/ContraCostaCountyOrgChart`,
where italics mark elected offices):

| Title (verbatim) | Holder | Source | Occupancy start |
|---|---|---|---|
| Assessor | Gus Kramer | county staff directory `Directory.aspx?DID=16`; 2026-27 assessment roll letter | **TODO** (since ~1995) |
| Auditor-Controller | Joanne M. Bohren | `/192/Auditor-Controller` + `Directory.aspx?DID=57` | **TODO** — APPOINTED 2025 |
| County Clerk-Recorder/Elections | Kristin B. Connelly | `contracostavote.gov` | **TODO** (first term, ~Jan 2023) |
| District Attorney | Diana Becton | `contracosta.ca.gov/9975` (contracostada.org redirects here) | **TODO** — appointed 2017, then elected |
| Sheriff-Coroner | David O. Livingston | `cocosheriff.org/about-us/sheriff-david-o-livingston-biography` | **TODO** (4th term; ~Jan 2011) |
| Treasurer/Tax Collector | Dan M. Mierzwa | `/199/Treasurer---Tax-Collector` | **TODO** — APPOINTED Jan 2024 |

🔴 Robert Campbell (Auditor-Controller 30+ years) **RETIRED**; Bohren was appointed to succeed him
and is not running in 2026. Do not seed Campbell.

🔴 The June 2, 2026 primary elected a new Clerk-Recorder and a new Assessor. **They take office
January 2027** — the holders above are correct through December 2026. Re-check after Jan 2027.

## ✅ Kern — SEEDED (migration 1638). Roster came from the ACFR "Directory of County Officials".

## Kern County (06029, pop 913,820) — DONE

`kerncounty.com` 403s WebFetch (Playwright works). `kernvote.com` publishes a Form 700 filer list
that names OFFICES but no people. Likely office set (UNVERIFIED — confirm from source):
Assessor-Recorder · Auditor-Controller-County Clerk · District Attorney · Sheriff-Coroner ·
Treasurer-Tax Collector · Superintendent of Schools.
Names seen only in search (**do not seed these — unverified**): Laura Jeanne Avila, Aimee Xochil
Espinoza, Cynthia Jane Zimmer, Donny Youngblood, Jordan Alexander Kaufman.
Next step: Playwright + same-origin fetch on each `kerncounty.com/government/departments/<dept>`.

## Ventura County (06111, pop 829,590) — NOT SOURCED

🔴 The county moved to **`venturacounty.gov`**; mig 1619's `official_web_url`
(`countyofventura.org`) is stale. `venturacounty.gov/government/elected-officials/` lists SIX office
titles and no names: Assessor · Auditor-Controller · Clerk-Recorder, Registrar of Voters ·
District Attorney · Sheriff · Treasurer-Tax Collector.
**2 of 6 CONFIRMED from primary sources (2026-08-08):**
- **District Attorney = Erik Nasarenko** — `da.venturacounty.gov` (that subdomain answers plain fetches)
- **Auditor-Controller = Jeffery S. Burgh** — signature block of the **FY2025 ACFR Letter of
  Transmittal**, `vcportal.venturacounty.gov/auditor/docs/financial-reports/Annual%20Comprehensive%20Financial%20Reports-2025/Letter%20of%20Transmittal%202025.pdf`
  (8 pages, page 8). 🔴 `vcportal.venturacounty.gov` is NOT walled — use it, not `venturacounty.gov`.

**Still needed (4):** Assessor · Clerk-Recorder, Registrar of Voters · Sheriff · Treasurer-Tax Collector.
Best next move: the FY2025 ACFR is published as SEPARATE component PDFs in that same folder. A
`List of Principal Officials 2025.pdf` / `Principal Officials 2025.pdf` returns 404, so find the
real filename by listing the 2025 folder or reading the FY2023 full ACFR
(`.../Annual Comprehensive Financial Reports-2023/Annual Comprehensive Financial Report 2023.pdf`,
already downloadable) for its principal-officials page — then CONFIRM each name against a current
page, since 2023 is stale.

🔴 **The other Ventura subdomains sit behind a WAF that returns "The requested URL was rejected"
to plain fetches** — `assessor.`, `sheriff.`, and `venturacounty.gov/ttc/` all rejected. Playwright
DOES render `venturacounty.gov`, so drive each department in the browser and read the DOM (or use
the same-origin `fetch()` trick once on that origin). Remaining to source:
`assessor.venturacounty.gov`, `sheriff.venturacounty.gov`, `clerkrecorder.venturacounty.gov`,
`venturacounty.gov/auditor-controllers-office/`, `venturacounty.gov/ttc/`.
Names seen only in search (**do not seed**): Jeffery Burgh (Auditor-Controller), Sue Horgan
(Treasurer-Tax Collector).

## Then: 14 more counties to reach the 93.4% target

By population: San Joaquin, San Mateo, Stanislaus, Sonoma, Tulare, Solano, Santa Barbara, Monterey,
Placer, Merced, San Luis Obispo, Santa Cruz, Marin (+ San Francisco already done, which displaces
Marin from the top 25).

## Adjacent defects found, not fixed

- **Orange County has only 2 of 5 supervisors seated** (Janet Nguyen D1, Doug Chaffee D4) on chamber
  `9e68f81c`. Three seats missing.
- Two chambers are both named **"County Board of Supervisors"** (LA `9de1e8c8`, Orange `9e68f81c`).
  Not duplicates — different counties, generic name. Renaming changes `chambers.slug`, which is
  GENERATED ALWAYS from `name_formal`, so it needs care.
- **`npm run check:migrations` cannot see a number collision once both sides are pushed** — it only
  diffs newly added files against `origin/master`. 1632 was claimed twice before this was noticed.
- San Francisco's 9 citywide officials all carry `start_precision='unknown'` from the phase-2
  backfill. Dates would be an easy quality win; the officials themselves are correct.
