# Deep-URL reachability — partial results (6,205 of 17,888 probed)

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

⚠ Not yet done: whether the same bills live at new actonmass.org paths (a rename → re-point, cheap and
mechanical) or are gone entirely (→ Wayback, or re-research). **Check before treating any of it as a
retirement.** Given this workstream's record, a rename is the likelier explanation.

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
