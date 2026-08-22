import { describe, it, expect } from 'vitest';
import { pickSittingMember, parseNcgaDate } from './build-nc-legislature-roster.mjs';

describe('parseNcgaDate', () => {
  it('converts NCGA M/D/YY to ISO', () => {
    expect(parseNcgaDate('1/29/25')).toBe('2025-01-29');
    expect(parseNcgaDate('11/18/25')).toBe('2025-11-18');
    expect(parseNcgaDate('6/23/26')).toBe('2026-06-23');
  });
});

describe('pickSittingMember', () => {
  it('returns the only row when a district is uncontested', () => {
    const rows = [{ name: 'Jay Adams', appointedOn: null, resignedOn: null }];
    expect(pickSittingMember('96', rows).name).toBe('Jay Adams');
  });

  // HD-47: BOTH rows annotated — the easy shape.
  it('prefers the appointed successor over an annotated resignation', () => {
    const rows = [
      { name: 'Jarrod Lowery', appointedOn: null, resignedOn: '2025-10-07' },
      { name: 'John L. Lowery', appointedOn: '2025-10-13', resignedOn: null },
    ];
    expect(pickSittingMember('47', rows).name).toBe('John L. Lowery');
  });

  // HD-40: the DEPARTED member carries NO annotation. Filtering on "Resigned"
  // alone keeps both rows and seats two people in one seat.
  it('prefers the appointed successor when the predecessor is UNANNOTATED', () => {
    const rows = [
      { name: 'Joe John', appointedOn: null, resignedOn: null },
      { name: 'Phil Rubin', appointedOn: '2025-01-29', resignedOn: null },
    ];
    expect(pickSittingMember('40', rows).name).toBe('Phil Rubin');
  });

  // HD-119: same unannotated shape, different district.
  it('handles the second unannotated-predecessor district', () => {
    const rows = [
      { name: 'Mike Clampitt', appointedOn: null, resignedOn: null },
      { name: 'Anna Ferguson', appointedOn: '2026-04-16', resignedOn: null },
    ];
    expect(pickSittingMember('119', rows).name).toBe('Anna Ferguson');
  });

  // HD-90: the appointee is listed FIRST, so source order proves nothing.
  it('ignores source ordering', () => {
    const rows = [
      { name: 'Dan Kiger', appointedOn: '2026-06-23', resignedOn: null },
      { name: 'Sarah Stevens', appointedOn: null, resignedOn: '2026-06-16' },
    ];
    expect(pickSittingMember('90', rows).name).toBe('Dan Kiger');
  });

  it('takes the LATEST appointment when a seat turned over twice', () => {
    const rows = [
      { name: 'First Appointee', appointedOn: '2025-03-01', resignedOn: '2025-09-01' },
      { name: 'Second Appointee', appointedOn: '2025-09-15', resignedOn: null },
    ];
    expect(pickSittingMember('99', rows).name).toBe('Second Appointee');
  });

  // Failing loudly is the point: a shape we have not seen must not be guessed.
  it('throws when a contested district has no appointment date to arbitrate on', () => {
    const rows = [
      { name: 'Person A', appointedOn: null, resignedOn: null },
      { name: 'Person B', appointedOn: null, resignedOn: null },
    ];
    expect(() => pickSittingMember('7', rows)).toThrow(/district 7/i);
  });

  // essentials.office_terms.how_started has a CHECK constraint; a contested
  // district's survivor reached the seat by appointment, not election, and the
  // later migration must not silently assert 'elected' for these 8 people.
  it('marks the appointed successor of a contested district with howStarted appointed', () => {
    const rows = [
      { name: 'Jarrod Lowery', appointedOn: null, resignedOn: '2025-10-07' },
      { name: 'John L. Lowery', appointedOn: '2025-10-13', resignedOn: null },
    ];
    expect(pickSittingMember('47', rows).howStarted).toBe('appointed');
  });

  it('marks an uncontested member with howStarted elected', () => {
    const rows = [{ name: 'Jay Adams', appointedOn: null, resignedOn: null }];
    expect(pickSittingMember('96', rows).howStarted).toBe('elected');
  });
});
