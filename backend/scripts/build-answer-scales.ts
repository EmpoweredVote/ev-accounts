/**
 * Propose a 7-mark `options_scale` for every numeric question that can honestly carry one.
 *
 *   npx tsx scripts/build-answer-scales.ts            # write the review files
 *   npx tsx scripts/build-answer-scales.ts --selftest # controls only, no database
 *
 * ## What a scale is for
 *
 * CC_0188 added `trivia.questions.options_scale`: 7 ascending marks with the correct answer
 * at index 3. At serve time the server rolls s in 1..4 and shows marks[s-1 .. s+2], so the
 * answer lands on D/C/B/A uniformly while the four options still read in ascending order.
 * See services/questionQuality/answerScale.ts. This script writes nothing to the database;
 * it produces a reviewable proposal.
 *
 * ## Why the marks are evenly spaced
 *
 * Not for tidiness. Any window of four marks is then equally spaced, so no option is
 * singled out by its spacing. Keeping the original four irregular values and padding
 * around them would make the real answer the odd one out in some windows -- the same class
 * of defect as a position tell, expressed as arithmetic.
 *
 * The step is anchored ON THE ANSWER, so every mark shares the answer's residue. 33 with a
 * step of 10 gives 3,13,23,33,43,53,63 rather than a run of round numbers with one odd
 * value among them. Round marks around an unround answer is a tell.
 *
 * ## Why a question is refused
 *
 * A refusal is the correct outcome, not a gap to be filled later. `options_scale` is
 * nullable on purpose and the serve path falls back to the stored `options`, so a refused
 * question behaves exactly as it does today. The reasons are counted and listed.
 *
 * EVERY MARK MUST BE A POSSIBLE ANSWER. A mark a player can rule out without knowing the
 * answer is a free elimination -- it makes the question easier than the four options it
 * replaces. That is what the domain floor and ceiling below are for, and it is why
 * ordinals, clock times and multi-number options are refused rather than guessed at.
 */
import fs from 'node:fs';
import path from 'node:path';
import 'dotenv/config';
import pg from 'pg';
import { pathToFileURL } from 'node:url';
import {
  magnitudeValues,
  isBoundedSeries,
} from '../src/trivia/services/questionQuality/answerPlacement.js';
import {
  isValidScale,
  SCALE_LENGTH,
  SCALE_ANSWER_INDEX,
} from '../src/trivia/services/questionQuality/answerScale.js';

const SELFTEST = process.argv.includes('--selftest');
const OUT_DIR = path.join('data', 'answer-scales-2026-10-25');

/** A number inside an option, with enough context to render a sibling that matches it. */
interface Parsed {
  template: string; // the option with its number replaced by {}
  value: number;
  decimals: number;
  grouped: boolean; // the original wrote thousands separators
}

const NUMBER = /[0-9][0-9,]*(?:\.[0-9]+)?/g;

/**
 * A word that, sitting directly in front of the number, means the number NAMES something.
 *
 * "Interstate 10" is a road, not ten of anything, and a scale through it proposes
 * Interstates 1, 4, 7, 13, 16 and 19 -- roads that mostly do not exist, which a player
 * eliminates without knowing the answer. Matched against the option, never the question:
 * "the Metropolitan District Commission" is a body whose members are perfectly countable.
 */
const NAMES_A_THING =
  /\b(interstate|highway|route|district|ward|precinct|chapter|title|article|amendment|section|clause|proposition|measure|initiative|question|bill|act|phase|tier|grade|level)\s*$/i;

/**
 * Parse one option, or null when a sibling mark cannot be rendered for it.
 *
 * Refuses three shapes that `magnitudeValues` accepts but that must not be scaled:
 *  - more than one number ("The 13th and 14th Amendments" parses to 13 and reads as a series)
 *  - an ordinal ("18th", "The 89th") -- a rank or a name, not a quantity
 *  - a clock ("6:00 PM") -- bounded by the world in a way a step cannot express
 */
