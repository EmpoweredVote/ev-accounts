// The Bloomington names file (data/local-record/bloomington-in/names.json) against the council roster.
// The roster is a copy of the workspace inventory's roster.json (__fixtures__/bloomington-in-roster.json).
import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { normaliseName, resolveName, type NameFile, type TermSpan } from './names.js';

interface NamesFileEntry {
  key: string;
  name: string;
  politicianId: string | null;
  onboardId: string | null;
  variants: string[];
}
interface NamesFileJson {
  city: string;
  members: NamesFileEntry[];
}
interface RosterJson {
  city: { scope: string };
  members: { name: string; seat: string; from: string; to: string | null; source_url: string }[];
}

const names: NamesFileJson = JSON.parse(
  readFileSync(new URL('../../../data/local-record/bloomington-in/names.json', import.meta.url), 'utf8'),
);
const roster: RosterJson = JSON.parse(
  readFileSync(new URL('./__fixtures__/bloomington-in-roster.json', import.meta.url), 'utf8'),
);

/** The person key for a roster name: the surname as a slug ("Isabel Piedmont-Smith" -> "piedmont-smith"). */
const surnameOf = (full: string) => full.trim().split(/\s+/).pop()!;
const keyOf = (full: string) => normaliseName(surnameOf(full));

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const pendingIds = names.members.filter((m) => m.politicianId === null).map((m) => m.key);

describe('names.json (Bloomington)', () => {
  it('is for the roster city', () => {
    expect(names.city).toBe(roster.city.scope);
  });

  it('has one entry per person key, each with a non-empty variant list', () => {
    const keys = names.members.map((m) => m.key);
    expect(new Set(keys).size).toBe(keys.length);
    for (const m of names.members) {
      expect(m.variants.length, m.key).toBeGreaterThan(0);
      for (const v of m.variants) expect(normaliseName(v), `${m.key}: "${v}"`).not.toBe('');
      expect(m.politicianId === null || UUID.test(m.politicianId), `${m.key}: politicianId`).toBe(true);
    }
  });

  it('lists every roster member under their surname key, with the full name and surname as variants', () => {
    for (const r of roster.members) {
      const m = names.members.find((x) => x.key === keyOf(r.name));
      expect(m, r.name).toBeDefined();
      const forms = m!.variants.map(normaliseName);
      expect(forms, r.name).toContain(normaliseName(r.name));
      expect(forms, r.name).toContain(normaliseName(surnameOf(r.name)));
    }
  });

  it('lists nobody who is not on the roster', () => {
    const rosterKeys = new Set(roster.members.map((r) => keyOf(r.name)));
    for (const m of names.members) expect(rosterKeys.has(m.key), m.key).toBe(true);
  });

  it('maps no printed variant to two people', () => {
    const owner = new Map<string, string>();
    for (const m of names.members) {
      for (const v of m.variants) {
        const n = normaliseName(v);
        const prev = owner.get(n);
        expect(prev === undefined || prev === m.key, `"${v}" is listed for ${prev} and ${m.key}`).toBe(true);
        owner.set(n, m.key);
      }
    }
  });

  it('maps no politician id to two people', () => {
    const ids = names.members.map((m) => m.politicianId).filter((x): x is string => x !== null);
    expect(new Set(ids).size).toBe(ids.length);
  });

  const resolvesTitle =
    pendingIds.length > 0
      ? `every roster surname resolves on a date inside its span — SKIPPED: ${pendingIds.length} politicianId(s) ` +
        `are still null (${pendingIds.join(', ')}); fill them from a read-only lookup after the people migration is applied`
      : 'every roster surname resolves on a date inside its span';

  it.skipIf(pendingIds.length > 0)(resolvesTitle, () => {
    const file = names as unknown as NameFile;
    const idOf = (full: string) => names.members.find((m) => m.key === keyOf(full))!.politicianId!;
    const terms: TermSpan[] = roster.members.map((r) => ({ politicianId: idOf(r.name), start: r.from, end: r.to }));
    for (const r of roster.members) {
      const dates = [r.from, r.to ?? '2026-11-26'];
      for (const d of dates) {
        for (const printed of [surnameOf(r.name), r.name]) {
          expect(resolveName(printed, d, file, terms), `${printed} on ${d}`).toEqual({ politicianId: idOf(r.name) });
        }
      }
    }
  });
});
