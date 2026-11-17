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

## A session whose roll calls the dump does not hold

A dump can hold a session's bills and none of its roll calls. Utah's 2025 General Session is one: 959 bills and 0
roll calls in the 2026-11 dump, with the sessions either side full. Count roll calls per session before a run; a
year that has a special session can hide a missing regular one.

The count is a tool, and it exits 1 when a session with 50 bills or more has no roll call, or roll calls that list no
voter. Run it on the extract before the scan:

```bash
python3 -I scripts/stage5/openstates/coverage.py $W/extracts/2026-11/ut
```

In the 2026-11 dump it names gaps in Utah (2025), Maryland (2023), Minnesota (2020 special sessions to 2021-2022),
North Dakota (the 66th and 67th assemblies) and Nevada (the 80th, 81st and 84th sessions). Puerto Rico's extract is
empty. It also prints each state's roll-call addresses, which is the page a state reader has to read.

`fetch-legislature-rollcalls.ts` reads the missing roll calls from the legislature's own site, **for the bills you
name** (the ones the run's bill scan found; the tool knows no topic):

```bash
npx tsx scripts/stage5/openstates/fetch-legislature-rollcalls.ts ut 2025 $W --bills "HB 133,SB 14"   # or --bills-file
python3 -I scripts/stage5/openstates/convert.py $W/extracts/<YYYY-MM>/ut      # the whole state again, never --sessions
```

It writes `$W/supplements/<ST>/<session>.json`, and `convert.py` merges that file on every run from then on. A merged
roll call is a roll call like any other: step 7 and the verifier read it unchanged, and its voters are linked by the
same label rules. It carries `_openstates.from_legislature`, and the session's `.openstates.json` lists the count and
the bills under `rollcalls_from_legislature`.

- Two documents must agree for each roll call, or it is **refused and listed** (exit 1): the bill's own vote list
  (which votes, each tally) and the roll call's own page (the bill, the members). Nothing is guessed.
- 🔴 **Only the bills named are looked up.** Every other bill of that session still has no roll call on disk. A bill
  the scan finds later needs the fetch run again, then the convert.
- 🔴 **Run `convert.py` for the whole state**, not `--sessions`: a session with no linked voter of its own gets its
  links from the sessions either side.
- Committee and voice votes are counted in the supplement's `checked` block and not read.
- Every request waits the site's crawl delay (Utah: 10 seconds; Ohio and South Dakota state none, and the tool waits 1 second),
  and bodies are kept in `supplements/<ST>/raw/`.
- Ohio: once a bill's record is read, the record IS the bill's floor votes. `convert.py` adds the votes the dump
  misses and drops a dump floor vote of that bill that is not on the record (counted in `.openstates.json` as
  `dump_floor_rollcalls_not_on_the_record_dropped`). The 136th's dump dates are UTC clock times, so a late vote lands
  on the next day; the record gives the session day. Run the fetch for every bill the scan finds.
- 🔴 South Dakota: **no dump vote is placed.** The dump cannot tell a committee's vote from the floor's, so only a vote
  read from the record is a roll call on disk; every other dump row is kept marked committee, with the reason in
  `_openstates.sd_not_placed`. A bill the fetch did not read has no floor vote at all. The site names a bill by its
  own id, so the fetch looks it up in the session's bill list first (`listUrl`, `billUrlFromList`). The dump's copy
  of a record vote is kept aside only to teach which person a label is.
- A later dump that does hold the session is safe: a roll call whose page the dump already has is not added twice.
- A new state is one entry in `INDEX` in that file (where a bill's vote list is, and how to read it) on top of the
  page reader below.

## A new state needs two things

1. **A reader for its roll-call page**: one entry in `FORMATS` in `src/lib/stateRollCallEvidence.ts` (the address
   pattern, the site's crawl delay, and a function from the page's markup to members under Yea, Nay and absent),
   with a saved page as a fixture and the refusals tested. The reader must fail closed: refuse the page unless every
   group holds the count its heading prints and the counts are the printed tally. Utah, Ohio and South Dakota are
   the entries so far; Ohio's reader reads three documents per vote, South Dakota's cites a script-shell page and
   reads the vote's data (see the file's header).
2. **Its rules in `SRC_RULES` in `convert.py`**, when its Open States rows are wrong about something the roll-call
   address states. Utah: the rows carry the bill's chamber, not the chamber that voted, and nothing marks a committee
   vote; both are read from the address. Ohio: the stored addresses and text links are dead (v1) and are rewritten
   to the bill's Votes page and the live v2 text address; the 135th holds most votes two to four times (each kept
   once); from the 136th a committee vote is told by its motion. South Dakota: every vote address becomes
   `/Session/Vote/<id>`, each vote is kept once per bill (a consent calendar's copies under its several bills are
   separate roll calls), and only votes read from the record are placed (`sd_record_is_the_floor`).

Check the state before trusting it: per session, roll calls with member votes (a session can have none: Utah's 2025
General Session), the share of voters linked to a person, and whether `robots.txt` lets `EmpoweredVoteBot` read the
roll-call pages.

## Files

- `extract.py`: the dump -> one TSV per table for one state. Reads only.
- `coverage.py`: sessions of an extract that hold bills and no roll calls. Reads only.
- `convert.py`: the TSVs -> dataset folders. `--work`, `--out`, `--legiscan-root` (read only, to keep a person's real
  LegiScan `people_id` when the state also has LegiScan datasets), `--sessions`.
- `verify.py`: compare a converted session with a real LegiScan dataset of the same session, where one exists.

## Checked

| State | Sessions | Result |
|---|---|---|
| Washington | 2017-18 to 2025-26 | 0 member-vote differences against LegiScan and against the Legislature's own roll calls (2026-11-13) |
| Tennessee | 2017-18 to 2025-26 | 99.6% of LegiScan's floor roll calls found; 19 of 2.6 million member votes differ (2026-11-13) |
| Utah | 2017 to 2026 | see the pilot report, `backend/data/legislatures/ut.json`, and the checks in `check_tools.py` (2026-11-15) |
| South Dakota | 2018 to 2026 (2017 holds no bills) | 107 floor roll calls of a 102-bill dry batch (11 votes on a motion and 153 committee votes not mapped): 14 missing from the dump (read from the legislature), 9 dump tallies short by one Yea (2018: the dump leaves three members out), 0 of 5,013 member-vote differences; see `backend/data/legislatures/sd.json` (2026-11-17) |
| Ohio | 132nd to 136th Assembly (2017-2026) | 57 floor roll calls of a 213-bill dry batch (two votes on a motion not mapped): 10 missing from the dump (read from the legislature), 0 tally and 0 of 2,726 member-vote differences; see `backend/data/legislatures/oh.json` (2026-11-16) |

Washington's own sites refuse our reader (`robots.txt`), so Washington has no roll-call reader here and keeps its
LegiScan lines.
