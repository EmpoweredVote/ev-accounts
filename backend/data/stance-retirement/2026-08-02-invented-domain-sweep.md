# The FETCH_FAILED bucket, swept for invented domains — and the congressional surface audited

The three invented publications found on 2026-08-02 surfaced by accident: the composed set was built from
URLs already classed `GONE`, so hosts classed `FETCH_FAILED` never entered it. This sweeps that bucket
deliberately — **308 URLs across 71 distinct hosts** — and then audits the surface the first finding
implicated.

Artifacts: `2026-08-02-invented-domain-sweep.json` (voided first pass) ·
`2026-08-02-invented-domain-reverify.json` (the verdicts to trust) ·
`2026-08-02-congress-host-audit.json`. Scripts: `_tmp-invented-domain-sweep.mjs`,
`_tmp-invented-domain-reverify.mjs`, `_tmp-congress-host-audit.mjs`.

---

## 🔴 The first pass was VOID, and its own controls are what caught it

62 of 71 hosts came back `ARCHIVED`. But the run carried controls, and two failed — so every verdict was
discarded and re-derived.

🔴 **The failure mode is worse than the 429 trap this workstream already documents.** Both archive
endpoints returned **HTTP 200 with an empty result** for `clark.house.gov`, while `bass.house.gov`,
`curtis.house.gov` and `democracyreform-sarbanes.house.gov` resolved correctly *in the same run*. An
empty 200 is indistinguishable from a real absence **and does not look like an error**, so the
retry-on-non-200 rule — the entire defence against throttling — cannot see it. `newtonvillearea.com`
failed the other way, flipping to UNKNOWN after being confirmed absent an hour earlier.

**Fix: absence must REPRODUCE.** 3 independent rounds × 3 query forms (availability API, CDX
`matchType=domain`, CDX prefix). A host is absent only if every successful probe is empty, **and** ≥2
distinct methods succeeded, **and** ≥4 probes succeeded. Anything less is UNKNOWN, never absence.

## 🔴 5 invented news outlets — reproducible, 8–9 of 9 probes, all 3 methods

| host | citations | real source it corrupts |
|---|---|---|
| `medfordmirror.com` | 36 | none — no such paper |
| `newtonvillearea.com` | 13 | none |
| `alhambraource.com` | 7 | **`alhambrasource.com`** minus the "s" |
| `walthamtribunenews.com` | 4 | inverts the real *Waltham News Tribune* |
| `walthamatch.com` | 2 | **`walthampatch.com`** minus the "p" |

**The matched pairs are the strongest evidence this workstream has produced.** In two cases the corrupted
host has zero captures while the real host it mangles is richly archived — tested in the same run, under
identical conditions, with the real host as a live positive control. That is not a crawl gap.

⚠ **`alhambraource.com` is NOT a typo repair.** The obvious hope was to re-point to the real Alhambra
Source. Tested: the real site's root IS archived (capture 2025-01-25, control passed) and **none of the
three cited paths exist there**. Host *and* path are fabricated, so these rows need retirement or
re-research, not a re-point.

## ⚠ 3 campaign/advocacy hosts are absent, and I am NOT calling them invented

`octavioforwhittier.com` (2 rows, **both sole-sourced**) · `kennethforla.com` (2) ·
`fairshareforma.com` (1).

Wayback routinely misses a single-cycle local campaign site, so absence here is **weak** evidence — the
same restraint that held the four thin hosts out of the composed set. Suggestive but not sufficient:
`fairsharema.com` (the real Fair Share campaign) **is live**, which makes `fairshareforma.com` look like
the same corruption pattern — but `/endorsers` 404s on the real site and has no capture either, so the
path cannot be confirmed in either direction. **These 5 rows want a hand pass; the 2 sole-sourced
Octavio Martinez rows are the priority, being the only rows here with no other citation at all.**

---

## 🔴 The "control failure" was MY error — and it is the most valuable find

I asserted `clark.house.gov` was real without checking it. The detector was right.

| | |
|---|---|
| `clark.house.gov` | no DNS · **CDX empty across 9 probes / 3 methods** |
| `katherineclark.house.gov` | **live 200 · archived since 2014-01-25** |
| `katherineclark.house.gov/issues` | **live 200** — the cited path is correct there |

So `https://clark.house.gov/issues` is a **composed hostname pointing at a page that genuinely exists
elsewhere**, and it carries **43 citations — every stance Katherine Clark has.**

