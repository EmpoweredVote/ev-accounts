# Open States data in the LegiScan dataset layout

A state with no LegiScan dataset on disk can be run from Open States data. Open States is free, public domain and
needs no key, so nothing here spends the LegiScan monthly cap. Built 2026-11-13 for Washington and Tennessee, moved
here and proved on Utah on 2026-11-15.

Open States is the **index**: which bills, who sponsored them, which roll calls, how each member voted, and the
address of the legislature's own page for each. It is never the citation. A vote line is read from the legislature's
own roll-call page and checked against it (`src/lib/stateRollCallEvidence.ts`).

## Steps (per state; the dump is one file for every state)

```bash
W=<work dir>          # a LOCAL folder outside the repo; it holds id_registry.json, name_overrides.json and extracts/
# 1. The monthly dump: about 11 GB, no sign-in. Ask the runner before a download this size.
#    https://data.openstates.org/postgres/monthly/YYYY-MM-public.pgdump
# 2. One state's rows -> $W/extracts/<YYYY-MM>/<st>/ (needs pg_restore 17: brew install postgresql@17; about 3 minutes)
python3 -I scripts/stage5/openstates/extract.py <dump> ut $W
# 3. Convert -> $W/../datasets-openstates/<ST>-<session id>/<ST>/<session>/{bill,vote,people}
python3 -I scripts/stage5/openstates/convert.py $W/extracts/<YYYY-MM>/ut
# 4. Put the folders where the Stage 5 tools read LegiScan datasets (links, not copies)
for d in $W/../datasets-openstates/UT-*; do ln -sfn $d <stage5>/legiscan/ds/$(basename $d); done
```

From there the state runs like any other: `scan_bills.py`, `sponsor_cover.py`, `link_check.py`, and step 7 with
`"votes": "legiscan-plan"` in the recipe. `_onfile.py` finds the folders, so no tool calls LegiScan.

🔴 **Keep `id_registry.json`.** It maps Open States ids to the numbers we hand out (`session_id` 900001+, `bill_id`,
`roll_call_id` and `doc_id` 90000001+, `people_id` 9000001+). Without it every number changes, and every `idmap.tsv`
and saved pair breaks. `convert.py` refuses to start a new registry unless `OPENSTATES_NEW_REGISTRY=1`.

🔴 **Never keep an Open States folder and a LegiScan folder for the same session in one `ds/`**: the scan counts
every bill twice.

## What is different from a LegiScan dataset

| | LegiScan dataset | Converted from Open States |
|---|---|---|
| Marker | none | `<ST>-<id>/.openstates.json` (source, counts, warnings, voters it could not identify, labels linked across sessions) |
| Ids | LegiScan's | ours; **no legiscan.com page exists for them** |
| A vote's citation | `legiscan.com/<ST>/rollcall/…`, checked against LegiScan's record | the roll call's `state_link`, the legislature's own page, checked against that page |
| A sponsorship's citation | `legiscan.com/<ST>/bill/…` | none is made: it keeps the official page it is cited on, and is listed in `legiscan/sponsor-own-page.json` |
| Bill text | `getBillText(doc_id)` | download `texts[].state_link`; a `doc_id` here means nothing to LegiScan |
| Committee votes | mostly present | often missing |
| Party | printed | never written |

How step 7 tells them apart: `legiscan-rollcalls.ts` marks a hit `openstates: true` when the bill file carries
`_openstates`; `state_legiscan.py pairs` then writes the roll call's own page as the pair's address;
`legiscan-evidence-lines.ts` reads the line from that page with the verifier's own fetch; `legiscan_merge.py`
cross-checks the line's vote against the finding, as for a LegiScan line.

## A new state needs two things

1. **A reader for its roll-call page**: one entry in `FORMATS` in `src/lib/stateRollCallEvidence.ts` (the address
   pattern, the site's crawl delay, and a function from the page's markup to members under Yea, Nay and absent),
   with a saved page as a fixture and the refusals tested. The reader must fail closed: refuse the page unless every
   group holds the count its heading prints and the counts are the printed tally. Utah is the one entry so far.
2. **Its rules in `SRC_RULES` in `convert.py`**, when its Open States rows are wrong about something the roll-call
   address states. Utah: the rows carry the bill's chamber, not the chamber that voted, and nothing marks a committee
   vote; both are read from the address.

Check the state before trusting it: per session, roll calls with member votes (a session can have none: Utah's 2025
General Session), the share of voters linked to a person, and whether `robots.txt` lets `EmpoweredVoteBot` read the
roll-call pages.

## Files

- `extract.py`: the dump -> one TSV per table for one state. Reads only.
- `convert.py`: the TSVs -> dataset folders. `--work`, `--out`, `--legiscan-root` (read only, to keep a person's real
  LegiScan `people_id` when the state also has LegiScan datasets), `--sessions`.
- `verify.py`: compare a converted session with a real LegiScan dataset of the same session, where one exists.

## Checked

| State | Sessions | Result |
|---|---|---|
| Washington | 2017-18 to 2025-26 | 0 member-vote differences against LegiScan and against the Legislature's own roll calls (2026-11-13) |
| Tennessee | 2017-18 to 2025-26 | 99.6% of LegiScan's floor roll calls found; 19 of 2.6 million member votes differ (2026-11-13) |
| Utah | 2017 to 2026 | see the pilot report, `backend/data/legislatures/ut.json`, and the checks in `check_tools.py` (2026-11-15) |

Washington's own sites refuse our reader (`robots.txt`), so Washington has no roll-call reader here and keeps its
LegiScan lines.
