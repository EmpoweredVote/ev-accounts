# Fabricated-source sweep — COMPLETE. Findings, corrections, and what the numbers do not say

**Run 2026-08-06, resuming the 2026-08-05 run. Nothing has been retired. No migration has been written.**
Supersedes the coverage section of `2026-08-05-fabricated-source-sweep-FINDINGS.md`; that document's
findings table is still valid, it is the *totals* and the *stopped-early* framing that were wrong.

Evidence: per-chunk artifacts `fabricated-article-sweep-{dated,undated}-*.json` (47 undated + 14 dated).
New findings only: `2026-08-06-fabricated-new-34.json`. Prior 87: `2026-08-05-fabricated-confirmed-87.json`.
Tooling: `sweep-fabricated-articles.mjs`, `sweep-wide.sh`, `aggregate-fabricated-sweep.mjs`,
`fabricated-impact-report.mjs` — all committed under permanent names.

---

## ✅ Coverage is now COMPLETE. This is the first total in this workstream that is not a floor.

| | URLs |
|---|---|
| Eligible (specific page, ≥2 path segments) | **13,705** |
| **With a verdict** | **13,705 (100.0%)** |
| Never probed | **0** |
| ✅ NO_ANSWER re-probed and resolved (was the un-evaluated hole) | **1,025** |
| Remaining un-evaluated: archive.org citations, moot by design | 73 |
| **Genuinely evaluated** | **13,632 (99.5%)** |

✅ **The "126 degraded NO_ANSWER" caveat is CLOSED** — every one was re-asked with curl, per-host pacing
and a 25s timeout. 914 answered LIVE, 111 reproduced as dead across two independent measurements, and
**not one new fabrication was hiding there.** See the re-probe section below.

Computed by `aggregate-fabricated-sweep.mjs` from the artifacts, not by hand. Undated 11,728 URLs across
47 chunks, dated 1,977 across 14 — **0 duplicate URL records and 0 gaps**, verified.

### 🔴 Three corrections to the 2026-08-05 coverage claims

1. **"Chunks 30–47 not probed, 4,478 URLs."** It was 4,228 undated, because 30 undated chunks had
   completed rather than 29.
2. **"1,977 article-shaped cited URLs remain unswept" / 1,945 dated probed.** 32 dated URLs had no
   verdict — and they were **indices 0–31, the HEAD of the ordering, not a tail**: the single
   most-cited URLs in the entire dated corpus, including one cited by **147 rows**
   (`mainerighttolife.org/.../2025-132nd-House-Roll-Call.pdf`) and another by 34. A fabrication there
   would have outweighed every finding in the doc's table. **All 32 probed clean (LIVE).**
3. 🔴 **"The run stopped at chunk 29" was wrong: it never stopped.** See below — this is the important one.

---

## 🔴 THE PREVIOUS SESSION'S RUN WAS STILL ALIVE, AND I RAN A SECOND ONE ON TOP OF IT

The 2026-08-05 doc says the run "stalled at chunk 29" and told the next session to resume there. It had
not stalled. It was still executing, at the un-fixed ~55s/URL, in a shell from the previous session.
Node PID 2533140 started at 22:07:11 and `fabricated-article-sweep-undated-7250-7500.json` carries mtime
22:07:11; it then spent nearly two hours on the next chunk and wrote it at **00:05**, *overwriting the
copy my run had already produced*. Two more old node processes (21:58, 22:05) were alive alongside it.

**What that cost, and what it did not.**
- For ~2 hours two sweeps hammered the same hosts. **`malegislature.gov` "blocking us" is almost
  certainly my own duplicate load** — 60 of its URLs recorded NO_ANSWER at 00:13, and the same chunk
  re-run later returned **250/250 LIVE**. I diagnosed a host-side block and the cause was on this side.
- My "the doc undercounts completed chunks by one" correction was measured against a **moving target**:
  the completed-chunk count was rising while I counted it.
- **No finding is affected.** FABRICATED requires a 404 from a live server; contention cannot manufacture
  one. Contention produces false NO_ANSWER only — the safe direction, and that is the re-probe queue.
- Where the two runs overlapped, the surviving artifact for 7500–7750 is the **old** run's, and its data
  is *better* (46 LIVE vs my 19): paying the full 55s got more answers out of a throttling host.

⚠ **Before resuming any long sweep, check for a live one** (`ps` for node started before this session).
"It stalled" is a hypothesis about a process, and this workstream has now twice mistaken *slow* for
*dead*. Artifact mtimes are the cheap check: they were rising the whole time.

🔴 **AND I LAUNCHED A DUPLICATE OF MY OWN DRIVER.** `nohup … &` inside an already-backgrounded call left
two copies of `sweep-wide.sh` running in near-lockstep, each re-doing chunks the other had written —
chunk 11250-11500 was written at 01:47 and rewritten at 01:58. So three sweeps were live at once, not
two. Launch a long driver **once**, in one mechanism, and confirm a single process before walking away.