function parseOption(option: string): Parsed | { bad: string } {
  if (option.includes(':')) return { bad: 'a clock time' };
  const matches = [...option.matchAll(NUMBER)];
  if (matches.length !== 1) return { bad: 'two or more numbers in one option' };
  const m = matches[0];
  const raw = m[0];
  const before = option.slice(0, m.index!);
  const after = option.slice(m.index! + raw.length);
  if (/^(st|nd|rd|th)\b/i.test(after)) return { bad: 'an ordinal: a rank or a name, not a quantity' };
  if (NAMES_A_THING.test(before)) {
    return { bad: `the number names a thing ("${before.trim()} ${raw}"), it is not a quantity` };
  }
  const dot = raw.indexOf('.');
  return {
    template: option.slice(0, m.index!) + '{}' + after,
    value: Number(raw.replace(/,/g, '')),
    decimals: dot === -1 ? 0 : raw.length - dot - 1,
    grouped: raw.includes(','),
  };
}

function isBad(p: Parsed | { bad: string }): p is { bad: string } {
  return 'bad' in p;
}

function render(p: Pick<Parsed, 'template' | 'decimals' | 'grouped'>, value: number): string {
  let s = value.toFixed(p.decimals);
  if (p.grouped) {
    const [int, frac] = s.split('.');
    s = int.replace(/\B(?=(\d{3})+(?!\d))/g, ',') + (frac ? '.' + frac : '');
  }
  // "1 members" is wrong on its face, so it is a tell: the odd-looking option is never
  // the answer. The stored options are all plural because no stored answer is 1, which is
  // exactly why this only shows up once a scale reaches down to it.
  const unit = value === 1 ? p.template.replace(/(\{\})(\s+[A-Za-z-]*?)s\b/, '$1$2') : p.template;
  return unit.replace('{}', s);
}

/**
 * People who sit on a body: a council, a court, a commission, a board.
 *
 * These carry a floor the question itself implies. "How many justices serve on the
 * Supreme Court?" cannot honestly offer 1 -- a one-judge supreme court is not a thing a
 * player has to know the answer to rule out. Three is the smallest number that still
 * reads as a body, and requiring it also makes the generator pick a tighter step, which
 * is a better question anyway.
 */
const SEATS_IN_A_BODY =
  /\b(members?|justices?|judges?|senators?|representatives?|councill?ors?|commissioners?|supervisors?|aldermen|delegates?|trustees?|directors?|seats?)\b/;

/**
 * Hard bounds the real world puts on a quantity.
 *
 * Reads the QUESTION as well as the option, because half of these options are a bare
 * number: "How many justices serve on the Supreme Court?" offers 5/7/9/11 with no unit
 * anywhere in the option text. Reading the option alone gave that court a floor of 1.
 */
function domainOf(template: string, question: string, integerOnly: boolean): { min: number; max: number } {
  const opt = template.toLowerCase();
  const both = (template + ' ' + question).toLowerCase();
  // A share cannot exceed the whole. "0 percent" is not a plausible distractor for a
  // question that asks what share something is, so the floor sits above nothing.
  if (/%|percent/.test(both)) return { min: 1, max: 100 };
  // 🔴 THE OPTION, NOT THE QUESTION. "There are 50 states" bounds a count OF states.
  // Read off the question text it also fires on "the state Supreme Court", which capped
  // a count of justices at 50 and, worse, took priority over their floor of 3 -- the
  // generator then proposed a one-justice supreme court and the accept case still passed.
  if (/\bstates?\b/.test(opt)) return { min: 1, max: 50 };
  if (SEATS_IN_A_BODY.test(both)) return { min: 3, max: Number.POSITIVE_INFINITY };
  // Everything else is open above. Below, a count of zero is not a plausible answer to
  // "how many X are there" -- the question presupposes some -- and a negative is absurd.
  return { min: integerOnly ? 1 : 0, max: Number.POSITIVE_INFINITY };
}

/** Steps a person would choose, largest first. */
function stepLadder(granularity: number): number[] {
  const out: number[] = [];
  for (let k = 9; k >= -2; k--) {
    for (const mant of [5, 2.5, 2, 1]) {
      const s = mant * 10 ** k;
      if (s >= granularity - 1e-12) out.push(Number(s.toPrecision(12)));
    }
  }
  return out;
}

