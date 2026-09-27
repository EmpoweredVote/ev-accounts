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
 * FAIL CLOSED on an unresolvable `<style>` rule: if a rule sets line-through on a selector this
 * reader cannot reduce to a bare class name (a combinator, a pseudo-class, an attribute or id
 * selector, or a bare-tag/universal selector with no class at all), it may be marking elements this
 * reader cannot find — so the whole page cannot be trusted to have kept every deletion, and the
 * output carries the literal marker {@link MARKUP_UNRESOLVED_MARKER}. amendmentMarkup
 * (snapshotSources.ts) treats its presence as 'unknown' even when `[deleted: …]` fences are also
 * present elsewhere on the page — some deletions being visibly caught is not evidence that all of
 * them were.
 */
import { parseHTML } from 'linkedom';
import { htmlToText } from '../../src/lib/verificationFetch.js';

const STRIKE_TAGS = new Set(['STRIKE', 'S', 'DEL']);
const LINE_THROUGH_RE = /text-decoration(?:-line)?\s*:[^;]*line-through/i;

/** The literal marker appended when a `<style>` rule set line-through on a selector this reader
 * could not resolve to a bare class (see the module doc's FAIL CLOSED note). */
export const MARKUP_UNRESOLVED_MARKER = '[markup-unresolved]';

// A selector this reader trusts itself to test via an element's classList: one or more class tokens
// (each ".name"), with an optional leading tag name and no combinator, pseudo-class, attribute or id
// selector anywhere in it. "div.struck", ".struck", ".a.b" all qualify; "p .struck" (descendant),
// ".struck:hover", "[data-x]", "#id", or a bare "p" (no class at all) do not.
const RESOLVABLE_SELECTOR_RE = /^[a-zA-Z][a-zA-Z0-9_-]*(?:\.[a-zA-Z0-9_-]+)+$|^(?:\.[a-zA-Z0-9_-]+)+$/;
const CLASS_TOKEN_RE = /\.([a-zA-Z0-9_-]+)/g;

interface StruckClasses { classes: Set<string>; unresolved: boolean }

/** Class names (lower-cased) declared struck by any `<style>` block's rules (a simple, non-nested
 * CSS reader), plus whether any line-through rule used a selector it could not resolve to a class. */
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
        } else {
          unresolved = true;
        }
      }
    }
  }
  return { classes, unresolved };
}

interface StruckElement {
  tagName: string;
  getAttribute(name: string): string | null;
  contains(other: unknown): boolean;
  textContent: string | null;
  replaceWith(node: unknown): void;
}

function isStruck(el: StruckElement, struckClasses: Set<string>): boolean {
  if (STRIKE_TAGS.has(el.tagName)) return true;
  const style = el.getAttribute('style');
  if (style && LINE_THROUGH_RE.test(style)) return true;
  const cls = el.getAttribute('class');
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

export function htmlToMarkedText(html: string): string {
  const { document } = parseHTML(html);
  const { classes: struckClasses, unresolved } = struckClassesFrom(document as unknown as Parameters<typeof struckClassesFrom>[0]);
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
  const stripped = mergeAdjacentFences(htmlToText(document.toString()));
  return unresolved ? `${stripped} ${MARKUP_UNRESOLVED_MARKER}` : stripped;
}
