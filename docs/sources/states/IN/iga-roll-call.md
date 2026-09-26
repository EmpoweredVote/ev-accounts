---
profile: in-iga-roll-call
version: 1
scope: state:IN
body: legislature
match:
  url_prefixes:
    - https://iga.in.gov/pdf-documents/
page_kind: vote
rules:
  vote_block: aye-count
  chamber: page-header
  name_format: surname-initial
seat_titles:
  Senator: upper
  State Senator: upper
  Representative: lower
  State Representative: lower
controls:
  - batch: 2026-09-25-shadow-yoder
    snapshot: 6024804d
    person: Shelli Yoder
    office_title: Senator
    instrument: HB 1041 (2025)
    record_kind: vote
    actor_quote: "N AY - 6 Ford J.D. Jackson Qaddoura Spencer Hunley Yoder"
    tally_quote: "Yea 42 Student eligibility in interscholastic sports. Nay 6"
    expect: pass
  - batch: 2026-09-25-shadow-yoder
    snapshot: 6024804d
    person: Shelli Yoder
    office_title: State Representative
    instrument: HB 1041 (2025)
    record_kind: vote
    actor_quote: "N AY - 6 Ford J.D. Jackson Qaddoura Spencer Hunley Yoder"
    tally_quote: "Yea 42 Student eligibility in interscholastic sports. Nay 6"
    expect: chamber-not-evidenced
---
# Indiana General Assembly — roll call (PDF)

**Page:** `pdf-documents/<ga>/<year>/<house|senate>/bills/<BILL>/rollcalls/<BILL>.<n>_<H|S>.pdf` — one
roll call. The first line names the chamber (`Senate` / `House`), then the session, `GENERAL ASSEMBLY`,
the date, `Roll Call <n>`, the motion and `Yea N … Nay N`, then the YEA / NAY / EXCUSED / NOT VOTING lists.

**Access:** the PDF link opens from the bill page, which is JavaScript-only. Ask the operator before any
download (it shows a save dialog); read the saved file's text.

**What it proves:** how a named member voted on one roll call. Pair it with the bill page or bill text.

**Traps:**
- `GENERAL ASSEMBLY` is the whole legislature, not the House. The chamber is the page header (rule
  `page-header`). The `_S` / `_H` file suffix agrees with it.
- Shared surnames print with an initial after them (`Walker G`, `Walker K`) — rule `surname-initial`.
- The PDF text splits some words (`Y EA`, `N AY`); copy the words as the text shows them.