✅ **This one is REPAIRABLE, not retirable.** Re-point 43 rows to a live, verified page. And all 43 carry
a real second source already (Ballotpedia, Wikipedia, LCV scorecard or OnTheIssues), so none is
sole-sourced and the repair is a clean improvement rather than a rescue.

⚠ **Lesson worth more than the fix: a control is only a control if it was verified, not assumed.** Setting
`clark.house.gov` as "expected ARCHIVED" from memory nearly buried a real finding as a tooling bug — the
mirror image of the House-XML `Hoyle (OR)` parser bug that nearly buried the pre-tenure finding.

## ✅ So the whole congressional surface was audited — and it is sound

If one composed hostname existed on `*.house.gov`, others might. **177 cited hosts, 1,655 citations**,
live-probe first and Wayback only on failure (a retired subdomain is real-but-dead, not invented).

| verdict | hosts | citations |
|---|---|---|
| LIVE | **168** | 1,577 |
| 🔴 NEVER_EXISTED | **1** | 43 |
| RETIRED_BUT_REAL | 8 | 35 |

**Exactly one invented congressional hostname exists, and it is the one already found.** That is a
reassuring bound on the composed-hostname problem, and it is worth having measured rather than assumed.

The 8 retired-but-real hosts are all members who left the seat — `schiff.house.gov` (14) and
`curtis.house.gov` (Senate), `cardenas.house.gov` (12) and `democracyreform-sarbanes.house.gov` (3)
(retired), `rubio.senate.gov` (State), `vance.senate.gov` (VP), `bass.house.gov` (LA Mayor),
`braun.senate.gov` (Governor). ⚠ **Re-point these to Wayback captures; do not retire them.** The pages
were real and the archive holds them.

⚠ Not covered: bare `senate.gov` (359 citations) and `web.archive.org` (59) are not member subdomains and
fall outside this audit.

## Disposition summary

| cohort | citations | action |
|---|---|---|
| `clark.house.gov` | 43 | ✅ **re-point** to `katherineclark.house.gov/issues` (verified live) |
| 8 retired-but-real congressional subdomains | 35 | **re-point** to Wayback captures |
| 5 invented news outlets | 62 | ⏳ **retire or re-research** — no real page exists |
| 3 weak-evidence campaign hosts | 5 | hand pass; 2 sole-sourced rows first |

---

## ✅ BOT_BLOCKED and HTTP_202 swept — and the invented-host question is now CLOSED, not sampled

Swept on request: **130 distinct hosts, 1,302 URLs** (`BOT_BLOCKED` 732 + `HTTP_202` 570).
Artifact: `2026-08-02-bb202-host-sweep.json` · `scripts/_tmp-bb202-host-sweep.mjs`.

**Result: 130 of 130 hosts LIVE. Zero invented.** Live status codes: 106×403, 23×200, 1×401.

🔴 **And that outcome was predictable from the sweep data, which is the more useful finding.** Checking
the class → status mapping instead of reasoning from the class *names*:

| class | observed status | did the host answer? |
|---|---|---|
| OK | 15,404×200, 1×307 | ✅ |
| GONE | 789×404, 7×410 | ✅ |
| **BOT_BLOCKED** | **731×403, 1×401** | ✅ |
| **HTTP_202** | **570×202** | ✅ |
| THROTTLED_OR_ERROR | 26×429, 9×500, 9×503, 1×502 | ✅ |
| HTTP_400 / 406 / 526 / 204 | real codes | ✅ |
| **FETCH_FAILED** | **308 × status=0, error set** | ❌ **nothing answered** |

**A 403 or a 202 requires DNS to resolve AND a server to answer, so a host in either bucket is real by
construction — an invented domain cannot produce one.** `FETCH_FAILED` is the only class where nothing
answered.

✅ **The converse is confirmed empirically: all 9 invented / no-trace hosts sit EXCLUSIVELY in
`FETCH_FAILED`** — medfordmirror ×28 URLs, alhambraource ×4, walthamtribunenews ×4, walthamatch ×2,
newtonvillearea ×2, clark.house.gov ×1, and the three campaign hosts ×1 each. Nowhere else.

**So `FETCH_FAILED` is the only class that can hide an invented host, and it is fully swept. The
invented-host surface across all 17,888 URLs is closed.**

