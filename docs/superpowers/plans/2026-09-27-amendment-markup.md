# Amendment Markup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Snapshots of amending bills keep deleted words as `[deleted: …]` fences (HTML and Indiana PDFs), sources declare how they print amendments, and CONFIRM fails closed when a provision comes from lost or deleted markup.

**Architecture:** A pure function turns a PDF page's geometry (text items + thin filled rectangles) into fenced text; a thin pdfjs-dist wrapper extracts that geometry. `htmlToMarkedText` fences struck HTML. Source profiles gain `amendment_text`; snapshots gain `amendment_markup`; CONFIRM gains `amendment-markup-lost` and `provision-deleted`.

**Tech Stack:** TypeScript ESM (`.js` suffixes), vitest, `pdfjs-dist` 5.4.296 (already in node_modules via pdf-parse; add as a direct dependency at that exact version), linkedom (already a dependency, used by `htmlToArticleOrText`).

**Spec:** `docs/superpowers/specs/2026-09-27-amendment-markup-design.md` (approved 2026-09-27).

## Global Constraints

- P1 stays SHADOW: do not import or change `backend/scripts/lib/stancePublishPolicy.ts`; its test passes unchanged.
- No DB writes; no `--apply`.
- The fence text is exactly `[deleted: ` + the deleted words + `]`. Adjacent deleted words merge into ONE fence.
- `htmlToText` (verifier) is unchanged; the new converter is used only by the snapshot path.
- A word is deleted when ≥ 60 % of its width is covered by strike rectangles; a strike rectangle has height < 1.5 pt and its centre lies strictly above the line's baseline and below baseline + 0.6 × font height (a rectangle at or below the baseline is an underline — ignored).
- `amendment_text` values: `final` (default) | `marked` | `unmarked`. `amendment_markup` values: `kept` | `none` | `unknown`.
- Fail closed: any doubt → a finding, never a pass.
- Commits: explicit pathspec only (`git add <paths>`, `git commit -F <msg> -- <paths>`); every message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Tests from `backend/`: `npx vitest run <paths>`. Scripts are not in `tsc -p .`; type-check them directly:
  `npx tsc --noEmit --module esnext --moduleResolution bundler --target es2022 --strict --esModuleInterop --skipLibCheck --forceConsistentCasingInFileNames --resolveJsonModule <files>`

---

### Task 1: PDF strike detection (`pdfMarkedText`)

**Files:**
- Create: `backend/scripts/lib/pdfMarkedText.ts`, `backend/scripts/lib/pdfMarkedText.test.ts`, `backend/scripts/lib/__fixtures__/in-hea1296-2022-p16.geometry.json`
- Modify: `backend/package.json` (+ `package-lock.json` via `npm install pdfjs-dist@5.4.296 --save-exact` from `backend/`)

**Interfaces (produces):**
```ts
export interface PdfTextItem { str: string; x: number; y: number; width: number; height: number; fontName: string }
export interface PdfRect { x0: number; x1: number; y0: number; y1: number }   // page coordinates, y up
export interface PageGeometry { items: PdfTextItem[]; rects: PdfRect[] }
/** Pure: geometry → page text with [deleted: …] fences. Items in reading order (top→bottom, left→right). */
export function markedTextFromGeometry(g: PageGeometry): string;
/** pdfjs-dist wrapper: every page's geometry. */
export async function pdfGeometry(data: Uint8Array): Promise<PageGeometry[]>;
/** Whole document: pages' marked text joined with '\n', whitespace collapsed per line. */
export async function pdfMarkedText(data: Uint8Array): Promise<string>;
```

