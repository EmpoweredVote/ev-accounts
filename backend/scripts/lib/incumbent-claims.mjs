/**
 * Does a result citation that says somebody BEAT AN INCUMBENT name a person who actually lost
 * that race? Pure and tested; `scripts/check-incumbent-claims.mjs` is the database shell.
 *
 * ── WHY THIS EXISTS ──────────────────────────────────────────────────────────────────────────
 *
 * `CC_0447` wrote, live on a voter-facing page, that Paul LePage won ME-02 "defeating incumbent
 * Jared Golden". Golden held ME-02 and was not a candidate: he announced on 2025-11-05 that he
 * would not seek re-election. `CC_0452` corrected the row and `match-losers.mjs` now carries the
 * three-branch test that stops the generator repeating it.
 *
 * 🔴 THIS IS THE HALF THE GENERATOR CANNOT COVER: A CITATION WRITTEN BY HAND. The matcher guards
 *    the path that produces claims in bulk. Nothing guarded the claim once it was in the column,
 *    and `result_source` has no history table, so a false sentence sits there until a person
 *    reads it. This asks the one question that is answerable in SQL about every such claim at
 *    once, and it is the question that would have caught `CC_0447` on the day:
 *
 *      ▶ EVERY "defeating incumbent X" MUST NAME SOMEBODY HOLDING A LOSING ROW IN THAT RACE.
 *
 * ── 🔴 THE TRAP: TWO OPPOSITE GRAMMARS SHARE THESE WORDS ─────────────────────────────────────
 *
 * Read against production before this was written, 30 citations mention an incumbent and only 6
 * are the shape above. TWENTY are quoted Ballotpedia text on primary rows, in the MIRROR
 * grammar, where the incumbent is the WINNER:
 *
 *     "Incumbent Tracey Mann defeated Craig Musser in the Republican primary for U.S. House"
 *     "Incumbent Wesley Bell defeated Cori Bush, Alissa Murphy, Carl Harris Sr. ..."
 *
 * A predicate on the words "incumbent" and "defeated" catches both and inverts the meaning of
 * half of them — it would fail all 20 of those rows, each of which is TRUE and is a quotation of
 * a source besides. The discriminator is WORD ORDER, and nothing weaker works: the claim this
 * checks puts `incumbent` IMMEDIATELY AFTER the verb (`defeated incumbent Mike Thompson`), and
 * the mirror grammar puts it before the subject (`Incumbent Wesley Bell defeated ...`).
 * ▶ A PREDICATE READS THE SHAPE OF A VALUE, NEVER WHAT THE VALUE IS — so these were read, all
 *   thirty, before this regex was written.
 *
 * ── 🔴 WHY THE NAME IS NOT PARSED OUT OF THE PROSE ───────────────────────────────────────────
 *
 * The obvious implementation captures the name with something like /defeating incumbent ([^.]+)\./
 * — which is what `CC_0452`'s own post-verify did, and it is one initial away from being wrong:
 * it truncates "Dan S. Sullivan" at "Dan S." and "Carl Harris Sr." at "Carl Harris Sr.". There is
 * no reliable sentence boundary in English prose that contains initials and suffixes.
 *
 * So the question is asked the other way round. Rather than parsing an unknown name out of prose
 * and looking it up, this tests whether a KNOWN name — one the DATABASE says lost this race —
 * appears at that position. Exact, no boundary needed, and ▶ THE EXPECTATION COMES FROM SOMEWHERE
 * THE CITATION'S AUTHOR CANNOT EDIT, which is the house rule these gates keep relearning.
 */

/** The claim: a defeat verb with `incumbent` as its OBJECT. Not `Incumbent X defeated Y`. */
export const DEFEAT_CLAIM = /defeat(?:ing|ed)\s+incumbents?\s+/gi;

/** A row describing ITSELF as the beaten incumbent ("…47%, the defeated incumbent"). Names nobody. */
export const SELF_DESCRIBED_LOSER = /\bthe\s+defeated\s+incumbent\b/i;

/** "Incumbent re-elected: AP winner candidateID … equals AP incumbent candidateID …" */
export const RE_ELECTED = /\bincumbent\s+re-?elected\b/i;

/** Separators between names in a plural claim: "A and B", "A, B and C", "A, B, and C". */
const NAME_SEPARATOR = /^(?:,\s*and\s+|,\s*|\s+and\s+)/;

const lower = (s) => (s ?? '').toLowerCase();

