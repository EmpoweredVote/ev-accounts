# St. Louis County certified results — how to get them back

The raw CSVs are not in the repo. They total 52 MB and they are re-fetchable.
`fetch.sh` downloads them; `derive_roster.py` asserts every byte before it reads a vote.

## 🔴 The trap these files set

`curl` returned **HTTP 200 with no error** for three of five files on 2026-09-29 and wrote a
**truncated** body:

| File | Downloaded | Actual |
|---|---|---|
| `el241105` (Nov 2024 general) | 6,127,301 | **9,364,370** |
| `el240806` (Aug 2024 primary) | 5,449,212 | **14,766,495** |
| `el220802` (Aug 2022 primary) | 6,675,537 | **6,929,384** |

A truncated precinct file is not a smaller answer — it is a **different** answer. The partial
`el241105` held only some of County Council District 6's precincts, so aggregating it named
**Kevin Schartner** the winner at 53.13%. The complete file names **G. Michael Archer** at 52.50%.
The runner-up, at a believable margin, correctly formatted, with nothing erroring.

It was caught only because the county council's own roster page names Archer. **Cross-check a
certified tally against the body's published roster; do not trust the tally alone.**

The truncation also hid **six contests** from the Nov 2024 enumeration (83 → 89).

### So: verify the byte count

The server sends `Content-Length` and honours `Accept-Ranges: bytes`, so `curl -C -` resumes.
`fetch.sh` loops until the local size equals `Content-Length`.

## The URLs

Pattern: `https://extcontent.stlouisco.com/BOE/eResults/el<YYMMDD>/CSV.csv`

⚠ **The pattern does not hold before about 2021.** Nov 2020 is
`el201103/112020Detailed.csv`, and `el201103/CSV.csv` is a 404. Take the href from the archive page
rather than composing it.

Archive index (⚠ **`curl` gets HTTP 403 from `stlouiscountymo.gov` even with a browser user agent —
use Playwright**):
`stlouiscountymo.gov/st-louis-county-government/board-of-elections/election-results-archive/`
Each election page carries three links — `Official Election Results` (PDF), `Precinct Results`
(PDF) and **`CSV Results`**. 🟢 **Take the CSV.** It carries `Contest Title`, `Choice Name`,
`Choice Party` and `Total Votes` as columns, so none of the three ways a certified PDF lies
(abbreviated contests, pypdf space injection, presence-is-not-a-win) applies to the first two.
The third still does: read the vote counts, never the mere presence of a name.

## Which elections, and why

The county's elective offices sit in two four-year cohorts. Both must be read to enumerate them.

| File | Election | Why |
|---|---|---|
| `csv-221108.csv` | Nov 8 2022 general | cohort A: executive, prosecuting attorney, assessor, council 1/3/5/7 |
| `csv-241105.csv` | Nov 5 2024 general | cohort B: council 2/4/6 |
| `csv-260804.csv` | Aug 4 2026 primary | mirrors the Nov 2026 ballot, so it re-states cohort A |
| `csv-201103.csv` | Nov 3 2020 general | cross-check of cohort B, one cycle back |
| `csv-220802.csv`, `csv-240806.csv` | the August primaries | party fields and the nomination contests |

⚠ **County Executive appears in Nov 2020 AND Nov 2022.** Charter § 3.010 puts the office on
1982 + 4n, so 2020 is not on the cycle. Sam Page won both. Do not read the 2020 row as a regular
term.