⚠ **"The log stopped growing" is NOT proof a sweep finished.** I checked the driver log at 01:53, saw it
stable, and reported the run complete — while a second driver kept writing artifacts until **02:00**.
The log belonged to one process; the work did not. **Check the artifacts' newest mtime over an interval,
and check for live node processes.** Two verdicts moved between my first and final aggregate because of
this (one URL EXISTS→INCONCLUSIVE): totals taken while anything is still writing are provisional.
✅ The 121 FABRICATED and the 34 new were **identical across both aggregates** — findings were stable
even while the tail was not.

---

## Findings: 120 fabricated URLs → 389 stance rows, 83 politicians

*(121 → 120: the control re-derivation below downgraded one. Pre-re-derivation: 121 / 390 / 84.)*
87 prior + **33 new** (34 found, 1 downgraded). Row-citations 410 — a row can cite more than one.

| host | urls | row-cites | new? |
|---|---|---|---|
| `actonmass.org` | 26 | 210 | |
| `dailybreeze.com` | 12 | 34 | |
| `somervillema.gov` | 5 | 33 | 🔴 gov |
| `lynnjournal.com` | 15 | 30 | |
| `sgvtribune.com` | 6 | 19 | |
| **`markey.senate.gov`** | **11** | **16** | **+8 new** 🔴 US Senate |
| `carsonca.gov` | 1 | 8 | gov |
| **`pressley.house.gov`** | **5** | **8** | **+4 new** 🔴 US House |
| **`lynnma.gov`** | **6** | **7** | **+5 new** gov, ⚠ thin control |
| **`marylandmatters.org`** | **6** | **6** | **+2 new** |
| `ladowntownnews.com` / `mass.gov` | 1 / 1 | 5 / 5 | |
| **`theeastsiderla.com`** | **2** | **5** | **+1 new** |
| `bostonglobe.com`, `kamlager-dove.house.gov` | 3, 3 | 3, 3 | |
| **`moulton.house.gov`** | **3** | **3** | **all new** 🔴 US House |
| **`oag.ca.gov`** | **3** | **3** | **all new** 🔴 CA Attorney General |
| **`medfordma.org`** | **2** | **2** | **all new** gov |
| `govtrack.us` | 1 | 2 | |
| singles: `precinctreporter.com`, `commonwealthbeacon.org`, `governor.maryland.gov` | 1 each | 1 each | |
| **new singles: `latimes.com`, `slc.gov`, `lynch.house.gov`, `onyourballot.vote411.org`, `cbsnews.com`** | 1 each | 1 each | **all new** |
| ~~`audacy.com`~~ | — | — | found new, then **downgraded to WEAK_CONTROL** on re-derivation |

### Two things the new findings establish that the old set did not

🔑 **A congressional `/issues/<topic>` class, and a generation tell.** `lynch.house.gov/issues/technology`,
`moulton.house.gov/issues/technology`, `pressley.house.gov/issues/technology` — **the same invented slug
on three different members' sites**, plus `/climate`, `/democracy`, `/seniors`, `/jobs-economy`,
`/national-security`. Real siblings on those hosts are `/economy`, `/education`, `/energy`, `/congress`,
`/covid-19`, `/criminal-injustice`. Verified by hand: `pressley.house.gov/issues/healthcare` → 200,
`pressley.house.gov/issues/climate` → 404.

🔑 **The lowellsun shape reaches NATIONAL outlets.** `cbsnews.com/news/murkowski-ukraine-aid/` — real
live outlet, article that never existed. The audit has been assuming this defect lives in thinly-covered
local papers. It does not.

✅ **Detector validation, unprompted:** `latimes.com/socal/daily-pilot/news/story/carson-economic-development-council`
is one of the four URLs the 2026-08-05 doc records as found **by hand** among co-sources. The widened
sweep re-found it independently, which is the evidence that eligibility-by-depth did its job.

---

## ✅ DETECTOR FLAW FOUND **AND FIXED**, ALL 121 CONTROLS RE-DERIVED (2026-08-06)

**The control counted the wrong thing.** It counted distinct archived URLs under the prefix — which
includes crawler asset paths and the section's own index — and called them "sibling pages".

⚠ **My first diagnosis of this said "it counts CAPTURES, not pages". That was wrong.** `collapse=urlkey`
does dedupe: `lynnma.gov/news*` is 240 captures and 8 distinct URLs, and the sweep recorded 8. The defect
was never double-counting; it is **which URLs qualify as a sibling.** Three ways it inflated, all on real
findings:

| control | reported | real pages | what the rest were |
|---|---|---|---|
| `pressley.house.gov/issues*` | 200 | **6** | 993 of 1,000 are JS module paths (`/issues/dojo/dom-class`, `/issues/esri/dijit/Popup`) from an embedded ArcGIS widget |
| `lynnma.gov/news*` | 8 | **7** | `/news`, `/news/archived_news`, `/news/what_s_new` are section indexes, not articles |
| `audacy.com/knxnews/news/local*` | 200 | **1** | almost all are entity-mangled image URLs: `/local/&apos;https://images.radio.com/….jpg?width=70` |

