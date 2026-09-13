# RI — results not yet official · KS — site blocks automated access

Two clusters attempted 2026-09-11 with **no migration written**, for two different and both
legitimate reasons.

---

## Rhode Island: the state says its own results are not official yet

**6 rows, 2 races (CD-1, CD-2), `provisional_until` 2026-09-09.**

RI's 2026 Statewide Primary was held **2026-09-09** — two days ago. Its results API
(`electionresults.ri.gov/results/public/api/elections/RhodeIsland/RI2026StatewidePrimary/data`,
fetched 2026-09-11) reports:

```
election.name            "2026 Statewide Primary"
election.electionDate    2026-09-09
election.isOfficialResults   false      <-- the state's own flag
asOf                     2026-09-10T22:52:20Z
```

**Nothing was culled.** 1842's rule is that certification must be proven, not assumed; here the
publisher affirmatively says it has not certified.

⚠ **Do not bump `provisional_until` forward to quiet the banner.** The rows are *correctly* flagged
right now: the primary has happened, our field is the pre-primary field, and it genuinely may be out
of date. Pushing the date forward would flip the reader-facing message to "Filing or withdrawal
deadlines are still open. We re-verify on or after …", which would be false — deadlines are closed
and the ballots are being counted.

**How to close it:** poll the same endpoint until `election.isOfficialResults` flips to `true`, then
write the cluster the way 1853 and 1856 are written. Our field, for whoever picks it up:
CD-1 Gabe Amo (inc), Kellie Keenan, Pedro DeSouza · CD-2 Seth Magaziner (inc), Stephen Skoly,
Victor Mellor.

---

## Kansas: blocked

**2 rows, 1 race (CD-4: Michael Gaynor, Paul Catanese), `provisional_until` 2026-09-01.**

Migration 1576 deliberately declined to retire these on 2026-08-07 — they were absent from the
certified general field and from every primary-result and withdrawn/disqualified list checked, but
were **not retired on absence alone**, pending the KS SoS official November candidate list.

That list could not be reached. `sos.ks.gov/elections/elections_upcoming_candidate.aspx` returns
**HTTP 403** to both a normal request and to WebFetch. The site was not worked around.

**How to close it:** open that page in a browser, find U.S. Representative District 4 on the
November 3, 2026 candidate list, and report whether Gaynor and Catanese appear. Two names settles
it, and the migration is then three lines of the shape 1859 uses for Virginia.

Note what Kansas is *not*: it is not Connecticut. Kansas publishes the document and blocks the
fetch; Connecticut does not appear to publish it at all.
