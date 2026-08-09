# CA county wave — remaining work (as of 2026-08-08)

Shipped: 1629-1631, 1633, 1637-1639, 1641-1644 (seeds), 1635 (LA repair).
**15 counties, 76 seats, 22.64M residents.** LA repaired. San Francisco confirmed already complete.
(Corpus-wide that is 16 CA county districts / 79 offices / 79 seated — the extra county is LA,
seeded before this wave and only repaired by it.)

## 🔴🔴 NEXT TASK FOUND: `official_web_url` IS ROTTEN ACROSS ALL 58 CA COUNTIES

Sonoma's stored county URL turned out to redirect to **winecountry.com**, a commercial tourism
site. That prompted a sweep of all 58 CA county districts (`district_type='COUNTY'`, `state='ca'`):

- **2 point at NON-COUNTY sites.** `sonomacounty.org` → winecountry.com (fixed in 1644);
  🔴 **Sierra County `sierracounty.ws` → `mampir123.org`**, an expired-domain takeover serving
  "The mampir123". STILL BROKEN — not fixed here.
- **28 of 58 do not return 200.** Many are dead hosts (`co.alameda.ca.us`, `co.marin.ca.us`,
  `co.napa.ca.us`, `co.solano.ca.us`, `co.slo.ca.us`, `san-benito.ca.us`, …); some are only
  WAF 403s that a browser would render, so **each needs classifying, not bulk-replacing**.
- **1 is a typo:** Lake County holds `http://www.w.co.lake.ca.us` ("www.w."). `co.lake.ca.us`
  answers 200 and the current site is `lakecountyca.gov`.
- **14 redirect off the stored host**, mostly benign `.ca.us` → `.gov` migrations.

**A URL that resolves is not evidence that it resolves to the county.** Worth its own migration;
check the other states too, since these all came from the same migration-1619 import.

## ⭐ LOOK FOR AN ROV "ELECTED OFFICIALS" LIST FIRST

Stanislaus' Registrar publishes `stanvote.com/pdf/elected-officials-list.pdf` — office, name,
election year and **term expires** in one table, with `(A)` marking appointees, updated fortnightly.
One PDF replaced six department pages, and its term-expiry column independently confirmed AB 759.
Riverside has the same thing as a compensation page. **Check for this before reading department
sites** — then still confirm each holder once against their own page.

## 🔴🔴 CORRECTION TO EVERY EARLIER MIGRATION HEADER — AB 759

Migrations 1630–1641 each say "all countywide seats were on the 2026-06-02 ballot; winners take
office January 2027". **That is wrong for DA and Sheriff in every California county.**
**AB 759 (Chapter 743, approved 2022-09-29)** amended Elections Code §1300 and Government Code
§24200: *"An election to select a district attorney and sheriff shall be held with the presidential
primary"*, and *"a district attorney or sheriff elected in 2022 shall serve a six-year term and the
next election for that office shall occur at the 2028 presidential primary."*

- The 2026 winners for Assessor / Auditor / Controller / Clerk / Treasurer seats **do** take office
  January 2027 — that part stands.
- **DA and Sheriff do not turn over until January 2029.** Ventura's, Kern's, Contra Costa's and
  Fresno's DA/Sheriff rows are good two years longer than their headers claim. **No seeded row is
  wrong** — occupancy is unaffected; only the re-check dates in those comments.
- Diagnosis path worth remembering: San Joaquin showed the symptom (no DA/Sheriff contest on its
  certified 2026 ballot), San Mateo showed the same gap, and two counties agreeing meant a
  statewide cause rather than a local quirk. Then read the bill text, not a summary of it.

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

## ✅ San Joaquin — SEEDED (migration 1641). 5 offices; NOT an ACFR county.

## San Joaquin County (06077, pop 800,965) — DONE

**`sjgov.org` is NOT walled** — plain `curl` works, so each holder came straight off their own
department page: `/department/assessor` (Steve J. Bestolarides), `/department/aud`
(Jeffery M. Woltkamp), `/department/da` (Ron Freitas), `sjsheriff.org` (Patrick Withrow),
`/department/ttc` (Phonxay Keokham).

