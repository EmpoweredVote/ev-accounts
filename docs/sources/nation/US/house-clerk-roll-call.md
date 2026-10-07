---
profile: us-house-clerk-roll-call
version: 1
scope: nation:US
body: congress
match:
  url_prefixes:
    - https://clerk.house.gov/Votes/
page_kind: vote
rules:
  vote_block: whole-page
  chamber: page-header
  name_format: surname-doubled
seat_titles:
  Representative: lower
  U.S. Representative: lower
controls:
  - batch: 2026-10-07-shadow-houchin-abortion
    snapshot: 3c6cba5a
    person: Erin Houchin
    office_title: U.S. House of Representatives - Indiana 9th Congressional District
    instrument: H.R. 26 (118th Congress)
    record_kind: vote
    actor_quote: "Houchin Houchin Republican Indiana IN Yea"
    tally_quote: "yea: 220 nay: 210"
    expect: pass
---
# U.S. House — Clerk roll call vote

**Page:** `https://clerk.house.gov/Votes/<year><roll number>` (for example `/Votes/202329` is roll call
29 of 2023). One page is one recorded vote: `Roll Call <n> | Bill Number: H. R. 26`, the date and
Congress/session, `Vote Question: On Passage`, the bill's short title, `VOTES yea: 220 nay: 210 present: 1
not voting: 3`, a table of votes by party, and then every member as `<Surname> <Surname> <Party> <State>
<USPS> <Vote>`. The XML form of the same vote is `https://clerk.house.gov/evs/<year>/roll<nnn>.xml`.

**Access:** fetchable by code (no robots block, no JavaScript needed). To find a bill's roll calls, read the
bill's actions from api.congress.gov (`recordedVotes`), or scan the Clerk XML files for a `legis-num`.

**What it proves:** how a named member voted on one question. It does not print the bill text: pair it
with the congress.gov bill page (profile `us-congress-gov-bill`). Check the vote question — `On Motion to
Recommit`, `On Ordering the Previous Question` and `On Agreeing to the Resolution` (a rule) are not
passage votes.

**Traps:**
- **The page prints every member's party** (`Houchin Houchin Republican Indiana IN Yea`), and a
  votes-by-party table. Party is never evidence (codebook 0.2). A coder must not read a vote as
  party-line support.
- Two members with one surname print with the state: `Higgins (LA)`, `Higgins (NY)`. The `surname` rule
  sees the shared surname; give the state with the name in `actor_quote`.
- The navigation at the top names `U.S. Senate`, but only after the page title `U.S. House of
  Representatives`, so `page-header` reads the House (lower).
- The surname prints twice (a display column and a sort column). Copy it as the text shows it.
