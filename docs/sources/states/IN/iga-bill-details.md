---
profile: in-iga-bill-details
version: 2
scope: state:IN
body: legislature
match:
  url_prefixes:
    - https://iga.in.gov/legislative/2019/bills/
    - https://iga.in.gov/legislative/2020/bills/
    - https://iga.in.gov/legislative/2021/bills/
    - https://iga.in.gov/legislative/2022/bills/
    - https://iga.in.gov/legislative/2023/bills/
    - https://iga.in.gov/legislative/2024/bills/
    - https://iga.in.gov/legislative/2025/bills/
    - https://iga.in.gov/legislative/2026/bills/
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
    instrument: SB 208 (2024)
    record_kind: author
    actor_quote: "Authored by: Sen. Shelli Yoder"
    tally_quote: null
    expect: pass
  - batch: 2026-09-25-shadow-yoder
    snapshot: d9257546
    person: Shelli Yoder
    office_title: State Representative
    instrument: SB 208 (2024)
    record_kind: author
    actor_quote: "Authored by: Sen. Shelli Yoder"
    tally_quote: null
    expect: chamber-not-evidenced
---
# Indiana General Assembly — bill details (iga)

**Page:** `iga.in.gov/legislative/<year>/bills/<senate|house>/<n>/details` — title, digest, and the
author line `Authored by: Sen. Shelli Yoder, Sen. Vaneta Becker`, then co-authors and sponsors.

**Access:** JavaScript-only. Code cannot fetch it. Save it from a real browser into
`<batch>/human-saved/`.

**What it proves:** authorship (the author line) and the digest. It does not prove a vote — the roll
calls are separate PDFs (`in-iga-roll-call`).

**Traps:**
- The chamber is the title inside the author line (`Sen.` / `Rep.`), read back from the surname
  (rule `nearest-before`). `Indiana General Assembly 2024 Session` is not a chamber.
- This page spells the bill out in full (`Senate Bill 208`), never the short prefix a coder usually
  writes (`SB 208`) — CONFIRM maps the two to one instrument, so use whichever form reads naturally.
- `match.url_prefixes` lists one line per session year (`.../legislative/<year>/bills/`), not the bare
  `.../legislative/` root — a prefix that broad would also swallow other IGA pages under `/legislative/`
  that this profile's rules do not fit (final review fix 3). **A new session year needs a new prefix
  line here, plus a version bump**, or that year's pages resolve to no profile at all and CONFIRM
  reports `no-source-profile` for them.
