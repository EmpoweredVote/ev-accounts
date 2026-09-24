// Split a roster display name into the essentials.politicians name columns.
//
// The UT roster loaders used to split at the FIRST space, which put a middle initial into last_name
// ("Jeffrey S. Gray" -> last_name 'S. Gray'). Surname matchers read last_name, so that shape hid
// duplicates (the Jeff Gray pair merged by CA_0261). CA_0267 repaired the 89 rows it left behind;
// this is what keeps a re-run from writing them again.
//
//   "Jeffrey S. Gray"           -> first 'Jeffrey', middle 'S.', last 'Gray'
//   "David S. Kerr, Jr."        -> first 'David',   middle 'S.', last 'Kerr', suffix 'Jr.'
//   'James C. "Jim" McDermott'  -> first 'James',   middle 'C.', last 'McDermott', preferred 'Jim'
//   "J. Lowry Snow"             -> first 'J. Lowry', last 'Snow'   (leading initial: the given name follows it)
//   "Mary Jo Van Pelt"          -> first 'Mary', last 'Jo Van Pelt' (unchanged: a multi-word remainder is kept whole)
//   "Cher"                      -> first 'Cher', last 'Cher'       (unchanged fallback)

export interface SplitName {
  first: string;
  middle_initial: string | null;
  last: string;
  suffix: string | null;
  preferred: string | null;
}

const INITIAL = /^[A-Z]\.?$/;
const SUFFIX = /^(?:jr|sr)\.?$|^(?:ii|iii|iv|v)$/i;
const NICKNAME = /^["“”'](.+)["“”']$/;

export function splitPersonName(fullName: string): SplitName {
  let tokens = fullName.trim().split(/\s+/).filter(Boolean);

  let preferred: string | null = null;
  tokens = tokens.filter((t) => {
    const m = t.match(NICKNAME);
    if (m && preferred === null) { preferred = m[1]; return false; }
    return true;
  });

  let suffix: string | null = null;
  if (tokens.length > 2 && SUFFIX.test(tokens[tokens.length - 1])) {
    suffix = tokens.pop()!;
  }
  if (tokens.length > 0) tokens[tokens.length - 1] = tokens[tokens.length - 1].replace(/,$/, '');

  if (tokens.length === 0) return { first: '', middle_initial: null, last: '', suffix, preferred };
  if (tokens.length === 1) return { first: tokens[0], middle_initial: null, last: tokens[0], suffix, preferred };

  let first = tokens[0];
  let rest = tokens.slice(1);
  if (INITIAL.test(first) && rest.length >= 2) {
    first = `${first} ${rest[0]}`;
    rest = rest.slice(1);
  }

  const initials: string[] = [];
  while (rest.length > 1 && INITIAL.test(rest[0])) initials.push(rest.shift()!);

  return {
    first,
    middle_initial: initials.length ? initials.join(' ') : null,
    last: rest.join(' '),
    suffix,
    preferred,
  };
}
