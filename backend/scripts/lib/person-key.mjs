/**
 * Name keys for spotting one person split across two essentials.politicians rows.
 *
 * A key is "<canonical first name> <surname>", lower case, accents stripped. It is deliberately loose:
 * it exists to PROPOSE pairs for a human to rule on, never to merge anything. A false pair costs one
 * line in the reviewed baseline; a missed pair costs a person whose seat and compass answers sit on
 * different rows, which is invisible (see check-duplicate-people.mjs).
 *
 * What it undoes, each one measured on a real pair:
 *   - a leading middle initial inside last_name ("J. Pearson", CA_0267)
 *   - an initial or nickname inside first_name ("Justin J.", 'Wendell "Wells"')
 *   - a nickname on one row and the formal name on the other ("Matt" / "Matthew", CA_0270)
 *   - a suffix ("Eloy Morales Jr." / "Eloy Morales", CA_0182)
 *   - accents and apostrophes ("Barragán" / "Baragán" is NOT undone — that is a spelling, not a form)
 */

// Each group is one formal name and its common short forms. A short form that belongs to two formal
// names (e.g. "chris" -> Christopher / Christine) maps to its OWN group, so both formal names meet it.
const NICKNAME_GROUPS = [
  ['alexander', 'alex', 'al'], ['alexandra', 'alex', 'sandra'], ['andrew', 'andy', 'drew'],
  ['anthony', 'tony'], ['barbara', 'barb'], ['benjamin', 'ben'], ['catherine', 'cathy', 'kate', 'katie'],
  ['charles', 'charlie', 'chuck'], ['christopher', 'chris'], ['christine', 'chris', 'christy'],
  ['cynthia', 'cindy'], ['daniel', 'dan', 'danny'], ['david', 'dave'], ['deborah', 'deb', 'debbie', 'debra'],
  ['donald', 'don'], ['edward', 'ed', 'eddie', 'ted'], ['elizabeth', 'liz', 'beth', 'betsy', 'betty'],
  ['gerald', 'jerry'], ['gregory', 'greg'], ['james', 'jim', 'jimmy', 'jamie'], ['jeffrey', 'jeff'],
  ['jennifer', 'jen', 'jenny'], ['john', 'jack', 'johnny'], ['jonathan', 'jon'], ['joseph', 'joe', 'joey'],
  ['katherine', 'kathy', 'kate', 'katie', 'kathryn'], ['kenneth', 'ken', 'kenny'], ['kimberly', 'kim'],
  ['lawrence', 'larry'], ['margaret', 'maggie', 'peggy'], ['matthew', 'matt'], ['michael', 'mike', 'mick'],
  ['nicholas', 'nick'], ['patricia', 'pat', 'patty', 'trish'], ['patrick', 'pat'], ['peter', 'pete'],
  ['philip', 'phil', 'phillip'], ['raymond', 'ray'], ['richard', 'rick', 'rich', 'dick', 'richie'],
  ['robert', 'bob', 'bobby', 'rob', 'robbie', 'bert'], ['ronald', 'ron'], ['samuel', 'sam'],
  ['stephen', 'steve', 'steven'], ['susan', 'sue', 'susie'], ['thomas', 'tom', 'tommy'],
  ['timothy', 'tim'], ['walter', 'walt'], ['william', 'bill', 'billy', 'will', 'willie', 'liam'],
];

const CANONICAL = new Map();
for (const [formal, ...short] of NICKNAME_GROUPS) {
  for (const n of [formal, ...short]) {
    if (!CANONICAL.has(n)) CANONICAL.set(n, new Set());
    CANONICAL.get(n).add(formal);
  }
}

const SUFFIX = /^(jr|sr|ii|iii|iv|v|phd|md|esq)$/;

export function fold(s) {
  return String(s ?? '')
    .normalize('NFD').replace(/\p{M}/gu, '')
    .toLowerCase()
    .replace(/[‘’'`.]/g, '')
    .replace(/[^a-z\s-]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/** The given name a row is known by, without initials, quoted nicknames or trailing tokens. */
export function firstToken(first) {
  const f = fold(String(first ?? '').replace(/["“”(].*?["“”)]/g, ' '));
  return f.split(' ').find((t) => t.length > 1) ?? '';
}

/** Surname without a leading initial or a trailing suffix. */
export function surname(last) {
  const toks = fold(last).split(' ').filter(Boolean);
  while (toks.length > 1 && toks[0].length === 1) toks.shift();
  while (toks.length > 1 && SUFFIX.test(toks[toks.length - 1])) toks.pop();
  return toks.join(' ');
}

/** Every canonical first name a given name can stand for (itself included). */
export function canonicalFirsts(first) {
  const t = firstToken(first);
  if (!t) return [];
  return [...(CANONICAL.get(t) ?? new Set([t]))];
}

/**
 * All keys a row answers to: its first_name and preferred_name, each against its last_name, plus any
 * alternate_names written as "First Last". Two rows are a candidate pair if they share one key.
 */
export function personKeys({ first_name, last_name, preferred_name, alternate_names }) {
  const keys = new Set();
  const sn = surname(last_name);
  if (sn) {
    for (const g of [first_name, preferred_name]) {
      for (const c of canonicalFirsts(g)) keys.add(`${c} ${sn}`);
    }
  }
  for (const alt of alternate_names ?? []) {
    const toks = String(alt).trim().split(/\s+/);
    if (toks.length < 2) continue;
    const asn = surname(toks.slice(1).join(' '));
    for (const c of canonicalFirsts(toks[0])) keys.add(`${c} ${asn}`);
  }
  return [...keys];
}

/** Pairs, keyed "<smaller id>|<larger id>", with every reason that proposed them. */
export function findPairs(rows) {
  const pairs = new Map();
  const add = (a, b, why) => {
    if (a.id === b.id) return;
    const [x, y] = a.id < b.id ? [a, b] : [b, a];
    const k = `${x.id}|${y.id}`;
    if (!pairs.has(k)) pairs.set(k, { key: k, a: x, b: y, why: new Set() });
    pairs.get(k).why.add(why);
  };

  const byName = new Map();
  for (const r of rows) {
    for (const k of personKeys(r)) {
      if (!byName.has(k)) byName.set(k, []);
      byName.get(k).push(r);
    }
  }
  for (const group of byName.values()) {
    if (group.length < 2 || group.length > 25) continue; // a 25-way "john smith" is noise, not a lead
    for (let i = 0; i < group.length; i++) {
      for (let j = i + 1; j < group.length; j++) {
        const [a, b] = [group[i], group[j]];
        if (!a.st || !b.st || a.st === b.st) add(a, b, 'NAME_STATE');
      }
    }
  }

  const byFec = new Map();
  for (const r of rows) {
    for (const f of r.fec ?? []) {
      if (!byFec.has(f)) byFec.set(f, []);
      byFec.get(f).push(r);
    }
  }
  for (const group of byFec.values()) {
    for (let i = 0; i < group.length; i++) {
      for (let j = i + 1; j < group.length; j++) add(group[i], group[j], 'SHARED_FEC');
    }
  }
  return pairs;
}

/** The pairs that cost a voter something today: seat on one row, answers only on the other. */
export function isSplit(p) {
  const [s, u] = p.a.seated ? [p.a, p.b] : [p.b, p.a];
  return s.seated && !u.seated && u.answers > 0 && s.answers === 0;
}

