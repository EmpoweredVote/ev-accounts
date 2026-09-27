/**
 * htmlMarkedText — HTML→text for the snapshot path that keeps deleted words as `[deleted: …]`
 * fences, so an amending bill's struck text is never read as law (spec 2026-09-27-amendment-markup-
 * design.md §2). Used ONLY by the collector's snapshot path (snapshot-sources.ts); the verifier's
 * htmlToText (backend/src/lib/verificationFetch.ts) is unchanged.
 *
 * A struck element is one of:
 *   - a <strike>, <s> or <del> tag,
 *   - an element whose inline `style` attribute sets `text-decoration` (or the longhand
 *     `text-decoration-line`) to include `line-through`,
 *   - an element whose class (matched case-insensitively — CSS class names are case-sensitive in
 *     the DOM, but a hand-written stylesheet's casing is not something to trust) is named by a
 *     `<style>` rule whose declarations set the same.
 *
 * Every top-level struck element (an element inside another struck element is not fenced again —
 * its text is already carried by the ancestor's own fence) is replaced with the text
 * `[deleted: <its textContent, whitespace collapsed>]` before the document is stripped to plain text
 * with the same legacy tag-stripping/entity-decoding {@link htmlToText} uses, so ordinary text reads
 * exactly as it always has. Adjacent fences left separated only by whitespace (two `<strike>` runs
 * split by an inline element boundary, most often) are merged into one.
 *
 * FAIL CLOSED, reported as `unresolved` rather than embedded in the text (fix round 2 — the marker
 * used to be appended to the returned string, but an excerpt-only snapshot can cut it off, so the
 * caller must see it as an explicit flag instead): a rule may be striking text this reader cannot
 * find when
 *   - a `<style>` rule sets line-through on a selector this reader cannot reduce to either a bare
 *     class name or a bare tag name already in {@link STRUCK_TAGS} (a combinator, a pseudo-class, an
 *     attribute or id selector, or a bare tag/universal selector this reader does not already treat
 *     as struck), or
 *   - the page links or `@import`s an external stylesheet this reader never reads at all.
 * `htmlMarkedTextWithStats` returns `{ text, unresolved }`; `htmlToMarkedText` is a string-only
 * convenience wrapper for callers that only need the text. `unresolved` must be threaded through to
 * `buildSnapshot`'s `markupUnresolved` (snapshotSources.ts) rather than searched for in the text —
 * the literal marker this module used to embed is NOT coder-visible output.
 *
 * ATTRIBUTE NAMES ARE READ CASE-INSENSITIVELY (fix round 3): HTML attribute names are case-insensitive
 * by spec, but linkedom's `Element.getAttribute` is a case-SENSITIVE lookup against whatever case the
 * source HTML actually used — `getAttribute('style')` on `<span STYLE="...">` returns `null`. That
 * silently failed open: `STYLE="text-decoration:line-through"`, `CLASS="s"` (against a `.s` rule), and
 * `<link REL="stylesheet">` were all missed, so the struck words read as law with `unresolved` false.
 * {@link attrCI} reads `element.attributes` (name/value pairs preserving source casing) and matches
 * the wanted name case-insensitively; every attribute this module inspects (`style`, `class`, `rel`)
 * goes through it instead of `getAttribute`.
 */
import { parseHTML } from 'linkedom';
import { htmlToText } from '../../src/lib/verificationFetch.js';

const STRIKE_TAGS = new Set(['STRIKE', 'S', 'DEL']);
const LINE_THROUGH_RE = /text-decoration(?:-line)?\s*:[^;]*line-through/i;

export interface HtmlMarkedTextResult { text: string; unresolved: boolean }

interface AttrHolder { attributes: ArrayLike<{ name: string; value: string }> }

/** Case-insensitive `getAttribute` (see the module doc's ATTRIBUTE NAMES note): linkedom's own
 * `getAttribute` matches the source HTML's exact casing, so `STYLE=`/`CLASS=`/`REL=` are invisible to
 * a lower-case lookup. Reads `element.attributes` directly instead and compares names lower-cased. */
function attrCI(el: AttrHolder, name: string): string | null {
  const lower = name.toLowerCase();
  for (const a of Array.from(el.attributes)) if (a.name.toLowerCase() === lower) return a.value;
  return null;
}

// A selector this reader trusts itself to test via an element's classList: one or more class tokens
// (each ".name"), with an optional leading tag name and no combinator, pseudo-class, attribute or id
// selector anywhere in it. "div.struck", ".struck", ".a.b" all qualify; "p .struck" (descendant),
// ".struck:hover", "[data-x]", "#id", or a bare "p" (no class at all) do not.
const RESOLVABLE_SELECTOR_RE = /^[a-zA-Z][a-zA-Z0-9_-]*(?:\.[a-zA-Z0-9_-]+)+$|^(?:\.[a-zA-Z0-9_-]+)+$/;
const CLASS_TOKEN_RE = /\.([a-zA-Z0-9_-]+)/g;
// A bare tag name, and nothing else — resolvable only when that tag is already one of STRIKE_TAGS
// (matching it needs no class lookup at all; isStruck already covers every element with this tag).
const BARE_TAG_RE = /^[a-zA-Z][a-zA-Z0-9-]*$/;

interface StruckClasses { classes: Set<string>; unresolved: boolean }

/** Class names (lower-cased) declared struck by any `<style>` block's rules (a simple, non-nested
 * CSS reader), plus whether any line-through rule used a selector it could not resolve to either a
 * class or a tag this reader already treats as struck. */
