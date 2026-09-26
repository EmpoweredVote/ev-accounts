---
profile: az-azleg-bill-status
version: 1
scope: state:AZ
body: legislature
match:
  url_prefixes:
    - https://apps.azleg.gov/BillStatus/
page_kind: vote
rules:
  vote_block: whole-page
  chamber: word-before-reading
  tally_format: dash-ayes-nays
  name_format: surname
seat_titles:
  Senator: upper
  State Senator: upper
  Representative: lower
  State Representative: lower
controls:
  - batch: 2026-09-26-shadow-gowan
    snapshot: "7c587e83"
    person: David Gowan
    office_title: State Senator
    instrument: HB 2552 (2023)
    record_kind: vote
    actor_quote: "GOWAN Y"
    tally_quote: "Passed 16-14-0-0-0"
    expect: pass
  - batch: 2026-09-26-shadow-gowan
    snapshot: "7c587e83"
    person: David Gowan
    office_title: State Representative
    instrument: HB 2552 (2023)
    record_kind: vote
    actor_quote: "GOWAN Y"
    tally_quote: "Passed 16-14-0-0-0"
    expect: chamber-not-evidenced
---
# Arizona Legislature — bill status and roll-call votes (azleg)

**Page:** `apps.azleg.gov/BillStatus/BillOverview?SessionID=<n>&BillNumber=<bill>` — sponsors, committee
actions, and one row per floor vote (`Show House THIRD`, `Show Senate THIRD`). Clicking a row opens a
dialog: `Senate Third Reading - <bill> <title>`, the date, `Passed 16-14-0-0-0`, then every member as
`SURNAME Y|N`.

**Access:** JavaScript-only. Code cannot fetch it. Open it in a real browser, open the vote dialog, and
save **the dialog text alone** into `<batch>/human-saved/`. Do not save the sponsor list in the same
file: a sponsor who also voted is then printed twice, and CONFIRM reads two members
(`name-collision`).

**What it proves:** how a named member voted on one floor vote. It does not carry the bill text — pair
it with `azleg-bill-text`.

**Traps:**
- `Senate Third Reading` / `House Third Reading` names the chamber that voted (rule
  `word-before-reading`). This is the opposite of California, where `Motion Assembly 3rd Reading`
  names the bill's house of origin.
- The tally is unlabelled: `16-14-0-0-0` = Ayes-Nays-Not voting-Excused-Vacant (rule
  `tally_format: dash-ayes-nays`).
- Members print by surname only, in capitals; a shared surname prints with an initial.
- `SessionID` numbers the session (127 = 2023, 56th Legislature, 1st Regular).
