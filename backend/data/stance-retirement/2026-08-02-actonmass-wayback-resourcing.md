# Act on Mass legislator pages → Wayback — review for migration 1532

**Scope:** the 147 dead `actonmass.org/legislators/…` URLs / 1,318 row-citations in
`2026-08-02-actonmass-legislators-dead.json`.

**Outcome:** **1,106 rows re-pointed** to Wayback across 123 URLs · **212 rows deliberately NOT
re-pointed** across 24 URLs · **0 retired** · **0 stance values changed**.

| | URLs | rows | |
|---|---|---|---|
| `RE_POINT` | 123 | 1,106 | current-generation capture verified to carry the scorecard |
| `NO_CAPTURE` | 22 | 196 | Wayback has nothing, in any query form |
| `HOLD_OFF_GENERATION` | 2 | 16 | only a different legislative session's board exists |

683 of the 1,318 were **sole-sourced** to a dead page — with no re-source they cite nothing at all.

---

## 🔴 The four things that decided this pass

### 1. These pages are scorecards, and the scorecard is an image class

An Act on Mass legislator page lists ~27 tracked bills under the heading `Co-Sponsored Bills`. Whether
the legislator actually signed on is carried **only** by `<img class="green_check">` vs
`<img class="red_x">`. The bill name renders identically either way:

```html
<div class="item_1"><img class="green_check"…><a href="/bills/medicare-for-all/">Medicare for All</a></div>
<div class="item_1"><img class="red_x"…><a href="/bills/safe-communities-act/">Safe Communities Act</a>
  <div><a class="btn contact-modal">Request co-sponsorship</a></div></div>
```

**Tags-stripped text reads the same for both.** Any plain-text verdict on a co-sponsorship claim —
which is what nearly every one of these 1,318 rows asserts — is therefore void. Every capture was
DOM-parsed into `{bill → signed on?}` instead.

⚠ And it has to be a DOM parse, not a regex. A green-check item has no nested `<div>` and a red-x item
has one, so a non-greedy `<div class="item_1">…</div>` match silently drops and mislabels bills:
measured on Decker, **15 of 27 bills survived and 3 co-sponsorships were flattened to unknown**.

### 2. Capture chosen by scorecard generation, not by date

Act on Mass rebuilt the board **seven times** between 2021 and 2026:

| bills | captures | span |
|---|---|---|
| **27** | 405 | 2024-03 → 2026-05 ← current |
| 30 | 146 | 2021-10 → 2023-02 |
| 26 | 34 | 2021-05 → 2021-07 |
| 24 | 28 | 2023-03 / 2023-12 |
| 23 | 4 | 2023-09 |
| 19 | 1 | 2023-05 |

So "the latest capture" and "the page the research read" are not the same thing. All 618 captures of
all 113 archived pages were parsed to settle it. **Within the current 27-bill generation the marks are
effectively frozen** — 5 value changes across 405 captures, all `no → YES` late sign-ons in the single
2024-07→2024-10 window (Ashe, Gentile, Ultrino on *Age of Criminal Majority*; Mark on *Abortion Access
Act*; Payano on *Medicare for All*), **none of them a bill any contradicted row turns on**. That makes
the latest current-generation capture safe to cite, and it is what 1532 uses.

⚠ **The CDX `digest` cannot stand in for this.** All 3 of Decker's captures have distinct digests and
byte-identical scorecards — the pages carry dated chrome (latest *Saturday Scoop*) that moves on every
crawl. Digest drift measures the newsletter, not the votes. Reading it as content change would have
flagged 111 of 113 pages as unstable.

### 3. A capture that exists but contradicts the row is not a source — the Jemison rule

Two pages have **no** current-generation capture, and both are held back:

- **Alice Peisch** (11 rows, 9 sole-sourced). Her rows say she did *not* co-sponsor the Safe
  Communities Act — one of them spelling out **"(red X on AOM)"**. Her only captures are a 2021-22
  30-bill board carrying a **green check**. Citing it would publish a link that refutes the row.
- **Jay Livingstone** (5 rows, all sole-sourced). Only 2021-10 → 2023-12 captures, on the 30- and
  24-bill boards.

This is exactly the Malik/Jemison split from 1531: Malik's capture carried every specific and was
cited; Jemison's did not and was not.

### 4. An empty CDX body is a query-form artifact as often as a real absence

25 URLs returned nothing from the `/legislators*` prefix sweep. Each was re-queried **four ways** —
bare, trailing slash, `*` prefix, `/*` path prefix — and every one of the 100 responses was classified,
never read as absence on sight. One earlier attempt returned a **504 Gateway Time-out**, which is a
retry, not a zero. Final: **100/100 parseable, genuinely empty JSON**. The `www.` host form returns the
same 945 captures as the bare host, so it adds nothing.

