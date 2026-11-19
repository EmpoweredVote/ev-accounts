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
- Every request waits the site's crawl delay (Utah: 10 seconds; Ohio, South Dakota, Mississippi, Maryland, Kansas and Colorado state none, and the tool waits 1 second),
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
- 🔴 South Dakota sponsorships are cited on the bill's **introduced text** (runner, 2026-11-17), a PDF that prints
  "Introduced by: ...": the bill page is a script shell. For each bill it reads, the fetch also reads the record's
  sponsors (`/api/Bills/<BillId>`, prime or co-sponsor), the version list and that PDF, and writes `sponsors` into
  the supplement; `convert.py` (`sd_sponsors_from_text`) then keeps only the sponsors the text names and makes the text
  the bill's page. The 2018 and 2019 texts name every sponsor, 2020's some, and from 2021 a text names only the lead
  sponsor, so the rest are left out and counted (`sd_sponsors_not_named_on_the_text`). A bill whose sponsors are
  refused cites none of them (`sd_sponsor_rows_dropped_sponsors_refused`), never the dump's. A printed name must be exactly one member of that
  chamber in the session's member list and one sponsor of the record, or the bill's sponsors are refused: the text
  prints "Kolbeck" for the record's "Kolbeck (Jack)" and "Kevin Jensen" for "Jensen (Kevin)", and a bare "Peterson"
  is refused while two Petersons sit.
- 🔴 Mississippi: **no dump vote is placed** either (`record_is_the_floor`). The dump reads each vote's member list
  from the vote PDF and misreads it ("Absent or those Barnett"; the name before a total that runs over a line is
  lost), so only a vote read from the record is a roll call on disk; every other dump row is kept marked committee,
  with the reason in `_openstates.not_placed`. The fetch reads the bill's history XML (`/<session>/pdf/history/<HB>/
  <HB1793>.xml`, the number padded to four), keeps each linked vote whose action is a vote on the bill, and reads
  its PDF with the session's author list and the current member list. The record prints full legal names where
  Open States stores nicknames; `ms_resolve` links them (see the convert rule below) and prints every link made by the
  seat rule at the end of the run, to be checked by hand against the legislature's member pages.
- 🔴 Maryland: **no dump vote is placed** either (`record_is_the_floor`). The dump links about one member vote in
  twenty of 2017-2022 to no one ("Washington, A.", "Davis, D.E.", the presiding officer), and holds no 2023 vote. The
  fetch reads the bill's page (`/mgawebsite/Legislation/Details/sb0001?ys=2023RS`), keeps each linked vote whose
  action is a vote on the bill (`MD_FLOOR_ACTION`: third reading, a conference report, a veto override), counts each
  floor amendment or motion (`MD_MOTION_ACTION`), and stops on any other action or a vote link of a shape it does not
  know (2018 onward writes `href=" /2018RS/votes/..."`, with a space). The reader reads the vote's PDF (2017: a
  page, `.htm`) with the chamber's standing committee pages for that session, which give each member's full name.
  2013 (read for SB 281, the Firearm Safety Act, 2026-11-18): the bill page links no vote file, only the day's
  Proceedings page (`MD_LINKLESS_SESSIONS`). The fetch sends each tallied floor action to that page and takes the one
  vote link printed under the bill with the same motion and tally (`mdVoteFromProceedings`; none or two stop it). Its
  votes are pages, `.htm`, like 2017's (`MD_PAGE_YEARS`). The dump holds no 2013 SB 281, so convert.py titles the bill
  from its kept bill page (`md_bill_from_page`). 2014-2016 are not read.
  A bill's page can leave out a vote on the bill (2022 SB 861: the Senate's third reading after the House amended it,
  vote 1377): `md_dump_votes.py` lists every vote address the dump holds for the scanned bills, and the fetch's
  `--also <json>` reads each one the page does not link, keeping it only if the vote file itself says it is a vote on
  this bill. A veto overridden in the next session is filed under that session and cited with the bill's year:
  `/2021RS/votes/house/0042.pdf#2020-HB4`.
