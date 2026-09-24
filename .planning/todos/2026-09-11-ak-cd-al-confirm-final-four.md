# AK At-Large — confirm the final top four against the general ballot

**Opened:** 2026-09-11 (during the AK 2026 primary certification pass, migration 1856)
**Re-enter:** on/after **2026-09-25**. One row is held at that date: John B. Williams, rank 5.

## What is settled

The Alaska Division of Elections' OFFICIAL certified results for the 2026-08-18 primary give the
top four as Begich (72,696), Hill (53,008), Schultz (13,149) and Hafner (6,175). Fifth is John B.
Williams at 4,413 — **1,762 votes**, 1.08% of all votes cast, behind fourth. Nothing about the
count is in doubt; the PDF summary report and the precinct CSV agree to the vote.

## What is not

Alaska replaces a withdrawing top-four candidate with the next highest vote-getter, so the identity
of the general-election field depends on whether any of the four withdrew after certification —
and **no state document consulted answers that**:

- the Division's general-election candidate list
  (elections.alaska.gov/candidates/?election=26genr) is served only through a search form that
  returns an unfiltered, paginated list with no contest column;
- no candidate-list PDF is published for the general;
- the primary results page cannot show a later withdrawal by construction.

Ranks 6-15 were culled regardless: a single withdrawal can only promote rank 5, so they are out
under every one-withdrawal scenario. Rank 5 is held rather than culled for exactly that reason.

## How to close it

1. **Best:** the general-election ballot or the Official Election Pamphlet for the 2026 general,
   which lists the four names a voter will actually rank.
2. Or ask the Division directly (elections.alaska.gov contact page) whether the U.S. Representative
   top four changed after the 2026-08-31 certification.

Then either set Williams to `not_nominated` (citing the confirmed four) or to `advanced` (citing the
withdrawal and his promotion), and clear `provisional_until`.