⚠ **Two things I asserted before checking, both wrong, both dissolved by looking at the status codes:**
that `BOT_BLOCKED`/`HTTP_202` were worth sweeping for invented hosts, and that `THROTTLED_OR_ERROR` was a
no-response class. Reasoning from bucket names rather than the underlying data manufactured a
"highest-value next check" that had no yield available to it.

⚠ **The NXDOMAIN-hijack caveat was tested, not waved at.** This machine's resolver answers `192.168.1.1`
for every nonexistent host, which could in principle have turned invented domains into 200s hidden inside
`OK`. It does not: the router serves no HTTPS for arbitrary hosts, so those probes fail at connect — which
is exactly why all 9 known-invented hosts landed in `FETCH_FAILED`.

⚠ **A refinement to this workstream's own rule.** "A failed control voids the run" is too blunt.
`walthamatch.com` returned UNKNOWN here instead of its verified NEVER_EXISTED, because this script used
2 rounds × 2 query forms and archive.org throttled it. But **every one of the 130 bucket verdicts came
from a live HTTP response and none queried Wayback at all**, so the failing control exercises a code path
no result depends on. It also abstained rather than flipping to ARCHIVED — the safe direction. Void the
verdicts that depend on the failing path, not all verdicts.

---

## ✅ RE-POINTS APPLIED — migration 1539, 78 of 78 citations, nothing held

**Applied 2026-08-02. Gate green: 678 rows / 3 checks, baseline unchanged. Next number: 1540.**
Rollback: `2026-08-02-repoint-rollback.json` · targets: `2026-08-02-repoint-targets.json` ·
scripts `_tmp-repoint-resolve.mjs`, `_tmp-repoint-retry.mjs`, `_tmp-gen-1539.mjs`.

**31 of 31 URLs resolved · 69 rows updated · 78 citations replaced · 0 held.**

| repair | citations | target |
|---|---|---|
| HOSTNAME | 43 | `clark.house.gov/issues` → **`katherineclark.house.gov/issues`** (live 200, verified to name her) |
| ARCHIVE | 35 | 30 URLs on 8 retired-but-real subdomains → Wayback captures, each verified to name the member |

Verified post-state: 0 rows still cite the invented hostname · 43 rows carry the real one · **0 citations
remain on any of the 9 hosts** · no row left sourceless.

🔴 **THE FIRST PASS HELD 10 URLS AND WOULD HAVE BEEN WRONG TO. 7 were `availability-unresolved` — the API
never returned 200 after four tries, which is THROTTLING, NOT ABSENCE.** Retried with 6 tries and growing
backoff: **9 of them resolved through the availability API on the second attempt.** Abandoning 15 citations
to a 429 would have been a wrong result wearing the costume of a conservative one.

🔴 **And the one sole-sourced casualty was saved by the SECOND METHOD.** Karen Bass's row —
`bass.house.gov/media-center/press-releases/bass-votes-codify-supreme-court-marriage-equality-decision`,
her **only** citation — had availability reporting **"no capture"**. CDX found a 2022-12-09 capture that
names her. Availability said absent and was simply wrong. **This is why absence needs two independent
methods even for a single URL, not just for a host.**

⚠ **Every archive target was fetched with the `id_` modifier** — raw original bytes, no injected Wayback
banner. The banner echoes the archived URL, and `schiff.house.gov` contains "schiff", so without `id_` the
surname test would have passed on the toolbar rather than the page and confirmed itself.

⚠ **Unrelated pre-existing state noticed while verifying, and it is NOT a defect:** 404 context rows have
an empty `sources` array, and **all 404 have no answer row** — "searched, found nothing" notes with no
chair attached, which is the correct blank-spoke outcome. Always join to `politician_answers` before
calling a context row a defect.

## What is owed

1. ⏳ **Operator decision on the 62 invented-outlet citations** — the only substantive item left here.
   No real page exists for any of them, so re-pointing is not available; it is retire or re-research.
2. ✅ **Re-points DONE** — migration 1539, 78 of 78 citations, nothing held.
3. ✅ **Nothing further to sweep for invented hosts.** `BOT_BLOCKED` and `HTTP_202` are done and were
   structurally incapable of hiding one; `FETCH_FAILED` is the only class that can, and it is complete.
4. ⚠ **Add a standing host-reality check.** Every one of these defects would have been caught at write
   time by asking whether the cited host has ever been archived — and the cheap version of that check is
   simply "did the host return any HTTP response", which is one line in the existing sweep.
