---
profile: in-iga-roll-call
version: 2
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
  amendment_text: marked
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

**Amendment markup (`amendment_text: marked`):** `match.url_prefixes` is `/pdf-documents/`, which also
covers an Indiana **bill-text** PDF (the enrolled/engrossed act), not only a roll call — a roll call has
no amending language to lose, but a bill-text PDF read from the same prefix does. Read it with
`pdf-snapshot.ts`, not a plain fetch: it detects the drawn strike-through rectangles, fences each
deleted word as `[deleted: …]` (added text is bold in the PDF and needs no fence — it is the law), and
appends its trailer line — so a `pdf-snapshot.ts` read is `amendment_markup: 'kept'` **because of that
trailer alone**, even on a page with no deletions to fence at all. The fail-closed case is a snapshot
with **neither** the `pdf-snapshot.ts` trailer **nor** a `[deleted: …]` fence — a plain fetch or a
plain-text extraction of the same PDF, with no strike detection run over it — which reads as
`amendment_markup: 'unknown'`; CONFIRM then fails closed (`amendment-markup-lost`) when the page also
says "is amended to read."
