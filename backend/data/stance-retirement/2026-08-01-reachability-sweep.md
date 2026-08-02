# Reachability sweep of every cited site in the homepage bucket

`scripts/sweep-cited-site-reachability.mjs` — **587 rows across 241 distinct hosts**, each probed once
(transient shapes retried on the other scheme), every non-200 classified separately.
Raw: `2026-08-01-reachability.json`.

## Result

| class | hosts | rows | what it means |
|---|---|---|---|
| **OK** | 203 | **488** (83%) | readable, judgeable |
| **THIN_SHELL** | 20 | **55** | JS shell — 🔴 **not a defect, and not dead** |
| **FETCH_FAILED** | 13 | 20 | includes the garbage-source rows below |
| **GONE** (404/410) | 3 | 18 | genuinely dead |
| **BOT_BLOCKED** (403) | 2 | 6 | renders fine in a browser |

**99 rows (17%) cite something we cannot currently read.** The `DEAD_SITE` backlog item records **16**.

⚠ **Correcting my own estimate.** From a 12-site sample I said 3-of-12 sites and inferred the item was
"badly understated". Understated it is — 99 vs 16 — but the sample overstated the *rate*: the true
figure is 38/241 hosts (16%), not 25%. Twelve sites was too few to rate-estimate from, and I should
have said so at the time.

## The distinction that matters most

Only **18 rows are actually GONE.** The other 81 are tooling limits, not data defects:

- **THIN_SHELL (55 rows)** — React/Vue/Wix sites serving an empty shell to a plain fetch. Several
  return **body=0**. 🔴 **Every tool in this workstream is blind to these**, so any verdict reached on
  them by a tool is void. They need a JS-capable fetch, not a retirement.
- **BOT_BLOCKED (6 rows)** — 403 with a browser UA already set, so these are IP-level blocks. The page
  is fine for a voter. Never read a 403 as absence.

**Wayback coverage: 20 of 36 unreachable hosts have a usable capture — 70 rows re-sourceable**, the
1519 remedy. All 3 GONE hosts have captures (18 rows), though `erinforutah.com` has only **one**, a
2,026c landing page (see the queue-validation note — it cannot confirm or convict her rows).

## ✅ Self-check: no prior judgement rested on an unreadable page

Cross-referencing the 83-row judged cohort against the unreachable set: **0 overlap.** Every row read
in the `NO_QUOTE` review and the queue pass was judged against a page that genuinely rendered.

---

# 🔴 New defect class the sweep uncovered: prose in the `sources` column

`FETCH_FAILED` contained "hosts" that are not URLs at all:

> `prioritizes balanced budgets` · `combined with criminal justice reform support` ·
> `expanded Medicaid for pregnant people and undocumented immigrants` · `SB0438 pharmacy benefits`

Measured corpus-wide, across **all 33,475 published rows** (not just this bucket):

- **316 entries in `sources` are not URLs**, out of 60,067 entries
- affecting **279 rows across 46 politicians**

Samples make the cause unambiguous — a reasoning string was **split on commas into the array**:

> `"and the Energy Equality Act of 2026 — strongly opposing climate mandates."`
> `"which restricts ICE cooperation. As Senate Minority Leader he led Republican opposition to Maryland sanctuary-style immigration policies."`
> `"though he supported gun buyback destruction requirements (voted for SB444 2025)"`
> plus bare junk: `"\r"`, `"_2026"`, `"46873"`, `"pharmacy agreements"`

**This is an ingestion bug, not a research-judgement problem** — which makes it the cheapest real
defect found on this workstream so far. It is also voter-facing: `Citations.jsx` renders these as
sources, so a voter clicking through gets a sentence fragment or a carriage return.

⚠ **The gate cannot see it.** `check-stance-sources.mjs` classifies rows by the *shape of the host
part*; a value with no host at all falls through every bucket. That is a gap in the gate, not just a
batch of bad rows — new occurrences would be invisible.

## Suggested order

1. **Add a `NON_URL_SOURCE` check to the gate** — zero-tolerance, since no legitimate row has prose in
   `sources`. Cheap, and stops the class recurring.
2. **Repair the 279 rows.** The fragments look reconstructable (re-join and compare against
   `reasoning`), but this needs a look at how the array was built before assuming the original URL
   survives anywhere. If it does not, these are re-source candidates, not deletions.
3. **THIN_SHELL 55 rows** — fetch with a JS-capable client and re-probe. Until then they are
   *unassessed*, and must not be counted as either sound or defective.
4. **GONE 18 rows** — re-source to Wayback, 1519 shape. 18 of 18 have captures.
5. **BOT_BLOCKED 6 rows** — leave alone; the citation works for a voter.
