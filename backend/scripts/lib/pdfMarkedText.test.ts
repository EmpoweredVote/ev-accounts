import { describe, expect, it } from 'vitest';
import fixture from './__fixtures__/in-hea1296-2022-p16.geometry.json';
import p29Line from './__fixtures__/in-hea1296-2022-p29-struck-line.geometry.json';
import p17Line from './__fixtures__/in-hea1296-2022-p17-struck-line.geometry.json';
import {
  markedTextFromGeometry, markedTextFromGeometryWithStats, type PageGeometry, type PdfTextItem,
} from './pdfMarkedText.js';

const item = (str: string, x: number, width: number, y = 100, height = 10): PdfTextItem =>
  ({ str, x, y, width, height, fontName: 'f1' });

describe('markedTextFromGeometry — Indiana HEA 1296 (2022) page 16', () => {
  const text = markedTextFromGeometry(fixture as PageGeometry);

  it('fences the struck words', () => {
    expect(text).toContain('[deleted: Except as provided in subsection (c),]');
  });

  it('keeps the unstruck words that follow as law', () => {
    expect(text).toContain('A person may carry a handgun');
    expect(text).not.toContain('[deleted: A person');
  });
});

describe('markedTextFromGeometry — fully struck lines (regression: short words leaked as law)', () => {
  // Real geometry: one rect per word. Character-count placement left "of" / "a" unfenced between fences.
  it.each([
    ['p29', p29Line, 'enforcement of any provision of this chapter, it is not necessary to'],
    ['p17', p17Line, 'battery under IC 35-42-2-1.3 may not possess or carry a handgun.'],
  ])('%s: every word is inside ONE fence', (_p, geo, line) => {
    const g = geo as PageGeometry;
    expect(g.rects.length).toBe(line.split(' ').length);
    const r = markedTextFromGeometryWithStats(g);
    expect(r.text).toBe(`[deleted: ${line}]`);
    expect(r.text).not.toMatch(/\] (a|of) \[deleted:/);
    expect(r.fences).toBe(1);
    expect(r.widthFallbacks).toBe(0);
  });
});

