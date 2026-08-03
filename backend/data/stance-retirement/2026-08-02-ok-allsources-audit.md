# All sources, same 100 rows — does the second citation cover the gap?

**Question left open by the single-source pass.** Testing one citation per row scored 16 of 100
"right page, asserted specific absent" — but 14 of those 16 carried a second source, and a row citing a
person-page *and* a bill-page may legitimately name a bill the person-page omits. Testing one source
cannot tell **"the other source covers it"** from **"nothing covers it"**.

**Answer: about half. It splits 7 / 9, and the residue is small.** Of the 16, seven become fully covered
once the other sources are read; nine do not. At row level:

| verdict (all sources) | n | 95% CI |
|---|---|---|
| **FULLY_COVERED** — every asserted specific lands on some source | **86** | 77.9 – 91.5% |
| **PARTLY_COVERED** — some specific lands nowhere | **11** | 6.3 – 18.6% |
| **UNCOVERED / no working source** | **2** | 0.6 – 7.0% |
| INCONCLUSIVE — every source a PDF or JS shell | 1 | |

Same 100 rows, same seed, 198 source-citations, 197 distinct URLs. Coverage is computed **per asserted
specific across the union of a row's sources**: every measure the reasoning names, every verbatim
quoted span, and the politician's name. A row is `FULLY_COVERED` only when each applicable one lands
*somewhere*.

## 🔴 Correction to the single-source write-up

That pass reported **3 URL defects**. Two hold; one does not.

- ❌ **Karen Ross / `plantingseedsblog.cdfa.ca.gov` is NOT a confirmed 404.** The URL 301s to a path
  without `/wordpress/`, and *that* 404s — but a direct fetch returned the real 11,011-char article in
  this run. The host is inconsistent between a redirect-following and a direct request. It is
  **intermittent**, not dead, and calling it a hard 404 was wrong.
- ✅ Jennifer White Holland's `mgaleg.maryland.gov/…/holland03` soft-404 holds.
- ✅ Simon Cataldo's `malegislature.gov/Committees/Detail/J28` wrong-committee holds (J28 is Housing;
  the row says Mental Health, Substance Use and Recovery).

**Corrected hard-URL-defect rate: 2/100, not 3/100.** The conclusion is unchanged and slightly
stronger — the OK set is not the composed-URL tail.

Also corrected: **Amy Kuhn is fully covered.** Her "missing quote" is our own chair text, and the row
says so in plain language — *matches stance 3's "targeted help like subsidies for affordable projects,
first-time buyer assistance."* The chair-label guard only catches spans reused across three or more
politicians; a self-referential quote used **once** slips through. Detectable structurally by the
introducing phrase (`stance N's "…"`), and exactly one row in the sample does it.

## Source-level health across all 198 citations

| kind | n | share |
|---|---|---|
| readable page | 188 | 94.9% |
| bot-blocked (403) | 3 | 1.5% |
| **dead (404)** | **3** | 1.5% |
| JS shell | 2 | 1.0% |
| soft-404 | 1 | 0.5% |
| PDF | 1 | 0.5% |

**Dead-or-soft-404 rate: 4/198 = 2.0% (CI 0.8–5.1%)** — consistent with the row-level figure.

⚠ **Three of those four were never in the `GONE` worklist.** The sweep classified them OK, and they are
dead now: `communityimpact.com/…/frisco-businesses-struggle-hire-high-housing`,
`friscotexas.gov/586/Mayor-Jeff-Cheney`, and `ballotpedia.org/Jennifer_White_Holland`. Link rot is a
**flow**, not a fixed backlog — a reachability sweep is perishable, and this one is four weeks from
being out of date.

## The two rows that genuinely fail

| politician | topic | why |
|---|---|---|
| **Jennifer White Holland** | Voting Rights | **No working source at all.** `mgaleg` member id soft-404s; `ballotpedia.org/Jennifer_White_Holland` 404s. Nothing supports the row. |
| **Karina Talamantes** | Climate Change | Both sources are real Sacramento press releases about the 2040 General Plan and Climate Action Plan — **neither names her**. The row claims she was part of the council that adopted them; the pages are evidence about the *policy*, not about *her*. |

## The 11 partly-covered, sub-typed

**Bill number asserted but on no source (5):** Tim McOsker `SB 71` · Mike Olcott `HB 3175` ·
Alan Schoolcraft `SB2` (cited source is a Texas member-info page, which lists no bills) ·
Cliff Bentz `H.R. 7120` and `H.R. 5` · Luz Maria Rivas `H.R. 1589`.

- ⚠ **Rivas is not a real failure** — the source that would carry it, `congress.gov/bill/119th-congress/house-bill/1589/text`, returns **403** to us. Inconclusive, not absent.
- 🔴 **Bentz is the sharpest finding in the sample.** His single source is
  `clerk.house.gov/evs/2021/roll060.xml`, which is the roll call for **H R 1280** — the 117th-Congress
  George Floyd Justice in Policing Act. The row asserts votes on **H.R. 7120** (the 116th-Congress
  version) and **H.R. 5**. The vote is real; the bill numbers cited against it are not the ones the
  source records. ⚠ Note a detector gap here too: `BILL_RE` does not match the clerk's `H R 1280`
  spacing, so the *page's* bill number was invisible to the matcher — it does not change the verdict
  (1280 ≠ 7120), but a page using that format elsewhere could produce a false "uncovered".

**Quoted span on no source (5):** Warren Davidson (*"coerce actions willfully hostile to our traditions
and values"*) · Karen Ross (*"Both of these events provided California with excellent opportunities…"*)
· Jeanette Shaw (*"developing Tigard's future growth through a comprehensive strategic plan"*) ·
Jessica Ancona (*"all residents have access to green spaces"*) · Jeff Cheney (two quotes — and **two of
his three sources are 404**, so partly inconclusive).

These are attributed quotations that the cited pages do not contain. That is the class 1518 addressed
with 16 quote corrections; it is a characterisation defect, not a link defect.

**Name on no source (1):** Gregg Hart — both sources are `leginfo` bill texts for SB 252 and SB 684. A
bill page does not name a legislator who is not an author, so his *vote* is not verifiable from either.
Weak citation, correct pages.

## What this settles

- **The 16% was roughly half benign.** Corrected and resolved across all sources it is **11%**
  (CI 6.3–18.6%) — real, but a third smaller than the single-source figure implied, and it is a
  quote-and-bill-number accuracy problem, not a URL problem.
- **Only 2% of rows have no supporting source at all**, and 2.0% of individual sources are dead. The OK
  set remains categorically unlike the `GONE` tail, where 518 of 559 URLs had never been archived.
- **The reachability sweep is perishable.** Three of the four dead sources here were classed OK four
  weeks ago. Any future sweep should record its date and be re-run before its results drive a
  migration.
- **Next, if anything:** the 11 partly-covered rows are a *reading* queue, not a bulk operation —
  quote-by-quote against the cited page, like the 42-row calibrated queue already in the backlog. The
  Bentz case suggests it would be worth checking roll-call citations specifically: a right vote cited
  under the wrong bill number is invisible to every check except reading it.

Artifacts: `2026-08-02-ok-allsources.jsonl` (per-row, per-source signals and where each specific
landed) · `scripts/_tmp-ok-allsources.mjs` · sample and single-source pass in
`2026-08-02-ok-sample.json` / `-ok-verify.jsonl` / `-ok-sample-audit.md`.
