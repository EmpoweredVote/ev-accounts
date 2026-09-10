import { describe, it, expect } from 'vitest';
import { resolveLane, LANE_PRECEDENCE } from './lanes.js';

describe('resolveLane', () => {
  it('prefers iran over us for a US strike on Iran', () => {
    expect(resolveLane(['us', 'iran'])).toBe('iran');
  });

  it('prefers climate over us for a US emissions ruling', () => {
    expect(resolveLane(['us', 'climate'])).toBe('climate');
  });

  it('prefers iran over climate', () => {
    expect(resolveLane(['climate', 'iran'])).toBe('iran');
  });

  it('returns us for a US-domestic story', () => {
    expect(resolveLane(['us'])).toBe('us');
  });

  it('falls back to world when no topic matches', () => {
    expect(resolveLane([])).toBe('world');
  });

  it('ignores unrecognised topics', () => {
    expect(resolveLane(['sport', 'celebrity'])).toBe('world');
  });

  it('ignores unrecognised topics alongside a real one', () => {
    expect(resolveLane(['sport', 'iran'])).toBe('iran');
  });

  it('is order-independent', () => {
    expect(resolveLane(['world', 'us', 'iran'])).toBe(
      resolveLane(['iran', 'us', 'world']),
    );
  });

  it('declares precedence most-specific-first with world last', () => {
    expect(LANE_PRECEDENCE).toEqual(['iran', 'climate', 'us', 'world']);
  });
});
