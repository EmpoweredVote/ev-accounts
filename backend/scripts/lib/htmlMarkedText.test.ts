// backend/scripts/lib/htmlMarkedText.test.ts
import { describe, it, expect } from 'vitest';
import { htmlToMarkedText } from './htmlMarkedText.js';

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
});
