// The Massachusetts district key, in ONE place because three readers use it and a key that
// drifts between them is a silent mis-join.
//
// 🔴 THE ORDER OF THE COUNTY TOKENS IS LOAD BEARING. "Middlesex & Norfolk" and "Norfolk &
//   Middlesex" are both real senate districts, as are Suffolk/Middlesex and Worcester/Middlesex.
//   A key that sorted its tokens would collide three real pairs, so this one keeps the order the
//   source prints.
//
// 🔴 EACH SOURCE SPELLS THE ORDINAL ITS OWN WAY, AND THEY DISAGREE WITHIN A SINGLE SOURCE.
//   AP writes "21st Middlesex". The Secretary of the Commonwealth writes "Twenty-First Middlesex
//   District". Our own labels write the senate in words ("Fifth Middlesex District") and the
//   house in numerals ("25th Middlesex District"). Leaving the compound ordinals out of this map
//   cost 17 Massachusetts house districts, which came back as "no district of this name" —
//   loudly, because the comparison reports both directions.
const UNITS = {
  first: 1, second: 2, third: 3, fourth: 4, fifth: 5, sixth: 6, seventh: 7, eighth: 8,
  ninth: 9, tenth: 10, eleventh: 11, twelfth: 12, thirteenth: 13, fourteenth: 14,
  fifteenth: 15, sixteenth: 16, seventeenth: 17, eighteenth: 18, nineteenth: 19,
};
const TENS = { twentieth: 20, thirtieth: 30, fortieth: 40, fiftieth: 50 };
const TENS_PREFIX = { twenty: 20, thirty: 30, forty: 40, fifty: 50 };

const ordinalSuffix = (n) => {
  const two = n % 100;
  if (two >= 11 && two <= 13) return 'th';
  return { 1: 'st', 2: 'nd', 3: 'rd' }[n % 10] || 'th';
};
export const numberToOrdinal = (n) => `${n}${ordinalSuffix(n)}`;

export function maDistrictKey(raw) {
  const tokens = (raw || '')
    .normalize('NFD').replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/&/g, ' ')
    .replace(/[,\-/]/g, ' ')
    .replace(/[^a-z0-9 ]/g, ' ')
    .split(/\s+/)
    .filter(Boolean)
    .filter((t) => t !== 'district' && t !== 'and');

  const out = [];
  for (let i = 0; i < tokens.length; i++) {
    const t = tokens[i];
    if (TENS_PREFIX[t] !== undefined && UNITS[tokens[i + 1]] !== undefined) {
      out.push(numberToOrdinal(TENS_PREFIX[t] + UNITS[tokens[i + 1]]));
      i++;
      continue;
    }
    if (TENS[t] !== undefined) { out.push(numberToOrdinal(TENS[t])); continue; }
    if (UNITS[t] !== undefined) { out.push(numberToOrdinal(UNITS[t])); continue; }
    out.push(t);
  }
  return out.join('-');
}
