# Deep-URL reachability — ✅ COMPLETE (17,888 URLs)

## Final

| class | urls | row-citations | |
|---|---|---|---|
| OK | 15,405 | 51,168 | |
| **GONE** | **796** | **3,108** | 🔴 dead |
| HTTP_202 | 570 | 2,534 | ✅ Ballotpedia bot mitigation — **not** dead |
| BOT_BLOCKED (401/403) | 732 | 1,630 | ✅ fine for a voter |
| FETCH_FAILED | 308 | 781 | needs a retry pass |
| THROTTLED_OR_ERROR | 45 | 169 | says nothing |
| HTTP_406/400/204/526 | 32 | 54 | odd; read individually |

🔴 **3,108 row-citations point at a page that is gone** — the largest defect class this workstream has
found. **1,514 are actonmass.org** (below); the other **1,594 are spread across ~790 URLs and many
hosts**, so there is no second easy win — it is a long tail.

⚠ **4,333 row-citations sit in 202/403 — do NOT count them as broken.** Together they are larger than
the genuine dead set, and folding them in would have inflated the finding from 3,108 to ~7,400.

**Next dead hosts after actonmass** (row-citations): `ontheissues.org` 118+39 · `newtonma.gov` 102 ·
`wbur.org` 66 · `mass.gov` 63 · `somervillema.gov` 51 · `lynnjournal.com` 50 · `bhcourier.com` 46 ·
`auchincloss.house.gov` 43. Government and news hosts reorganising — likely archivable.

---

# (partial-run notes below, kept for the reasoning)

Run is resumable: `scripts/sweep-deep-url-reachability.mjs` checkpoints to
`2026-08-02-deep-url-reachability.jsonl`; re-running the same command skips what is done.
⚠ Killed twice by the harness as a tracked background task; relaunched detached with `nohup`.

| class | urls | row-citations |
|---|---|---|
| OK | 5,227 | 20,297 |
| **HTTP_202** | 538 | **2,460** |
| **GONE** | 197 | **1,634** |
| BOT_BLOCKED (401/403) | 144 | 319 |
| FETCH_FAILED | 95 | 292 |
| THROTTLED_OR_ERROR | 4 | 19 |

## 🔴 `actonmass.org` — 1,514 row-citations pointing at deleted pages

**173 of 189** cited actonmass.org URLs are **genuine 404s**. This is not a block and not a dead site:
the root returns **200**, and `/bills/abortion-access-act` still resolves while
`/bills/100-renewable-energy-by-2045/` and `/bills/100-renewable-energy/` do not. The site reorganised
its bill pages and the citations were never updated.

This one host is **93% of every dead citation found so far**, and it is the single largest concrete
defect this workstream has turned up — bigger than the 279 malformed arrays. Massachusetts stance rows
lean on it heavily.

### ✅ Rename check done — and it splits in two

| section | urls | row-citations | verdict |
|---|---|---|---|
| `/bills/…` | 26 | **196** | ✅ **RENAMED — cheaply recoverable** |
| `/legislators/…` | 147 | **1,318** | 🔴 **section removed — not a rename** |

**Bills moved from `/bills/<slug>/` to a shorter top-level slug.** Confirmed:
`/bills/safe-communities-act/` (404, 37+19 rows) → **`https://actonmass.org/safe-communities/` → 200,
titled "Safe Communities Act"**. The sitemap carries the same shape for others — `/medicare-for-all/`,
`/healthy-youth/`, `/clean-energy-equity/`, `/voting-rights-restoration/`. 16 `/bills/` URLs still
resolve, so the old prefix was retired only partially. **Mechanical re-point once each slug is mapped;
map it from `sitemap-1.xml`, do not guess.**

**Legislator pages are gone, not moved.** No `/legislators/` in `sitemap-1.xml` (153 URLs, of which 103
are dated blog posts), no legislator directory anywhere in the site nav — only `/transparency/` and
`/transparency-on-tour/` — and the one sitemap hit matching "legislator" is a July 2026 blog post.
Act on Mass appears to have withdrawn its per-legislator pages entirely.

🔴 **So the big number is NOT a rename.** 1,318 of the 1,514 row-citations need Wayback or re-research,
not a find-and-replace. These were almost certainly per-legislator voting-record/scorecard pages — high
value evidence for Massachusetts rows, and worth an archive pass before anything is retired.
Act on Mass is a prominent org, so Wayback coverage is likely good. **Not yet attempted.**

## ✅ The `HTTP_202` bucket is Ballotpedia, and it is NOT dead

All 538 are `ballotpedia.org`. HTTP 202 here is bot mitigation, not a missing page.

🔴 **This is the exact trap already documented on this workstream** — a previous pass saw 214 HTTP-202s
and nearly recorded **168 correctly-sourced rows as unsupported**. The sweep gives 202 its own class
precisely so it can never be summed into "dead". Had 202 been folded into the failure bucket, this run
would have reported ~4,000 broken citations instead of ~1,600, and the overcount would have been
entirely Ballotpedia working normally.

Same for the 144 `BOT_BLOCKED` (401/403): those pages are fine for a voter.

## Still to come

11,683 URLs unprobed, including the two largest hosts (`malegislature.gov` 754, `ontheissues.org` 626).
⚠ 88 `ontheissues.org` URLs are already confirmed GONE — worth watching as its remaining 626 are probed,
since OnTheIssues is a very common citation here.

⚠ **The sweep cannot see the fourth failure mode.** `evandone.com` returns 200 and will be counted OK,
though the content its 11 rows cite no longer exists. A page that rots without breaking passes every
check we have.