🔴 **THE ACFR TRICK FAILS HERE — CHECK THE DOCUMENT TYPE BEFORE PLANNING AROUND IT.** San Joaquin
publishes *audited financial statements prepared by CLA*, not an ACFR: no introductory section, so
no principal-officials page. **The substitute is the Registrar of Voters.** The certified
**Statement of Votes Cast** names the countywide contests exactly (its TOC alone is enough), and
the **qualified candidate list** carries each incumbent's ballot designation — which cross-checked
three of the five holders against a second county document with no row shift.

🔴🔴 **"ALL CA COUNTY SEATS WERE ON THE JUNE 2026 BALLOT" IS FALSE — SAN JOAQUIN RUNS TWO CYCLES.**
The 2026 SOV lists Assessor-Recorder-County Clerk, County Auditor-Controller and Treasurer-Tax
Collector and **no DA and no Sheriff**. Not a single-candidate cancellation either: the SOV's own
"Resolution to Appoint Candidates in Lieu of Election" (R-26-46) covers only two Board of Education
trustee areas. So those two terms do not expire in January 2027. Ballotpedia puts the DA's term end
at 2029-01-08 (a one-time extension onto the presidential cycle would explain it) — **mechanism
unverified, not asserted in the migration.** Re-check the other three after Jan 2027; leave DA and
Sheriff until 2028. **Test this assumption per county from now on rather than carrying it.**

🔴 **THE LETTERHEAD TRICK PAID OFF AGAIN, AND CONTRADICTED THE CALENDAR.** Keokham was elected
2018-06-05, which implies a January 2019 start — but he was already certifying the county treasury
over his own name on the **2018-07-31** and **2018-08-31** monthly portfolio reports. Same shape as
Ventura's Burgh: elected in June to an already-vacant office. Recorded as 2018 at year precision.

