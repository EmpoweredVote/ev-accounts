# CA county wave — remaining work (as of 2026-08-10)

Shipped: 1629-1631, 1633, 1637-1639, 1641-1645, 1650, 1652, 1656 (seeds), 1635 (LA repair),
1646 (Sierra URL). **19 counties, 95 seats, 24.44M residents.** LA repaired. San Francisco
confirmed already complete. (Corpus-wide that is 20 CA county districts / 98 offices / 98 seated —
the extra county is LA, seeded before this wave and only repaired by it.)

## 🔴🔴 JANUARY 2027 RE-CHECK QUEUE (build this into the Jan-2027 pass)

Seats seeded with a holder who leaves in Dec 2026, and the successor already elected:
Contra Costa (Clerk-Recorder, Assessor) · Sonoma (ACTTC → Amanda Ruch) · San Mateo (Assessor-County
Clerk-Recorder → David Canepa) · Kern (Assessor-Recorder, Auditor-Controller-County Clerk) ·
Ventura (all six) · Solano (Treasurer/TC/County Clerk → **Denise Dix**) ·
**Santa Barbara (THREE: Auditor-Controller → Kyle Slattery; Clerk, Recorder and Assessor →
Melinda Greene; Treasurer-TC-PA → Kimberly A. Tesoro)**. Tulare and Stanislaus need no re-check.

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

## ✅ Tulare — SEEDED (migration 1645). 4 offices; the first county in the wave with NO Jan-2027 turnover.

## Tulare County (06107, pop 479,468) — DONE

`tularecounty.ca.gov` 403s plain curl and WebFetch with its own "Access denied" page — Playwright
renders it. But the two primary documents both live on the **`tc-web.widen.net` CDN, which is NOT
walled**, so each downloads with plain `curl`. Worth trying first on any county whose site 403s.

| Title (ACFR verbatim) | Holder | Occupancy start | Precision |
|---|---|---|---|
| Assessor/Clerk-Recorder | Tara K. Freitas | Apr 2021 (appointed) | month |
| Auditor-Controller/Treasurer-Tax Collector | Cass Cook | Oct 2017 (appointed) | month |
| District Attorney | Tim Ward | 2012 (appointed) | year |
| Sheriff-Coroner | Mike Boudreaux | 2013-10-08 (appointed) | day |

Roster from the county's **ACFR "List of Elected and Appointed Officials", printed p.15** of
`tc-web.widen.net/s/ldfs6xbkn5/tulare-county-acfr-24-25` (printed page == PDF page), cross-checked
against the certified **2026-06-02 Statement of Vote** (`.../s/fkq6vdxkxx/june-2-2026-statement-of-vote`),
then each holder re-confirmed on their own department page.

🔴 **THE ROV PAGE NAMED "ELECTED OFFICIALS INFORMATION" IS NOT A ROSTER.** Tulare publishes
`/elections/registrar-of-voters/elected-officials` — the exact path shape that gave Stanislaus its
roster PDF (1643) — and it contains only STATE/FEDERAL links plus a statutory terms-of-office table.
No county names at all. The source class is real; the page title does not identify it. Open and read.

🔴 **THE TWO PRIMARY DOCUMENTS DISAGREE ABOUT THE SUPERINTENDENT OF SCHOOLS — the roster wins.**
The SOV lists "County Superintendent of Schools" under its **COUNTY** heading (Tim A. Hire,
unopposed). The ACFR's elected-officials list does not, the org chart does not, and the department
directory has no Office of Education entry. Kern (1638) and Riverside (1630) resolved the same way;
San Bernardino / Alameda / Fresno seed one only because *their* rosters list it. **The ROV conducts
the election because that is its job — the ballot is not evidence of what is a county office.**
Migration 1645 carries a gate that fails if a Superintendent office ever appears here.

🔴 **THE REGISTRAR OF VOTERS IS APPOINTED HERE** (Michelle Baldwin, under *Appointed Officials*).
Sixth distinct office set in the wave.