---

## ⚠ Three of the dead URLs were never valid — a different defect from link rot

Not every 404 is a removal. Three cited slugs are misspellings of pages that exist under the site's own
slug, **for the same politician**, confirmed two ways — shared `politician_id` in our own data, and the
archived page naming them:

| cited (dead) | real page | rows | confirmation |
|---|---|---|---|
| `/legislators/dave-rogers` | `/legislators/david-rogers` | 11 | same `politician_id` (David M. Rogers), which already cites the correct slug too |
| `/legislators/steven-owens` | `/legislators/steve-owens` | 6 | same `politician_id` (Steven C. Owens), ditto |
| `/legislators/danillo-sena` | `/legislators/dan-sena` | 9 | capture titled *"Dan Sena \| Act On Mass"*, *"Ask Rep. Sena…"* |

🔴 **`john-rogers` is a DIFFERENT legislator** (John H. Rogers vs David M. Rogers) and is not used.
Likewise `orlando-ramos` is not Adrianne Ramos. A last-name match is not an identity.

---

## Row-level verdicts within the 1,106 re-pointed

| verdict | rows | meaning |
|---|---|---|
| `SUPPORTED` | 849 | names a scorecard bill; the capture agrees at the asserted polarity |
| `NO_NAMED_BILL` / `TOPICAL_ONLY` | 227 | names no scorecard bill, so the capture neither confirms nor refutes |
| `MIXED` | 19 | names several bills; the capture agrees on some and not others |
| `CONTRADICTED` | 11 | the capture says the opposite |

### Why the contradicted rows are re-pointed anyway

They are. The citation is a truthful pointer to the source the research used, and a live archive makes
the defect **visible and checkable** instead of hiding it behind a 404. What is not done is calling them
sound — they are listed here for correction, and they are a characterisation defect, not a link defect.

**11 contradicted rows** (all stable across every current-generation capture of their page):

| politician | topic | bill | row says | page says | |
|---|---|---|---|---|---|
| Marjorie C. Decker | Immigration and Treatment of Immigrants | Safe Communities Act | co-sponsored | **not** | 2nd source |
| Erika Uyterhoeven | Climate Change and Environmental Protection | 100% Renewable Energy by 2045 | co-sponsored | **not** | 2nd source |
| Alan Silvia | Childcare Affordability & Access | CARE Act | co-sponsored | **not** | 2nd source |
| Christine P. Barber | Immigration and Treatment of Immigrants | Safe Communities Act | co-sponsored | **not** | 2nd source |
| Jennifer Balinsky Armini | Taxation and Public Spending | Stop Corporate Offshoring | co-sponsored | **not** | 2nd source |
| Michael J. Moran | Childcare Affordability & Access | Campaign Childcare | co-sponsored | **not** | **sole source** |
| Frank A. Moran | Healthcare Access | The THRIVE Act | co-sponsored | **not** | 2nd source |
| Kate Lipper-Garabedian | Medicare / Medicaid | Medicare for All | co-sponsored | **not** | 2nd source |
| Kate Lipper-Garabedian | Healthcare Access | Medicare for All | co-sponsored | **not** | 2nd source |
| Ryan M. Hamilton | Civil Rights and Social Justice | Voting Rights Restoration | co-sponsored | **not** | 2nd source |
| Ryan M. Hamilton | Voting Rights and Electoral Integrity | Voting Rights Restoration | co-sponsored | **not** | 2nd source |

🔴 **Three of these name the source's own marking and get it backwards** — Silvia *"per the Act on Mass
tracker"*, Frank Moran *"(Act on Mass green checkmark)"*, Hamilton *"as tracked by Act on Mass (green
checkmark)"*. Peisch's held rows are the same failure inverted (*"red X on AOM"* against a green check).
That is not a research gap; it reads like the checkmark was assumed rather than read, and it is worth
knowing how far the pattern extends beyond this host.

🔴 **Decker's own rows disagree with each other.** One asserts she co-sponsored the Safe Communities Act;
another reasons from her **non**-co-sponsorship of it. The capture settles it — red x — so the
*Immigration* row is the wrong one, and the *Deportation Priorities* row is right.

**19 MIXED rows** (one bill wrong among several right) are recorded in
`2026-08-02-actonmass-decisions.json` under `rows[].bad`: Mindy Domb, Estela Reyes ×3, John Keenan ×2,
James Arciero, Michael Brady, Antonio Cabral, David Linsky, Steven Owens, Judith Garcia, Joan Lovely,
Joanne Comerford, Andres Vargas ×2, Daniel Cahill ×2, Michael Moore.

