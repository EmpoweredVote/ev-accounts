# The dead-URL long tail — review for migration 1535

**Scope:** the 623 cited URLs / 1,594 row-citations the 08-02 deep sweep classed `GONE`, excluding
actonmass.org (closed by 1532–1534). 190 hosts.

**Outcome:** **234 row-citations fixed** · **1,166 rows on 497 URLs left alone and reported** · 0
retired · 0 stance values changed. Gate green, 643 rows / 3 checks.

---

## 🔴 The headline: this tail is mostly not link rot

Of the 559 URLs still dead on re-probe, **Wayback has never captured 518 of them** — 1,324
row-citations. That is a 7% archive rate, and it is not a coverage gap. Asked how much of the *same
directory* the archive holds:

| host | our URLs | our rows | distinct URLs Wayback holds in the same directory | archived of ours |
|---|---|---|---|---|
| `www.ontheissues.org/House/` | 18 | 118 | **3,000+** | **0** |
| `www.wbur.org/news/` | 23 | 66 | **3,000+** | **0** |
| `www.mass.gov/info-details/` | 23 | 63 | **3,000+** | **0** |
| `www.somervillema.gov/departments/` | 16 | 51 | **3,000+** | **0** |
| `www.newtonma.gov/government/` | 3 | 98 | **3,000+** | **0** |
| `www.bhcourier.com/article/` | 45 | 46 | **3,000+** | **0** |
| `pressley.house.gov/issues/` | 12 | 29 | **3,000+** | **0** |
| `www.lynnjournal.com/2025/` | 28 | 50 | 1,231 | 0 |
| `votesmart.org/candidate/` | 3 | 26 | 3,000+ | 0 |
| `www.isidewith.com/candidates/` | 9 | 25 | 3,000+ | 0 |

(3,000 is the query limit, so those are floors.)

A URL that a continuously-crawled host never served, that the archive never saw once while capturing
thousands of its siblings, and that returns a hard 404 today, was on the balance of evidence
**composed rather than visited**. The OnTheIssues case below proves the mechanism outright.

⚠ **Four hosts are the honest exception and should NOT be lumped in** — Wayback's coverage of them is
genuinely thin, so a real crawl gap is plausible: `www.lynnma.gov/city-council/` (0 siblings),
`www.alhambraca.gov/government/` (7), `carsonca.gov/government/` (67), `www.medfordma.org/city-council/`
(78). Together 30 URLs / 115 rows.

**Re-pointing cannot fix a citation to a page that never existed**, so those rows are not touched here.
Whether they are re-researched or retired is an operator call, not a migration's.

---

## ✅ What was fixed

### Group L — OnTheIssues, 20 URLs / 136 rows → the page the site actually has

This is the one place in the tail where the real page could be identified and verified, and it is also
what proves the composed-URL mechanism. OnTheIssues files a politician under **four** shapes with no
rule that predicts which:

```
/MA/Jim_McGovern.htm     /House/Jahana_Hayes.htm     /Senate/Ed_Markey.htm     /Maura_Healey.htm
```

…and under the *familiar* name, so Stephen Lynch is `Steve_Lynch` and Edward Markey is `Ed_Markey`.
The cited URLs used a single invented shape. Candidates came from the **site's own `/house.htm` index
(735 links)**, not a guessed transform; every one was fetched and confirmed.

🔴 **Identity was checked by name AND corroboration, never by name alone.** OnTheIssues has pages for
several Robert Garcias, Mike Rogerses and John Rogerses. Four of these politicians are 2026 candidates
with no office row, so our own data had no state to check against — those were confirmed against a
specific in the row's own reasoning:

| politician | target | corroborated by |
|---|---|---|
| Robert Garcia | `/CA/Robert_Garcia.htm` | page carries **"District 42"** (row: Long Beach mayor) |
| Andy Barr | `/House/Andy_Barr.htm` | **Kentucky** + **Sugar** Reform Act, both named in the row |
| Mike Rogers | `/Senate/Mike_Rogers.htm` | **Michigan** (row cites 2002 Bush tax-cut votes) |
| Pete Aguilar | `/CA/Pete_Aguilar_Energy_+_Oil.htm` | **California**; cited URL already said CA |
| Chuy García | `/IL/Chuy_Garcia.htm` | **Illinois**, **Chicago** |

