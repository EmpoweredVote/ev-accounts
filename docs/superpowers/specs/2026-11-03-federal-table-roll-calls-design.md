# Federal roll calls from `essentials.legislative_votes` — design

Status: draft for Chris Andrews' review, 2026-11-03. Nothing is built.

## Why

Federal Stage 5 batches rest many seats on roll-call votes. Today each vote reaches a person in two
hand steps:

1. **Identity by surname (step 2, pre-fill).** A census instrument in the source store
   (`backend/data/source-store/instruments/federal/*.json`) lists each roll call's members by surname,
   often taken from a reader summary (`"note": "names from: reader summary"`). `census:identity` turns
   each surname into a `politician_id`, and `topic:stage5-prefill` turns each matched member into a
   finding. Surnames collide ("Jackson (IL)"). A wrong match seats the wrong person; a missed match
   leaves a person uncoded, and nothing downstream can add them back.
2. **Citation by fetch (step 7).** Each House vote needs its Clerk XML, and each Senate vote goes
   senate.gov → Voteview → LegiScan (`senate-vote-legiscan-urls.ts`).

`essentials.legislative_votes` now holds the recorded position of every sitting member, keyed by
`politician_id` through the bioguide id (official, not a name): 438 of 439 House seats and 107 of 108
Senate seats have votes, current to 2026-10-19 (House) and 2026-09-30 (Senate). A spot check matched
the public record (Jeffries, House roll call 190 of 2025, nay, 218-214).

So the table can settle **who** voted **how** without name matching. It cannot be the citation: a
reader cannot open a database row. The citation stays the public page the verifier already re-reads.

Accuracy comes first. Fewer fetches and fewer API calls are the second gain, not the goal.

## Goals

1. **Match each census roll call to exactly one table roll call.** For each `roll-call` vote on a
   federal instrument that the census reviewed (`stage0/gates.tsv`): the same bill (instrument id →
   Congress and bill number, e.g. `US-HJRES-44-2023` ↔ session `118`, bill `HJRES 44`), the same date,
   and yea/nay totals within one of the instrument's (existing ruling: LegiScan totals can differ from
   the official tally by one; each person's own vote must agree). No match, or more than one, is
   reported and that vote falls back to today's path for everyone.
2. **Step 2 takes positions from the table, by `politician_id`.** For every roster member, the pre-fill
   reads their position on each matched roll call from the table and writes the finding from it. No
   surname is used. This replaces `census:identity` for matched federal roll calls. (Decided by Chris
   Andrews, 2026-11-03.)
3. **Cross-check the hand lists at step 2.** Where the instrument's member list names a roster member
   with a `politician_id`, compare that vote with the table:
   - **Disagree** (yea vs nay): 🔴 the pre-fill writes nothing and prints every disagreement. The
     runner fixes the instrument by hand (or the table is wrong, and that is reported), then re-runs.
   - **In the hand list, not in the table** (e.g. a member whose votes did not load): keep the hand
     finding, as today, and list it.
   - **In the table, not matched in the hand list:** the new finding, the gain. Listed by count.
4. **Step 7 builds the citations with fewer fetches** and re-checks each seated vote against the table:
   - **House:** the citation is the Clerk XML (`clerk.house.gov/evs/<year>/roll<NNN>.xml`), unchanged.
     The roll number comes from the table (`vote_question` ends `RC# <n>`; year from `vote_date`). The
     XML is fetched **once per roll call**, not once per person, to read how it prints each member
     (surname, state). The line is the one `rollCallEvidence.ts` already verifies.
   - **Senate (115th Congress on):** the citation is the LegiScan roll-call page, unchanged. The
     LegiScan roll-call id comes straight from the table (`external_vote_id` = `legiscan-<id>`), so the
     senate.gov → Voteview → LegiScan mapping is skipped. The line is built by the existing
     `legiscan-evidence-lines.ts`, which still makes one counted call per roll call.
   - One command for the vote half of step 7 at the federal unit, in the shape of `iga-votes.ts`: it
     writes the lines, cites them, uncites a covered page, writes `crosscheck.json` (🔴 0 disagree), and
     lists every vote it could not place in `unmapped.json` (hold that person; do not guess).

## Non-goals

- **Finding new bills.** The table never decides which bills belong to a topic. A vote on a bill the
  census did not review and pass must not seat anyone. (Possible later work, only with its own design.)
