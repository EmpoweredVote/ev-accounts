import { describe, it, expect } from 'vitest';
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = new URL('../../', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
const MIGRATIONS = join(ROOT, 'migrations');

const journalMigration = (): string => {
  const f = readdirSync(MIGRATIONS).find((n) => n.includes('compass_topic_journal'));
  if (!f) throw new Error('no compass_topic_journal migration found');
  return readFileSync(join(MIGRATIONS, f), 'utf8');
};

/**
 * The DDL with `--` comments blanked out.
 *
 * ⚠ NOT OPTIONAL, AND IT FAILED WITHOUT IT. The migration's own header explains
 * the rule by naming the columns it forbids — "a parent_id or reply_to column
 * here is what losing that decision looks like" — so a scan of the raw file
 * reports the warning as the violation. Lines are blanked rather than deleted so
 * any line number in a failure still points at the right place.
 */
const ddlOnly = (sql: string): string =>
  sql.replace(/--[^\n]*/g, (m) => ' '.repeat(m.length));

/**
 * 🔴 THE DECISION THIS PROTECTS, IN FULL, BECAUSE THE FAILURE MESSAGE IS THE
 * ONLY PLACE THE NEXT PERSON WILL READ IT.
 *
 * The Compass PUBLISHES journal entries. Focused Communities HOSTS the
 * conversation about them, in FC's own tables, keyed to these ids. FC is a
 * separate product with moderation, tier gating and pseudonymity rules that
 * this table has none of.
 *
 * Adding replies here is always one small column, and it always arrives with a
 * good reason. That is what losing the decision looks like. If replies are
 * genuinely needed before FC ships, that is a product decision to take
 * deliberately — delete this test in the same commit, and say why.
 */
describe('the journal is not a forum', () => {
  const FORBIDDEN = [
    'parent_id', 'reply_to', 'reply_id', 'in_reply_to',
    'thread_id', 'reaction', 'upvote', 'vote_count', 'comment_count',
  ];

  it('the table has no reply or reaction column', () => {
    const sql = ddlOnly(journalMigration()).toLowerCase();
    const found = FORBIDDEN.filter((c) => sql.includes(c));
    expect(found, `forbidden column(s) in the journal table: ${found.join(', ')}. ` +
      'The Compass publishes; Focused Communities hosts the conversation. See the ' +
      'header of this test before adding one.').toEqual([]);
  });

  /**
   * answers_id is the one self-reference, and it exists so a 'changed' entry can
   * point at the 'watching' entry it settles. Following it a SECOND hop is a
   * thread by another name.
   *
   * ⚠ This asserts the TRAVERSAL, not an occurrence count. The plan proposed
   * counting `answers_id` mentions and failing above four — which is exactly how
   * many the finished service has, so a single added comment naming the column
   * would have failed it. A count grades verbosity; what matters is whether the
   * code walks the link. Walking it requires either recursion or selecting rows
   * BY answers_id, so those are what this looks for.
   */
  it('never walks answers_id a second hop', () => {
    const svc = readFileSync(join(ROOT, 'src/lib/compassJournalService.ts'), 'utf8');
    expect(svc, 'a recursive CTE over the journal is a thread query')
      .not.toMatch(/WITH RECURSIVE/i);
    expect(svc, 'selecting journal rows BY answers_id is following the link, which is a thread')
      .not.toMatch(/answers_id\s*=\s*\$/);
  });

  it('the table still carries its own warning', () => {
    expect(journalMigration()).toMatch(/NOT A FORUM/i);
  });
});