Topic sub-pages were preserved where the site still has them under the *correct* directory —
`/Economic/Ed_Markey_Free_Trade.htm` → the profile, but
`/House/Jahana_Hayes_Welfare_%26_Poverty.htm` → `/House/Jahana_Hayes_Welfare_+_Poverty.htm`, and
`archive.ontheissues.org/CA/Pete_Aguilar_Energy_+_Oil.htm` → the same path on `www`.

**Held: Ghazala Hashmi, 22 rows.** OnTheIssues has no page for her under any of the four shapes. Her
rows are not pointed at somebody else's page.

### Group A — 98 rows → a Wayback capture verified to carry the claim

41 of the dead URLs *are* archived. Each capture was fetched and tested on three things: it is a real
page (200, ≥400 chars, not a not-found shell); it **names** the politician whose row cites it; and any
verbatim span the reasoning quotes appears in it. 98 rows passed on 34 URLs — the largest single one
being `auchincloss.house.gov/issues` (43 rows).

🔴 **Group A is row-scoped, not URL-scoped**, because on four URLs some rows check out and some do not.
That is the Jemison rule from 1531 applied per row instead of per page, and it is the reason assertion
4 exists: a URL-scoped UPDATE would have swept up exactly the rows the capture does *not* support.

⚠ **A quoted compass chair label is not a quotation from the source** — the detector bug that produced
9 false failures earlier in this workstream. Handled structurally here: a quoted span reused across
three or more *different* politicians is our own vocabulary, not the page's, and is excluded from the
quote test.

**22 rows held on those same URLs** — recorded, not fixed:

| politician | topic | why | capture |
|---|---|---|---|
| Ross Romero ×3, Suzanne Harrison ×3, Sheldon Stewart ×2, Jiro Johnson, Carlos A. Moreno | Jail Capacity / Transportation / Public Safety | `NAME_ABSENT` | saltlakecounty.gov council release names 3 of the 13 officials citing it |
| Marty Jackley ×2 | Reproductive Rights, Immigration | `QUOTE_MISSING` | martyjackley.com/the-conservative-choice/ |
| Bob Kehr ×2 | Economic Development, Affordable Housing | `QUOTE_MISSING` | bob4plano.org |
| Richard J. Loa | Economic Development Incentives | `QUOTE_MISSING` | richardloa.com/issues-policy |
| Isaac G. Bryan | School Vouchers | `NAME_ABSENT` | californiapolicycenter.org SB-64 page |
| Suzanne Harrison | Environmental Protection vs. Development | `NAME_ABSENT` | ksltv.com |
| Eugene Escobar Jr. | Economic Development Incentives | `NAME_ABSENT` | princetonedc.com |
| Adam B. Schiff | US Tariff Policy | `QUOTE_MISSING` | finance.senate.gov release |
| Isabel Piedmont-Smith | Criminalization of Homelessness | `QUOTE_MISSING` | bsquarebulletin.com |
| Joshua G. Cole | Voting Rights | `QUOTE_MISSING` | jgcole.org/about-josh |
| Keith Mays | Economic Development Incentives | `QUOTE_MISSING` | sherwoodoregon.gov |

---

## ⚠ 64 URLs the sweep called dead are not dead

Re-probing before believing the sweep was worth it, and three of its classes were wrong:

