---
profile: ca-leginfo-bill-votes
version: 1
scope: state:CA
body: legislature
match:
  url_prefixes:
    - https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml
page_kind: vote
rules:
  vote_block: aye-count
  chamber: word-before-floor
  name_format: surname
seat_titles:
  Senator: upper
  State Senator: upper
  Assembly Member: lower
  Assemblymember: lower
controls:
  - batch: 2026-09-25-shadow-durazo
    snapshot: aa219c5b
    person: Maria Elena Durazo
    office_title: Senator
    instrument: SB 1174 (2023-2024)
    record_kind: vote
    actor_quote: "Cortese, Dodd, Durazo, Eggman"
    tally_quote: "Ayes Count 30 Noes Count 8 NVR Count 2"
    expect: pass
  - batch: 2026-09-25-shadow-durazo
    snapshot: 8666d0a3
    person: Maria Elena Durazo
    office_title: Senator
    instrument: AB 1955 (2023-2024)
    record_kind: vote
    actor_quote: "Dodd, Durazo, Eggman"
    tally_quote: "Ayes Count 29 Noes Count 8 NVR Count 3"
    expect: pass
  - batch: 2026-09-25-shadow-durazo
    snapshot: f3a91fb1
    person: Maria Elena Durazo
    office_title: Senator
    instrument: SB 57 (2025-2026)
    record_kind: vote
    actor_quote: "Cervantes, Cortese, Durazo, Grayson"
    tally_quote: "Ayes Count 29 Noes Count 8 NVR Count 3"
    expect: pass
  - batch: 2026-09-25-shadow-durazo
    snapshot: aa219c5b
    person: Maria Elena Durazo
    office_title: Assembly Member
    instrument: SB 1174 (2023-2024)
    record_kind: vote
    actor_quote: "Cortese, Dodd, Durazo, Eggman"
    tally_quote: "Ayes Count 30 Noes Count 8 NVR Count 2"
    expect: chamber-not-evidenced
  - batch: 2026-09-25-shadow-durazo
    snapshot: 8666d0a3
    person: Maria Elena Durazo
    office_title: Assembly Member
    instrument: AB 1955 (2023-2024)
    record_kind: vote
    actor_quote: "Dodd, Durazo, Eggman"
    tally_quote: "Ayes Count 29 Noes Count 8 NVR Count 3"
    expect: chamber-not-evidenced
---
# California Legislature — bill votes (leginfo)

**Page:** `billVotesClient.xhtml?bill_id=<session><bill>` — every recorded floor and committee vote on
one bill, newest first. Each vote starts `Date … Result … Location <Chamber> Floor | <Committee>`, then
`Ayes Count N Noes Count N NVR Count N`, the motion, and the Ayes / Noes / NVR name lists.

**Access:** robots-disallowed. Code does not fetch it. Save it from a real browser into
`<batch>/human-saved/` (`fetched_by = human`, `source_kind = public-record`).

**What it proves:** how a named member voted on one motion. It does **not** carry the bill text — pair it
with the bill-text page (`leginfo-bill-text`) in one record group (codebook V3, two-passage vote).

**Traps:**
- `Motion Assembly 3rd Reading` on a **Senate** floor vote names the bill's house of origin. The chamber
  is the word before `Floor` (rule `word-before-floor`).
- One page prints several votes (floor, concurrence, committee). Copy the `tally_quote` from the **same**
  vote as the `actor_quote`, or CONFIRM reports `tally-other-vote`.
- Members print by surname only; the same member appears once per vote.
- Committee votes (`Location` = a committee) are not floor votes; treat them as a separate vote.
