/**
 * readOnlyQuery — run one SQL file inside a read-only transaction that is always rolled back.
 *
 * Why: a runner or a blind drafter needs to look at the database without any chance of changing
 * it. `BEGIN READ ONLY` makes Postgres itself refuse every write (INSERT, UPDATE, DDL) for the
 * life of the transaction, and the closing ROLLBACK means even a function with side effects
 * leaves nothing behind.
 *
 * The one way out of that wrapper is SQL that ends the transaction itself: a `COMMIT;` (or
 * `END;`, `ROLLBACK;`, `ABORT;`) followed by a write runs that write in a fresh, writable
 * transaction. `refuseTransactionControl` stops such files before they reach the database.
 *
 * The guard is crude on purpose, and says so: it strips `--` and `/* *\/` comments, single-quoted
 * strings, dollar-quoted bodies and double-quoted identifiers, then looks for the keywords with a
 * regex. It does not parse SQL. It can refuse a harmless file (an unquoted column called `begin`);
 * it should not let a transaction-control statement through.
 */

export interface QueryResultLike {
  fields?: Array<{ name: string }>;
  rows?: Record<string, unknown>[];
}

/** The slice of a pg client or pool this module needs. */
export interface ReadOnlyClient {
  query(sql: string): Promise<QueryResultLike | QueryResultLike[]>;
}

export interface ReadOnlyResult {
  fields: string[];
  rows: Record<string, unknown>[];
}

export class TransactionControlError extends Error {}

/** Remove comments, string literals, dollar-quoted bodies and quoted identifiers. */
export function stripLiterals(sql: string): string {
  return sql
    .replace(/\/\*[\s\S]*?\*\//g, ' ')
    .replace(/--[^\n]*/g, ' ')
    .replace(/\$([A-Za-z_][A-Za-z0-9_]*)?\$[\s\S]*?\$\1\$/g, ' ')
    .replace(/'(?:[^']|'')*'/g, ' ')
    .replace(/"(?:[^"]|"")*"/g, ' ');
}

const ANYWHERE = /\b(COMMIT|ROLLBACK|ABORT|BEGIN|START\s+TRANSACTION|SET\s+TRANSACTION|SET\s+SESSION\s+CHARACTERISTICS)\b/i;
// END also closes a CASE expression, so it only counts at the start of a statement.
const END_STATEMENT = /(^|;)\s*END\b/i;

/** Throw when the SQL ends, opens or reconfigures a transaction itself. */
export function refuseTransactionControl(sql: string): void {
  const bare = stripLiterals(sql);
  const m = bare.match(ANYWHERE) ?? bare.match(END_STATEMENT);
  if (m) {
    const word = (m[1] && m[1] !== ';' ? m[1] : 'END').replace(/\s+/g, ' ').toUpperCase();
    throw new TransactionControlError(
      `refused: the SQL contains ${word}, which would escape the read-only wrapper. Remove it; the runner opens and rolls back the transaction itself.`);
  }
}

/**
 * Run `sql` inside BEGIN READ ONLY and always ROLLBACK, also when the query fails (the original
 * error is re-thrown). Several statements in one file give pg an array of results; the last one is
 * returned.
 */
export async function runReadOnly(client: ReadOnlyClient, sql: string): Promise<ReadOnlyResult> {
  refuseTransactionControl(sql);
  await client.query('BEGIN READ ONLY');
  try {
    const res = await client.query(sql);
    const last = Array.isArray(res) ? res[res.length - 1] : res;
    return { fields: (last?.fields ?? []).map((f) => f.name), rows: last?.rows ?? [] };
  } finally {
    await client.query('ROLLBACK');
  }
}

function cell(v: unknown): string {
  if (v === null || v === undefined) return 'NULL';
  if (v instanceof Date) return v.toISOString();
  if (typeof v === 'object') return JSON.stringify(v);
  return String(v);
}

/** Plain aligned text: a header, a rule, one line per row, and a row count. */
export function formatTable(fields: string[], rows: Record<string, unknown>[]): string {
  if (fields.length === 0) return `(no columns; ${rows.length} rows)`;
  const table = [fields, ...rows.map((r) => fields.map((f) => cell(r[f])))];
  const w = fields.map((_, i) => Math.max(...table.map((row) => row[i].length)));
  const line = (row: string[]) => row.map((c, i) => c.padEnd(w[i])).join('  ').trimEnd();
  const out = [line(fields), w.map((n) => '-'.repeat(n)).join('  '), ...table.slice(1).map(line)];
  return `${out.join('\n')}\n(${rows.length} ${rows.length === 1 ? 'row' : 'rows'})`;
}
