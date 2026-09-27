/**
 * htmlMarkedText — HTML→text for the snapshot path that keeps deleted words as `[deleted: …]`
 * fences, so an amending bill's struck text is never read as law (spec 2026-09-27-amendment-markup-
 * design.md §2). Used ONLY by the collector's snapshot path (snapshot-sources.ts); the verifier's
 * htmlToText (backend/src/lib/verificationFetch.ts) is unchanged.
 *
 * A struck element is one of:
 *   - a <strike>, <s> or <del> tag,
 *   - an element whose inline `style` attribute sets `text-decoration: ...line-through...`,
 *   - an element whose class is named by a `<style>` rule whose declarations set the same.
 *
 * Every top-level struck element (an element inside another struck element is not fenced again —
 * its text is already carried by the ancestor's own fence) is replaced with the text
 * `[deleted: <its textContent, whitespace collapsed>]` before the document is stripped to plain text
 * with the same legacy tag-stripping/entity-decoding {@link htmlToText} uses, so ordinary text reads
 * exactly as it always has.
 */
import { parseHTML } from 'linkedom';
import { htmlToText } from '../../src/lib/verificationFetch.js';

const STRIKE_TAGS = new Set(['STRIKE', 'S', 'DEL']);
const LINE_THROUGH_RE = /text-decoration\s*:[^;]*line-through/i;

/** Class names declared struck by any `<style>` block's rules (a simple, non-nested CSS reader). */
function struckClassesFrom(document: { querySelectorAll(sel: string): ArrayLike<{ textContent: string | null }> }): Set<string> {
  const classes = new Set<string>();
  for (const style of Array.from(document.querySelectorAll('style'))) {
    const css = style.textContent ?? '';
    for (const m of css.matchAll(/([^{}]+)\{([^{}]*)\}/g)) {
      const [, selectorList, decls] = m;
      if (!LINE_THROUGH_RE.test(decls)) continue;
      for (const sel of selectorList.split(',')) {
        const cm = /\.([a-zA-Z0-9_-]+)\s*$/.exec(sel.trim());
        if (cm) classes.add(cm[1]);
      }
    }
  }
  return classes;
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
  if (cls) for (const c of cls.split(/\s+/)) if (struckClasses.has(c)) return true;
  return false;
}

export function htmlToMarkedText(html: string): string {
  const { document } = parseHTML(html);
  const struckClasses = struckClassesFrom(document as unknown as Parameters<typeof struckClassesFrom>[0]);
  const all = Array.from(document.querySelectorAll('*')) as unknown as StruckElement[];
  // Document order from querySelectorAll means an ancestor is always visited before its descendants,
  // so checking against roots collected so far correctly skips a nested struck element.
  const roots: StruckElement[] = [];
  for (const el of all) {
    if (roots.some((r) => r.contains(el))) continue;
    if (isStruck(el, struckClasses)) roots.push(el);
  }
  for (const root of roots) {
    const text = (root.textContent ?? '').replace(/\s+/g, ' ').trim();
    root.replaceWith(document.createTextNode(text.length > 0 ? `[deleted: ${text}]` : ''));
  }
  return htmlToText(document.toString());
}
