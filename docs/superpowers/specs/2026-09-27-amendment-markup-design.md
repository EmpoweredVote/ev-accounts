# Amendment markup in snapshots — design

**Status:** approved in session (Chris Andrews, 2026-09-27), including `pdfjs-dist` as a direct
backend dependency. Not built.
**Parents:** `2026-09-26-source-profiles-design.md` (profiles), `2026-09-25-stance-quote-codebook-reliability-design.md` (shadow pipeline).
**P1 remains SHADOW.**

## Problem

A bill that **amends** existing law prints the old section with its changes marked: deleted words
struck through, added words bold (Indiana) or in capitals (Arizona). Our snapshots are plain text, so
the marking is lost and deleted words read as law.

- Indiana HEA 1296 (2022), the permitless-carry act. Extracted text reads "a person shall not carry a
  handgun … without being licensed" — words the act **deletes**. A coder would read the opposite of the
  law. (Found 2026-09-27; the batch was stopped.)
- Most rung-shaped bills amend existing law (carry permits, abortion limits, voucher eligibility), so
  without a fix they cannot be coded safely.

What the sources do (checked 2026-09-27):

| Source | Amended text | Deletions marked by |
|---|---|---|
| CA leginfo, chaptered text | printed in its **final** form | nothing to mark — safe |
| AZ azleg `.htm` | old + new text | strike-through in the HTML; added text in CAPITALS |
| IN iga PDFs | old + new text | a drawn line (a thin filled rectangle) through each deleted word; added text in a bold font |

Pure repeals ("Section 13-3603 … is repealed") and wholly NEW sections have no markup problem.

## Design

### 1. The profile says how the source prints amendments

New optional profile rule `amendment_text` (default `final`, today's behaviour):
- `final` — the page prints the law as it will read. No markup expected. (CA chaptered.)
- `marked` — deletions are recoverable from the page's markup (AZ HTML, IN PDFs once extracted with §3).
- `unmarked` — deletions are NOT recoverable (a PDF read without §3, or any plain-text copy).

The loader validates it like the other rule kinds. CA bill text → `final`; AZ bill text → `marked`;
IN bill details stays `final` (a digest page); an IN bill-text PDF profile → `marked`.

### 2. Deletions become text: `[deleted: …]`

Snapshot text keeps deleted words, fenced so no one can read them as law:
`… (b) [deleted: Except as provided in subsection (c),] A person may carry …`

- **HTML** (`htmlToText` for snapshots): an element that is `<strike>`, `<s>`, `<del>`, or whose inline
  style or class sets `text-decoration: line-through` → `[deleted: <its text>]`. A new function
  `htmlToMarkedText`, used only by the snapshot path; `htmlToText` is unchanged for the verifier.
- **PDF** (`pdfMarkedText.ts`, pdfjs-dist in Node): per page, collect the thin filled rectangles
  (height < 1.5 pt) that sit on a text line — between the line's baseline and baseline + 0.6 × its font
  height; a rectangle below the baseline is an underline and is ignored. Split each text item into words,
  place each word by its share of the item's width (glyph widths from the font when pdf.js gives them,
  else character count). A word is deleted when ≥ 60 % of its width is covered by strike rectangles.
  Adjacent deleted words merge into one `[deleted: …]`.
- Added text needs no fence: it is the law. (Bold/capitals stay as they are.)

### 3. How a snapshot gets it

- A **code fetch** of an HTML page from a `marked` source uses `htmlToMarkedText`.
- A **PDF** from a `marked` source (Indiana) is read with `pdfMarkedText` by a new collector script,
  `pdf-snapshot.ts --url <pdf> --out <batch>/human-saved/<name>.txt`, which the collector runs; the
  file records `[extracted by pdf-snapshot.ts with strike detection, <date>]` in a trailer line. The
  collector names it in `sources.json` like any saved page. (iga.in.gov PDFs need the `Referer` of the
  bill page; iga has no robots restriction.)
- Each snapshot records `amendment_markup: 'kept' | 'none' | 'unknown'`: `kept` when the text contains
  a `[deleted:` fence or came through §2, `none` for a `final` source, `unknown` otherwise.

### 4. CONFIRM fails closed

New finding **`amendment-markup-lost`** when a record group's `provision_quote` is taken from a page
that shows amending language (`is amended to read`, `IS AMENDED TO READ AS FOLLOWS`) and whose source is
not `final` and whose snapshot is not `kept`. And **`provision-deleted`** when the `provision_quote`
lies, in whole or in part, inside a `[deleted: …]` fence.

### 5. Codebook

V3/V4.1: text inside `[deleted: …]` is removed from the law. It is never the provision, and a coder
never quotes it as what the law says. A bill's effect is the added text plus the unchanged text.

## Tests (TDD)

- `htmlToMarkedText`: `<strike>`, `<s>`, `<del>`, inline `text-decoration:line-through`, a class whose
  style rule sets line-through → fenced; ordinary text unchanged; nested markup.
- `pdfMarkedText` on **HB 1296 (2022) enrolled, page 16**. The fixture is the page's GEOMETRY as JSON
  (text items with position/width/font, and the thin filled rectangles), captured once from the real PDF
  by the extractor itself — one PDF page carries the document's embedded fonts (520 KB), too big to
  commit. The mapping is a pure function over that geometry. The output
  contains `[deleted: Except as provided in subsection (c),]` and the unstruck `A person may carry a
  handgun`. A positive control on a page with no strike lines: no fence at all.
- CONFIRM: a provision inside a fence → `provision-deleted`; an amending page from an `unmarked` source
  → `amendment-markup-lost`; the same page `kept` → no finding; a `final` source → no finding.
- Profile loader accepts/rejects `amendment_text`.
- `stancePublishPolicy.test.ts` unchanged.

## Out of scope

- Arizona's capitals convention as a separate signal (the fence already marks deletions).
- Rebuilding past batches (they cite no amended provision; the stopped Smaltz batch is the first user).
