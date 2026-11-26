import { describe, expect, it } from 'vitest';
import { formatReport } from './report.js';

describe('formatReport', () => {
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