🔴 **FIRST COUNTY IN THE WAVE WITH NO JANUARY 2027 TURNOVER.** Both seats on the 2026 ballot were
won by their own incumbents unopposed at 100.00% — Freitas (53,045) and Cook (52,618). No
post-turnover re-check needed. AB 759 holds for a sixth county (no DA, no Sheriff contest); a junk
`cal_access_discovery` row, the committee **"BOUDREAUX FOR SHERIFF 2028"**, says the same thing
from an unrelated direction.

🔴 **THE LETTERHEAD TRICK WORKED AGAIN — BUT THE LETTERHEAD LIED AND THE SIGNATURE BLOCK DID NOT.**
Three consecutive Treasurer's investment reports bracket Cook's start inside two weeks:
2017-10-03 letterhead *and* signature Rita A. Woodard → 2017-10-20 letterhead *and* signature Cass
Cook → **2017-11-17 letterhead RITA A. WOODARD, signed CASS COOK.** The November template simply
had not been updated, so it named someone who had already left, a month *after* a document naming
her successor in both places. Ventura (1639) read a start date *off* the letterhead; here that
would have been wrong in both directions. **Prefer the signature block — it is what the officer
actually asserted.** Reports go back to 2007 at `/treasurertaxcollector/treasurer/reports/`.

🔴 **A CONGRESSIONAL WITNESS BIOGRAPHY IS A CLEAN SOURCE FOR A LOCAL OFFICIAL'S START DATE.**
Boudreaux's exact appointment (2013-10-08, by the Board of Supervisors) is in no county document
found, but is stated in his official bio filed with the **U.S. House Judiciary Committee** for its
2024-09-10 hearing: `congress.gov/118/meeting/house/117608/witnesses/HHRG-118-JU00-Bio-BoudreauxM-20240910-U1.pdf`.
Reusable source class for any sheriff/DA who has testified.

Ward is **year** precision: his own office says only "has served as District Attorney since 2012";
no county document names the month (LinkedIn says December — not a source). The Nasarenko rule.

## ✅ Solano — SEEDED (migration 1650). 5 offices; the ACFR named the WRONG SHERIFF.

## Solano County (06095, pop 449,218) — DONE

`solanocounty.gov` is unwalled (plain curl), except the ROV roster whose accordion panels render
client-side — expand them in Playwright.

| Title (certified ballot / ACFR) | Holder | Occupancy start | Precision |
|---|---|---|---|
| Assessor/Recorder | Glenn Zook | Jan 2023 | month |
| Auditor-Controller | Janine Harris | Feb 2025 (appointed) | month |
| District Attorney | Krishna A. Abrams | 2014 (appointed) | year |
| Sheriff/Coroner | Brad DeWall | 2025-09-26 (appointed) | day |
| Treasurer/Tax Collector/County Clerk | Charles A. Lomeli | 1999 | year |

🔴🔴 **THE NEWEST, MOST OFFICIAL-LOOKING COUNTY DOCUMENT NAMED A RETIRED SHERIFF.** The FY2025 ACFR
was **published February 2026** and its Elected Officials org chart shows **Tom A. Ferrara** with a
photograph. Ferrara retired; the Board appointed Undersheriff **Brad DeWall on 2025-09-26**. The
chart is captioned "June 30, 2025" — it reports the fiscal year it covers, not the date it shipped.
Seeding from the ACFR alone — the document this wave leans on hardest (1638, 1639, 1645) — would
have put a retired sheriff in a live seat with every count-based gate passing. **Ask what a document
is AS OF, not when it was published.** 1650 guards against a "Ferrara" being seated.
(Second time a Solano-class sheriff seat changed hands with no election — cf. San Mateo, 1642.)

🔴 **THE ROV PAGE SETTLED ITS OWN AUTHORITY ON THE SUPERINTENDENT QUESTION.** Solano's ROV roster
lists SUPERINTENDENT OF SCHOOLS under "SOLANO COUNTY ELECTED OFFICIALS" — but the *same page* also
lists City of Benicia / Fairfield / Vallejo officials, nine school districts, three community
colleges and four special districts. It is an **elections directory of every office on the county's
ballots**, not a roster of county government. The ACFR's ELECTED OFFICIALS column lists five and no
Superintendent, the Department Head Listing has no Office of Education, and Parr's address is
`solanocoe.net`. Excluded, as in Kern (1638), Riverside (1630) and Tulare (1645). **Sharpened rule:
the discriminator is the county's own GOVERNMENT roster; a ballot directory is not one.**

