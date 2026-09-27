import { describe, expect, it } from 'vitest';
import fixture from './__fixtures__/in-hea1296-2022-p16.geometry.json';
import { markedTextFromGeometry, type PageGeometry, type PdfTextItem } from './pdfMarkedText.js';

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

  it('a rect covering under 60 % of a word does not delete it', () => {
    const g: PageGeometry = { items: [item('abcdefghij', 0, 100)], rects: [{ x0: 0, x1: 50, y0: 102.8, y1: 103.2 }] };
    expect(markedTextFromGeometry(g)).toBe('abcdefghij');
  });

  it('a rect 1.5 pt or taller is not a strike', () => {
    const g: PageGeometry = { items: [line], rects: [{ x0: 100, x1: 210, y0: 102, y1: 103.5 }] };
    expect(markedTextFromGeometry(g)).toBe('keep this strike that');
  });

  it('reads lines top to bottom, items left to right', () => {
    const g: PageGeometry = { items: [item('second', 0, 60, 80), item('world', 60, 50, 100), item('hello', 0, 50, 100.5)], rects: [] };
    expect(markedTextFromGeometry(g)).toBe('hello world second');
  });

  it('positive control: items and no rects → no fence', () => {
    const g: PageGeometry = { items: (fixture as PageGeometry).items, rects: [] };
    const out = markedTextFromGeometry(g);
    expect(out).toContain('Except as provided in subsection (c), A person may carry a handgun');
    expect(out).not.toContain('[deleted:');
  });
});
