/**
 * sourceProfiles — one Markdown file per official record source (docs/sources/**), with a YAML header
 * that CONFIRM reads (spec 2026-09-26-source-profiles-design.md). The header CHOOSES from rule kinds
 * defined in recordBasis.ts; it never holds a regex. Validation is strict: an unknown key, an unknown
 * rule kind, a missing field or no `pass` control stops the run, naming the file and the key.
 * COLLECTOR/CONFIRM ONLY — coders never see a profile (their input stays byte-exact).
 */
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { load as yamlLoad } from 'js-yaml';
import { CHAMBER_RULES, NAME_FORMATS, VOTE_BLOCK_RULES, seatChamber, type Chamber, type SourceRules } from './recordBasis.js';

export type PageKind = 'vote' | 'author' | 'bill-text' | 'minutes';
const PAGE_KINDS: readonly PageKind[] = ['vote', 'author', 'bill-text', 'minutes'];
const CONTROL_RECORD_KINDS = ['vote', 'sponsor', 'author', 'other-act'] as const;
export interface ProfileControl {
  batch: string; snapshot: string; person: string; office_title: string; instrument: string;
  record_kind: (typeof CONTROL_RECORD_KINDS)[number]; actor_quote: string; tally_quote: string | null; expect: string;
}
export interface SourceProfile {
  profile: string; version: number; scope: string; body: string; url_prefixes: string[]; page_kind: PageKind;
  rules: SourceRules; seat_titles: Record<string, Chamber>; controls: ProfileControl[]; file: string;
}

export const SOURCES_DIR = fileURLToPath(new URL('../../../docs/sources/', import.meta.url));
const TOP_KEYS = ['profile', 'version', 'scope', 'body', 'match', 'page_kind', 'rules', 'seat_titles', 'controls'];
const RULE_KEYS = ['vote_block', 'chamber', 'not_chamber_after', 'name_format'];
const CONTROL_KEYS = ['batch', 'snapshot', 'person', 'office_title', 'instrument', 'record_kind', 'actor_quote', 'tally_quote', 'expect'];

const isObj = (v: unknown): v is Record<string, unknown> => typeof v === 'object' && v !== null && !Array.isArray(v);
const str = (v: unknown): v is string => typeof v === 'string' && v.trim().length > 0;