🔴 **A STATE agency can be the primary source for a COUNTY appointment.** Bestolarides' exact start
(2015-08-25, appointed to finish Kenneth Blakemore's term) came from **CA State Board of
Equalization Letter To Assessors No. 2015/048** — `boe.ca.gov/proptaxes/pdf/lta15048.pdf`. BOE
issues an LTA for every new county assessor; that is a reusable source class for all 58 counties.

Freitas and Woltkamp are **month** precision, not day: their 2023-01-02 start is widely repeated
and the county's own press-release URL is dated 2023/01/03, but that release is no longer served,
so no primary document could be read for the day.

🔴 **MIGRATION NUMBER COLLIDED MID-FLIGHT.** This shipped as 1640, was applied to prod, and then
another session pushed `1640_seed_tarrant_county_full_ballot.sql`. Renumbering meant fixing the
filename, the header, the in-file `source` strings **and the `source` text already written to
prod** — the migration carries a guarded UPDATE that repoints those 10 rows. `check:migrations`
only catches this when the other side is already on `origin/master`, so **re-run it immediately
before committing, not only when you write the file.**

## ✅ San Mateo — SEEDED (migration 1642). 6 offices, including a separately elected CORONER.

## San Mateo County (06081, pop 726,353) — DONE

`smcgov.org` is unwalled and its own nav carries an **"Elected Officials"** block — the cleanest
office-set source this wave has found. Titles come from the **certified Election Summary Report**
for 2026-06-02 (certified 2026-06-30); each holder from that office's own page.

🔴 **SAN MATEO ELECTS A SEPARATE CORONER** — most CA counties fold it into a Sheriff-Coroner. Fourth
distinct office set in this wave. Also note the county nav says "Tax Collector - Treasurer" while
the certified ballot says "Treasurer-Tax Collector"; the ballot name wins.

🔴🔴 **THE SHERIFF SEAT CHANGED HANDS WITH NO ELECTION, AND THE OFFICE'S HOME PAGE NAMES NO
SHERIFF.** Christina Corpus (elected 2022) was **removed** in 2025; the Board appointed **Kenneth
Binder**, who took the oath **2025-11-12**. Found only because the homepage naming nobody looked
wrong and the `/administration` page was checked. Any stale roster would have seeded Corpus. The
migration carries a named guard that fails if a "Corpus" is ever seated in this county.
**Recency of a source ≠ freshness of a roster — what matters is whether an election OR A REMOVAL
fell in between.**

🔴 **One seat turns over in Jan 2027:** David Canepa won Assessor-County Clerk-Recorder (56.21%);
Mark Church did not run and is the correct holder through December 2026. Raigoza, Foucrault and
Arnott each won unopposed.

## ✅ Stanislaus — SEEDED (migration 1643). 6 offices, from the ROV's own roster PDF.

## Stanislaus County (06099, pop 551,430) — DONE

Roster from `stanvote.com/pdf/elected-officials-list.pdf` (updated 7/27/26), every name
re-confirmed against that office's own bio page. Titles are the ROV's: **"Sheriff-Coroner"** (not
"Sheriff") and **"County Clerk-Recorder"** (though that department's own page says "Clerk-Recorder,
Registrar of Voters").

| Title | Holder | Occupancy start | Precision |
|---|---|---|---|
| Assessor | Don H. Gaekle | Oct 2013 (appointed) | month |
| Auditor-Controller | Mandip Dhillon | Oct 2024 (appointed) | month |
| County Clerk-Recorder | Donna Linder | Jan 2019 | month |
| District Attorney | Jeff Laugero | 2023-01-03 | day |
| Sheriff-Coroner | Jeff Dirkse | 2019-01-07 | day |
| Treasurer-Tax Collector | Donna Riley | Jan 2019 | month |

🔴 **AB 759 CONFIRMED BY A COUNTY DOCUMENT.** The ROV list states it as data: DA and Sheriff-Coroner
show election year **2028**, term expires **1-8-29**; the other four show 2026 / 1-4-27.

🔴 **A NAME-SHAPED REGEX FOUND A MURDER DEFENDANT.** Scanning the DA site for "District Attorney
<Name>" returned "District Attorney Peterson" — office news about the **Scott Peterson** case, not
the officeholder (Jeff Laugero). Pattern matching over a department site finds the office's subject
matter as readily as its staff. Only reading the page catches it.

🔴 **Linder and Riley are MONTH, and the early-start check was INCONCLUSIVE.** Both elected
2018-06-05. January 2019 is carried by the county's own term arithmetic (terms expire 1-4-27 = two
four-year terms back) and by their peer Dirkse being sworn 2019-01-07 — but the San Joaquin-style
check for an early start could not be completed: the Nov 2018 SOV is a ~50 MB scan that would not
download intact and the HTML summary has no signature block. Day precision was not assumed.

## ✅ Sonoma — SEEDED (migration 1644). FOUR offices — the most consolidated set in the wave.

## Sonoma County (06097, pop 481,812) — DONE

| Title | Holder | Occupancy start | Precision |
|---|---|---|---|
| County Clerk-Recorder-Assessor | Deva Marie Proto | Jan 2019 | month |
| Auditor-Controller-Treasurer-Tax Collector | Erick Roeser | Jun 2017 (appointed) | month |
| District Attorney | Carla Rodriguez | Jan 2023 | month |
| Sheriff-Coroner | Eddie Engram | 2023-01-02 | day |

🔴 **FOUR OFFICES — two mega-combined seats do the work of six elsewhere** (one officer is Auditor
+ Controller + Treasurer + Tax Collector; another is County Clerk + Recorder + Assessor + ROV).
Fifth distinct office set in the wave; a template would have invented two or three empty seats.

🔴 **THE CANDIDATE LIST IS WHAT REVEALED THE PENDING TURNOVER.** The only candidate for ACTTC is
**Amanda Ruch**, ballot designation "*Assistant* Auditor-Controller" — the incumbent didn't run.
That is the Contra Costa shape, where the deputy standing for the seat meant the incumbent had
already gone mid-term. Checked, not assumed: Roeser's own department page still has him in office,
so he holds through Dec 2026 and Ruch takes over Jan 2027. The migration carries a guard that fails
if Ruch is ever seated early. **Re-check this county in January 2027.**

Office set came from the ROV's "Candidates on the Ballot" page — a good substitute where no
standing elected-officials roster exists (Stanislaus has the better version).

## Then: 10 more counties to reach the 93.4% target

By population: Tulare, Solano, Santa Barbara, Monterey, Placer, Merced, San Luis Obispo,
Santa Cruz, Marin (+ San Francisco already done, which displaces Marin from the top 25).

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