export interface Proposal {
  id: number;
  externalId: string | null;
  text: string;
  options: string[];
  answer: string;
  scale?: string[];
  step?: number;
  reason?: string;
}

export function proposeScale(
  text: string,
  options: string[],
  correctAnswer: number,
  id = 0,
  externalId: string | null = null,
): Proposal {
  const base: Proposal = { id, externalId, text, options, answer: options[correctAnswer] };
  const refuse = (reason: string): Proposal => ({ ...base, reason });

  if (!Array.isArray(options) || options.length !== 4) return refuse('not four options');
  if (correctAnswer < 0 || correctAnswer > 3) return refuse('correct_answer out of range');

  const values = magnitudeValues(options);
  if (!values) return refuse('not a comparable magnitude series');
  if (isBoundedSeries(values)) return refuse('bounded series: no honest mark below the floor');

  // A term of office is institutionally fixed -- 1, 2, 4 or 6 years -- so a scale through
  // 3, 5 and 7 offers marks a player rules out without knowing the answer. isBoundedSeries
  // catches these only when the four stored options happen to sit at or below 12, and the
  // Pittsburgh mayor's term did not: it proposed "1 years | 2 years | 3 years ... 7 years".
  if (/\bterms?\b|how long is/i.test(text) && /\b(year|month)/i.test(options[correctAnswer])) {
    return refuse('term of office: the plausible lengths are institutionally fixed');
  }

  const parsed = options.map(parseOption);
  const firstBad = parsed.find(isBad);
  if (firstBad) return refuse(`cannot render a sibling mark: ${(firstBad as { bad: string }).bad}`);
  const ps = parsed as Parsed[];

  const templates = new Set(ps.map((p) => p.template));
  if (templates.size !== 1) {
    return refuse(`options are written differently (${[...templates].join(' / ')})`);
  }

  // 🔴 THE ANSWER'S OWN FORMATTING IS THE TEMPLATE, not the widest of the four.
  // The serve path requires scale[3] to equal the stored answer STRING exactly, so a
  // question whose answer reads "10%" beside a sibling "7.5%" must render marks with no
  // decimal place. Taking the maximum produced "10.0%" and refused two real questions.
  const decimals = ps[correctAnswer].decimals;
  const integerOnly = decimals === 0;
  const granularity = 10 ** -decimals;
  const fmt = { template: ps[0].template, decimals, grouped: ps[correctAnswer].grouped };

  const answer = ps[correctAnswer].value;
  const { min, max } = domainOf(fmt.template, text, integerOnly);

  // The writer's own spacing is the starting point: the tightest gap they thought fair.
  const sorted = [...values].sort((a, b) => a - b);
  const target = Math.min(sorted[1] - sorted[0], sorted[2] - sorted[1], sorted[3] - sorted[2]);
  if (!(target > 0)) return refuse('two options share a value');

  // Integer arithmetic at the answer's granularity, so a 0.1 step does not drift.
  const scaleUp = 10 ** decimals;
  const aI = Math.round(answer * scaleUp);
  const minI = Math.round(min * scaleUp);
  const maxI = Number.isFinite(max) ? Math.round(max * scaleUp) : Number.POSITIVE_INFINITY;

  const ladder = stepLadder(granularity).filter((s) => s <= target + 1e-12);
  if (!ladder.length) return refuse(`no step at or below the tightest gap (${target})`);

  for (const step of ladder) {
    const sI = Math.round(step * scaleUp);
    if (sI < 1) continue;
    if (aI - 3 * sI < minI) continue; // would fall through the floor
    if (aI + 3 * sI > maxI) continue; // would break the ceiling
    const marks: string[] = [];
    for (let k = -3; k <= 3; k++) marks.push(render(fmt, (aI + k * sI) / scaleUp));

    // The serve path's own two checks, run here so a bad proposal never reaches review.
    if (marks.length !== SCALE_LENGTH) continue;
    if (!isValidScale(marks)) continue;
    if (marks[SCALE_ANSWER_INDEX] !== base.answer) {
      return refuse(
        `rendered answer "${marks[SCALE_ANSWER_INDEX]}" does not match stored "${base.answer}"`,
      );
    }
    // 🔴 REPORT THE STEP THAT WAS USED, NOT THE LADDER VALUE THAT PRODUCED IT.
    // A 2.5 rung rounds to 3 when the answer has no decimal place, so 35 proposals
    // carried a `step` column that disagreed with their own marks. The marks were right
    // and uniform throughout -- but the review file is read by a person comparing the two.
    return { ...base, scale: marks, step: sI / scaleUp };
  }
  return refuse(`no step fits the domain (answer ${answer}, floor ${min}, ceiling ${max})`);
}

