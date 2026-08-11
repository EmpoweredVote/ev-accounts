#!/usr/bin/env node
/**
 * Generate migration 1689 -- repair every Maryland stance citing a wrong-person or dead mgaleg MEMBER page.
 *
 * Each replacement URL was confirmed by fetching IT, in the exact form it will be stored, and reading the
 * member page title. Bare where bare works; session-qualified where only that resolves (former members).
 * Nothing here is a guessed suffix -- guessing suffixes is what produced the defect.
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const IN = flag('--in'), SQL_OUT = flag('--sql'), ROLLBACK = flag('--rollback');
if (!IN || !SQL_OUT || !ROLLBACK) { console.error('need --in --sql --rollback'); process.exit(2); }

const data = JSON.parse(fs.readFileSync(IN, 'utf8'));
const plan = data.rows.filter((r) => r.final === 'REPLACE').map((r) => ({
  politician: r.politician, politician_id: r.politician_id,
  bad_slug: r.cited_slug, stored_verdict: r.stored_verdict,
  new_url: r.replacement.url, confirmed_as: r.replacement.confirmed_as, form: r.replacement.form,
}));

// Verified by hand this run: cox01 is Daniel L. Cox (same person as "Dan Cox" -- abbreviation), but the
// BARE url is NotFound, so the stored citation is dead and still needs repointing.
plan.push({
  politician: 'Dan Cox', politician_id: data.rows.find((r) => r.politician === 'Dan Cox').politician_id,
  bad_slug: 'cox01', stored_verdict: 'DEAD',
  new_url: 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/cox01?ys=2023RS',
  confirmed_as: 'Daniel L. Cox', form: 'SESSION_QUALIFIED',
});

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const ids = plan.map((p) => p.politician_id);
const { rows: live } = await pool.query(
  `SELECT c.politician_id, c.topic_id, p.full_name, t.title AS topic, c.sources
   FROM inform.politician_context c
   JOIN essentials.politicians p ON p.id = c.politician_id
   LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
   WHERE c.politician_id = ANY($1::uuid[])
   ORDER BY p.full_name, t.title`, [ids]);
await pool.end();

fs.writeFileSync(ROLLBACK, JSON.stringify({
  migration: '1689_repair_md_member_slug_citations',
  generated: 'pre-change snapshot from live DB',
  rule: 'Replace mgaleg member-page citations that are dead or belong to a different politician with a URL confirmed, in its stored form, to name the right person.',
  plan, row_count: live.length, rows: live,
}, null, 2));

const byId = new Map(plan.map((p) => [p.politician_id, p]));
const esc = (s) => s.replace(/'/g, "''");
const stmts = [];
let touched = 0, unchanged = 0;
for (const r of live) {
  const p = byId.get(r.politician_id);
  const cur = r.sources || [];
  // Replace any member-page URL carrying the bad slug (query strings included); keep everything else.
  // ⚠ Done with plain string logic on purpose. The first version built this regex inside a template
  // interpolation, where the `}` in the escape character class closed the `${...}` early and produced a
  // pattern that silently failed to match some slugs. The in-migration guard caught it -- 2 rows would
  // have kept citing a wrong-person page while the migration reported success.
  const isBad = (s) => {
    const i = s.toLowerCase().indexOf(`members/details/${p.bad_slug.toLowerCase()}`);
    if (i === -1) return false;
    const after = s.charAt(i + `members/details/${p.bad_slug}`.length);
    return after === '' || after === '?' || after === '#';
  };
  const next = [];
  let changed = false;
  for (const s of cur) {
    if (isBad(s)) { changed = true; if (!next.includes(p.new_url)) next.push(p.new_url); }
    else if (!next.includes(s)) next.push(s);
  }
  if (!changed) { unchanged++; continue; }
  touched++;
  stmts.push(
    `UPDATE inform.politician_context SET sources = ARRAY[${next.map((s) => `'${esc(s)}'`).join(',')}]::text[]\n` +
    `WHERE politician_id = '${r.politician_id}'::uuid AND topic_id = '${r.topic_id}'::uuid\n` +
    `;  -- ${esc(r.full_name)} / ${esc(r.topic ?? '?')}`
  );
}

const wrongPerson = plan.filter((p) => p.stored_verdict === 'WRONG_PERSON');
const sql = `-- 1689_repair_md_member_slug_citations.sql
--
-- Every Maryland stance whose cited mgaleg MEMBER page is dead or belongs to a DIFFERENT POLITICIAN.
--
-- 🔴 THE DEFECT: a member-page citation can name the wrong person and pass every previous check --
-- the URL returns 200, it is a real member page, and it carries the right surname. Nothing keyed on
-- 404s, topic vocabulary, or source count could see it.
--   ${wrongPerson.map((p) => `${p.politician} cited ${p.bad_slug} = "another member"`).join('\n--   ')}
-- The rest cite pages that do not exist at all (mgaleg answers 200 and redirects to /Error/NotFound,
-- so status code alone never revealed them).
--
-- HOW EACH REPLACEMENT WAS ESTABLISHED -- and it is not by guessing a suffix, which is what created
-- this mess in the first place:
--   1. candidate slugs came from the MGA roster (current members) or enumeration (former members)
--   2. every candidate was FETCHED IN THE EXACT FORM IT WILL BE STORED and its page title read
--   3. only a page titled with this politician's own name was accepted
-- ⚠ Slugs may contain SPACES ("jacobs j", "miller a", "davis d") -- a [A-Za-z0-9]+ pattern truncates
--   them into a DIFFERENT member's slug. That bug briefly turned Jay A. Jacobs into Nancy Jacobs.
-- ⚠ Former members resolve only with a session: those URLs keep ?ys=, because the citation must work
--   as stored, not merely in principle.
--
-- SCOPE: ${stmts.length} rows across ${plan.length} politicians. Citations only -- NO stance value is modified.
-- Rollback: backend/data/stance-retirement/2026-08-11-md-member-slug-repair-1689-rollback.json
--
BEGIN
;

${stmts.join('\n\n')}

DO $$
DECLARE bad int;
BEGIN
  -- No politician may still cite THEIR OWN bad slug.
  -- ⚠ This check MUST be per politician, never corpus-wide: \`jones01\` is Adrienne A. Jones's WRONG
  -- slug and Dana Jones's CORRECT one, so a global "nobody cites jones01" assertion would fire on a
  -- correctly repaired row. Same shape of over-broad assertion as migs 1524/1530.
  -- ⚠ Where the repair only ADDS A SESSION to the same slug (Dan Cox: bare \`cox01\` is dead,
  -- \`cox01?ys=2023RS\` names him), the bad and good URLs share a slug. Asserting "no row cites cox01?%"
  -- matches the REPAIRED url, because \`?\` is a LITERAL in SQL LIKE, not a wildcard. For those entries
  -- assert only that the BARE form is gone. The first version of this guard failed on exactly that.
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE
    ${plan.map((p) => {
      const sameSlug = p.new_url.includes(`Details/${p.bad_slug}?`);
      const cond = sameSlug
        ? `s LIKE '%Members/Details/${p.bad_slug}'`
        : `(s LIKE '%Members/Details/${p.bad_slug}' OR s LIKE '%Members/Details/${p.bad_slug}?%')`;
      return `(c.politician_id = '${p.politician_id}'::uuid AND ${cond})`;
    }).join('\n    OR ')}
  );
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) still cite their own bad slug', bad; END IF;

  -- Every politician repaired here must end up citing their verified replacement URL on at least one row.
  SELECT count(*) INTO bad FROM (
    SELECT v.pid FROM (VALUES
      ${plan.map((p) => `('${p.politician_id}'::uuid, '${p.new_url.replace(/'/g, "''")}')`).join(',\n      ')}
    ) AS v(pid, newurl)
    WHERE NOT EXISTS (
      SELECT 1 FROM inform.politician_context c, unnest(c.sources) s
      WHERE c.politician_id = v.pid AND s = v.newurl
    )
  ) d;
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % politician(s) lack their replacement citation', bad; END IF;

  -- Nobody may be left sourceless, and no source array may contain duplicates.
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE c.politician_id = ANY(ARRAY[${plan.map((p) => `'${p.politician_id}'::uuid`).join(',')}])
    AND (c.sources IS NULL OR cardinality(c.sources) = 0);
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) left with no sources', bad; END IF;

  SELECT count(*) INTO bad FROM (
    SELECT c.politician_id, c.topic_id FROM inform.politician_context c
    WHERE c.politician_id = ANY(ARRAY[${plan.map((p) => `'${p.politician_id}'::uuid`).join(',')}])
    AND cardinality(c.sources) <> (SELECT count(DISTINCT s) FROM unnest(c.sources) s)
  ) d;
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) have duplicate sources', bad; END IF;
END
$$;

COMMIT
;
`;
fs.writeFileSync(SQL_OUT, sql);
console.log(`politicians   : ${plan.length}`);
console.log(`rows rewritten: ${stmts.length}`);
console.log(`rows untouched (slug not present): ${unchanged}`);
console.log(`wrong-person  : ${wrongPerson.length} (${wrongPerson.map((p) => p.politician).join(', ')})`);
console.log(`session-qualified: ${plan.filter((p) => p.form === 'SESSION_QUALIFIED').map((p) => p.politician).join(', ')}`);
