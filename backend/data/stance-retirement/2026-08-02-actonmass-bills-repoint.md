# Act on Mass `/bills/` re-points — review for migrations 1533 and 1534

**Scope as carried in the backlog:** "26 urls / 196 rows, genuinely renamed."
**Scope as it turned out:** 42 cited `/bills/` URLs, 299 row-citations, and **three** different defects.

**Outcome:** **284 row-citations re-pointed** across 38 URLs (243 distinct rows) · **15 rows deliberately
NOT re-pointed** across 4 URLs · 0 retired · 0 stance values changed. Gate green, 643 rows / 3 checks.

| group | URLs | rows | situation | remedy |
|---|---|---|---|---|
| **A** | 9 | 95 | 404, but the bill is still on the site under a new path | cite the live page |
| **B** | 13 | 86 | 404, and the bill is gone from the current agenda | cite Wayback |
| **C** | 16 | 103 | still resolves, via the site's own 301 | cite the destination directly |
| **HOLD** | 4 | 15 | the cited slug names a bill Act on Mass never tracked | left dead |

---

## 🔴 "The pages were renamed" was one third right

The backlog recorded this task as 26 renamed URLs, on the strength of one example
(`/bills/safe-communities-act/` → `/safe-communities/`). Probing all 42 against the live site found
that the 26 dead ones split two ways, and that the 16 the 08-02 sweep had passed as `200/OK` are a
third case that also deserved fixing.

**The site was rebuilt, not reorganised.** `actonmass.org` is now **WordPress**; every capture Wayback
holds is of the previous **Gatsby** site. That is why `/bills/` vanished wholesale instead of shifting,
and it is why "map each slug from `sitemap-1.xml`; don't guess the transform" was the right
instruction — but not a sufficient one, because the new sitemap contains no `/bills/` path at all and
only 30 of the old bills survive under any name.

### How each mapping was derived, not invented

- **Group C — from the site's own `301`.** These URLs still work. Following each redirect gives the
  destination the site itself considers canonical. Nothing to guess.
- **Group A — by joining bill NAME across two independent sources.** The archived legislator
  scorecards from the 1532 pass carry `<a href="/bills/<slug>">Bill Name</a>`, giving old-slug → name
  for 38 bills. The live pages give new-path → name via their `<h1>`. Every group-A pair is an **exact
  name match**; nothing was mapped on slug resemblance.
- **Group B — from the archived page's own `<title>`,** checked to name the expected bill. All 11
  distinct archive targets confirmed (e.g. `/bills/moratorium-on-high-stakes-testing/` →
  *"The THRIVE Act | Act On Mass"*).

⚠ **A 200 from this site does not mean the page exists, and that cuts both ways.** The sweep's 16
`200/OK` are real 301s, not soft-404s; the other 26 serve a genuine 404 behind a ~7.5 KB not-found
shell. Status code and existence were measured separately, because a Gatsby or WordPress front end can
serve either one dressed as the other.

---

## ⚠ Four cited slugs name bills Act on Mass never tracked — left dead, 15 rows

None of the four was ever captured by Wayback under that slug, which is consistent with the URL having
been composed rather than visited. Mapping them would assert an identity no source supports.

| URL | rows | what the rows actually name | nearest Act on Mass campaign | why not mapped |
|---|---|---|---|---|
| `/bills/rent-control/` | 8 | "the Rent Stabilization Act" | Lift the Ban on Local Tenant Protections | related campaign, not the same filing |
| `/bills/the-roe-act/` | 3 | "the ROE Act (H.3320 / S.1209)" | Abortion Access Act | the ROE Act is the 2019-20 predecessor — **different bills** |
| `/bills/universal-childcare/` | 3 | "the Affordable and Accessible Child Care for All Act" | Campaign Childcare | Campaign Childcare is childcare for **candidates** — different bill |
| `/bills/racially-inclusive-education/` | 1 | "the Racially Inclusive Education bill" | CARE Act | not confidently the same bill |

Rows: Decker ×2, Connolly ×2, Barber ×3, Uyterhoeven ×3, Gregoire, Lawn, Stanley, Lipper-Garabedian,
Arena-DeRosa. **All 15 carry a second source**, so none is left citing nothing.

⚠ **Two other never-valid slugs WERE mapped**, and the distinction is the point:
`/bills/100-renewable-energy` (rows: *"the 100% Renewable Energy Act"*) and `/bills/cherish-act`
(row: *"the Cherish Act"*) point at archives whose titles name **exactly** the bill the rows name —
*"100% Renewable Energy by 2045"* and *"The Cherish Act: Fully Funded Public Higher Ed"*. A shortened
slug for a bill the archive confirms is not the same thing as a slug for a bill the site never had.

⚠ `/bills/cherish-act-fully-funded-public-higher-ed/` was **not** mapped to the live
`/debt-free-public-higher-education/`. The Cherish Act funds public higher-ed operating budgets;
Debt-Free Public Higher Education is about student cost. Adjacent, not identical — so it went to
Wayback with the rest of group B.