/* ------------------------------------------------------------------ controls */

/**
 * WATCH THE CONTROL FAIL FIRST. Each case states what must happen; a generator that
 * accepted everything would pass three cases and fail seven, which is the point of
 * listing refusals here rather than only acceptances.
 *
 * An ACCEPT case states the exact marks. "Something came back" is not an assertion --
 * the floor rule passed an accept case while still proposing a one-justice supreme court,
 * and only spelling the marks out caught it.
 */
export type ControlCase = [
  question: string,
  options: string[],
  correctAnswer: number,
  want: 'accept' | 'refuse',
  why: string,
  expect?: string,
];

export const CONTROL_CASES: ControlCase[] = (
  [
    [
      'How many members serve on the council?',
      ['9 members', '11 members', '13 members', '15 members'],
      0,
      'accept',
      'even spacing, room below 9',
      '3 members | 5 members | 7 members | 9 members | 11 members | 13 members | 15 members',
    ],
    [
      'What share of the vote?',
      ['About 94 percent', 'About 96 percent', 'About 98 percent', 'About 99 percent'],
      2,
      'refuse',
      'ceiling: 98 plus three steps passes 100 at every step that fits',
    ],
    [
      'How many counties?',
      ['2 counties', '3 counties', '4 counties', '5 counties'],
      0,
      'refuse',
      'bounded series',
    ],
    [
      'Which amendments?',
      [
        'The 12th and 13th Amendments',
        'The 13th and 14th Amendments',
        'The 14th and 15th Amendments',
        'The 15th and 16th Amendments',
      ],
      1,
      'refuse',
      'two numbers in one option',
    ],
    ['What time do polls close?', ['4:00 PM', '5:00 PM', '6:00 PM', '7:00 PM'], 2, 'refuse', 'clock'],
    [
      'Which state in order?',
      ['The 25th', 'The 28th', 'The 30th', 'The 33rd'],
      2,
      'refuse',
      'ordinal',
    ],
    [
      'What is the population?',
      ['3.0 million', '4.5 million', '6.0 million', '7.5 million'],
      2,
      'accept',
      'decimals preserved',
    ],
    [
      'How many states do this?',
      ['20 states', '30 states', '40 states', '48 states'],
      3,
      'refuse',
      'ceiling of 50 leaves no room above 48',
    ],
    [
      'How many justices serve on the state Supreme Court?',
      ['5', '7', '9', '11'],
      1,
      'accept',
      'a body of 7 must not reach down to 1 -- the floor of 3 forces a step of 1',
      '4 | 5 | 6 | 7 | 8 | 9 | 10',
    ],
    [
      'How long is the mayor of Pittsburgh’s term in office?',
      ['4 years', '6 years', '8 years', '10 years'],
      0,
      'refuse',
      'term of office: 3, 5 and 7 years are not real terms',
    ],
    [
      'How many at-large members serve on the council?',
      ['4 at-large members', '5 at-large members', '6 at-large members', '7 at-large members'],
      0,
      'refuse',
      'a body of 4 cannot be centred above a floor of 3',
    ],
    [
      'Which interstate highway runs east-west just north of Biloxi?',
      ['Interstate 10', 'Interstate 20', 'Interstate 55', 'Interstate 65'],
      0,
      'refuse',
      'the number names a road: Interstates 1, 4, 7 and 13 are not plausible distractors',
    ],
    [
      'How many members serve on the Metropolitan District Commission?',
      ['5 members', '7 members', '9 members', '11 members'],
      1,
      'accept',
      '"District" in the QUESTION must not refuse a countable body',
      '4 members | 5 members | 6 members | 7 members | 8 members | 9 members | 10 members',
    ],
    [
      'How many days before an election does registration close?',
      ['4 days', '8 days', '12 days', '16 days'],
      0,
      'accept',
      'the singular mark reads "1 day", never "1 days"',
      '1 day | 2 days | 3 days | 4 days | 5 days | 6 days | 7 days',
    ],
  ] as ControlCase[]
);