| class | URLs | rows | reality |
|---|---|---|---|
| `OK` | 43 | 71 | resolves fine today; 3 of them via a redirect worth canonicalising later |
| `THIN` | 11 | 56 | **HTTP 200 with a correct `<title>`** — nine `freedomindex.us` SPA shells and two Deschutes County **PDFs**. My extractor got no `<body>` text; that is not the page being gone. This is the JS-shell mistake the workstream has already made once. |
| `BOT_BLOCKED` | 10 | 23 | 403. `curl` with a browser UA returns the **same 4,215-byte block page** for every one, including a URL whose shape is malformed — so the status says nothing either way. |
| `FETCH_FAILED` | 4 | 18 | re-probed by hand: all four saltlakecounty.gov URLs are a real 404, so they *were* promoted into the dead set |

⚠ Two `sgvtribune.com` URLs among the bot-blocked have a **malformed date path** (`/2021/08/slug`,
missing the day segment the site requires). They are plausibly composed too, but 403 means that cannot
be settled here — flagged, not concluded.

---

## 🔴 Method notes worth carrying forward

**A throttled availability response is indistinguishable from a real absence.** Four-way concurrency on
`archive.org/wayback/available` drew HTTP 429 on 129 of 559 — and the endpoint returns
`{"archived_snapshots": {}}` for a genuine miss, so a throttled run would have silently reported 129
extra "never archived". Those were discarded and re-run **one at a time**. Same family of error as
"an empty CDX body is a query-form artifact".

**CDX is too slow to use as the primary lookup on a tail this wide.** Measured per URL: 4s, 36s, and a
60s **504** for three query forms of the *same* page. Three retries with backoff can burn three minutes
on one URL — 5+ hours for 559. The availability API answers the same yes/no in ~5s. CDX still ran, but
only where it earns its cost: sibling-coverage queries per host, and spot cross-checks (which agreed
with the availability verdict on every sample).

**OnTheIssues serves windows-1252.** Decoding as UTF-8 mangled the text and turned five successful
corroborations into false MISSes. And an accented surname (`García`) failed a title test against the
page's unaccented spelling (`Garcia`) — one more false miss, hand-corrected and noted in the map.

---

## Verification

```
node scripts/dry-run-migration.mjs migrations/1535_repoint_dead_url_tail.sql
  DRY RUN OK   stmt1:INSERT=20  stmt3:INSERT=98  stmt4:UPDATE=137  stmt5:UPDATE=98
  all assertions passed against real data · ROLLED BACK — prod is unchanged.
```

Five assertions, each scoped to `(politician_id, topic_id)`. Three earlier dry runs failed, each on a
real modelling error worth recording:

1. **The pre-flight guard was too strict.** It refused any row citing two mapped URLs, but L and A are
   separate statements — Stephen Lynch's Healthcare row legitimately cites both `lynch.house.gov/issues`
   and his OnTheIssues page, and each UPDATE replaces its own one value. The constraint is per
   *statement*, not per migration.
2. **The verifier never carried `topic_id`,** so group A was emitted with the string `"undefined"` as a
   uuid. Recovered by joining back to the row export on `(url, politician_id, topic)`; a row whose id
   cannot be recovered is dropped rather than emitted with a null key.
3. **The group-L targets are not empty.** `/Senate/Ed_Markey.htm` already carried 40 healthy citations
   and `/GA/Rick_Allen.htm` 5 — most OnTheIssues citations in the corpus were always correct, and only
   some were composed. Expected counts are now the true post-state union, not the moved count.
4. **Held-row count.** Assertion 4 expected all 29 unsupported rows; the truth is 15, because the 7
   URLs where *no* row is supported never enter `tail_a` at all.

Post-apply: gate **643 rows / 3 checks**, `NON_URL_SOURCE` **0**. Jim McGovern's 31 rows now cite
`/MA/Jim_McGovern.htm`.

Artifacts: `2026-08-02-tail-rows.json` · `-tail-probe.jsonl` (623 live re-probes) · `-tail-avail.jsonl`
(559 availability checks) · `-tail-verify.jsonl` (41 capture verifications) · `-tail-hostcheck.json`
(per-host sibling coverage) · `-oti-final.json` (the OnTheIssues map, with what each was verified
against) · `-tail-rollback.json` (pre-image of all 249).