🔴 **AB 759, SEVENTH COUNTY — AND HERE THE COUNTY CITES THE BILL BY NAME.** The ROV roster's own
footnote: *"With passage of AB 759, District Attorney and Sheriff elections will move to be in line
with Presidential Elections beginning in 2028"*, with both terms printed as 2022-2028. Stanislaus
(1643) stated it as data; Solano states it as law.

🔴 **ONE SEAT TURNS OVER JANUARY 2027 — the Contra Costa/Sonoma shape a third time.** All three
county contests were single-candidate: Zook 75,242 and Harris 74,801 (re-elected, continue), and
**Denise Dix 74,051** for Treasurer/Tax Collector/County Clerk. The county's press release of
2026-02-27 says Lomeli **retires 2026-12-28** after 28 years and endorsed his *Assistant* TTCCC,
Dix, to succeed him. Dix is not seeded; 1650 guards against it. **Re-check in January 2027.**

🔴 **Seventh distinct office set:** Assessor+Recorder combined, but Treasurer+Tax Collector+County
Clerk combined *separately* from the Recorder — a split no earlier county in the wave has. The ROV
is appointed here too (Tim P. Flanagan, who is also the CIO).

🔴 **ONLY ONE OF THE FIVE HAS A BIO PAGE** (`/government/sheriff-coroner/sheriff-coroner-brad-dewall`)
— and it is the one that gave an exact date. Lomeli's start came from arithmetic on a county press
release ("28 years", retiring 2026-12-28 → January 1999), which is why it is year precision.

## ✅ Santa Barbara — SEEDED (migration 1652). 5 offices; TWO SITTING OFFICERS WERE DEFEATED.

## Santa Barbara County (06083, pop 441,257) — DONE

`countyofsb.org` is not walled but is a CivicPlus site that renders department pages
**client-side** — plain curl returns a shell with no officeholder names. Use Playwright.
`da.countyofsb.org` and `sbsheriff.org` are ordinary sites where curl works.

| Title (certified ballot / dept) | Holder | Occupancy start | Precision |
|---|---|---|---|
| Auditor-Controller | Betsy M. Schaffer | Jan 2019 | month |
| Clerk, Recorder and Assessor | Joseph E. Holland | 2003 | year |
| District Attorney | John T. Savrnoch | 2023-01-02 | day |
| Sheriff-Coroner | Bill Brown | 2007-01-09 | day |
| Treasurer-Tax Collector-Public Administrator | Harry E. Hagen | 2011 | year |

🔴 **THE ACFR TRICK FAILS HERE — READ THE TOC FIRST.** Santa Barbara publishes a 17 MB ACFR whose
Introductory Section contains **only a letter of transmittal**: no principal-officials list, no org
chart. That is the San Joaquin shape (1641), not the Kern/Ventura/Tulare/Solano shape. Substitute =
the Registrar of Voters; the certified Statement of Vote is published as plain **HTML** at
`sbcvote.com/elections/results/2026june02/results-1.htm`, which is far easier to parse than the
185-page district-results PDFs other counties publish.

🔴🔴 **FIRST COUNTY IN THE WAVE WHERE SITTING OFFICERS WERE DEFEATED AT THE POLLS — TWO OF THEM.**
Certified June 2026: **Kyle Slattery 51.72% def. Auditor-Controller Betsy Schaffer 47.93%**;
**Melinda Greene 60.22% def. Clerk-Recorder-Assessor Joseph Holland 39.48%**; Kimberly A. Tesoro
98.49% (sole) succeeds the retiring Hagen. Every earlier turnover in this wave was a retirement or
an unopposed succession, where the incumbent's own page still being current was reassuring. **Here
the loser is still the correct holder through December 2026** — a post-election roster read
carelessly would seed the WINNERS eight months early. Verified the other way round: Schaffer and
Holland are both still named on their own department pages today. 1652 guards all three names.
Tesoro is the **fourth** "deputy succeeds a departing incumbent" case (Contra Costa, Sonoma, Solano).

🔴 **AB 759, eighth county** — no DA and no Sheriff contest on the certified ballot.

