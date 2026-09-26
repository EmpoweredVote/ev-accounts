---
profile: in-iga-bill-details
version: 1
scope: state:IN
body: legislature
match:
  url_prefixes:
    - https://iga.in.gov/legislative/
page_kind: author
rules:
  vote_block: whole-page
  chamber: nearest-before
  name_format: surname
seat_titles:
  Senator: upper
  State Senator: upper
  Representative: lower
  State Representative: lower
controls:
  - batch: 2026-09-25-shadow-yoder
    snapshot: d9257546
    person: Shelli Yoder
    office_title: Senator
    instrument: Senate Bill 208 (2024)
    record_kind: author
    actor_quote: "Authored by: Sen. Shelli Yoder"
    tally_quote: null
    expect: pass
---
# Indiana General Assembly — bill details (iga)

**Page:** `iga.in.gov/legislative/<year>/bills/<senate|house>/<n>/details` — title, digest, and the
author line `Authored by: Sen. Shelli Yoder, Sen. Vaneta Becker`, then co-authors and sponsors.

**Access:** JavaScript-only. Code cannot fetch it. Save it from a real browser into
`<batch>/human-saved/`.

**What it proves:** authorship (the author line) and the digest. It does not prove a vote — the roll
calls are separate PDFs (`in-iga-roll-call`).

**Traps:** the chamber is the title inside the author line (`Sen.` / `Rep.`), read back from the surname
(rule `nearest-before`). `Indiana General Assembly 2024 Session` is not a chamber.
