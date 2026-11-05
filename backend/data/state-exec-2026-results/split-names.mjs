// Split each seeded person's Ballotpedia name into first_name / last_name.
//
// 🔴 DO NOT GUESS THE SPLIT. AP publishes `first` and `last` as SEPARATE FIELDS, so AP owns
//    where the surname starts; Ballotpedia owns the spelling. The rule is therefore:
//      last_name  = the tail of Ballotpedia's name matching AP's surname token count
//      first_name = everything before it
//    and the script ASSERTS that the tail actually equals AP's surname. "Jose Javier
//    Rodriguez" splits to ("Jose Javier", "Rodriguez"), not ("Jose", "Javier Rodriguez");
//    "T. W. Shannon" to ("T. W.", "Shannon"). A first-token-is-the-first-name rule gets
//    both of those wrong, and the error is invisible once it is a column.
import fs from 'node:fs';
const SP = process.argv[2];
const resolved = JSON.parse(fs.readFileSync(`${SP}/resolved.json`, 'utf8'));
const ap = JSON.parse(fs.readFileSync(`${SP}/gap-ballots.json`, 'utf8'));

const apLast = new Map();
for (const r of ap) for (const c of r.candidates) apLast.set(`${r.st}|${r.office}|${c.apId}`, c.last);
const apFirstOf = new Map();
for (const r of ap) for (const c of r.candidates) apFirstOf.set(`${r.st}|${r.office}|${c.apId}`, c.first);

const norm = s => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z]/g, '');
const SUF = new Set(['jr', 'jr.', 'sr', 'sr.', 'ii', 'iii', 'iv']);

// Each one is a read of that person's own Ballotpedia article, not a rule.
const OVERRIDE = {
  // ⚠ A MONONYM. The Idaho Constitution Party candidate's LEGAL NAME is the single word
  //   "Pro-Life" — ballotpedia.org/Pro-Life_(Marvin_Thomas_Richardson), read 2026-11-05:
  //   "Pro-Life (formerly Marvin Thomas Richardson) ... was born Marvin Thomas Richardson on
  //   August 5, 1941". first_name is NULL because there is no given name to put in it.
  'ID|Governor|56769': { first_name: null, last_name: 'Pro-Life' },
  // AP's surname field reads "Van Morgan"; his own Ballotpedia article is titled
  //   "Charles Morgan (Tennessee)" and names him "Charles Morgan" throughout, with
  //   "Governor of Tennessee candidate, 2022" and "2026". Ballotpedia owns the spelling.
  'TN|Governor|70888': { first_name: 'Charles', last_name: 'Morgan' },
};

// 🔴 THE TWO SOURCES DISAGREE ON DIACRITICS AND NEITHER SAYS SO. AP writes "José Rodriguez"
//    and "Amanda López Askin"; Ballotpedia writes "Jose Javier Rodriguez" and "Amanda Lopez
//    Askin" — same people, accents dropped. Ballotpedia has the fuller name and AP has the
//    accents, so each token takes AP's spelling where the two agree ignoring accents. The
//    accented form is the person's name; the stripped one is a transcription loss. And prod
//    has NO unaccent extension, so a name stored one way is unfindable by the other — a
//    last-name join on Lujan/Luján already returned 32 of 33 rows SILENTLY once.
const bare = s => s.normalize('NFD').replace(/[̀-ͯ]/g, '');
const accented = [];
const reaccent = (bpName, apFirst, apLast) => {
  const apTok = `${apFirst || ''} ${apLast || ''}`.trim().split(/\s+/);
  const byBare = new Map(apTok.filter(t => bare(t) !== t).map(t => [bare(t).toLowerCase(), t]));
  if (!byBare.size) return bpName;
  const outTok = bpName.split(/\s+/).map(t => byBare.get(t.toLowerCase()) ?? t);
  const joined = outTok.join(' ');
  if (joined !== bpName) accented.push(`${bpName} -> ${joined}`);
  return joined;
};

const out = [], problems = [];
for (const x of resolved.filter(r => !r.politicianId)) {
  const k = `${x.st}|${x.office}|${x.apId}`;
  const ov = OVERRIDE[k];
  if (ov) { out.push({ ...x, ...ov, apLast: apLast.get(k), splitOk: true, splitOverridden: true }); continue; }
  // ⚠ AP puts "(write-in)" inside the SURNAME field too, not only the composed name.
  const last = (apLast.get(k) || '').replace(/\s*\(write-in\)\s*$/i, '').trim();
  if (!last) throw new Error(`no AP surname for ${k}`);
  const apFirst = (apFirstOf.get(k) || '');
  const name = reaccent(x.name, apFirst, last);
  const bpTok = name.split(/\s+/);
  const lastTok = last.split(/\s+/);
  // trailing suffix on Ballotpedia's spelling belongs with the surname, not the given names
  let tail = bpTok.length, sfx = [];
  while (tail > 0 && SUF.has(bpTok[tail - 1].toLowerCase())) { sfx.unshift(bpTok[--tail]); }
  const take = lastTok.length;
  const surname = bpTok.slice(tail - take, tail).concat(sfx).join(' ');
  const given = bpTok.slice(0, tail - take).join(' ');
  const agree = norm(bpTok.slice(tail - take, tail).join('')) === norm(last);
  if (!agree || !given) { problems.push(`${x.st} ${x.office}: Ballotpedia "${x.name}" vs AP surname "${last}" -> given="${given}" surname="${surname}"`); }
  out.push({ ...x, name, first_name: given, last_name: surname, apLast: last, splitOk: agree && !!given });
}
fs.writeFileSync(`${SP}/seeds.json`, JSON.stringify(out, null, 1));
console.log(`seeds: ${out.length}`);
console.log(`splits confirmed against AP's own surname field: ${out.filter(s => s.splitOk).length}`);
console.log(`names given AP's accents back: ${accented.length}`);
for (const a of accented) console.log('  ' + a);
if (problems.length) { console.log(`\n🔴 ${problems.length} SPLIT(S) THE ASSERTION REJECTED — read each:`); for (const p of problems) console.log('  ' + p); }