---

## 🔴 What the assertions caught before anything was written

The first four dry runs all failed, each on a real modelling error:

1. **`array_replace` was the wrong operation.** 35 of these rows cite **two or three** mapped URLs, and
   `array_replace` substitutes one value per call — it would have left the second and third citation
   dead while reporting success. Replaced with a single-pass rewrite of every array element,
   preserving original order.
2. **Two source URLs can share a target,** so per-target counts had to be *distinct rows*, not the sum
   of the sources' counts. `/climate-change-superfund/` sums to 16 and the true post-state is **11** —
   5 rows cite both `/bills/polluter-pays/` and `/bills/climate-superfund/`. That collision is itself
   confirmation of the mapping: those rows call it *"the Polluter Pays / Climate Superfund Act
   (H.872 / S.481)"* in one breath.
3. **Row-citations are not rows.** 284 citations live on 243 distinct rows.
4. **The post-state total resisted arithmetic.** `citations + held − collapses` gave 293; the truth is
   **294**, because a row that already cited the live target alongside the dead URL also collapses.
   The expected value is now **simulated read-only** against real data rather than derived.

Because the rewrite touches every element of `sources` and de-duplicates, two guards were added that a
narrower migration would not need: it refuses to run if any affected row has a **pre-existing**
duplicate source (checked: zero, so the dedupe can only collapse this pass's own collisions), and
assertion 6 compares each row against its **pre-image** to prove no unmapped citation was dropped.
Assertion 6 was itself checked for vacuity — its join matches all 284 pre-image rows.

---

## 🔴 1534 — a citation was republishing a supporter's mail-list contact IDs

1533 chose the **latest** capture of `/bills/driver-license-regardless-immigration-status/`, and the
latest one Wayback holds is of the URL as it appeared in an EveryAction email blast:

```
?utm_medium=&emci=62e031af-…&emdi=f18f9377-…&ceid=21506428
```

`emci` / `emdi` / `ceid` are **per-recipient contact identifiers**. Left alone, six profiles would
carry one supporter's mail-list IDs in a public citation, for no benefit.

**The bug that let it through:** capture selection grouped CDX rows by URL **path**, which merged the
clean captures and the tracked ones into one bucket and then took the newest — a tracked one. Wayback
treats the query string as part of the URL; grouping has to as well, or a tracking parameter wins on
recency alone. Nine clean captures of this page were available the whole time.

1534 re-points those 6 rows to `20241031023942` — same day, same page, verified *"Work & Family
Mobility Act | Act On Mass"*, 63,034 chars, full bill history. Its second assertion is deliberately
broader than the fix: **no citation anywhere may carry `emci`/`emdi`/`ceid`**. Post-apply sweep of the
whole corpus for `emci|emdi|ceid|utm_`: **0**.

---

## ⚠ Known limitation of the group-A and group-C citations

The live WordPress bill pages carry **`HOUSE COSPONSORS` / `SENATE COSPONSORS`** headings whose names
are **not in the served HTML** — they are JS-gated, and Playwright is blocked by a *"Checking your
browser…"* 403, so the names could not be confirmed rendered either. A reader checking a
co-sponsorship claim cannot do it from a group-A or group-C link alone.

That is acceptable here, and measured rather than assumed: of the 196 rows on dead URLs, **111 also
cite a legislator scorecard** (re-pointed to Wayback by 1532, which does carry the green-check/red-x),
51 cite `malegislature.gov`, and only **10 are sole-sourced**. On these rows the bill citation's job is
to identify the bill and give its history — which the live page does better than the archive, with a
fuller session-by-session record.

---

## Verification

```
node scripts/dry-run-migration.mjs migrations/1533_repoint_actonmass_bills.sql
  DRY RUN OK   stmt1:INSERT=38   stmt2:UPDATE=243
node scripts/dry-run-migration.mjs migrations/1534_clean_tracked_actonmass_archive_url.sql
  DRY RUN OK   stmt0:UPDATE=6
  all assertions passed against real data · ROLLED BACK — prod is unchanged.
```

Independent post-apply counts: **15** old `/bills/` citations left (exactly the 4 held URLs), **86**
now on Wayback, **193** on live actonmass pages (95 + 103 − 5 de-duplications). Gate: **643 rows /
3 checks**, `NON_URL_SOURCE` **0**. Spot-checked live and archive targets: all 200.

Artifacts: `2026-08-02-aombills-probe.json` (all 42 cited + 47 site pages, status/redirect/title) ·
`-aombills-rows.json` · `-aombills-archive-verify.json` (title-confirmed archive targets) ·
`-aombills-decisions.json` (the mapping, with a justification per URL) · `-aombills-rollback.json`
(pre-image of all 284) · `actonmass-sitemap-1.xml` · `cdx-actonmass-bills-prefix.json`.