function selftest(): number {
  let bad = 0;
  for (const [text, options, answer, want, why, expect] of CONTROL_CASES) {
    const got = proposeScale(text, options, answer);
    let ok = want === 'accept' ? !!got.scale : !got.scale;
    if (ok && expect && got.scale!.join(' | ') !== expect) ok = false;
    if (!ok) bad++;
    const detail = got.scale
      ? `${got.scale.join(' | ')}   (step ${got.step})`
      : `refused: ${got.reason}`;
    console.log(`  ${ok ? 'ok  ' : 'FAIL'}  want ${want.padEnd(6)} ${why}\n        ${detail}`);
  }
  return bad;
}

/* ------------------------------------------------------------------ main */

// 🔴 IMPORTING THIS FILE MUST NOT TOUCH THE DATABASE. The controls are also a vitest
// suite (build-answer-scales.test.ts) so CI enforces them, and a test run that opened a
// pool against production would be a very bad surprise.
const invokedDirectly =
  !!process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url;

if (invokedDirectly) {
  console.log('controls:');
  const badControls = selftest();
  if (badControls) {
    console.error(`\n${badControls} control(s) failed -- the rules are wrong. Stopping.`);
    process.exit(1);
  }
  if (SELFTEST) process.exit(0);

  if (!process.env.DATABASE_URL) {
    console.error('\nDATABASE_URL is not set (backend/.env).');
    process.exit(2);
  }
  await main();
}

async function main(): Promise<void> {
const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});
const { rows } = await pool.query(
  `SELECT id, external_id, text, options, correct_answer
     FROM trivia.questions
    WHERE status = 'active' AND options_scale IS NULL`,
);
await pool.end();

const proposals: Proposal[] = [];
for (const r of rows) {
  const options: string[] = Array.isArray(r.options) ? r.options : JSON.parse(r.options);
  const values = options.length === 4 ? magnitudeValues(options) : null;
  if (!values) continue; // prose: not this script's business
  if (values.every((v) => Number.isInteger(v) && v >= 1500 && v <= 2100)) continue; // years: a later pass
  proposals.push(proposeScale(r.text, options, r.correct_answer, r.id, r.external_id));
}

const accepted = proposals.filter((p) => p.scale);
const refused = proposals.filter((p) => !p.scale);

fs.mkdirSync(OUT_DIR, { recursive: true });
fs.writeFileSync(path.join(OUT_DIR, 'proposed-scales.json'), JSON.stringify(accepted, null, 1));
fs.writeFileSync(path.join(OUT_DIR, 'refused.json'), JSON.stringify(refused, null, 1));

const q = (s: string) => `"${String(s).replace(/"/g, '""')}"`;
const csv = ['id,question,answer,step,mark1,mark2,mark3,mark4_answer,mark5,mark6,mark7'];
for (const p of accepted) {
  csv.push([p.id, q(p.text), q(p.answer), p.step, ...p.scale!.map(q)].join(','));
}
fs.writeFileSync(path.join(OUT_DIR, 'proposed-scales.csv'), csv.join('\n') + '\n');

const byReason = new Map<string, number>();
for (const p of refused) {
  const key = (p.reason ?? '').replace(/\(.*\)/, '(...)');
  byReason.set(key, (byReason.get(key) ?? 0) + 1);
}

console.log(`\nnumeric questions considered  ${proposals.length}`);
console.log(`  scale proposed              ${accepted.length}`);
console.log(`  refused                     ${refused.length}`);
console.log('\nrefusals by reason:');
for (const [reason, n] of [...byReason].sort((a, b) => b[1] - a[1])) {
  console.log(`  ${String(n).padStart(4)}  ${reason}`);
}
console.log(`\nwrote ${OUT_DIR}/proposed-scales.csv (+ .json, refused.json)`);
}
