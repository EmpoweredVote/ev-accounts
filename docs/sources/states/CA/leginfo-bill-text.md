---
profile: ca-leginfo-bill-text
version: 1
scope: state:CA
body: legislature
match:
  url_prefixes:
    - https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml
    - https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml
page_kind: bill-text
rules:
  vote_block: whole-page
  chamber: bill-origin
  name_format: surname
seat_titles:
  Senator: upper
  State Senator: upper
  Assembly Member: lower
  Assemblymember: lower
controls:
  - batch: 2026-09-25-shadow-durazo
    snapshot: fb096408
    person: Maria Elena Durazo
    office_title: Senator
    instrument: SB 580 (2025-2026)
    record_kind: author
    actor_quote: "SB 580, Durazo."
    tally_quote: null
    expect: pass
  - batch: 2026-09-25-shadow-durazo
    snapshot: fb096408
    person: Maria Elena Durazo
    office_title: Assembly Member
    instrument: SB 580 (2025-2026)
    record_kind: author
    actor_quote: "SB 580, Durazo."
    tally_quote: null
    expect: chamber-not-evidenced
---
# California Legislature — bill text (leginfo)

**Page:** `billNavClient.xhtml?bill_id=…` (bill text, with the Legislative Counsel's Digest).

**Access:** fetchable by code.

**What it proves:** the provision (quote it as `provision_quote`), and the **primary author**: the
Digest opens `SB 580, Durazo.` The primary author sits in the bill's house of origin, so the chamber
comes from the bill prefix (rule `bill-origin`: SB → Senate, AB → Assembly). Co-authors listed further
down may sit in either house — do not use them as an actor line.

**Traps:** the text shown is the latest amended version; cite the version in force at the vote you pair
it with.