describe('markedTextFromGeometry — synthetic geometry', () => {
  // "keep this strike that": 21 chars over 210 pt → 10 pt per char; "strike that" = chars 10..21 → x 100..210.
  const line = item('keep this strike that', 0, 210);

  it('a thin rect above the baseline strikes the words it covers', () => {
    const g: PageGeometry = { items: [line], rects: [{ x0: 100, x1: 210, y0: 102.8, y1: 103.2 }] };
    expect(markedTextFromGeometry(g)).toBe('keep this [deleted: strike that]');
  });

  it('the same rect below the baseline is an underline — no fence', () => {
    const g: PageGeometry = { items: [line], rects: [{ x0: 100, x1: 210, y0: 98.8, y1: 99.2 }] };
    expect(markedTextFromGeometry(g)).toBe('keep this strike that');
  });

  it('adjacent struck words in two items on one line make ONE fence', () => {
    const g: PageGeometry = {
      items: [item('keep one', 0, 80), item('two end', 90, 70)],
      // "one" = x 50..80 in item 1; "two" = x 90..120 in item 2.
      rects: [{ x0: 50, x1: 80, y0: 102.8, y1: 103.2 }, { x0: 90, x1: 120, y0: 102.8, y1: 103.2 }],
    };
    expect(markedTextFromGeometry(g)).toBe('keep [deleted: one two] end');
  });

  it('a run that continues across a line end is ONE fence', () => {
    const g: PageGeometry = {
      items: [item('keep one', 0, 80, 100), item('two end', 0, 70, 88)],
      rects: [{ x0: 50, x1: 80, y0: 102.8, y1: 103.2 }, { x0: 0, x1: 30, y0: 90.8, y1: 91.2 }],
    };
    expect(markedTextFromGeometry(g)).toBe('keep [deleted: one two] end');
  });

  it('a word that receives a rect is struck even when coverage is under 60 %', () => {
    const g: PageGeometry = { items: [item('abcdefghij', 0, 100)], rects: [{ x0: 0, x1: 20, y0: 102.8, y1: 103.2 }] };
    expect(markedTextFromGeometry(g)).toBe('[deleted: abcdefghij]');
  });

  it('each rect goes to the word it overlaps most — a neighbour it grazes stays law', () => {
    // "aaaa bbbb": aaaa = x 0..40, bbbb = x 50..90. The rect covers aaaa and grazes bbbb by 2 pt.
    const g: PageGeometry = { items: [item('aaaa bbbb', 0, 90)], rects: [{ x0: 0, x1: 52, y0: 102.8, y1: 103.2 }] };
    expect(markedTextFromGeometry(g)).toBe('[deleted: aaaa] bbbb');
  });

  it('fail closed: a word 30–60 % covered with no rect of its own is fenced and counted ambiguous', () => {
    // bbbb = x 50..90; the rect is assigned to aaaa (overlap 40) but covers 16 of bbbb's 40 pt (40 %).
    const g: PageGeometry = { items: [item('aaaa bbbb', 0, 90)], rects: [{ x0: 0, x1: 66, y0: 102.8, y1: 103.2 }] };
    const r = markedTextFromGeometryWithStats(g);
    expect(r.text).toBe('[deleted: aaaa bbbb]');
    expect(r.ambiguous).toBe(1);
  });

  it('places words by glyph width when the font gives it, else counts a fallback', () => {
    // "WWW i": glyph widths W=1000, space=250, i=250 → WWW = x 0..3000/3500 × 70 = 0..60, i = 65..70.
    // By character count WWW would be x 0..42 and "i" 56..70, and the rect over x 58..70 would miss WWW.
    const it0 = item('WWW i', 0, 70);
    const rects = [{ x0: 58, x1: 70, y0: 102.8, y1: 103.2 }];
    const glyph = markedTextFromGeometryWithStats({ items: [it0], rects, fontWidths: { f1: { W: 1000, ' ': 250, i: 250 } } });
    expect(glyph.text).toBe('WWW [deleted: i]');
    expect(glyph.widthFallbacks).toBe(0);
    const noWidths = markedTextFromGeometryWithStats({ items: [it0], rects });
    expect(noWidths.widthFallbacks).toBe(1);
    const partial = markedTextFromGeometryWithStats({ items: [it0], rects, fontWidths: { f1: { W: 1000 } } });
    expect(partial.widthFallbacks).toBe(1);
  });

  it('a rect 1.5 pt or taller is not a strike', () => {
    const g: PageGeometry = { items: [line], rects: [{ x0: 100, x1: 210, y0: 102, y1: 103.5 }] };
    expect(markedTextFromGeometry(g)).toBe('keep this strike that');
  });

  it('reads lines top to bottom, items left to right', () => {
    const g: PageGeometry = { items: [item('second', 0, 60, 80), item('world', 60, 50, 100), item('hello', 0, 50, 100.5)], rects: [] };
    expect(markedTextFromGeometry(g)).toBe('hello world second');
  });

  it('a weakly-assigned rect (below both MIN_ASSIGN_* thresholds) does not by itself force a delete, but the fail-closed coverage rule still fences genuine partial coverage', () => {
    // One word, two rects, each a weak "best" (it's the only word on the line): rect1 overlaps 15/100 of
    // the word (15 %, rectShare 15/35 ≈ 43 %) and rect2 overlaps 20/100 (20 %, rectShare 20/90 ≈ 22 %) —
    // both under MIN_ASSIGN_WORD_COVERAGE (30 %) and MIN_ASSIGN_RECT_COVERAGE (50 %), so NEITHER assignment
    // forces a strike. Their UNION coverage of the word is (15+20)/100 = 35 %, which is squarely in the
    // ordinary ambiguous band (30–60 %) — so the word is still fenced, but via that rule, not the rect
    // assignment.
    const g: PageGeometry = {
      items: [item('aaaaaaaaaa', 0, 100)],
      rects: [{ x0: -20, x1: 15, y0: 102.8, y1: 103.2 }, { x0: 80, x1: 170, y0: 102.8, y1: 103.2 }],
    };
    const r = markedTextFromGeometryWithStats(g);
    expect(r.text).toBe('[deleted: aaaaaaaaaa]');
    expect(r.ambiguous).toBe(1);
  });

  it('a rect that only grazes its sole candidate word (well under both thresholds, and under the coverage floor too) does not fence it at all', () => {
    // rect overlaps only 5/100 of the word (5 %) and 5/55 of itself (9 %) — the word is the only
    // candidate so it is still "best", but neither MIN_ASSIGN_* threshold nor AMBIGUOUS_COVERAGE is met.
    const g: PageGeometry = { items: [item('aaaaaaaaaa', 0, 100)], rects: [{ x0: -50, x1: 5, y0: 102.8, y1: 103.2 }] };
    const r = markedTextFromGeometryWithStats(g);
    expect(r.text).toBe('aaaaaaaaaa');
    expect(r.fences).toBe(0);
    expect(r.ambiguous).toBe(0);
  });

  it('a `]` inside deleted text is swapped for U+3015 so it cannot close the fence early', () => {
    const g: PageGeometry = { items: [item('a [b] c', 0, 70)], rects: [{ x0: 0, x1: 70, y0: 102.8, y1: 103.2 }] };
    const text = markedTextFromGeometry(g);
    expect(text).toBe('[deleted: a [b〕 c]');
    expect(text.indexOf(']')).toBe(text.length - 1); // the only real `]` is the fence's own close
  });

  it('positive control: items and no rects → no fence', () => {
    const g: PageGeometry = { items: (fixture as PageGeometry).items, rects: [] };
    const out = markedTextFromGeometry(g);
    expect(out).toContain('Except as provided in subsection (c), A person may carry a handgun');
    expect(out).not.toContain('[deleted:');
    const r = markedTextFromGeometryWithStats(g);
    expect([r.fences, r.ambiguous]).toEqual([0, 0]);
  });
});