**Fixed** in `cdxSiblingPages()`: query `fl=original` at limit 1000, drop asset/module segments and file
extensions, and require a sibling to be deeper than the controlled section. Both numbers are kept —
`control_siblings` is now real pages, `control_urls` the raw count — so an inflated control stays visible
instead of being silently corrected away.

### Re-derivation result — 59 distinct controls behind 121 findings

| | |
|---|---|
| still FABRICATED | **120** urls, 410 row-cites |
| **DOWNGRADED** | **1** — `audacy.com/…/la-councilmember-traci-park-blasts-sanctuary-city-law` → **WEAK_CONTROL** (1 real page) |
| control unresolved | 0 |

🔑 **The re-derivation can only ever downgrade.** Filtering removes siblings, so no URL can cross *into*
FABRICATED — this pass cannot manufacture a finding, only retract one that was never proven.

Artifacts updated in place with `verdict_original` and `control_siblings_urls_original` preserved.
Record: `2026-08-06-control-rederivation.json`.

### ✅ The 11 thin-control findings were HAND-CHECKED (2026-08-06). All 11 resolve; none are dropped.

A thin control means *the archive cannot prove absence by itself* — so each was decided on evidence that
does not depend on the sibling count. **Verdict: 10 confirmed, 1 re-point. Nothing withdrawn.**

**`lynnma.gov/news/*` — 6 findings, CONFIRMED and effectively upgraded.** The thin control here is not an
archive gap:
- All 6 cited URLs **404 live**.
- 🔑 **The archive's coverage is COMPLETE relative to the live site.** `lynnma.gov/news/what_s_new/` today
  lists exactly the same 4 articles the archive holds. The section is genuinely tiny; Wayback did not
  miss anything. So absence *is* meaningful despite the count of 7.
- 🔑 **The cited URL convention does not exist on this site.** Real articles are
  `/news/what_s_new/<underscore_slug>`; every citation is `/news/<hyphen-slug>`. **Zero** hyphenated
  `/news/<slug>` links appear anywhere on the live index or section page.
- 🔑 **Topic test over 3,000 archived `lynnma.gov` URLs** (the willametteweek rule — ask whether the
  outlet ever covered the topic): `complete street` **0**, `homeless` **0**, `housing development` **0**.
  `waterfront`/`harbor` appear only as 2008–2011 planning PDFs and a parks page — never as news. The
  Nicholson hits are all campaign-finance PDFs, never a housing announcement.

**`pressley.house.gov/issues/*` — 5 findings, 4 CONFIRMED + 1 RE-POINT.**
⚠ The site **has restructured**: issue pages now live at the ROOT (`/criminal-injustice/`,
`/energy-the-environment/`, `/housing/`), not under `/issues/`. This is exactly the case the 08-05 doc
warned about, so each was tested against the **live taxonomy**, not the archive.
- 🔴 **`/issues/criminal-justice` → RE-POINT, do not retire.** Pressley's real page is
  **`criminal-injustice`** — her deliberate wording — and it is **live 200**. The citation is a
  one-word corruption of a real page, not an invented one.