function struckClassesFrom(document: { querySelectorAll(sel: string): ArrayLike<{ textContent: string | null }> }): StruckClasses {
  const classes = new Set<string>();
  let unresolved = false;
  for (const style of Array.from(document.querySelectorAll('style'))) {
    const css = style.textContent ?? '';
    for (const m of css.matchAll(/([^{}]+)\{([^{}]*)\}/g)) {
      const [, selectorList, decls] = m;
      if (!LINE_THROUGH_RE.test(decls)) continue;
      for (const selRaw of selectorList.split(',')) {
        const sel = selRaw.trim();
        if (!sel) continue;
        if (RESOLVABLE_SELECTOR_RE.test(sel)) {
          for (const cm of sel.matchAll(CLASS_TOKEN_RE)) classes.add(cm[1].toLowerCase());
        } else if (BARE_TAG_RE.test(sel) && STRIKE_TAGS.has(sel.toUpperCase())) {
          // e.g. "s { text-decoration: line-through }" — isStruck already fences every <s>, so this
          // rule adds nothing this reader doesn't already catch; not unresolved.
        } else {
          unresolved = true;
        }
      }
    }
  }
  return { classes, unresolved };
}

/** True when the page links or `@import`s a stylesheet this reader never reads — it may set
 * line-through on elements no local `<style>` rule (or tag/inline check) ever mentions. */
function hasExternalStylesheet(document: {
  querySelectorAll(sel: string): ArrayLike<AttrHolder & { textContent: string | null }>;
}): boolean {
  for (const link of Array.from(document.querySelectorAll('link'))) {
    const rel = (attrCI(link, 'rel') ?? '').toLowerCase().split(/\s+/);
    if (rel.includes('stylesheet')) return true;
  }
  for (const style of Array.from(document.querySelectorAll('style'))) {
    if (/@import\b/i.test(style.textContent ?? '')) return true;
  }
  return false;
}

interface StruckElement extends AttrHolder {
  tagName: string;
  contains(other: unknown): boolean;
  textContent: string | null;
  replaceWith(node: unknown): void;
}

function isStruck(el: StruckElement, struckClasses: Set<string>): boolean {
  if (STRIKE_TAGS.has(el.tagName)) return true;
  const style = attrCI(el, 'style');
  if (style && LINE_THROUGH_RE.test(style)) return true;
  const cls = attrCI(el, 'class');
  if (cls) for (const c of cls.split(/\s+/)) if (struckClasses.has(c.toLowerCase())) return true;
  return false;
}

/** A literal `]` inside deleted text would close the fence early (and let a downstream reader pair
 * it with the wrong `[deleted:`), so it is swapped for the visually similar U+3015 RIGHT TORTOISE
 * SHELL BRACKET, which cannot be confused with the fence's own delimiter. Mirrors pdfMarkedText.ts's
 * identical guard. */
const fenceSafe = (s: string) => s.replace(/\]/g, '〕');

/** Merge fences left adjacent by nothing but whitespace ("[deleted: one] [deleted: two]" → one
 * fence) — repeated passes so a run of 3+ adjacent fences collapses fully, not just pairwise. */
function mergeAdjacentFences(text: string): string {
  let prev: string;
  let cur = text;
  do {
    prev = cur;
    cur = cur.replace(/\[deleted: ([^\]]*)\]\s*\[deleted: ([^\]]*)\]/g, '[deleted: $1 $2]');
  } while (cur !== prev);
  return cur;
}

/** Full result: the fenced, stripped text, and whether any line-through rule could not be fully
 * resolved (an unresolvable `<style>` selector, or an external/`@import`ed stylesheet this reader
 * never read). `unresolved` is a flag, never embedded in `text` — an excerpt-only snapshot can cut a
 * trailing marker off, so the caller (buildSnapshot's `markupUnresolved`) must see it explicitly. */
export function htmlMarkedTextWithStats(html: string): HtmlMarkedTextResult {
  const { document } = parseHTML(html);
  const { classes: struckClasses, unresolved: unresolvedRule } = struckClassesFrom(document as unknown as Parameters<typeof struckClassesFrom>[0]);
  const externalStylesheet = hasExternalStylesheet(document as unknown as Parameters<typeof hasExternalStylesheet>[0]);
  const all = Array.from(document.querySelectorAll('*')) as unknown as StruckElement[];
  // Document order from querySelectorAll means an ancestor is always visited before its descendants,
  // so checking against roots collected so far correctly skips a nested struck element.
  const roots: StruckElement[] = [];
  for (const el of all) {
    if (roots.some((r) => r.contains(el))) continue;
    if (isStruck(el, struckClasses)) roots.push(el);
  }
  for (const root of roots) {
    const text = fenceSafe((root.textContent ?? '').replace(/\s+/g, ' ').trim());
    root.replaceWith(document.createTextNode(text.length > 0 ? `[deleted: ${text}]` : ''));
  }
  const text = mergeAdjacentFences(htmlToText(document.toString()));
  return { text, unresolved: unresolvedRule || externalStylesheet };
}

/** String-only convenience wrapper over {@link htmlMarkedTextWithStats} for a caller that does not
 * need the `unresolved` flag (tests, mainly) — production callers should use the full result so
 * amendment_markup can fail closed on it. */
export function htmlToMarkedText(html: string): string {
  return htmlMarkedTextWithStats(html).text;
}