- 🔴 Kansas: **no dump vote is placed** either (`record_is_the_floor`). The dump holds far fewer roll calls for
  2019-2020 and 2023-2024 than for the bienniums either side, and every vote address in it is the old host's
  (`www.kslegislature.org/li/...`), which redirects to a 404. For 2017-2022 and the specials the fetch reads the
  archive's bill page (`/li_2018/b2017_18/measures/hb2476/`, lower case) and each `vote_view/je_.../` page it links;
  for 2023 on, the bill's history filtered to votes (`/b2023_24/bills/SB113/history/?filter=votes&per_page=50`, a
  resolution under `/resolutions/`) and each vote page (`/b2023_24/vote/?apn=.../vote_records/<file>.odt`). It keeps
  final action, conference reports, concurring, veto overrides and the consent calendar, counts Committee of the Whole
  votes and other motions, accepts a substitute's title ("Sub for HB 2278"), and reads "No votes recorded yet." as no
  votes only when the page shows no vote row or link. The record prints surnames only; the reader builds each full
  name from the member id in the link (`rep_paige_wanda_1` printed "Brownlee Paige" is Wanda Brownlee Paige).
- 🔴 Colorado: **no dump vote is placed** either (`record_is_the_floor`). The dump's 2017A votes are committee
  summaries only, and 2018-2019 votes are filed under the chamber and day of the bill's last vote. The fetch reads the
  bill's page (`/bills/hb19-1177`, lower case), keeps the House and Senate floor votes on the bill (Third Reading,
  amendments repassed or concurred in, conference reports, adopting a resolution), counts committee votes and
  motions, and reads each vote page (`/bill_votes/16466`, cited `#HB19-1177`). The page prints family names only
  ("Valdez A.", "President"); the reader names each member from the session's member list
  (`/legislators?sess=2019a`), and a label two members fit gives no line. `convert.py` stores bill numbers in
  LegiScan's form, the year dropped ("HB 19-1177" -> HB1177, "SB 4" -> SB004), and rewrites old text links to
  `content.leg.colorado.gov` (`co_texts`); 2026 texts (`/bill_files/N/download`) are disallowed by robots.txt and only
  counted.
