import { describe, it, expect } from 'vitest';
import { STATE_RUN_MAKEVALID } from '../../backend/scripts/load-state-tiger-boundaries.js';

describe('STATE_RUN_MAKEVALID — UT MakeValid coverage (D-07..D-09)', () => {
  const utLayers = ['cd119', 'sldu', 'sldl', 'unsd', 'place', 'county'];

  for (const layer of utLayers) {
    it(`UT ${layer}: runMakeValid resolves to true`, () => {
      const runMakeValid = STATE_RUN_MAKEVALID['UT']?.has(layer) ?? (layer === 'place');
      expect(runMakeValid).toBe(true);
    });
  }

  it('CA non-place layers: runMakeValid resolves to false (byte-equivalence preserved)', () => {
    for (const layer of ['cd', 'sldu', 'sldl', 'unsd']) {
      const runMakeValid = STATE_RUN_MAKEVALID['CA']?.has(layer) ?? (layer === 'place');
      expect(runMakeValid).toBe(false);
    }
  });

  it('CA place layer: runMakeValid resolves to true via fallback', () => {
    const layer = 'place';
    const runMakeValid = STATE_RUN_MAKEVALID['CA']?.has(layer) ?? (layer === 'place');
    expect(runMakeValid).toBe(true);
  });
});
