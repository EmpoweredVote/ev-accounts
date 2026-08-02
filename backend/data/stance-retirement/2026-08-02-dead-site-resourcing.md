# Dead cited sites — re-sourcing pass

The 2026-08-01 reachability sweep found 3 hosts fully GONE. Worked here.

| host | rows | outcome |
|---|---|---|
| `faizahforla.com` | **19** | ✅ **re-sourced to Wayback (1531)** |
| `colterforla.com` | **9** | ⏳ blocked — see below |
| `erinforutah.com` | **10** | ⏳ unverifiable — only capture is a 2,026c landing page |

## 🔴 The sweep undercounted, and by a lot

It reported **6** Malik rows, **2** Colter, 10 Jemison — because its query required **every** source on a
row to be a bare host. Any row pairing a dead host with a second *pathed* source was invisible to it.

The true figures are **19 Malik and 9 Colter** — dead-citation exposure was understated ~2x. This is the
same blind spot as the gate itself: classification by URL *shape* cannot see a URL that simply fails.

## ✅ Faizah Malik — 19 rows re-sourced (1531)

Capture `20260609024810` archives **eight** pages — `/policy`, `/housing-tenants-rights`,
`/homelessness`, `/immigrants-rights` and more — and **every specific these rows assert is in it**:
the "50,000" sidewalk backlog, "Windward" Plaza, "sanctuary" (×5), "rapid response" teams,
"Public Counsel", "climate-resilient", "Venice Dell" (×6).

That verification is the whole point: a Wayback record can be a bare landing page that proves nothing.
Compare Jemison below.

## ⏳ Colter Carlisle — 9 rows, and **both** of his sources are dead

- `colterforla.com` → 404. Its captures are **root-only**; the archived `/priorities` page (11,477c)
  does **not** contain SB 79, "rent-stabilized", 41.18, "Inside Safe", "sidewalk" or "sanctuary" —
  i.e. almost none of what his rows assert.
- `theeastsiderla.com/news/.../colter-carlisle-...` → **also 404**, and on several rows it is the only
  substantive source. 🔴 This one is a *pathed* URL, so the host-level sweep never probed it — found
  only by hand while checking the first.

So his claims currently rest on nothing reachable. Options, none applied yet: find a Wayback capture of
the Eastsider interview (not yet attempted), or retire. **Deliberately left for the deep-URL sweep**,
which will settle whether the interview is archived and how many other rows are in this position.

## ⏳ Erin Jemison — 10 rows, unverifiable in either direction

One capture only (`20260216010533`), **2,026 chars**, a landing page whose entire policy content is six
slogans. Her rows quote specific language ("opposes unchecked voucher expansion diverting funds from
neighborhood schools") and name endorsements (AFT Utah, Better Boundaries) that appear nowhere in it —
but the capture **predates the site's death** and may predate what the researcher actually read.

Not re-sourced (the capture supports almost nothing) and **not retired** (absence from a thin, early
capture is not evidence the claims were invented). They are owed re-research, and that is the honest
resting place.

## Next

The deep-URL sweep (`scripts/sweep-deep-url-reachability.mjs`) probes all **17,958** distinct cited
URLs, paths included, classifying every non-200 separately. It will size this class properly instead of
finding it one accident at a time.