- ✅ `climate`, `democracy`, `seniors`, `technology` — **404 under `/issues/` AND at root**, and none of
  them exist anywhere in Pressley's live taxonomy (`congress, covid-19, criminal-injustice, education,
  energy-the-environment, financial-services-economy, haiti, healthcare-public-health, housing,
  immigration, labor, reproductive-justice, survivor-justice, transportation, trauma, veterans`).
  Climate is covered as *energy-the-environment*; there is no seniors, technology or democracy page and
  no evidence there ever was. Fabricated topics, not moved pages.
- ⚠ **Do not trust this host's control either way:** `/healthcare` is live 200 but **absent from the
  archived `/issues*` listing**, so the archive demonstrably missed a real page here. The live-taxonomy
  test is what carried these verdicts.

🔑 **Generalised: control strength and scheme/taxonomy mismatch are INDEPENDENT signals.** A thin control
is a reason to stop trusting the archive, not a reason to doubt the finding — go and ask the live site
what it actually publishes and how it names things.

---

## ✅ ALL .gov / CONGRESSIONAL FINDINGS HAND-CHECKED (2026-08-06)

⚠ **The count was 41, not 25.** My earlier "25" wrongly included `medfordma.org` and `govtrack.us`,
which are neither. 41 total: 11 done above (pressley 5, lynnma 6) + **30 checked here**.

**Result: 26 confirmed · 3 mechanical re-points · 1 unproven.** Nothing else withdrawn.

### 🔴 Mechanical RE-POINTS — a real page exists, the citation is a corrupted slug. Do not retire.
| cited | real page (live 200) |
|---|---|
| `kamlager-dove.house.gov/issues/health-care` | **`/issues/health`** |
| `moulton.house.gov/issues/national-security` | **`/issues/strengthening-our-national-security`** |
| `moulton.house.gov/issues/jobs-economy` | **`/issues/building-economic-security`** (archived as `jobs-and-the-economy`) |

Together with `pressley/criminal-justice → criminal-injustice`, that is **4 re-points** among the
congressional set — all the same shape: a plausible generic slug standing in for the member's actual,
idiosyncratic one.

### Confirmed — the cited URL never existed (26)
- **`markey.senate.gov` ×11.** Decisive test: **0 of the 11 appear in a COMPLETE archive of 3,375
  `markey-*` and `senators-*` press releases.** ⚠ His real releases *do* cover most of these topics under
  quite different slugs — his actual Dobbs statement is
  `markey-condemns-supreme-court-abortion-ruling-calls-for-supreme-court-expansion-and-abolishing-filibuster`
  (12 real `supreme-court` releases, 7 `transgender`, 2 `inflation-reduction`, 29 `infrastructure`).
  **So the URLs are invented but the underlying positions are largely real** — this is a per-row
  re-research queue, not a mechanical re-point, and re-pointing without reading the release would
  manufacture support (the willametteweek rule).
- **`somervillema.gov` ×5** (33 row-cites, the largest .gov cluster). All 404 live; prefix queries over
  richly-archived sections return nothing: `/departments/somerville-*` holds 21 real paths (police,
  housing authority, city cable…) but no `heart-program` and no `homeless-coalition`;
  `/departments/programs*` holds **304** real paths with **0** matches for `by-design` or `immigrant`;
  `/departments/econo*` is **0**. ⚠ Re-point candidate: the real immigrant-services program is
  `welcoming-and-inclusive-neighborhoods-somerville-wins`. ⚠ "Somerville Homeless Coalition" is a real
  **nonprofit** (`somervillehomelesscoalition.org`), not a city department — the citation attributes it
  to the city.
- **`oag.ca.gov` ×3.** 0 of 3 in 5,000 archived `attorney-general-bonta-*` releases. Real coverage exists
  for two topics (`birth-control` 2, `preventive` 4) but **`workforce` 0**.
- **`kamlager-dove` `lgbtq` + `technology`, `moulton` `technology`.** Absent from both the live taxonomy
  and a rich archived one (moulton's archive holds ~40 real topic slugs including `health-care`,
  `seniors`, `jobs-and-the-economy` — but never `technology`).
- **`carsonca.gov/government/mayor`** (8 row-cites). The site's real convention is
  `government/<section>/index.php` with **underscores** (`boards_commissions/…`); the cited path matches
  no page in 67 archived `/government*` paths. ⚠ It is also a **landing page**, so it falls under the
  2026-08-04 nav ruling regardless of this verdict.
- **`mass.gov/info-details/mbta-communities-compliance-status`.** The real family is archived 5× over —
  `mbta-communities-law-qa`, `-frequently-asked-questions`, `-compliance-model-components`,
  `-compliance-model-user-guide…`, `-catalyst-fund-awards` — and the cited slug is not among them.
  ⚠ **The live page now returns 403, not 404** (bot wall), so the live signal is unusable in both
  directions; the verdict rests on the archive. Re-point candidate: `mbta-communities-law-qa`.
- **`governor.maryland.gov/priorities/environment/`.** The site is SharePoint —
  `/priorities/Pages/<slug>.aspx` — and the cited directory form matches no generation of it.
- **`slc.gov/council/completed-projects/connect-slc-a-city-wide-transportation-plan/`** — 404 live,
  control 31 real pages. No contrary evidence found.

### ⚠ UNPROVEN — withdraw from the retirement set pending per-row work (1)
**`lynch.house.gov/issues/technology`.** Three separate reasons the evidence will not carry:
1. The **entire `/issues` section is gone** — `/issues` itself and even a known-archived slug
   (`/issues/2nd-amendment`) both 404 today, so a 404 on any slug proves nothing about that slug.
2. 🔴 **The control is contaminated by soft-404s.** The archived slug list for a Massachusetts Democrat
   includes `illinois-local-issues`, `valley-fever`, `christian-values`, `pro-life` and `obamacare` —
   the old CMS evidently served 200 for arbitrary `/issues/<anything>`, so captures there are not
   evidence of a curated taxonomy.
3. A plausible real equivalent, **`science-and-technology`**, is archived on that host.

🔴 **THIRD CONTROL-INFLATION MODE FOUND HERE, and the re-derivation does not catch it:** lynch's archived
`/issues*` is full of **inline JavaScript captured as URLs** — `.colorbox`, `.ui-datepicker-calendar`,
`;a.yearshtml+=`, `1.3.2`. They have no asset segment and no file extension, so the page filter passes
them. Its "195 real pages" is mostly this. **Treat a control on an old CMS-driven congressional site as
unverified until the slug list is eyeballed.**

### 🔴 A TRAP THAT INVALIDATED TWO OF MY OWN CHECKS MID-RUN
**CDX returns results in alphabetical order and truncates at `limit`.** My first Markey keyword test ran
over 5,000 rows that stopped at `march-20-2011-…`: every slug sorting after "m" was simply absent, so the
zero counts for `disclose-act`, `dobbs` and the rest meant nothing. The same trap hit the Somerville
department test (1,000 rows covering only `a…an`). **Both had to be redone by querying narrower prefixes
until the result no longer hits the cap.** 🔑 **A truncated CDX listing is indistinguishable from
absence — always check the last row's sort position against what you are looking for.**

⚠ **Remaining limit, deliberately not "fixed":** the page count still includes section indexes one level
down (`/news/archived_news` counts). Telling an index from an article by URL alone is not reliable, and
inventing a heuristic for it is how this audit has over-fired sixteen times. So lynnma's 7 is really
~4 articles + 3 indexes. **Anything in the 5–10 band needs a human to look at the control listing.**

### 🔴 The re-derivation tool nearly destroyed the findings it was written to check
41 of the 121 — every dated one, from the original run — store `control` as a **display label in an old
format**: `bostonglobe.com|2021/01`, a pipe instead of a slash and no trailing `*`. Fed to CDX that
matches nothing, so the first run reported **"0 pages of 0 urls" for every dated control** and would have
downgraded all of them to INCONCLUSIVE. With `--write` that erases real verdicts silently, and the output
reads like a finding rather than a bug. **The tool now recomputes the prefix from the URL and never
trusts the stored string.** 🔑 **Run a reclassifier in report-only mode first — and if every result comes
back the same way, suspect the tool before the data.**

⚠ **And my ad-hoc verification of this nearly went the other way.** A one-off `curl` of the lynch control
returned "3 siblings", which I briefly took as evidence the finding was weak. It was a **503 HTML error
page**, three lines long. The sweep's own `cdxOnce()` tests for markup and retries — my hand-check did
not. Real answer for lynch: 312 captures, 240 real pages, control strong, finding stands.
🔑 **Never verify a detector's control with a query that lacks the detector's own throttle guard.**

### Evidence strength across all 121 (as currently recorded — see the flaw above)

| real sibling pages | urls |
|---|---|
| 5–9 (**THIN — suggestive only**) | 11 |
| 10–49 | 15 |
| 50–199 | 39 |
| 200+ | 55 |

Post-re-derivation. **The thin band nearly doubled (6 → 11)** once assets and section indexes stopped
counting: 6 × `lynnma.gov/news/*` at 7 pages and 5 × `pressley.house.gov/issues/*` at 6.
`lynnma.gov` is named in this audit's own notes as one of four hosts with a **real Wayback gap**.

---

## The remedy is a three-way split, and these numbers are a FLOOR

Computed by `fabricated-impact-report.mjs`, over all 389 rows:

| | rows |
|---|---|
| **SOLE_SOURCED** — cites nothing else. Unambiguous retirement | **141** |
| **NAV_ONLY** — only nav/landing pages survive → retire per the 2026-08-04 ruling | **42** |
| **HAS_COSOURCE** — a real citation survives → **strip the citation, keep the row** | **206** |

### ✅ SUPERSEDED — NAV_ONLY re-run BY READING every surviving page (2026-08-06)

The structural split below was a floor, and it was off by nearly 4×. **All 105 surviving citations were
fetched and read.** Scope corrected first: the 4 mechanical re-points and 1 withdrawn finding are
excluded, because those rows keep a working citation after repair and were never retirement candidates
— **115 URLs actually removed, 383 rows affected** (not 120/389).

| survivor URLs (105) | | rows (383) | structural | **by reading** |
|---|---|---|---|---|
| GONE (404 / dead / soft-404) | 36 | SOLE_SOURCED | 141 | **141** |
| COVERAGE | 33 | NAV_ONLY | 42 | **157** |
| NOT_COVERAGE | 25 | KEPT_UNVERIFIED | — | **8** |
| UNVERIFIED (bot-walled) | 11 | HAS_COSOURCE | 206 | **77** |
| | | **total retire** | **183** | **298** |

🔴 **Retirements rise 183 → 298 (+63%).** The structural rule kept 206 rows on "co-sources" that mostly
are not coverage at all.

**Why the survivors fail — and note the first one is not a nav question at all:**
- 🔴 **36 of 105 survivors are simply GONE.** The three biggest — `carsonca.gov/…/city-council-agendas-and-minutes`
  (24 rows), `alhambraca.gov/…/agendas-minutes` (19), `lynnma.gov/city-council/minutes` (19) — are **404**,
  not merely nav pages. 62 rows rest on pages that no longer exist.
- **~25 `somervillejournal.com` URLs** are the dead-domain paper. ⚠ Genuine journalism, **re-pointable to
  Wayback** — they are a repair queue, not fabrications, and must not be lumped in with invented sources.
- 🔴 **Search-result URLs cited as sources**: `commonwealthbeacon.org/?s=mariano+immigration`,
  `willbrownsberger.com/?s=redistricting`. A query string is not a source — its content is whatever the
  index returns today. New defect shape, worth its own detector.
- 🔴 **Substantive pages that never name the politician** — the attribute-prior class. Every
  `actonmass.org/<bill>/` topic page carries real prose about the bill and **names none** of the
  legislators citing it (hand-verified; a promising "Chan" hit turned out to be the word *channel*).
  Same for bare `malegislature.gov/Bills/<id>` pages — S2977's sponsor is a **committee**. By contrast
  `/Bills/<id>/Cosponsor` and `/Legislators/Profile/<id>` DO name them and DO count.
- **Homepages** (`oag.ca.gov`, campaign roots) — banner copy, no attributable position.

⚠ **8 rows are KEPT on UNVERIFIED survivors** — bot-walled `congress.gov` and `ontheissues.org` (403/503).
A server answered, so absence is not shown. **We retire on demonstrated absence, never on a failure to
confirm.**

### Chip check under the corrected split — FOUR governments go to zero
| government | retire / total answers | |
|---|---|---|
| **City of Carson** | 34 / 34 | 🔴 ZERO |
| **City of Lynn MA** | 30 / 30 | 🔴 ZERO |
| **City of Alhambra** | 19 / 19 | 🔴 **ZERO — invisible to the structural pass** |
| **City of Waltham MA** | 5 / 5 | 🔴 ZERO |
| Commonwealth of Massachusetts | 161 / 2,675 | low |
| City of Somerville MA | 30 / 85 | partial |
| Somerville Public Schools | 3 / 26 · Medford 3 / 10 · CA 1 / 2,186 · MD 1 / 2,248 | low |

**Alhambra only appears once the survivors are read**: all 19 of its rows hang on a single 404 agendas
index. ~20 politicians drop to zero, concentrated in Lynn (11) and Waltham (5).

### 🔴 Five tooling bugs found by reading — four would have silently mis-retired rows
1. **The name matcher stripped non-word characters**, turning `Farley-Bouvier` into `FarleyBouvier` —
   zero hits on a page *titled* "Representative Tricia Farley-Bouvier". It broke every hyphenated name
   in the corpus (Kamlager-Dove, Arena-DeRosa, Lungo-Koehn), each reading as "never mentions them".
2. **`agenda` matched anywhere in a title**, killing a real 1,789-word AG Bonta interview headlined
   "…Plots a Progressive Health Care **Agenda**". Now anchored to title start/end.
3. **Soft-404s**: `mgaleg.maryland.gov/…/ferguson01` serves **HTTP 200 with the title "NotFound"**.
4. **WordPress's empty `<main id="wp--skip-link--target">`** made every `actonmass.org` page extract to
   0 words from ~178KB and read as blank. Same family as the elanaforbend.com false alarm.
5. Search-URL vs homepage rule ordering — same verdict, wrong recorded reason. **A wrong reason is what
   the next reader inherits.**

🔑 **Substring name matching over-fires and under-fires at once**: it missed `Farley-Bouvier` entirely
while matching `Chan` inside `channel`. Match on a word-bounded, un-mangled name form.

Artifacts: `navonly-workset.json` · `navonly-pages.json` (fetched text) · `navonly-classification.json`.
Tools: `navonly-workset.mjs`, `navonly-read-pages.mjs`, `navonly-classify.mjs`.

---

🔴 **NAV_ONLY IS UNDER-COUNTED AND THE SPLIT MUST NOT BE USED AS-IS.** My classifier is structural — it
calls a survivor a nav page when its path has ≤1 segment. The operator ruling is not structural: it is
*does this page state a position attributable to this person*, which requires reading the page. Live
examples that my rule wrongly counts as real co-sources: **`lynnma.gov/city-council/minutes` (19 rows)**
and `lynnma.gov/city-council/agendas` (3) — index pages, depth 2. Meanwhile `wikipedia.org/wiki/Ed_Markey`
(15) and `ontheissues.org/Senate/Ed_Markey.htm` (15) are also depth 2 and **are** substantive, which is
exactly why the nav-page sweep's shape heuristic over-fired on them.

**This is why the 2026-08-05 doc said 31 politicians would drop to zero and this report says 2.** Neither
is wrong; they discount co-sources differently. The reconciliation is per-page reading, not a rule.

### Politicians who would drop to ZERO on the structural (conservative) split
- **Lula Davis-Holmes** (City of Carson) — losing 9 of 9
- **Jared Nicholson** (City of Lynn) — losing 7 of 7 · ⚠ 5 of his rows are the **thin-control** `lynnma.gov` set

⚠ **David B. Walgren has 1 context row and 0 answers** — already at zero, *not* a coverage loss. He is the
orphan-context class (~546 rows corpus-wide, still undiagnosed). Counting orphans as coverage loss
overstates blast radius; the first version of the report did exactly that.

### Blast radius by government (chip check)

| government | rows | pols |
|---|---|---|
| Commonwealth of Massachusetts | 212 | 29 |
| **City of Carson** | 34 | 5 |
| United States Federal Government | 31 | 6 |
| City of Somerville MA | 30 | 11 |
| **City of Lynn MA** | 30 | 12 |
| City of Alhambra | 19 | 5 |
| State of Maryland | 7 | 2 |
| City of Waltham MA | 5 | 5 |
| Somerville Public Schools · City of Medford MA | 3 · 3 | 1 · 1 |
| State of California · Los Angeles · Salt Lake City | 3 · 1 · 1 | 1 · 1 · 1 |

Chips live in `essentials/src/lib/coverage.js`; precedent `ca993e74`, `f0b26b4e`, `b2dfadf0`.
**Join occupancy through `office_current_holder → offices → chambers → governments`.**

---

## ✅ NO_ANSWER RE-PROBE DONE (2026-08-06) — the bucket is evaluated, and it holds NOTHING

**1,025 of the 1,098 NO_ANSWER URLs re-probed** (the other 73 are archive.org citations, skipped by
design — asking "is this archived?" of an archive URL is meaningless). Results, **reproduced by two
independent measurements** at different pacings (700ms/2.5s, then 3s/4s):

| | urls | row-cites |
|---|---|---|
| **LIVE** — answered fine, never was this defect | **914** | 1,703 |
| **NO_ANSWER_CONFIRMED** — dead in both measurements | **111** | 168 |
| 🔴 **new FABRICATED found hiding in the bucket** | **0** | 0 |

**Zero new findings.** The largest un-evaluated hole in the audit is now closed, and it was empty.
Findings stay at **120**; NO_ANSWER never produced a 404, and FABRICATED requires one.

### 🔴 "leginfo is IP-blocked" was substantially OUR BUG, not their block
905 of its 938 URLs answer **HTTP 200 in ~0.2s**. The doc's advice — "skip leginfo, 938 × 25s ≈ 6.5h to
confirm a known IP block" — was wrong on both halves: the block was gone (and may never have been the
whole story), and the pass took minutes, not hours.

🔴 **THE BUG, which invalidated a whole pass before it was caught: `curl` can print HTTP 200 on stdout
and STILL exit non-zero** (a content-decoding/stream quirk under `-L --compressed`). `execFileSync`
throws on a non-zero exit, and both `reprobe-no-answer.mjs` and the sweep's own curl fallback had
`catch { return 0 }` — so a perfectly good 200 was recorded as "nothing answered". The first re-probe
run confirmed **362 leginfo URLs dead while plain curl returned 200 in 0.2s**.
**The written status code is authoritative; the exit code is not.** Fixed in both scripts: read
`e.stdout` on throw.
🔑 **The failure direction is the dangerous one** — it MANUFACTURES NO_ANSWER, and NO_ANSWER is the
bucket that looks clean. A tool that invents un-evaluated states is as bad as one that invents findings.

### The 111 that stayed dead (two measurements, 168 row-cites)
`somervillejournal.com` **49** ⚠ genuine paper, dead domain — **re-point to Wayback, not a fabrication** ·
`leginfo.legislature.ca.gov` 33 (residue of 938) · `pamplinmedia.com` 5 · `legislature.vermont.gov` 4 ·
`a55.asmdc.org` 3 · `walthampatch.com` 2 · `commonwealthmagazine.org` 2 (confirmed dead earlier) ·
15 singles incl. `boli.oregon.gov`, `m.lasvegassun.com`, `tn.gov`, `cantonjournal.com`.

✅ The five "live major papers" the 08-05 doc flagged as a client artifact (`azcentral`, `detroitnews`,
`freep`, `indystar`, `ktlo`) all came back **LIVE** — that diagnosis was right.

Artifacts: `2026-08-06-reprobe-leginfo.json`, `2026-08-06-reprobe-tail.json`.

---

## NOT findings — the un-evaluated remainder

**NO_ANSWER 1,098.** Nothing answered, so nothing was evaluated. This is not a verdict and it fails in the
direction that looks clean.
- `leginfo.legislature.ca.gov` **938** — official CA legislature bill pages; our IP is blocked. Real
  sources, unchecked. 104 of them are additionally **degraded** (short probe, no curl fallback).
- `web.archive.org` **73** — citations that already ARE captures, several written by migs 1557/1559.
  Asking "is this archived" is moot; `reprobe-no-answer.mjs` skips them by design.
- `somervillejournal.com` **49** — genuine paper, dead domain. **Re-point target, NOT a fabrication.**
- Tail: `pamplinmedia.com` 5, `legislature.vermont.gov` 4, `a55.asmdc.org` 3, `walthampatch.com` 2,
  `commonwealthmagazine.org` 2 (confirmed genuinely dead), and singles.

⚠ **126 DEGRADED NO_ANSWER are the re-probe queue** (104 leginfo + 22 web.archive.org). They got a 3s
probe and no curl fallback because their host had failed 3 times consecutively. That is a throughput
decision, never a classification — see the note in the script.

**INCONCLUSIVE 23 / WEAK_CONTROL 1.** Unproven, not clean.

🔴 **10 of the 23 are `somervillema.gov`** — mostly `/city-council/members/*`: they 404, but the archive
holds no siblings for that control, so absence proves nothing. Normally a shrug. Not here:
`somervillema.gov` **already has 5 confirmed fabrications and 33 row-citations**, the third-largest
cluster in the set. An INCONCLUSIVE on a host with confirmed fabrications is a lead, not a dismissal —
and this one needs a *different control period*, not a verdict.
Remaining 13: `heraldnews.com` 3, `lynnma.gov` 2, and singles on `spectrumnews1.com`, `deseret.com`,
`wbur.org`, `carsonca.gov`, `alhambraca.gov`, `medfordma.org`, `sherwoodoregon.gov`, `valleytimes.news`.
⚠ Four of those hosts (`lynnma.gov`, `alhambraca.gov`, `carsonca.gov`, `medfordma.org`) are the known
thin-Wayback set, so INCONCLUSIVE there is expected and is not evidence either way.

---

## Next-session checklist

1. ✅ **DONE 2026-08-06** — control counts real pages; all 59 controls re-derived (including the original
   87); 1 downgraded. ✅ **All 11 thin-control findings hand-checked: 10 confirmed, 1 re-point
   (`pressley.house.gov/issues/criminal-justice` → the live `criminal-injustice`).** Nothing withdrawn.
2. **Hand-check the .gov / congressional URLs individually** — now **25**, not 14 (+8 markey, +4 pressley,
   +3 moulton, +1 lynch, +3 oag.ca.gov, +2 medfordma.org, +1 slc.gov). These sites restructure routinely,
   ✅ **DONE 2026-08-06 — all 41 hand-checked** (the count was 41, not 25; `medfordma.org` and
   `govtrack.us` are not .gov). **36 confirmed · 4 mechanical re-points · 1 unproven and withdrawn.**
   🔑 The method that worked: these sites move their pages, so test the cited topic against the **live
   taxonomy** and against a **complete** archived slug list — never a truncated one.
3. **Treat `onyourballot.vote411.org/m/candidate-detail.do?id=72262938` as a likely FALSE POSITIVE** —
   VOTE411 rotates candidate IDs per cycle, so a 404 is expiry, not fabrication.
4. ✅ **DONE 2026-08-06** — 1,025 of 1,098 re-probed (73 archive.org skipped by design): 914 LIVE, 111 dead in two independent measurements, **0 new FABRICATED**. See the section above. Superseded advice was:
   `reprobe-no-answer.mjs --host-pace 3000`. Skip leginfo (938 × 25s ≈ 6.5h to confirm a known IP block).
5. ✅ **DONE 2026-08-06** — NAV_ONLY re-run by reading all 105 surviving pages. Retirements 183 → 298; four governments to zero (Carson, Lynn, Alhambra, Waltham). See the section above.
6. Write the migration with the split computed in SQL. Chip check per the table above; flip in `essentials`.
7. Add every *confirmed* URL to `backend/data/fabricated-sources.json` so `FABRICATED_SOURCE` blocks it —
   **exact-URL match** for real live outlets (`cbsnews.com`, `latimes.com`, `markey.senate.gov`), never a
   host block.

## Tooling notes worth keeping

- **A per-host circuit breaker is what makes a wide sweep finish**, but un-breaking needs **hysteresis**.
  Clearing the streak on a single answer cost 20 minutes on one chunk: the blocking host was *throttling*,
  not dead — 19 of 250 answered, and each answer re-armed the breaker at full price.
- **A blocked host does not fail the same way twice.** leginfo refused connections instantly in one run
  (~0.6s/URL) and black-holed them in the next (full timeout). Any single measurement of "how expensive
  is this host" is a snapshot, not a constant. I quoted the fast one as the expected saving; it was not.
- **`process.exit()` after a `fetch` aborts the process on Node 24 + Windows** (`UV_HANDLE_CLOSING`,
  exit 127) while the keep-alive socket is closing. Reproduced on a bare 6-line script. Use
  `process.exitCode` — the `--url` regression contract is an exit code and a crash code is not a verdict.
- **Record the timing knobs in every artifact, not just argv.** Two artifacts produced under different
  caps are not comparable, and this run mixed pre- and post-fix chunks; the `timing` block is the only
  reason that provenance is recoverable.
