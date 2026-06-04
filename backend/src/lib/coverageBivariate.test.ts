import { describe, it, expect } from 'vitest';
import { aggregateUnits, type Unit } from './coverageBivariate.js';

const u = (started: boolean, depth: number): Unit => ({ started, depth });

describe('aggregateUnits', () => {
  it('breadth = started ÷ total; depth = mean over started only', () => {
    const r = aggregateUnits([u(true, 80), u(true, 60), u(false, 0), u(false, 0)]);
    expect(r.started).toBe(2);
    expect(r.total).toBe(4);
    expect(r.breadth).toBeCloseTo(0.5, 5);
    expect(r.depth).toBe(70); // (80+60)/2 — the two empties do NOT drag it down
  });

  it('all empty → breadth 0, depth 0', () => {
    expect(aggregateUnits([u(false, 0), u(false, 0)])).toEqual({ breadth: 0, depth: 0, started: 0, total: 2 });
  });

  it('all started → breadth 1', () => {
    const r = aggregateUnits([u(true, 50), u(true, 100)]);
    expect(r.breadth).toBe(1);
    expect(r.depth).toBe(75);
  });

  it('empty input → all zeros', () => {
    expect(aggregateUnits([])).toEqual({ breadth: 0, depth: 0, started: 0, total: 0 });
  });

  it('rounds depth to one decimal', () => {
    expect(aggregateUnits([u(true, 10), u(true, 10), u(true, 11)]).depth).toBe(10.3);
  });
});