/**
 * The spellings of one candidate row that a citation may legitimately use.
 *
 * ⚠ A LAST NAME ALONE IS ADMITTED ONLY WHEN IT IS UNAMBIGUOUS IN THAT RACE. Our rows and AP's
 * feed disagree about names often enough to have their own review file — AP writes "Tessa Hodge"
 * where we store "Tessa"/"Lynn Hodge" — so refusing anything but `full_name` would fail on true
 * claims. But admitting a bare surname everywhere would let a NAMESAKE satisfy the gate, and this
 * repo has shipped Mark Harris as NC-8 and put the late President of Yemen on a California
 * councilman. So the surname counts only where exactly one candidate in the race carries it.
 */
export function spellingsFor(row, allRowsInRace) {
  const out = [];
  const push = (s) => { if (s && s.trim()) out.push(s.trim()); };
  push(row.full_name);
  if (row.first_name && row.last_name) push(`${row.first_name} ${row.last_name}`);
  const surname = (row.last_name ?? '').trim();
  if (surname) {
    const sharing = allRowsInRace.filter((r) => lower(r.last_name).trim() === lower(surname));
    if (sharing.length === 1) push(surname);
  }
  // Longest first, so "Mike Thompson" is preferred over "Thompson" and the consumed length is right.
  return [...new Set(out)].sort((a, b) => b.length - a.length);
}

/** The longest spelling of any losing row that `text` begins with, or null. */
function matchLoserAtStart(text, losers, allRowsInRace) {
  let best = null;
  for (const loser of losers) {
    for (const spelling of spellingsFor(loser, allRowsInRace)) {
      if (lower(text).startsWith(lower(spelling))
          && (!best || spelling.length > best.length)) {
        best = { loser, spelling, length: spelling.length };
      }
    }
  }
  return best;
}

/**
 * Verify one claim. `losers` are the rows with `result = 'lost'` in this race; `allRowsInRace`
 * is every row in it, used both for the surname-ambiguity test and to say something useful when
 * the claim names someone who is in the race but did NOT lose.
 */
export function verifyClaim(citation, markerEnd, losers, allRowsInRace) {
  let rest = citation.slice(markerEnd);
  const named = [];

  for (;;) {
    const hit = matchLoserAtStart(rest, losers, allRowsInRace);
    if (!hit) {
      const notALoser = matchLoserAtStart(
        rest,
        allRowsInRace.filter((r) => r.result !== 'lost'),
        allRowsInRace,
      );
      return {
        ok: false,
        named: named.map((n) => n.spelling),
        unmatched: rest.slice(0, 60).replace(/\s+/g, ' ').trim(),
        why: notALoser
          ? `names "${notALoser.spelling}", who is in this race but did not lose it `
            + `(result: ${notALoser.loser.result ?? 'none recorded'})`
          : 'names somebody who holds no losing row in this race',
      };
    }
    named.push(hit);
    rest = rest.slice(hit.length);

    const sep = NAME_SEPARATOR.exec(rest);
    if (!sep) return { ok: true, named: named.map((n) => n.spelling) };
    rest = rest.slice(sep[0].length);
  }
}

/**
 * Every verdict this module has about one citation.
 *
 * ⚠ IT RETURNS WHAT IT EXAMINED, NOT ONLY WHAT IT REJECTED. A citation with no claim in it is
 * not a pass, it is a row this check has nothing to say about, and the two have to be countable
 * apart — a gate that reports "0 violations" over rows it never looked at is the shape of a
 * detector that has quietly stopped working.
 */
export function checkCitation({ result_source, result }, losers, allRowsInRace) {
  const citation = result_source ?? '';
  const claims = [];
  DEFEAT_CLAIM.lastIndex = 0;
  for (let m = DEFEAT_CLAIM.exec(citation); m; m = DEFEAT_CLAIM.exec(citation)) {
    claims.push({ marker: m[0].trim(), ...verifyClaim(citation, m.index + m[0].length, losers, allRowsInRace) });
  }

  const violations = claims.filter((c) => !c.ok)
    .map((c) => ({ rule: 'defeated-incumbent-must-have-lost', detail: c.why, unmatched: c.unmatched }));

  if (SELF_DESCRIBED_LOSER.test(citation) && result !== 'lost') {
    violations.push({
      rule: 'self-described-defeated-incumbent-must-have-lost',
      detail: `the citation calls this row "the defeated incumbent", but its result is `
        + `${result ?? 'not recorded'}`,
    });
  }

  if (RE_ELECTED.test(citation) && result !== 'won') {
    violations.push({
      rule: 'incumbent-re-elected-must-have-won',
      detail: `the citation says the incumbent was re-elected, but this row's result is `
        + `${result ?? 'not recorded'}`,
    });
  }

  return { claimsFound: claims.length, violations };
}
