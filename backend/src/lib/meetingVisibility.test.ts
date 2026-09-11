import { describe, it, expect } from 'vitest';
import {
  PUBLIC_MEETING_STATUSES,
  publicMeetingStatusClause,
  publicMeetingExistsClause,
} from './meetingVisibility.js';

describe('PUBLIC_MEETING_STATUSES', () => {
  it('excludes draft — the go-live safety gate', () => {
    expect(PUBLIC_MEETING_STATUSES).not.toContain('draft');
  });

  it('excludes processing and any other internal status', () => {
    expect(PUBLIC_MEETING_STATUSES).not.toContain('processing');
  });

  it('allows published and scheduled (the two publicly-visible statuses)', () => {
    expect(PUBLIC_MEETING_STATUSES).toContain('published');
    expect(PUBLIC_MEETING_STATUSES).toContain('scheduled');
  });
});

describe('publicMeetingStatusClause', () => {
  it('defaults to the bare status column', () => {
    expect(publicMeetingStatusClause()).toBe(
      `status IN ('published', 'scheduled')`,
    );
  });

  it('qualifies with a table alias when given', () => {
    expect(publicMeetingStatusClause('m.status')).toBe(
      `m.status IN ('published', 'scheduled')`,
    );
  });

  it('never emits draft', () => {
    expect(publicMeetingStatusClause('m.status')).not.toContain('draft');
  });
});

describe('publicMeetingExistsClause', () => {
  it('gates a derived row on its meeting being publicly visible', () => {
    const clause = publicMeetingExistsClause('s.meeting_id');
    expect(clause).toContain('EXISTS');
    expect(clause).toContain('meetings.meetings');
    expect(clause).toContain('s.meeting_id');
    expect(clause).toContain(`IN ('published', 'scheduled')`);
  });

  it('gates on a bind-parameter id expression', () => {
    expect(publicMeetingExistsClause('$1')).toContain('= $1');
  });
});