export function parseSourceProfile(md: string, file: string): SourceProfile {
  const fail = (msg: string): never => { throw new Error(`${file}: ${msg}`); };
  const m = /^---\r?\n([\s\S]*?)\r?\n---\r?\n?/.exec(md);
  if (!m) fail('no front matter (a profile starts with a --- YAML header ---)');
  const h = yamlLoad(m![1]);
  if (!isObj(h)) return fail('front matter is not a mapping');
  for (const k of Object.keys(h)) if (!TOP_KEYS.includes(k)) fail(`unknown key "${k}"`);
  for (const k of TOP_KEYS) if (h[k] === undefined) fail(`missing "${k}"`);
  if (!str(h.profile)) fail('profile must be a non-empty string');
  if (!Number.isInteger(h.version) || (h.version as number) < 1) fail('version must be an integer >= 1');
  if (!str(h.scope) || !/^(state|county|place):[A-Za-z0-9]+$/.test(h.scope as string)) fail(`scope "${String(h.scope)}" must be state:<USPS> | county:<fips> | place:<geoid>`);
  if (!str(h.body)) fail('body must be a non-empty string');
  if (!isObj(h.match)) return fail('match must be a mapping');
  for (const k of Object.keys(h.match)) if (k !== 'url_prefixes') fail(`unknown key "match.${k}"`);
  const prefixes = h.match.url_prefixes;
  if (!Array.isArray(prefixes) || prefixes.length === 0 || !prefixes.every((u) => str(u) && /^https?:\/\//.test(u as string))) fail('match.url_prefixes must be a non-empty list of http(s) URLs');
  if (!PAGE_KINDS.includes(h.page_kind as PageKind)) fail(`page_kind "${String(h.page_kind)}" is not one of ${PAGE_KINDS.join(' | ')}`);
  if (!isObj(h.rules)) return fail('rules must be a mapping');
  for (const k of Object.keys(h.rules)) if (!RULE_KEYS.includes(k)) fail(`unknown key "rules.${k}"`);
  const r = h.rules;
  if (!VOTE_BLOCK_RULES.includes(r.vote_block as never)) fail(`rules.vote_block "${String(r.vote_block)}" is not one of ${VOTE_BLOCK_RULES.join(' | ')}`);
  if (!CHAMBER_RULES.includes(r.chamber as never)) fail(`rules.chamber "${String(r.chamber)}" is not one of ${CHAMBER_RULES.join(' | ')}`);
  if (r.chamber === 'bill-origin' && h.page_kind !== 'author' && h.page_kind !== 'bill-text') {
    fail('rules.chamber bill-origin is only valid for page_kind author | bill-text');
  }
  if (!NAME_FORMATS.includes(r.name_format as never)) fail(`rules.name_format "${String(r.name_format)}" is not one of ${NAME_FORMATS.join(' | ')}`);
  const extra = r.not_chamber_after ?? [];
  if (!Array.isArray(extra) || !extra.every((w) => str(w) && /^[a-z0-9]+$/i.test(w as string))) fail('rules.not_chamber_after must be a list of single words');
  if (!isObj(h.seat_titles)) return fail('seat_titles must be a mapping');
  for (const [t, c] of Object.entries(h.seat_titles)) if (c !== 'upper' && c !== 'lower') fail(`seat_titles.${t} "${String(c)}" must be upper | lower`);
  if (!Array.isArray(h.controls)) return fail('controls must be a list');
  h.controls.forEach((c, n) => {
    if (!isObj(c)) return fail(`controls[${n}] must be a mapping`);
    for (const k of Object.keys(c)) if (!CONTROL_KEYS.includes(k)) fail(`unknown key "controls[${n}].${k}"`);
    for (const k of CONTROL_KEYS) if (k !== 'tally_quote' && !str(c[k])) fail(`missing "controls[${n}].${k}"`);
    if (!CONTROL_RECORD_KINDS.includes(c.record_kind as never)) fail(`controls[${n}].record_kind "${String(c.record_kind)}" is not one of ${CONTROL_RECORD_KINDS.join(' | ')}`);
    if (c.tally_quote !== undefined && c.tally_quote !== null && !str(c.tally_quote)) fail(`controls[${n}].tally_quote must be a string or null`);
  });
  if (!(h.controls as Record<string, unknown>[]).some((c) => c.expect === 'pass')) fail('needs at least one control with expect: pass');
  return {
    profile: h.profile as string, version: h.version as number, scope: h.scope as string, body: h.body as string,
    url_prefixes: prefixes as string[], page_kind: h.page_kind as PageKind,
    rules: { vote_block: r.vote_block, chamber: r.chamber, not_chamber_after: extra as string[], name_format: r.name_format } as SourceRules,
    seat_titles: h.seat_titles as Record<string, Chamber>,
    controls: (h.controls as Record<string, unknown>[]).map((c) => ({ ...c, tally_quote: (c.tally_quote as string | undefined) ?? null }) as ProfileControl),
    file,
  };
}

const mdFiles = (dir: string): string[] => readdirSync(dir).flatMap((n) => {
  const p = join(dir, n);
  if (statSync(p).isDirectory()) return mdFiles(p);
  return n.endsWith('.md') && n !== 'README.md' ? [p] : [];
});

export function loadSourceProfiles(dir: string = SOURCES_DIR): SourceProfile[] {
  const profiles = mdFiles(dir).sort().map((f) => parseSourceProfile(readFileSync(f, 'utf8'), relative(dir, f)));
  const ids = new Map<string, string>(); const prefixes = new Map<string, string>();
  for (const p of profiles) {
    if (ids.has(p.profile)) throw new Error(`duplicate profile "${p.profile}" in ${ids.get(p.profile)} and ${p.file}`);
    ids.set(p.profile, p.file);
    for (const u of p.url_prefixes) {
      if (prefixes.has(u)) throw new Error(`url prefix ${u} in both ${prefixes.get(u)} and ${p.file}`);
      prefixes.set(u, p.file);
    }
  }
  return profiles;
}

export function resolveProfile(profiles: readonly SourceProfile[], url: string): SourceProfile | null {
  let best: SourceProfile | null = null; let len = -1;
  for (const p of profiles) for (const u of p.url_prefixes) if (url.startsWith(u) && u.length > len) { best = p; len = u.length; }
  return best;
}

export function profileSeatChamber(p: SourceProfile, officeTitle: string | null | undefined): Chamber | null {
  const t = (officeTitle ?? '').trim().toLowerCase();
  for (const [title, c] of Object.entries(p.seat_titles)) if (title.toLowerCase() === t) return c;
  return seatChamber(officeTitle);
}

export const profileTag = (p: SourceProfile): string => `${p.profile}@${p.version}`;
