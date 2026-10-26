// SQL helpers for the PostgREST -> pg port.
//
// 🔴 TIMESTAMPS ARE SELECTED AS PostgREST WOULD HAVE SENT THEM. node-pg parses timestamptz
// into a JS Date, which JSON-serialises at MILLISECOND precision ('...T00:00:00.123Z').
// PostgREST sent the Postgres JSON form at MICROSECOND precision ('...T00:00:00.123456+00:00').
// Two things depend on the old form: (1) the response bodies the frontend already parses, and
// (2) the pagination cursors, which embed a row's timestamp and compare against it — a
// millisecond-truncated cursor would re-serve or skip rows that share a millisecond.
// `to_json(col) #>> '{}'` yields exactly the PostgREST text.
export function ts(column: string, alias = column.split('.').pop()!): string {
  return `to_json(${column}) #>> '{}' AS ${alias}`;
}