- **Sponsorships.** Out of scope at both steps; they keep today's path.
- No change to the verifier, the stance gate or the line formats.
- No new table, no index, no migration.
- Senate votes before the 115th Congress (Voteview only): no page the verifier can read (senate.gov
  blocks automated fetches). They keep today's path and are listed.
- State legislatures. The table also holds state votes; this lane reads federal sessions only
  (`legislative_sessions.jurisdiction = 'federal'`).

## Anti-goals (a failure even if it "works")

- A seat that cites a database row, or an internal URL, as its source.
- A finding from a roll call that matched zero or two table roll calls.
- Any party label in a finding, a line, a log or a report (antipartisan rule).
- A guessed identity: a roster member with no table votes (today: Senator Padilla, Rep. Clay Fuller)
  is never matched by surname as a new fallback. They keep exactly today's path and are named.

## Constraints

- **Read only against the database.** Step 2 writes findings to the source store, as today. Step 7
  writes files in the batch folder. Neither writes to the database.
- **Query shape.** The table is large (a plain `count(*)` times out at 60 s) and is indexed on
  `politician_id` only (`idx_essentials_legislative_votes_politician_id`, plus the unique
  `(politician_id, bill_id, session_id, external_vote_id)`). There is **no index on `bill_id` or
  `external_vote_id`**, so never query by roll call or bill alone. Query per roster member, restricted
  to the instruments' bill ids: about 0.2 s each, a few minutes for a federal roster.
- **No chamber column.** A roll call is identified by `external_vote_id`; the chamber is inferred,
  not read. Matching on bill + date + totals is what tells a House vote from a Senate one on the same
  bill and day (totals near 435 vs near 100).
- Party is never read, stored or printed. The Clerk XML carries a party attribute: never copy it.
- Clerk XML fetches use the verifier's honest identity (`src/lib/verificationFetch.ts`), not the
  browser user-agent the research tools use.
- Pure logic stays pure: `stage5Prefill.ts` is "no database, no network". The table read happens in
  the script and is passed in as data.

## Decided

- The table is the **finder and the identity source**; the public page is the **citation**. (Chris
  Andrews, 2026-11-03.)
- The table supplies positions **at step 2**, not only as a step-7 check. (Chris Andrews, 2026-11-03.)
- Accuracy over speed. (Chris Andrews, 2026-11-03.)

## Builder's calls (Claude's, to be checked)

- **Positions.** Table `yea` → `yea`, `nay` → `nay`, `present` → `abstain` (a deliberate act).
  `not_voting` → no finding: the table cannot tell an absence from a refusal to vote, and the federal
  hand lists record no `abstain` today.
- **Fallback when a roll call does not match:** today's path, for that roll call only, listed in
  `prefill/skipped.json` with the reason.
- **Where the code goes:** `stage5Prefill.ts` gains an optional input (matched roll calls with each
  roster member's position) and a cross-check result; `topic-stage5-prefill.ts` gains `--from-table`
  to read it. The step-7 tool is `backend/scripts/stage5/federal-votes.ts`. Pure matching sits in a
  library with tests on recorded fixtures (a House roll call, a Senate roll call, a one-off total, a
  no-match, a two-match, a disagreement).
- **Cross-check at step 7** covers the batch's seated votes only (as `iga-votes.ts` does).
- **Proof, House:** replay on the voting-rights federal batch
  (`.planning/research/s3-prep-voting-rights/stage5/write/federal-01/`, workspace root): the pre-fill
  dry run against its instruments, then step 7 against its seated votes. Compare only standard
  roll-call lines (`House roll call N (YYYY), …: Surname (ST) voted X.`); that folder also carries raw
  Season 1 snippets on Clerk pages that are not instrument votes.
- **Proof, Senate:** the replay batch has no Senate roll-call seats. Fixtures, plus a hand check of
  three real Senate votes against their LegiScan pages before first use; the first Senate batch's
  `PREVIEW.md` names the path as new.
- **Coverage** starts at the 115th Congress (2017). Every House vote on a federal instrument today is
  2017 or later. Committee votes and votes with no member names are listed as unmatched.

## Left to the builder

- The exact SQL: federal session ids, bill number normalisation, parsing `RC# <n>`.
- File names inside the batch folder, beyond `crosscheck.json` and `unmapped.json`.
- How STAGE5.md and the stage5 README describe the change.