🔴 **Superintendent of Schools (Susan C. Salcido, 96.01%) on the county ballot, not seeded.** Same
rule as Kern/Riverside/Tulare/Solano — but note this county gives **no ACFR officials list to
cross-check**, so the discriminator rests on the department directory at `/cosb-departments` alone
(28 departments, no office of education; SBCEO is `sbceo.org`).

🔴 **Holland's start is the weakest row in the county wave so far and is deliberately coarse.**
Two accounts agree "first elected in March 2002", but one says he "has served since 2002" while the
same article's "seeking his sixth term" implies 2007. Recorded as **2003 at year precision** (the
statutory start after a regular March 2002 primary) with an explicit note. **Do not sharpen it on
the news accounts** — correct it only from a county primary.

## ✅ Monterey — SEEDED (migration 1656). 5 offices; the June winner ALREADY holds one of them.

## Monterey County (06053, pop 430,723) — DONE

`countyofmonterey.gov` 403s plain curl (WAF) but renders in Playwright, and a same-origin `fetch()`
reaches every path. `mcso.countyofmonterey.gov` redirects to the same host, so the Sheriff's pages
are same-origin too.

| Title (county roster) | Holder | Occupancy start | Precision |
|---|---|---|---|
| Assessor-County Clerk/Recorder | Xochitl Marina Camacho | 2022-12-31 (interim appt) | day |
| Auditor/Controller | Enedina Garcia | 2026-07-07 (appointed) | day |
| District Attorney | Jeannine M. Pacioni | Jan 2019 | month |
| Sheriff/Coroner | Tina M. Nieto | 2022-12-30 | day |
| Treasurer/Tax Collector | Jake Stroud | 2025-12-30 (appointed) | day |

🔴🔴 **THE JUNE 2026 WINNER ALREADY HOLDS THE AUDITOR-CONTROLLER SEAT — THE EXACT INVERSE OF THE
SANTA BARBARA TRAP (1652).** The county's elected-officials roster still names **Rupa Shah**; she
retired. The Auditor-Controller's *bios* page says **Enedina Garcia "was appointed Auditor-Controller
on July 7, 2026, by the Board of Supervisors, following the June 2026 election in which she was
elected to begin her first four year term in January 2027."** Seeding Shah would be wrong — and so
would mechanically applying 1652's rule that a 2026 winner waits until January. **"The winner is not
yet in office" is a DEFAULT, not a rule**; it is the same election-or-removal question as San Mateo
and Solano, asked in the opposite direction. Note the two county sources disagree and the *newer,
more specific* one wins: a bios page stating a dated Board action beats a roster listing a name.

🔴 **AND IT IS NOT THE ONLY ONE — TWO OF FIVE ARE RECENT BOARD APPOINTEES.** Jake Stroud "was
unanimously appointed by the Board of Supervisors and began serving on December 30, 2025". Monterey
turns over faster than any other county in the wave and its own roster had caught neither change.

🔴 **AB 759, ninth county, and the clearest statement of the mechanism yet.** The County Offices
roster prints for DA and Sheriff/Coroner: **Term Length: 6 · Next Election: 03/07/2028** — the
six-year term AND the presidential-primary date, in a table where every other office shows 4.

🔴 **Superintendent excluded on the strongest form of the discriminator yet:** the county's own
elections directory has separate top-level sections for **County Offices** and **Superintendents &
Board of Education Members**. The county files it outside County Offices itself.

🔴 **DAY-vs-MONTH FOR END-OF-DECEMBER STARTS — the rule this wave now follows.** Monterey seats
officials in the last days of December when a predecessor retires early (Camacho 12-31, Nieto 12-30,
both 2022) rather than at the statutory first-Monday-after-Jan-1. Contrast Solano's Zook (1650),
whose 2022-12-30 oath is reported only by a newspaper and so is recorded at month precision against
the statutory January start. **County publishes a specific date → day precision; only press reports
it → statutory month.** Camacho's is nailed by BoS File **APP 22-234** (meeting 2022-12-07) on
`monterey.legistar.com` — Legistar is a good primary-source channel for appointment dates.

**Monterey needs NO January 2027 re-check** — all three June winners are already the seated holders.

## Then: 6 more counties to reach the 93.4% target

By population: Placer, Merced, San Luis Obispo,
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
