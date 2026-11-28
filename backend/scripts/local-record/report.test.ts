import { describe, expect, it } from 'vitest';
import { formatReport, WEEKS_SQL } from './report.js';

describe('WEEKS_SQL', () => {
  it('dates exceptions by opened_at, not created_at', () => {
    expect(WEEKS_SQL).toMatch(/opened_at/);
    expect(WEEKS_SQL).not.toMatch(/created_at/);
  });
});

describe('formatReport', () => {
  it('prints every one of the last 8 ISO weeks, zero weeks included', () => {
    const out = formatReport(
      [{ city_scope: 'place:1', cause: 'unknown_name', week: '2026-W47', n: 2 }],
      [],
      new Date('2026-11-26T12:00:00Z'),
    );
    for (const w of ['2026-W41', '2026-W42', '2026-W43', '2026-W44', '2026-W45', '2026-W46', '2026-W48']) {
      expect(out).toMatch(new RegExp(`${w}\\s+none`));
    }
    expect(out).toContain('2026-W47  unknown_name 2');
    expect(out).not.toContain('2026-W40');
  });

  it('says so when nothing is open', () => {
    expect(formatReport([], [])).toBe('No open exceptions.\n');
  });
  it('lists causes per week and the open rows, per city', () => {
    const out = formatReport(
      [
        { city_scope: 'place:1', cause: 'unknown_name', week: '2026-W47', n: 2 },
        { city_scope: 'place:1', cause: 'file_changed', week: '2026-W47', n: 1 },
        { city_scope: 'place:1', cause: 'unknown_name', week: '2026-W48', n: 1 },
      ],
      [{ city_scope: 'place:1', cause: 'file_changed', subject: 's1', run_id: 'r', detail: { a: 1 } }],
    );
    expect(out).toContain('place:1');
    expect(out).toContain('2026-W47  file_changed 1, unknown_name 2');
    expect(out).toContain('2026-W48  unknown_name 1');
    expect(out).toContain('file_changed         s1  {"a":1}');
  });
});
