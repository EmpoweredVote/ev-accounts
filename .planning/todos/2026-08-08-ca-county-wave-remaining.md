# CA county wave — remaining work (as of 2026-08-08)

Shipped: migrations 1629, 1630, 1631, 1633, 1637, 1638, 1639 (seeds), 1635 (LA repair).
**11 counties, 55 seats, 20.08M residents.** LA repaired. San Francisco confirmed already complete.
(Corpus-wide that is 12 CA county districts / 58 offices / 58 seated — the extra county is LA,
seeded before this wave and only repaired by it.)

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

## ✅ Ventura — SEEDED (migration 1639). 6 of 6 sourced from one primary document.

## Ventura County (06111, pop 829,590) — DONE

The whole roster came from **one page of the county's own ACFR**: "LISTING OF PRINCIPAL OFFICIALS /
JUNE 30, 2025", section ELECTED OFFICIALS → *Other Elected Officials* — printed page 14, **PDF page
20** of `vcportal.venturacounty.gov/auditor/docs/financial-reports/Annual%20Comprehensive%20Financial%20Reports-2025/Annual%20Comprehensive%20Financial%20Report%202025.pdf`
(10.7 MB, downloads with plain `curl`). The same page also names the five supervisors.

🔴 **The component-PDF hunt was the wrong move.** `Principal Officials 2025.pdf` and friends all
404; the FULL ACFR is published under a predictable name in that folder and its **table of contents
gives the page number** ("Listing of Principal Officials … 14"). Printed page 1 = PDF page 5.
Download the whole report and read two pages — that is cheaper than guessing filenames.

| Title (verbatim, county elected-officials page) | Holder | Occupancy start | Precision |
|---|---|---|---|
| Assessor | Keith Taylor | 2023 | year |
| Auditor-Controller | Jeffery S. Burgh | 2014 | year |
| Clerk-Recorder, Registrar of Voters | Michelle Ascencion | 2023 | year |
| District Attorney | Erik Nasarenko | 2021 (appointed) | year |
| Sheriff | James Fryhoff | 2023-01-02 | day |
| Treasurer-Tax Collector | Sue Horgan | Jan 2023 | month |

Titles are from `venturacounty.gov/government/elected-officials/`, not the ACFR (which says "Clerk
and Recorder"). Each holder was re-confirmed against a current department page before seeding —
the ACFR is 13 months old.

🔴 **All six were on the 2026-06-02 ballot; winners take office January 2027.** Re-check with the
rest of the wave.

🔴 **Bracketing a start date off LETTERHEAD works.** Burgh's start was in no bio anywhere. His own
office's audit PDFs settle it: he signs *Assistant* Auditor-Controller on 2014-01-30 and 2014-04-25,
and *Auditor-Controller* on the FY2014-15 Internal Audit Plan and the 2015-01-27 board letter. That
is a sourced YEAR, not a guess — and note the Jan-2014 letterhead has **no** Auditor-Controller name
at all, i.e. the office was vacant and the predecessor had already gone.

🔴 **A widely repeated date can still be unusable.** Search says Nasarenko was appointed by a 5-0
Board vote on 2021-01-26. No county document confirmed it, so the migration records 2021 at year
precision instead. The DA office's own "Past District Attorneys" page (Totten *2002-2021*) plus his
bio (elected 2022-06-07) is what carries the year.

🔴 **WAF note.** `venturacounty.gov` and every department subdomain answer plain fetches with
"The requested URL was rejected" — **HTTP 200, 269 bytes**, so a status-code check reads it as
success. `clerkrecorder.` returns **202 with an empty body** instead. Playwright renders all of
them; the same-origin `fetch()` trick works per-origin (cross-origin `fetch` from another Ventura
host is CORS-blocked — navigate first). `vcportal.venturacounty.gov` is NOT walled.

Also repointed the district's `official_web_url` to `https://venturacounty.gov/` (the old
`countyofventura.org` still 301s there, so it was stale rather than dead).

**Not done for Ventura:** the five supervisors (LaVere D1, Gorell D2, Long D3, Parvin D4, Lopez D5,
per that same ACFR page) are unseated — same scope rule as every other county in this wave.

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