- [ ] **Step 1: Capture the fixture.** Write a throwaway script (not committed) that runs `pdfGeometry` on `/private/tmp/claude-501/-Users-chrisandrews-Documents-GitHub-ev-accounts--claude-worktrees-clever-leakey-bd9943/6b39416e-dfe7-4b74-9487-27155eb0d3ad/scratchpad/HB1296.04.ENRS.pdf` and writes page 16 (index 15) to the fixture JSON. So implement `pdfGeometry` first:
  - `import { getDocument, OPS } from 'pdfjs-dist/legacy/build/pdf.mjs'` (the Node build).
  - Text: `page.getTextContent()`; for each item with non-empty `str`: `x = transform[4]`, `y = transform[5]`, `width`, `height`, `fontName`.
  - Rects: walk `page.getOperatorList()`; track the current transform (`OPS.save`/`restore`/`transform` → matrix stack); for `OPS.constructPath`, read the path's bounding box (pdf.js 5 passes `[ops, coords, minMax]` — use `minMax` = `[xMin, yMin, xMax, yMax]`; if absent, compute from coords), map through the current matrix, and keep it when the following paint op is a fill (`fill`/`eoFill`/`fillStroke`) and its height < 1.5 pt. Print how many rects were found; page 16 has ≥ 6.
- [ ] **Step 2: Write the failing tests** (`pdfMarkedText.test.ts`):
  - On the fixture: `markedTextFromGeometry` output contains `[deleted: Except as provided in subsection (c),]` and contains `A person may carry a handgun`, and does not contain `[deleted: A person`.
  - Synthetic: one item `"keep this strike that"` (x 0, width 210, height 10, y 100) with one rect over `strike that` at y 103 → `keep this [deleted: strike that]`.
  - Synthetic underline: same rect at y 99 (below baseline) → no fence.
  - Synthetic: two adjacent struck words in two items on one line → ONE fence.
  - Positive control: geometry with items and no rects → output has no `[deleted:`.
- [ ] **Step 3: Implement `markedTextFromGeometry`:** group items into lines by `y` (±1 pt), sort lines top→bottom (`y` desc) and items by `x`; split each item into words on spaces; word x-range = item.x + (chars before word / item length) × item.width (character-count share); a word is deleted if the union of overlapping strike rects (vertical rule above) covers ≥ 60 % of its x-range; emit words with runs of deleted words (across items on the line and across line ends) wrapped in one fence; join lines with a space.
- [ ] **Step 4: Run** `npx vitest run scripts/lib/pdfMarkedText.test.ts` → PASS; direct tsc on the lib → exit 0.
- [ ] **Step 5: Commit** lib, test, fixture JSON, package.json, package-lock.json — message `feat(snapshots): pdfMarkedText — Indiana PDF strike-throughs become [deleted: …] fences`.

---

### Task 2: HTML fences, profile rule, snapshot field, collector PDF script

