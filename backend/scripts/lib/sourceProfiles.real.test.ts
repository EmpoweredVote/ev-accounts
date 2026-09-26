/**
 * The real profiles in docs/sources: each loads, and each control runs on its real saved page with the
 * expected result. A profile with a failing control is a rule that does not match its own source.
 */
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { loadSourceProfiles, resolveProfile, profileSeatChamber } from './sourceProfiles.js';
import { checkRecordGroup, instrumentKey, seatChamber } from './recordBasis.js';
import type { Passage } from './coderLabel.js';

const batchDir = (b: string) => fileURLToPath(new URL(`../../data/stance-research/${b}/`, import.meta.url));
const snapshots = (b: string) => JSON.parse(readFileSync(`${batchDir(b)}snapshots.json`, 'utf8')) as { snapshot_id: string; url: string; ok: boolean; snapshot_text: string | null }[];
const profiles = loadSourceProfiles();
// Findings a control does not judge: they are about the content of a passage, not the page layout.
const CONTENT_FINDINGS = new Set(['provision-missing', 'near-unanimous-vote']);

describe('real source profiles', () => {
  it('there are at least the four first profiles', () =>
    expect(profiles.map((p) => p.profile).sort()).toEqual(expect.arrayContaining(['ca-leginfo-bill-text', 'ca-leginfo-bill-votes', 'in-iga-bill-details', 'in-iga-roll-call'])));
  for (const p of profiles) for (const [n, c] of p.controls.entries()) {
    it(`${p.file} control ${n}: ${c.snapshot} → ${c.expect}`, () => {
      const snap = snapshots(c.batch).find((s) => s.snapshot_id.startsWith(c.snapshot));
      expect(snap, `snapshot ${c.snapshot} in ${c.batch}`).toBeDefined();
      expect(resolveProfile(profiles, snap!.url)?.profile, 'the control page resolves to this profile').toBe(p.profile);
      const passage: Passage = { snapshot_id: snap!.snapshot_id, v1_attribution: 'own-act', v2_relevance: 'on-question', v3_class: 'record',
        v4_shape: 'chair-shaped', v5_time: 'in-term', instrument: c.instrument, record_kind: c.record_kind, actor_quote: c.actor_quote,
        tally_quote: c.tally_quote, provision_quote: null, date: null };
      const f = checkRecordGroup({ passages: [passage], snapshotText: new Map([[snap!.snapshot_id, snap!.snapshot_text ?? '']]), fullName: c.person,
        chamber: null, profileOf: () => ({ rules: p.rules, chamber: profileSeatChamber(p, c.office_title) }) }).findings.filter((x) => !CONTENT_FINDINGS.has(x));
      if (c.expect === 'pass') expect(f).toEqual([]); else expect(f).toContain(c.expect);
    });
  }
});

// Fix round 1: the IN bill-listing page prints only "Senate Bill 208" / "Senate Bill 170", never the
// short form, but all three Yoder coders wrote "SB 208" / "SB 170" — before the long-form fix
// (coderLabel.ts normalizeInstrumentForm) this was 6 false instrument-mismatch findings (2 bills x 3
// coders). Pinned below so a regression on either mapping direction is caught.
const NO_LONGER_MISMATCHED = new Set([instrumentKey('SB 208 (2024)'), instrumentKey('SB 170 (2022)')]);

describe('the two shadow batches under their profiles', () => {
  for (const [b, name] of [['2026-09-25-shadow-yoder', 'Shelli Yoder'], ['2026-09-25-shadow-durazo', 'Maria Elena Durazo']] as const) {
    it(`${b}: every record group gives the same findings as the generic rules, and every record page has a profile`, () => {
      const snaps = snapshots(b).filter((s) => s.ok);
      const text = new Map(snaps.map((s) => [s.snapshot_id, s.snapshot_text ?? '']));
      const url = new Map(snaps.map((s) => [s.snapshot_id, s.url]));
      for (const slot of [1, 2, 3]) {
        const rows = JSON.parse(readFileSync(`${batchDir(b)}labels/coder-${slot}.json`, 'utf8')).rows as { passages?: Passage[] }[];
        for (const r of rows) {
          const groups = new Map<string, Passage[]>();
          for (const p of r.passages ?? []) if (p.v3_class === 'record') { const k = instrumentKey(p.instrument) ?? '∅'; groups.set(k, [...(groups.get(k) ?? []), p]); }
          for (const [k, g] of groups.entries()) {
            for (const p of g) expect(resolveProfile(profiles, url.get(p.snapshot_id) ?? ''), `profile for ${url.get(p.snapshot_id)}`).not.toBeNull();
            const generic = checkRecordGroup({ passages: g, snapshotText: text, fullName: name, chamber: seatChamber('Senator') }).findings.sort();
            const profiled = checkRecordGroup({ passages: g, snapshotText: text, fullName: name, chamber: seatChamber('Senator'),
              profileOf: (p) => { const pr = resolveProfile(profiles, url.get(p.snapshot_id) ?? '')!; return { rules: pr.rules, chamber: profileSeatChamber(pr, 'Senator') }; } }).findings.sort();
            expect(profiled).toEqual(generic);
            if (b === '2026-09-25-shadow-yoder' && NO_LONGER_MISMATCHED.has(k)) {
              expect(generic, `${b} slot ${slot} group ${k}: no instrument-mismatch (long-form fix)`).not.toContain('instrument-mismatch');
            }
          }
        }
      }
    });
  }
});

describe('coders never see profiles', () => {
  it('build-coder-inputs.ts and coderPrompt.ts do not read docs/sources or sourceProfiles', () => {
    for (const f of ['../build-coder-inputs.ts', './coderPrompt.ts']) {
      const src = readFileSync(fileURLToPath(new URL(f, import.meta.url)), 'utf8');
      expect(src, f).not.toMatch(/docs\/sources|sourceProfiles/);
    }
  });
});