⚠ **The polarity detector was wrong three times before it was right, and each cut was checked by hand
against the page.** 55 → 36 → 15 → 11 "contradictions". What it was getting wrong:
an over-broad negation list (`opposed`, `voted against`) flipping *"backed the 100% Renewable Energy Act
and has consistently opposed fossil fuel infrastructure"*; generic aliases (`tenant protections`,
`mascot`, `right to unionize`) matching prose that names no bill; sentence-level rather than
clause-level scope, which inverted *"Co-sponsored the Healthy Youth Act…; did not co-sponsor any bill
restricting trans athletes"*; and no handling of sweep phrasing (*"Zero co-sponsorships including X"*,
*"No Cherish Act co-sponsorship"*), which alone accounted for 20 false contradictions across Wong,
Jones, Berthiaume, Muradian and Kane. **A mention is not a claim, and a claim is not a contradiction.**

---

## Not re-pointed — 212 rows owed re-research

**2 held for wrong generation:** Alice Peisch 11 rows (9 sole) · Jay Livingstone 5 rows (5 sole).

**22 with no capture at all** — 196 rows, **113 of them sole-sourced** and now citing nothing that
resolves:

| politician | rows | sole | | politician | rows | sole |
|---|---|---|---|---|---|---|
| Kate Hogan | 16 | 14 | | Richard G. Wells | 9 | 0 |
| Dawne Shand | 15 | 9 | | Ronald Mariano | 9 | 2 |
| Carole A. Fiola | 13 | 11 | | Tackey Chan | 9 | 0 |
| Adrianne P. Ramos | 12 | 8 | | Aaron Michlewitz | 8 | 7 |
| Bud L. Williams | 12 | 7 | | Daniel M. Donahue | 8 | 7 |
| James Arena-DeRosa | 12 | 12 | | William J. Driscoll | 7 | 2 |
| Mark C. Montigny | 12 | 12 | | Tricia Farley-Bouvier | 6 | 0 |
| Samantha Montaño | 10 | 10 | | James J. O'Day | 5 | 5 |
| Angelo J. Puppolo | 9 | 6 | | Kenneth I. Gordon | 3 | 0 |
| Karen E. Spilka | 9 | 1 | | Thomas M. Stanley | 2 | 0 |
| Kevin G. Honan | 9 | 9 | | William N. Brownsberger | 1 | 0 |

Wayback holds 183 distinct legislator pages; these 22 are simply not among them. 70 of the 183 are
pages we cite nothing from, so the gap is crawl coverage, not a slug convention we failed to guess —
but that is inference, not proof, and the three corrected slugs above show the other cause is real.
The remaining lead, unspent: `/legislator-search/` is a **Gatsby JS shell** (0 legislator links in the
raw HTML — `read-site-js.mjs` territory), and archived `/bills/…` pages expose only their own committee
rosters (21 slugs on `safe-communities-act`), so neither enumerates the site's full slug list cheaply.

---

## Verification

```
node scripts/dry-run-migration.mjs migrations/1532_resource_actonmass_legislators_to_archive.sql
  DRY RUN OK   stmt1:INSERT=123   stmt2:UPDATE=1106
  all assertions inside the migration passed against real data
  ROLLED BACK — prod is unchanged.
```

Five assertions inside the migration, each scoped to `(politician_id, topic_id)`:

1. per-**target** count matches the reviewed number — ⚠ grouped by target, not by dead URL: 11 targets
   are shared by two dead URLs each (the 9 trailing-slash pairs, plus `dave-rogers`+`david-rogers` and
   `steven-owens`+`steve-owens`, where the correct spelling was already cited too). Asserting per dead
   URL double-counts and fails all 22 — it did, on the first dry run.
2. nothing still cites a re-pointed dead URL;
3. exactly 1,106 rows cite the archive;
4. 🔴 the 212 **held** rows are untouched — the check that a wildcard UPDATE would have failed;
5. the cohort still totals 1,318 legislator citations, so no row gained or lost a source.

All 9 trailing-slash duplicate pairs were confirmed to resolve to the **same** capture.

Artifacts: `2026-08-02-actonmass-rows.json` (row export) · `-timeline.jsonl` (618 parsed captures) ·
`-scorecards.jsonl` · `-decisions.json` (per-URL and per-row verdicts) · `-cdx-misses.jsonl` (the
100-query absence proof) · `-wayback-rollback.json` (pre-image of all 1,106 rows).
