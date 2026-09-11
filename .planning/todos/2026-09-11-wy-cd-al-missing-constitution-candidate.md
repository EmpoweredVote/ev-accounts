# WY At-Large — a certified candidate we do not have, and a record with no source

**Opened:** 2026-09-11 (during the WY 2026 reconciliation, migration 1857)
**Blocks:** clearing `provisional_until` on the WY U.S. Representative At-Large race. The three
surviving rows are pinned at 2026-09-18.

## 1. Jeffrey Haggit (Constitution Party) is on the ballot and we do not have him

Wyoming's certified general-election roster
(sos.wyo.gov/Elections/Docs/2026/2026_WY_General_Election_Candidates.csv, fetched 2026-09-11)
holds four names under UNITED STATES REPRESENTATIVE:

| candidate | party | filed | in our data? |
|---|---|---|---|
| GRAY, CHARLES JAN | REP | 05/26/2026 | ✅ |
| KINNEY, LISA | DEM | 05/15/2026 | ✅ |
| JOHNSON, SHAWN A. | LBR | 08/17/2026 | ✅ |
| HAGGIT, JEFFREY A. | CT | 07/17/2026 | ❌ **missing** |

He filed on 07/17/2026, ten days after our 2026-07-07 seeding run, and never appeared in a
primary. **This is the second cluster in a row with this defect** — Vermont had three missing
independents (see 2026-09-11-vt-cd-al-three-missing-independents.md). Contact details are in the
roster: P.O. 1028, Mt View WY 82939, 307-800-7811, haggitforhouse@gmail.com, haggitforhouse.com.

Seeding needs the usual: a `politician_id`, the `external_id` scheme (WY fips = 56), a headshot,
and the federal 24-topic stance set.

## 2. Daniel Workman appears in no Wyoming roster at all

His row was seeded 2026-07-07 with the same source string as the rest of the field — "WY SoS 2026
Primary Election Candidate Roster ... 2026_WY_Primary_Election_Candidates.pdf" — but as of
2026-09-11 he is absent from:

- the current primary candidate roster (`2026_WY_Primary_Election_Candidates.csv`, 11 names),
- the withdrawn primary roster (which lists exactly one U.S. Representative entry, Frank Chapman,
  withdrawn 07/24/2026),
- the certified general roster.

Either the July PDF listed him and Wyoming has since removed him without recording a withdrawal,
or our read of that PDF invented a candidate. 1857 culls him on the safe ground that he is absent
from the general roster, so he cannot be on the ballot — but **which of those two explanations is
true matters**, because the second one is a seeding defect that would have produced phantom
candidates in other states seeded from PDFs on the same run.

Check the July version of the primary roster PDF (the repo's seeding notes for 2026-07-07 should
name the file it read) before assuming the state changed something.

## 3. Wyoming's own results link is broken

"Primary Election - Official Results" on sos.wyo.gov/Elections/2026ElectionInformation.aspx has
`href="INSERT LINK HERE"`. There is no machine-readable primary result file, which is why 1857
reconciles against the roster of who is on the ballot rather than against vote totals. Worth an
email to elections@wyo.gov; it costs them nothing to fix and it is the document any researcher
would look for first.
