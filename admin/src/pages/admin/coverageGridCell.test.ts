import { describe, it, expect } from 'vitest';
import { cellClass, rowStatus, type CellState } from './coverageGridCell';

describe('rowStatus', () => {
  it('rankable with >= 2 live', () => expect(rowStatus(['live', 'live', 'none'])).toBe('rankable'));
  it('near-rankable with 1 live + a draft', () => expect(rowStatus(['live', 'draft'])).toBe('near-rankable'));
  it('solo with a single live and no drafts', () => expect(rowStatus(['live', 'none'])).toBe('solo'));
  it('solo with only drafts', () => expect(rowStatus(['draft', 'none'])).toBe('solo'));
  it('none when nothing present', () => expect(rowStatus(['none', 'none'])).toBe('none'));
});

describe('cellClass', () => {
  it('distinct class per state', () => {
    const states: CellState[] = ['live', 'draft', 'none'];
    const classes = states.map(cellClass);
    expect(new Set(classes).size).toBe(3);
    expect(cellClass('live')).toContain('green');
    expect(cellClass('draft')).toContain('amber');
  });
});
