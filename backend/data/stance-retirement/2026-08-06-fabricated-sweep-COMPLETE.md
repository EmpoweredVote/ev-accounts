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
| ⚠ Of those, degraded NO_ANSWER (probed, not evaluated) | 126 |
| **Genuinely evaluated** | **13,579 (99.1%)** |

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

## Findings: 121 fabricated URLs → 390 stance rows, 84 politicians

87 prior + **34 new**. Row-citations 411 (a row can cite more than one fabricated URL).

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
| **new singles: `latimes.com`, `slc.gov`, `lynch.house.gov`, `onyourballot.vote411.org`, `audacy.com`, `cbsnews.com`** | 1 each | 1 each | **all new** |

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

## 🔴 A REAL DETECTOR FLAW: THE SIBLING CONTROL COUNTS CAPTURES, NOT PAGES

`pressley.house.gov/issues*` reports **200 siblings** and that number is worthless. Of 1,000 archived
captures under that prefix, **993 are JavaScript module paths** — `/issues/dojo/dom-class`,
`/issues/esri/dijit/Popup`, `/issues/dijit/TooltipDialog` — relative-path artifacts of an embedded ArcGIS
widget that the crawler recorded as if they were pages. **The real sibling count is 7.**

So four of the new findings (`pressley.house.gov/issues/*`) rest on a control of ~7, not 200. They are
**thin-control, suggestive, not proven** — the same band as `lynnma.gov`, not the same band as
`markey.senate.gov` (497 real siblings) or `moulton.house.gov` (150 real).

⚠ **This affects the ORIGINAL 87 too and has not been re-checked for them.** Any host serving a JS widget
under the control prefix has an inflated control. **Fix before the migration:** exclude
`dojo|dijit|esri|embed|js|css|images|widgets` path segments from the control count, or count distinct
*pages* rather than distinct capture URLs, and re-derive `control_siblings` for all 121.

⚠ **And my ad-hoc verification of this nearly went the other way.** A one-off `curl` of the lynch control
returned "3 siblings", which I briefly took as evidence the finding was weak. It was a **503 HTML error
page**, three lines long. The sweep's own `cdxOnce()` tests for markup and retries — my hand-check did
not. Real answer for lynch: 312 captures, 240 real pages, control strong, finding stands.
🔑 **Never verify a detector's control with a query that lacks the detector's own throttle guard.**

### Evidence strength across all 121 (as currently recorded — see the flaw above)

| archived siblings | urls |
|---|---|
| 5–9 (**THIN — suggestive only**) | 6 |
| 10–49 | 13 |
| 50–199 | 40 |
| 200+ (capped at the query limit) | 62 |

The 6 thin ones are all `lynnma.gov/news/*` at 8 siblings — and `lynnma.gov` is named in this audit's own
notes as one of four hosts with a **real Wayback gap**. They cleared `MIN_SIBLINGS=5` by three.

---

## The remedy is a three-way split, and these numbers are a FLOOR

Computed by `fabricated-impact-report.mjs`, over all 390 rows:

| | rows |
|---|---|
| **SOLE_SOURCED** — cites nothing else. Unambiguous retirement | **141** |
| **NAV_ONLY** — only nav/landing pages survive → retire per the 2026-08-04 ruling | **42** |
| **HAS_COSOURCE** — a real citation survives → **strip the citation, keep the row** | **207** |

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

1. 🔴 **Fix the control to count pages, not captures** (strip `dojo|dijit|esri|embed|js|css|images|widgets`),
   then **re-derive `control_siblings` for all 121** — including the original 87, which were never checked
   for this. Findings whose control collapses below ~10 real siblings drop to suggestive.
2. **Hand-check the .gov / congressional URLs individually** — now **25**, not 14 (+8 markey, +4 pressley,
   +3 moulton, +1 lynch, +3 oag.ca.gov, +2 medfordma.org, +1 slc.gov). These sites restructure routinely,
   so a re-point may exist. `pressley.house.gov/issues/climate` may simply be today's `/issues/energy`.
3. **Treat `onyourballot.vote411.org/m/candidate-detail.do?id=72262938` as a likely FALSE POSITIVE** —
   VOTE411 rotates candidate IDs per cycle, so a 404 is expiry, not fabrication.
4. **Re-probe the 126 degraded + the non-leginfo, non-archive NO_ANSWER tail** with
   `reprobe-no-answer.mjs --host-pace 3000`. Skip leginfo (938 × 25s ≈ 6.5h to confirm a known IP block).
5. **Re-run the NAV_ONLY classification by reading pages**, not path depth, before sizing any retirement.
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
