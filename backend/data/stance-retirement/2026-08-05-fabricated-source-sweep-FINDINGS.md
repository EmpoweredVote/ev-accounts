# Fabricated-source sweep — findings and migration spec

**Run 2026-08-05. Nothing has been retired. This document is the spec for the migration that should
follow, written so the next session can act from it without re-deriving anything.**

Tool: `backend/scripts/sweep-fabricated-articles.mjs` (+ `reprobe-no-answer.mjs`).
Evidence for the 87 confirmed findings, with per-URL control counts: `2026-08-05-fabricated-confirmed-87.json`.
The full per-chunk probe artifacts (2 MB, 9,195 records incl. every negative) are deliberately NOT committed —
regenerate with `sweep-wide.sh` if the negatives are ever needed.

---

## ⚠ Coverage — the sweep is INCOMPLETE. Read this before quoting any total.

| | URLs |
|---|---|
| Distinct cited URLs in the corpus | **17,492** |
| Eligible (specific page, ≥2 path segments) | 13,705 |
| **Probed** | **9,195** (dated 1,945 + undated 7,250) |
| **Not probed** | **4,478** — undated chunks 30–47 |

🔴 **Why it stopped, and the flaw that caused it.** The curl fallback added to `fetchStatus()` makes an
unresponsive host cost a 30s fetch timeout **plus** a 25s curl timeout per URL. The run hit a long block
of `leginfo.legislature.ca.gov` bill pages that rate-limited us, so it slowed to ~55s/URL and stalled at
chunk 29. **Fix before resuming: cap total per-URL time, and skip the curl fallback once a host has
produced N consecutive zeros.** Resume with `sweep-wide.sh` — it is resumable and skips completed chunks.

**So every number below is a FLOOR, not a total.** 87 fabricated URLs came from 53% of eligible URLs.

---

## Confirmed fabricated: 87 URLs → **364 stance rows, 76 politicians**

Every one: HTTP 404 on a **live** host, zero Wayback captures of the exact path, and ≥5 archived sibling
pages in the same section/month. The 41 dated findings were additionally verified by a **second
independent method** (curl + the availability API, versus Node fetch + CDX): **41/41 agreement.**

| host | URLs | row-cites | notes |
|---|---|---|---|
| `actonmass.org` | 26 | **210** | 🔴 largest by far. Real advocacy org; 183 archived sibling `/legislators/<name>/` pages, coverage 2021-05→2026-05 covers every term, zero captures of the cited ones in either slash form |
| `dailybreeze.com` | 12 | 34 | Daily Breeze, Carson CA. Controls 200 siblings |
| `somervillema.gov` | 5 | 33 | 🔴 **government site** |
| `lynnjournal.com` | 15 | 30 | Lynn Journal MA. Controls 13–141 |
| `sgvtribune.com` | 6 | 19 | SGV Tribune, Alhambra CA |
| `markey.senate.gov` | 3 | 8 | 🔴 **US Senate** |
| `carsonca.gov` | 1 | 8 | government |
| `ladowntownnews.com` | 1 | 5 | |
| `mass.gov` | 1 | 5 | 🔴 government |
| `marylandmatters.org` | 4 | 4 | hand-verified; real outlet DID cover the topics under real slugs |
| `pressley.house.gov` | 1 | 4 | 🔴 **US House** |
| `theeastsiderla.com` | 1 | 4 | |
| `bostonglobe.com` | 3 | 3 | hand-verified |
| `kamlager-dove.house.gov` | 3 | 3 | 🔴 **US House** |
| `govtrack.us` | 1 | 2 | |
| `lynnma.gov` | 1 | 2 | government |
| `precinctreporter.com`, `commonwealthbeacon.org`, `governor.maryland.gov` | 1 each | 1 each | |

⚠ **The .gov and congressional findings need extra scrutiny before retirement.** Congressional and state
sites restructure URLs routinely, so a 404 there is more likely to be a real page that moved than
elsewhere. The zero-capture + archived-siblings test still applies, but re-check these 14 URLs
(`markey.senate.gov`, `pressley.house.gov`, `kamlager-dove.house.gov`, `mass.gov`, `somervillema.gov`,
`carsonca.gov`, `lynnma.gov`, `governor.maryland.gov`, `govtrack.us`) individually — a re-point may exist.
Note the earlier "exactly ONE invented host on the congressional surface" result was **host-level**; these
are fabricated PATHS on real hosts and that audit could not see them.

---

## 🔴 The remedy is NOT a blanket retirement

| | rows |
|---|---|
| Rows citing a fabricated URL | **364** |
| Of those, **sole-sourced** to it (no other citation at all) | **122** |
| Of those, left with **no real source** once nav/landing-page co-sources are discounted | **236** |
| Politicians touched | 76 |
| Politicians who would drop to **zero answers** | **31** |

