# WA LD 42 State Senate — mandatory hand recount, re-enter after it certifies

**Opened:** 2026-08-20 (during the WA 2026 primary certification pass, migration 1842)
**Re-enter:** on/after **2026-08-25**, and again if the recount runs long. `provisional_until` on all
four rows is **2026-09-04** — that is the date the rows go stale and the Elections read path starts
flagging them, not the date the recount ends.

## Why this race is the one exception

Migration 1842 culled every other race on the WA 2026 Statewide General
(`51e7a875-bff9-4e96-adcf-41736454d25d`) to its certified top two. LD 42 Senate was held back.

Certified 2026-08-18/19 canvass, `State Senator - Legislative District 42`:

| | candidate | votes |
|---|---|---|
| 1 | Erika Creydt (REP) | 22,125 |
| 2 | **Michael Alvarez Shepard (DEM)** | **13,125** |
| 3 | **Eamonn Collins (DEM)** | **13,121** |
| 4 | Ryan Bowman | 1,248 |

**Second and third are four votes apart** — 0.015% of their combined total. RCW 29A.64.021 makes a
**hand** recount mandatory below 150 votes *and* 0.25%. Whatcom County scheduled it for
**2026-08-25 08:00**, Election Center, Whatcom County Courthouse, 311 Grand Ave Suite B3, Bellingham.

Culling on the certified number would have removed Collins, who may well be on the November ballot.
So all four rows keep `result = NULL` and stay live.

🔴 **The check that caught this was a MARGIN test, not a tie test.** An exact-tie guard passes this
race green. Any future certification pass in a top-two or runoff state needs the margin test:
`diff < 2000 AND diff/(2nd+3rd) < 0.5%` (machine), `< 150 AND < 0.25%` (hand).

## What to do

1. Get the **re-certified** recount result from Whatcom County (LD 42 is Whatcom + Skagit; the
   recount is conducted by the county auditors, and the amended abstract is what to cite):
   - `results.votewa.gov/results/public/api/elections/washington/20260804/data` — check whether the
     LD 42 numbers move and whether `lastUpdated` advances past 2026-08-19.
   - whatcomcounty.us/1732/Current-Election for the recount canvass document.
2. Whoever holds second place after the recount → `result = 'advanced'`; the other →
   `result = 'not_nominated'`; Creydt → `'advanced'`; Bowman → `'not_nominated'`. Set
   `provisional_until = NULL` on all four.
3. Follow the citation shape migration 1842 wrote for the other 142 contests: name the contest, the
   feed, the certification, the full tally, the contest total. **Add the recount** — the pre-recount
   certified figure and the post-recount figure are different facts and the row should say which one
   it rests on.
4. Row ids, if they help (they were stable at 2026-08-20):
   - Erika Creydt `46e8f9ec-55cd-4921-bb51-558c4d03ddfc`
   - Michael Alvarez Shepard `6dfd42a6-a29c-46bc-a64a-e93e9be42aca`
   - Eamonn Collins `29e39789-6707-4a17-9c12-e9d47828caac`
   - Ryan Bowman `325f5919-1689-4c41-b1cf-a0c74363fad6`

## Tooling

The pass that produced 1842 is committed and re-runnable. Re-fetch the feeds (the curl commands
are in the harvest script's header), then:

```bash
cd backend
node scripts/wa-cert-harvest.mjs          # disposition.json + the report, incl. the margin test
node scripts/wa-cert-emit-migration.mjs   # migrations/_wip_wa_2026_primary_certification_pass.sql
node scripts/dry-run-migration.mjs migrations/<NNNN>_....sql   # BEGIN … ROLLBACK against prod
```

The harvest script's cut-line check is the margin test that flagged this race in the first place —
it will keep flagging LD 42 until the recount margin clears the RCW 29A.64.021 thresholds, which is
the behaviour you want. Verified 2026-08-20 that re-running both scripts reproduces 1842
byte-for-byte below its header line.

The post-verify gate in 1842 asserts LD 42 still has **4 rows, all `result IS NULL`, all
`provisional_until = 2026-09-04`**. Resolving this race will make that assertion false, which is
correct — 1842 is applied once and never replayed. Do not "fix" 1842.
