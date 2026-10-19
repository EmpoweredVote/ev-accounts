/**
 * Who a journal entry is signed by.
 *
 * 🔴 THE AUTHOR'S TIER SETS THE CEILING; THE ROW ONLY EXPRESSES A PREFERENCE.
 * A Connected account's default is privacy to the world, so its `real`
 * preference is clamped to the handle — always, everywhere, not pending any
 * decision. An Empowered account has traded privacy for transparency and has
 * already published the link between its name and its activity, so there is
 * nothing left to leak and the preference is honoured.
 *
 * ⚠ PURE ON PURPOSE. No database, no imports. The service supplies the facts so
 * the RULE can be tested exhaustively without fixtures — and so a future reader
 * can see the whole policy in twenty lines.
 *
 * ⚠ Zero accounts are Empowered in production today. The Empowered branches
 * here are specified by their tests and by nothing else.
 */

export type JournalAttribution = 'none' | 'handle' | 'real';

export interface JournalAuthor {
  /** public.users.display_name — universal coverage, 27/27 populated. */
  displayName: string | null;
  /** connect.connected_profiles.legal_name — 9 of 12 populated, so often absent. */
  legalName: string | null;
  /** empower.empowered_profiles row exists AND is_active. Never a column. */
  isEmpowered: boolean;
}

export const TEAM_BYLINE = 'The EmpoweredVote team';

/** Trimmed, or null — an empty string is not a name. */
const name = (v: string | null): string | null => {
  const t = typeof v === 'string' ? v.trim() : '';
  return t.length > 0 ? t : null;
};

export function resolveByline(
  attribution: JournalAttribution,
  author: JournalAuthor,
): string {
  const handle = name(author.displayName);

  if (attribution === 'none') return TEAM_BYLINE;
  if (attribution === 'handle') return handle ?? TEAM_BYLINE;

  // 'real' — honoured only for an Empowered author.
  if (!author.isEmpowered) return handle ?? TEAM_BYLINE;
  return name(author.legalName) ?? handle ?? TEAM_BYLINE;
}
