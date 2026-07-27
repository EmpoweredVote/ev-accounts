// pg returns timestamptz columns as JS Date objects (no type parsers are
// registered in db.ts). Normalize to an ISO-8601 UTC string at the mapper
// boundary so service DTOs are honestly `string | null`. Meeting-local
// rendering uses the separate `timezone` column.
export function toIsoStringOrNull(value: string | Date | null | undefined): string | null {
  if (value == null) return null;
  return value instanceof Date ? value.toISOString() : value;
}