**Files:**
- Create: `backend/scripts/lib/htmlMarkedText.ts` (+ test), `backend/scripts/pdf-snapshot.ts`
- Modify: `backend/scripts/lib/recordBasis.ts` (`AmendmentText` type + `AMENDMENT_TEXTS` + field in `SourceRules`, default `final` in `GENERIC_RULES`), `backend/scripts/lib/sourceProfiles.ts` (+ test: accept/reject `amendment_text`), `backend/scripts/lib/snapshotSources.ts` (+ test: `amendment_markup` on `SnapshotRecord`), `backend/scripts/snapshot-sources.ts` (choose `htmlToMarkedText` when the URL's profile is `marked`)

**Interfaces (produces):**
```ts
// htmlMarkedText.ts
export function htmlToMarkedText(html: string): string;   // like htmlToText, plus [deleted: …] fences
// recordBasis.ts
export type AmendmentText = 'final' | 'marked' | 'unmarked';
export const AMENDMENT_TEXTS: readonly AmendmentText[];
// SourceRules gains: amendment_text: AmendmentText   (GENERIC_RULES: 'final')
// snapshotSources.ts — SnapshotRecord gains: amendment_markup: 'kept' | 'none' | 'unknown'
export function amendmentMarkup(text: string, amendmentText: AmendmentText): 'kept' | 'none' | 'unknown';
```

- `htmlToMarkedText`: parse with linkedom; before stripping, replace every element that is `strike`/`s`/`del`, or has inline `style` containing `line-through`, or whose class is named in a `<style>` rule containing `line-through`, with the text `[deleted: <its textContent collapsed>]`; then strip like `htmlToText`. Tests: each of the five forms fences; plain text unchanged; a struck element nested in a paragraph keeps the surrounding words.
- `amendmentMarkup(text, amendmentText)`: `'none'` when `amendmentText === 'final'`; `'kept'` when `text.includes('[deleted: ')` or the text ends with the pdf-snapshot trailer `[extracted by pdf-snapshot.ts with strike detection`; else `'unknown'`. `buildSnapshot` takes an optional `amendmentText` (default `'final'`) and fills the field; old snapshots.json files without the field read as `'unknown'` in CONFIRM (Task 3).
- `pdf-snapshot.ts --url <pdf> --referer <bill page> --out <file>`: fetch with headers `Referer`, `Accept: application/pdf,*/*`, the EmpoweredVoteBot UA; honour `robotsAllows` (fail closed on a known-disallow host); refuse a non-PDF response; write `pdfMarkedText(data)` + `\n[extracted by pdf-snapshot.ts with strike detection, <ISO date>, <url>]`.
- Profile loader: `rules.amendment_text` optional, validated against `AMENDMENT_TEXTS`, default `final`.
- Commit message: `feat(snapshots): amendment_text profile rule, HTML deletion fences, amendment_markup, pdf-snapshot collector`.

---

### Task 3: CONFIRM findings, codebook, profiles

**Files:**
- Modify: `backend/scripts/lib/recordBasis.ts` (+ test), `backend/scripts/lib/confirm.ts` (+ test), `docs/codebook/stance-and-quote-codebook.md`, `docs/sources/states/AZ/azleg-bill-text.md` (`amendment_text: marked`, version 2), `docs/sources/states/IN/iga-roll-call.md` (`amendment_text: marked` — it is the `/pdf-documents/` prefix, which also covers bill-text PDFs; version 2), `docs/sources/README.md` (catalogue row)

**Interfaces:**
- `RecordFinding` and `ConfirmFinding` gain `'amendment-markup-lost'` and `'provision-deleted'`.
- `checkRecordGroup` input gains `markupOf?: (p: Passage) => 'kept' | 'none' | 'unknown'` (absent → `'unknown'`).
- Rules (fail closed): for the passage(s) whose `provision_quote` is verbatim on its page:
  - `provision-deleted` if the quote overlaps any `[deleted: …]` fence on that page (compare on the collapsed page text: the quote's span intersects a fence span);
  - `amendment-markup-lost` if the page contains `is amended to read` (case-insensitive) and the passage's profile `amendment_text !== 'final'` and `markupOf(p) !== 'kept'`.
- `confirmRow` passes `markupOf` from the snapshot records (codingReport already has them via `snapshotText`; add `snapshotMarkup: ReadonlyMap<string, 'kept'|'none'|'unknown'>` to its input and to `buildCodingReport`, filled by `code-stance-batch.ts` from `snapshots.json`, missing field → `'unknown'`).
- Codebook V3: one bullet — text inside `[deleted: …]` is removed from the law; it is never the provision.
- Tests: a provision inside a fence → `provision-deleted`; an amending page, `unmarked`/`unknown` → `amendment-markup-lost`; the same page `kept` → none; a `final` source → none; the real-page controls in `sourceProfiles.real.test.ts` still pass.
- Commit message: `feat(confirm): provision-deleted and amendment-markup-lost fail closed; codebook fence rule; AZ/IN profiles marked`.

---

### Task 4 (controller): end-to-end on the Smaltz batch

Rebuild `2026-09-27-shadow-smaltz` (Ben Smaltz, IN HD-52, HEA 1296 (2022), `gun-policy`): the details page (author block, human-saved), the enrolled text via `pdf-snapshot.ts`, and the House roll-call PDF if found. Run the three coders; check the snapshot text around §35-47-2-1 shows `[deleted: …]`; run the report.
