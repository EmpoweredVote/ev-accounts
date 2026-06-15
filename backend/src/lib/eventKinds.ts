export const EVENT_KINDS = [
  'council',
  'school_board',
  'debate',
  'forum',
  'community_meeting',
  'news_clip',
  'other',
] as const;

export type EventKind = (typeof EVENT_KINDS)[number];
