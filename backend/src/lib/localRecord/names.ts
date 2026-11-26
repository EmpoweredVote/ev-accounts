// Resolve a name as printed in minutes or a feed to a politician, by meeting date.
// Exact match on normalised variants only; never fuzzy.
import type { CityScope } from './types.js';

export interface NameFile {
  city: CityScope;
  members: { politicianId: string; onboardId: string | null; variants: string[] }[];
}

/** A span of office from `office_terms`. Dates are ISO (YYYY-MM-DD); end null = still serving. */
export interface TermSpan {
  politicianId: string;
  start: string;
  end: string | null;
}

const TITLES = /\b(?:councilmember|council member|council president|vice president|president)\b/g;

export function normaliseName(s: string): string {
  return s
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '') // no unaccent on prod: fold in code
    .toLowerCase()
    .replace(TITLES, ' ')
    .replace(/\s*[-\u2010-\u2015]\s*/g, '-') // en/em dash and spaced hyphen -> plain hyphen
    .replace(/[^a-z0-9\s-]/g, '') // drops '*' and other punctuation, keeps hyphen
    .replace(/\s+/g, ' ')
    .trim();
}

export function resolveName(
  printed: string,
  date: string,
  names: NameFile,
  terms: TermSpan[],
): { politicianId: string } | { error: 'unknown_name' | 'not_seated' | 'ambiguous'; detail: string } {
  const key = normaliseName(printed);
  if (key === '') {
    return { error: 'unknown_name', detail: `"${printed}" has no name after normalising` };
  }
  const matched = names.members.filter((m) => m.variants.some((v) => normaliseName(v) === key));
  if (matched.length === 0) {
    return { error: 'unknown_name', detail: `no listed variant matches "${printed}"` };
  }
  const seated = matched.filter((m) =>
    terms.some((t) => t.politicianId === m.politicianId && t.start <= date && (t.end === null || date <= t.end)),
  );
  if (seated.length === 0) {
    return { error: 'not_seated', detail: `"${printed}" matches a member with no term on ${date}` };
  }
  if (seated.length > 1) {
    return {
      error: 'ambiguous',
      detail: `"${printed}" matches ${seated.map((m) => m.politicianId).join(', ')} on ${date}`,
    };
  }
  return { politicianId: seated[0].politicianId };
}