- A later dump that does hold the session is safe: a roll call whose page the dump already has is not added twice.
- A new state is one entry in `INDEX` in that file (where a bill's vote list is, and how to read it) on top of the
  page reader below.

## A new state needs two things

1. **A reader for its roll-call page**: one entry in `FORMATS` in `src/lib/stateRollCallEvidence.ts` (the address
   pattern, the site's crawl delay, and a function from the page's markup to members under Yea, Nay and absent),
   with a saved page as a fixture and the refusals tested. The reader must fail closed: refuse the page unless every
   group holds the count its heading prints and the counts are the printed tally. Utah, Ohio, South Dakota,
   Mississippi, Maryland, Kansas and Colorado are the entries so far; Ohio's reader reads three documents per vote, South Dakota's cites a
   script-shell page and reads the vote's data, Mississippi's reads a PDF with the bill's history and two member
   lists, Maryland's reads a PDF (some printed sideways) with the chamber's committee pages, Kansas's reads one page in
   two layouts and names each member from the member id in the link, Colorado's reads one page with the session's member list (see the file's header).
2. **Its rules in `SRC_RULES` in `convert.py`**, when its Open States rows are wrong about something the roll-call
   address states. Utah: the rows carry the bill's chamber, not the chamber that voted, and nothing marks a committee
   vote; both are read from the address. Ohio: the stored addresses and text links are dead (v1) and are rewritten
   to the bill's Votes page and the live v2 text address; the 135th holds most votes two to four times (each kept
   once); from the 136th a committee vote is told by its motion. South Dakota: every vote address becomes
   `/Session/Vote/<id>`, each vote is kept once per bill (a consent calendar's copies under its several bills are
   separate roll calls), and only votes read from the record are placed (`sd_record_is_the_floor`). Mississippi
   (`ms_vote_page`, `record_is_the_floor`, `ms_full_names`): every vote address becomes the vote's PDF with the bill
   named after a # (`/2026/pdf/votes/house/0830060.pdf#HB1793`), only votes read from the record are placed, and a
   record name links to a person only when (1) a family name (or one word of a two-word one: "Heather Bagnall" for
   "Bagnall Tudball") and a given name fit (an initial, or the start of the stored name: "Chris" for "Christopher")
   among the session's roster; else (2) exactly one person of the whole state fits by the family name and the FIRST
   given name, written out (Maryland: the dump links none of 2017 "Theodore Sophocleus"'s votes, and Open States keeps
   Alonzo Washington only as a senator, so as a delegate he is on no House roster; a middle initial is not enough
   here: Mississippi's "Robert L. Jackson" is not Lataisha Jackson); else (3) exactly one member of that family name
   is seated in that chamber by a membership AND the record prints only one member of it there that session (two
   Huddlestons sat in the 2018 House). Links made by (2) and (3) are printed at the end of the run, to be checked by
   hand. (3) used to run before (2) existed, and gave "Theodore Sophocleus" to Alice Sophocleus and 2020's "Dana Jones"
   to the Speaker, Adrienne Jones, whom the record prints by office. Maryland (`md_vote_page`, `md_bill_page`, `https_texts`, `record_is_the_floor`,
   `ms_full_names`): every vote address becomes the vote's file with the bill named
   (`/2026RS/votes/house/1104.pdf#SB128`); 2017's rows carry a page that is gone
   (`webmga/frmMain.aspx?pid=flrvotepage&...&id=hb0760,h-0501`), rewritten to `/2017RS/votes/house/0501.htm#HB760`
   only when it names the row's bill; the chamber is read from the address (2017's rows are filed under the whole
   legislature); the old bill page becomes `/mgawebsite/Legislation/Details/hb0760?ys=2017RS`; and a record name is
   read with its accents folded ("Peña-Melnyk"). Kansas (`ks_vote_page`, `ks_bill_page`, `ks_texts`,
   `record_is_the_floor`, `ms_full_names`): a 2017-2022 or special-session vote address becomes the archive's
   (`/li_2018/b2017_18/measures/vote_view/je_.../`); a 2023-24 `je_` address leads nowhere on either host and is left
   as it is and counted (`ks_vote_address_not_rewritten`); the old bill page becomes the archive's
   (`/li_2018/b2017_18/measures/hb2278/`) or the current site's (`/b2023_24/bills/SB113/`, `/b2023_24/resolutions/
   HCR5020/`); a text becomes the archive's `measures/documents/<file>.pdf` or, for 2023-24, the current site's
   download address.

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
| Maryland | 2017 to 2026 (2023 and 2021s1 hold no dump vote; regular sessions only); 2013 SB 281 only (3 floor votes, read from the record 2026-11-18) | 282 floor roll calls of a 534-bill dry batch, 24 only on the record (all 17 of 2023; four 2020 vetoes overridden in 2021; three others); 0 tally and 0 of 23,517 member-vote differences; 61 dump labels fit no record name, all the presiding officer; see `backend/data/legislatures/md.json` (2026-11-18) |
| Kansas | 2017-2018 to 2025-2026 (the 2020 and 2021 special sessions held no scanned bill) | 55 floor roll calls of a 146-bill dry batch (38 Committee of the Whole votes and motions not mapped), all with a dump copy (2023-24's matched by bill, chamber and day); 0 tally and 0 of 4,920 member-vote differences; all 4,920 record votes linked to a person (three by hand); see `backend/data/legislatures/ks.json` (2026-11-18) |
| Mississippi | 2018 to 2026 (2017 holds no bills; 20171E only resolutions) | 67 floor roll calls of a 289-bill dry batch, all with a dump copy: 2 dump tallies short by one vote (the name before a total that runs over a line), 8 member votes missing from the dump, 0 of 5,975 member-vote differences; 5,919 of 5,983 record votes linked to a person (four members Open States does not hold); see `backend/data/legislatures/ms.json` (2026-11-17) |

Washington's own sites refuse our reader (`robots.txt`), so Washington has no roll-call reader here and keeps its
LegiScan lines.
