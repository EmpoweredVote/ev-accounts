// backend/scripts/lib/htmlMarkedText.test.ts
import { describe, it, expect } from 'vitest';
import { htmlToMarkedText, htmlMarkedTextWithStats } from './htmlMarkedText.js';

describe('htmlToMarkedText', () => {
  it('fences a <strike> element', () => {
    expect(htmlToMarkedText('<p>A person <strike>shall not</strike> may carry a handgun.</p>'))
      .toBe('A person [deleted: shall not] may carry a handgun.');
  });
  it('fences an <s> element', () => {
    expect(htmlToMarkedText('<p>Before <s>deleted words</s> after.</p>'))
      .toBe('Before [deleted: deleted words] after.');
  });
  it('fences a <del> element', () => {
    expect(htmlToMarkedText('<p>Before <del>deleted words</del> after.</p>'))
      .toBe('Before [deleted: deleted words] after.');
  });
  it('fences an element with an inline style setting line-through', () => {
    expect(htmlToMarkedText('<p>Before <span style="text-decoration: line-through">deleted words</span> after.</p>'))
      .toBe('Before [deleted: deleted words] after.');
  });
  it('fences an element whose class is named in a <style> rule with line-through', () => {
    const html = '<html><head><style>.struck { text-decoration: line-through; color: red; }</style></head>' +
      '<body><p>Before <span class="struck">deleted words</span> after.</p></body></html>';
    expect(htmlToMarkedText(html)).toBe('Before [deleted: deleted words] after.');
  });
  it('leaves plain text unchanged', () => {
    expect(htmlToMarkedText('<p>A person may carry a handgun.</p>')).toBe('A person may carry a handgun.');
  });
  it('keeps the surrounding words when a struck element is nested inside a paragraph', () => {
    expect(htmlToMarkedText('<p>The law reads: <strike>except as provided,</strike> a person may carry.</p>'))
      .toBe('The law reads: [deleted: except as provided,] a person may carry.');
  });
  it('merges adjacent deleted words from nested markup into one fence', () => {
    expect(htmlToMarkedText('<p>Keep <strike>one <b>two</b> three</strike> end.</p>'))
      .toBe('Keep [deleted: one two three] end.');
  });
  it('fences an element whose inline style sets the longhand text-decoration-line', () => {
    expect(htmlToMarkedText('<p>Before <span style="text-decoration-line: line-through">deleted words</span> after.</p>'))
      .toBe('Before [deleted: deleted words] after.');
  });
  it('matches a <style> class rule case-insensitively', () => {
    const html = '<html><head><style>.STRUCK { text-decoration: line-through; }</style></head>' +
      '<body><p>Before <span class="struck">deleted words</span> after.</p></body></html>';
    expect(htmlToMarkedText(html)).toBe('Before [deleted: deleted words] after.');
    const html2 = '<html><head><style>.struck { text-decoration: line-through; }</style></head>' +
      '<body><p>Before <span class="STRUCK">deleted words</span> after.</p></body></html>';
    expect(htmlToMarkedText(html2)).toBe('Before [deleted: deleted words] after.');
  });
  it('merges two separate adjacent <strike> elements (whitespace-only gap) into one fence', () => {
    expect(htmlToMarkedText('<p>A <strike>one</strike> <strike>two</strike> b</p>')).toBe('A [deleted: one two] b');
  });
  it('merges a run of three adjacent struck elements into one fence', () => {
    expect(htmlToMarkedText('<p>A <strike>one</strike> <strike>two</strike> <strike>three</strike> b</p>'))
      .toBe('A [deleted: one two three] b');
  });
  it('swaps a `]` inside deleted text for U+3015 so it cannot close the fence early', () => {
    const text = htmlToMarkedText('<p>Keep <strike>a [b] c</strike> end.</p>');
    expect(text).toBe('Keep [deleted: a [b〕 c] end.');
    expect(text.indexOf(']')).toBe(text.length - 1 - ' end.'.length);
  });
  describe('an unresolvable <style> selector fails closed — via the `unresolved` flag, never embedded in text', () => {
    it('sets unresolved when a rule uses a descendant-combinator selector, and the text carries no marker', () => {
      const html = '<html><head><style>p .struck { text-decoration: line-through; }</style></head>' +
        '<body><p>Before <span class="struck">deleted words</span> after.</p></body></html>';
      const r = htmlMarkedTextWithStats(html);
      expect(r.unresolved).toBe(true);
      expect(r.text).toBe('Before deleted words after.');
      expect(r.text).not.toContain('[markup-unresolved]');
    });
    it('sets unresolved when a rule sets line-through on a bare tag selector this reader does not already treat as struck', () => {
      const html = '<html><head><style>span { text-decoration: line-through; }</style></head>' +
        '<body><p>Before <span>maybe deleted</span> after.</p></body></html>';
      expect(htmlMarkedTextWithStats(html).unresolved).toBe(true);
    });
    it('does NOT set unresolved when every line-through rule resolves to a class', () => {
      const html = '<html><head><style>span.struck { text-decoration: line-through; }</style></head>' +
        '<body><p>Before <span class="struck">deleted words</span> after.</p></body></html>';
      expect(htmlMarkedTextWithStats(html).unresolved).toBe(false);
    });
    it('does NOT set unresolved for a bare tag selector already in STRIKE_TAGS (s/del/strike)', () => {
      const html = '<html><head><style>s { text-decoration: line-through; }</style></head>' +
        '<body><p>Before <s>deleted words</s> after.</p></body></html>';
      const r = htmlMarkedTextWithStats(html);
      expect(r.unresolved).toBe(false);
      expect(r.text).toBe('Before [deleted: deleted words] after.');
    });
    it('does NOT set unresolved for a selector list of only STRIKE_TAGS tags', () => {
      const html = '<html><head><style>s, del, strike { text-decoration: line-through; }</style></head>' +
        '<body><p>Before <del>deleted words</del> after.</p></body></html>';
      expect(htmlMarkedTextWithStats(html).unresolved).toBe(false);
    });
    it('sets unresolved for a mixed selector list where one selector is not resolvable', () => {
      const html = '<html><head><style>span, s { text-decoration: line-through; }</style></head>' +
        '<body><p>Before <s>deleted words</s> after.</p></body></html>';
      expect(htmlMarkedTextWithStats(html).unresolved).toBe(true);
    });
  });
  describe('an external stylesheet fails closed (it may strike text this reader never sees)', () => {
    it('sets unresolved when the page links an external stylesheet', () => {
      const html = '<html><head><link rel="stylesheet" href="/styles.css"></head>' +
        '<body><p>Plain text, no local markup at all.</p></body></html>';
      expect(htmlMarkedTextWithStats(html).unresolved).toBe(true);
    });
    it('sets unresolved when a <style> block `@import`s another stylesheet', () => {
      const html = '<html><head><style>@import url("/other.css");</style></head>' +
        '<body><p>Plain text, no local markup at all.</p></body></html>';
      expect(htmlMarkedTextWithStats(html).unresolved).toBe(true);
    });
    it('does NOT set unresolved for a page with no <link rel="stylesheet"> and no @import', () => {
      const html = '<html><head><link rel="icon" href="/favicon.ico"></head>' +
        '<body><p>Plain text.</p></body></html>';
      expect(htmlMarkedTextWithStats(html).unresolved).toBe(false);
    });
  });
});
