---
profile: us-congress-gov-bill
version: 1
scope: nation:US
body: congress
match:
  url_prefixes:
    - https://www.congress.gov/bill/
page_kind: author
rules:
  vote_block: whole-page
  chamber: bill-origin
  name_format: last-first
  amendment_text: final
seat_titles:
  Representative: lower
  U.S. Representative: lower
  Senator: upper
  U.S. Senator: upper
controls:
  - batch: 2026-10-07-shadow-houchin-abortion
    snapshot: 149ab2b0
    person: Erin Houchin
    office_title: U.S. House of Representatives - Indiana 9th Congressional District
    instrument: H.R. 26 (118th Congress)
    record_kind: sponsor
    actor_quote: "Rep. Houchin, Erin [R-IN-9]"
    tally_quote: null
    expect: pass
---
# congress.gov — bill page (read through api.congress.gov)

**Page:** `https://www.congress.gov/bill/<n>th-congress/<house-bill|senate-bill|house-joint-resolution|…>/<number>`.
The website refuses code (HTTP 403, a browser-fingerprint wall). `coding:snapshot` and the verifier read
the same URL through `backend/src/lib/adapters/congressAdapter.ts`, which rebuilds the page from
api.congress.gov under our own key: title, policy area, `Sponsor: Rep. Wagner, Ann [R-MO-2]`, the latest
action, the CRS summaries, `Cosponsors: …` (the whole list, up to 250 — before 2026-10-07 only the
API's first 20 were printed), the first 15 actions, and the newest text version of the bill.

**What it proves:** who sponsored and who cosponsored the bill, and what the bill's text says. It does
not show a vote: pair it with the Clerk roll call (`us-house-clerk-roll-call`). Sponsorship evidences
the bill **as filed** (C37); the text printed is the **newest** version (for a passed bill, the
engrossed or enrolled text), so check that the provision a coder quotes was in the version the person
acted on.

**Traps:**
- Names print `Rep. <Surname>, <Given> [<Party>-<State>-<District>]` — the party prints with every
  name. Party is never evidence.
- The original cosponsors also print inside the introduced text (`Mrs. Houchin`), without a given name.
- Federal bills amend law in words (`is amended by striking … and inserting …`), so no deleted text is
  hidden: `amendment_text: final`.
- An omnibus or reconciliation bill (for example H.R. 1, 119th Congress) is far longer than this page
  can usefully carry. Cite its roll call and the person's own words about the provision instead.