So: **122 rows are unambiguous retirements.** A further ~114 keep only agenda/minutes/mayor landing
pages, which the 2026-08-04 operator ruling already excludes as coverage — those are retirements too by
transitive application, exactly as migration 1562 handled Lowell. The remaining ~128 have a genuine
co-source and should have the **fabricated citation stripped, not the row retired**.

**That three-way split is the migration's shape**, and it must be computed in the migration rather than
copied from here.

## Blast radius by government — chips to check

| government | pols hit | rows hit | govt total answers | chip risk |
|---|---|---|---|---|
| Commonwealth of Massachusetts | 29 | 212 | 2,675 | low (large base) |
| **City of Carson** | 5 | **34** | **34** | 🔴 **would go to ZERO** |
| City of Somerville MA | 12 | 33 | 85 | partial |
| City of Lynn MA | 12 | 30 | ~30 | 🔴 likely ZERO |
| **Lynn Public Schools** | 1 | **7** | **7** | 🔴 **ZERO** |
| **City of Waltham MA** | 5 | **5** | **5** | 🔴 **ZERO** |
| State of Maryland | 2 | 5 | 2,248 | low |
| City of Medford MA | 1 | 2 | 10 | partial |
| Medford Public Schools | 1 | 2 | 4 | partial |

Alhambra rows sit under the MA/CA state totals via `sgvtribune.com`; verify its own government row too.
Chip flips go in `essentials/src/lib/coverage.js` — precedent `ca993e74`, `f0b26b4e`, `b2dfadf0`.
**Join occupancy through `office_current_holder → offices → chambers → governments`, never
`politicians.office_id`.**

---

## NOT findings — do not retire these

**NO_ANSWER, 560 URLs.** Nothing answered, so they were never evaluated. This is an un-evaluated state,
not a verdict, and it fails in the direction that looks clean.
- `leginfo.legislature.ca.gov` **439** — official CA legislature `?bill_id=` pages. Host root answers 200;
  these were rate-limited, then our IP appears blocked (0/8 even paced at 3s). **Real sources, unchecked.**
- `web.archive.org` **47** — citations that already ARE archive captures, several written by our own
  migrations 1557/1559. `reprobe-no-answer.mjs` skips these by design; asking "is this archived" is moot.
- `somervillejournal.com` **49** — genuine paper, dead domain. **Re-point target, NOT a fabrication.**
- 5 live major papers (`azcentral`, `detroitnews`, `freep`, `indystar`, `ktlo`) — answer 200 to curl;
  Node fetch failure was a client artifact. The curl fallback was added for exactly this.

⚠ **A NO_ANSWER re-probe is still OWED** for the non-archive, non-leginfo remainder (~25 URLs) via
`node scripts/reprobe-no-answer.mjs --host-pace 3000`. Smoke-tested; `commonwealthmagazine.org` (2 URLs)
confirmed genuinely dead.

**INCONCLUSIVE 16 / WEAK_CONTROL 1.** Unproven, not clean. The control had no siblings (or <5), so absence
proves nothing. Needs a different control period, not a verdict.

---

## Structural notes worth keeping

- **A fetch artifact can never invent a fabrication.** FABRICATED requires a 404 — a server answered. A
  failed fetch can only land in NO_ANSWER, so tooling flakiness hides findings, never manufactures them.
- **Trailing slash is a real false-positive risk.** CDX matches exactly and archived siblings often carry
  a trailing `/` the citation lacks. Checked on the `actonmass.org` hits (both forms empty, findings
  stand); **re-check both forms for every URL before retiring it.**
- **Cleaning one defect class exposes the next.** These 87 were only reachable because migration 1560
  stripped nav-page co-sources first. Expect another layer after this one.
- Detector self-checks that mattered: the `504`-substring bug (CDX timestamps contain "504", silently
  degrading every FABRICATED to INCONCLUSIVE) and the missing CDX retry. Both fixed in `0a4eeee1`.

## Next-session checklist

1. Fix the per-URL timeout flaw, resume `sweep-wide.sh` for chunks 30–47 (4,478 URLs).
2. Run the owed NO_ANSWER re-probe on the ~25 non-archive/non-leginfo URLs.
3. Individually re-check the 14 `.gov`/congressional URLs for a re-point before retiring.
4. Re-check trailing-slash variants across all confirmed URLs.
5. Write the migration with the three-way split computed in SQL: retire sole-sourced, retire
   nav-only-survivors, strip the citation where a real co-source remains.
6. Chip check per the table above; flip in `essentials`.
7. Add every confirmed URL to `backend/data/fabricated-sources.json` so `FABRICATED_SOURCE` blocks them.
