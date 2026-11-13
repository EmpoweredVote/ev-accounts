/**
 * stage5CoderInputs.ts — Stage 5 coding: the lean inputs one coder batch reads.
 *
 * Two pieces, both pure:
 *
 * - `compactBatch` writes one findings file per batch: this topic's findings only, with the source-tracking
 *   fields a coder never judges on dropped (`provenance`, `topic_keys`, other topics' gates, the search's `by`),
 *   each bill's subjects stated once in a `bills` table, and the search subjects stated once. Notes, passages,
 *   dates, acts, motions, gates and URLs stay word for word. `expandCompact` rebuilds every finding from it, and
 *   the CLI refuses to write a file whose rebuild differs from the store (no finding id lost, no field changed).
 *   Georgia, 204 people: 3.8M characters of findings files, about a quarter of that compacted.
 *
 * - `filterRulings` keeps only the rulings a batch needs. The digest is markdown: `## Heading {scope}` sections
 *   of `- ` bullets, a bullet may carry its own `{scope}` first. Scope is `all` (the default), `federal`, or
 *   `state:xx[,yy]`. A batch of state XX keeps `all` and the ones that list `xx`; a federal batch keeps `all`
 *   and `federal`. A ruling that names another state's bill only as an EXAMPLE of a general rule is `all`:
 *   tagging is a reading of the ruling, done once per topic by whoever builds the digest, never guessed here.
 */
import type { Finding, PersonFindings, Search } from './sourceStore.js';

/** What a coder sees of one finding. */
export interface CoderFinding {
  id: string;
  kind: Finding['kind'];
  url: string;
  date: string;
  date_precision: Finding['date_precision'];
  instrument_id?: string;
  act?: Finding['act'];
  motion?: string;
  /** This topic's census gate for a pre-filled vote (`none` = no gate). */
  gate?: string;
  local_record?: boolean;
  note: string;
  passage?: string;
  /** Left out when it equals the bill's subjects in the `bills` table. */
  subjects?: string[];
}

export interface CoderSearch { season: number; places: string[]; found: number; at: string; subjects?: string[] }

export interface CoderPerson {
  politician_id: string;
  name: string;
  level: string;
  state: string;
  scope: string;
  searches: CoderSearch[];
  findings: CoderFinding[];
}

export interface CompactBatch {
  about: string;
  topic_key: string;
  season: number;
  /** The subjects every search of this topic looked for, stated once (a search that differs keeps its own). */
  search_subjects: string[];
  /** Instrument id → its subjects (the most common list across the batch) and its store file. */
  bills: Record<string, { subjects: string[]; file?: string }>;
  people: CoderPerson[];
}

export interface RosterRow { politician_id: string; full_name: string; level: string; state: string; scope: string; office?: string }

/**
 * One line of the coder brief's batch list. The office title is what tells a coder what this seat can act on: a
 * State Auditor's old House votes are a record from another office (Missouri pilot, Scott Fitzpatrick: the
 * record-only coder saw "state, MO, sitting", seated him at rung 4, and only the second pass, which read his
 * office in the search notes, coded him doesn't fit).
 */
export function batchLine(row: RosterRow): string {
  const office = row.office?.trim() ? `${row.office.trim()}, ` : '';
  return `- ${row.politician_id} — ${row.full_name}, ${office}${row.level}, ${row.state.toUpperCase()}, ${row.scope}`;
}

const ABOUT = 'One file per coder batch. Each finding is as the source store holds it, minus source-tracking fields. '
  + 'A record finding\'s subjects are its bill\'s subjects in "bills" unless the finding lists its own. "gate" is this '
  + 'topic\'s census gate for a pre-filled vote (none = no gate). Each search\'s subjects are "search_subjects" unless '
  + 'it lists its own. Cite findings by "id".';

const key = (a: string[]) => JSON.stringify(a);
function mostCommon(lists: string[][]): string[] {
  const n = new Map<string, number>();
  for (const l of lists) n.set(key(l), (n.get(key(l)) ?? 0) + 1);
  let best = '[]'; let bestN = -1;
  for (const [k, c] of n) if (c > bestN) { best = k; bestN = c; }
  return JSON.parse(best) as string[];
}

/** The fields a coder reads, for one finding on one topic. The round-trip check compares exactly this. */
export function projectFinding(f: Finding, topicKey: string): CoderFinding {
  const o = { id: f.id, kind: f.kind, url: f.url, date: f.date, date_precision: f.date_precision } as CoderFinding;
  if (f.instrument_id !== undefined) o.instrument_id = f.instrument_id;
  if (f.act !== undefined) o.act = f.act;
  if (f.motion !== undefined) o.motion = f.motion;
  const g = f.gate_by_topic?.[topicKey];
  if (g !== undefined) o.gate = g;
  if (f.local_record !== undefined) o.local_record = f.local_record;
  o.note = f.note;
  if (f.passage !== undefined) o.passage = f.passage;
  o.subjects = f.subjects;
  return o;
}

export function projectSearch(s: Search): CoderSearch {
  return { season: s.season, places: s.places, found: s.found, at: s.at, subjects: s.subjects };
}

/** This topic's findings, of the kinds asked for (all kinds when none are named). */
export function onTopic(pf: PersonFindings | undefined, topicKey: string, kinds?: ReadonlySet<Finding['kind']>): Finding[] {
  return (pf?.findings ?? []).filter((f) => f.topic_keys.includes(topicKey) && (!kinds || kinds.has(f.kind)));
}

/**
 * This topic's findings and this topic-and-season's searches, per person, in the roster's order. `kinds`
 * limits the findings, for the record-first pass (`new Set(['record'])`): coded on their record alone.
 */
export function compactBatch(
  people: { row: RosterRow; pf: PersonFindings | undefined }[], topicKey: string, season: number,
  instrumentFile: (id: string) => string | undefined, kinds?: ReadonlySet<Finding['kind']>,
): CompactBatch {
  const projected = people.map(({ row, pf }) => ({
    row,
    findings: onTopic(pf, topicKey, kinds).map((f) => projectFinding(f, topicKey)),
    searches: (pf?.searches ?? []).filter((s) => s.topic_key === topicKey && s.season === season).map(projectSearch),
  }));
  const byBill = new Map<string, string[][]>();
  for (const p of projected) for (const f of p.findings) if (f.instrument_id) {
    byBill.set(f.instrument_id, [...(byBill.get(f.instrument_id) ?? []), f.subjects ?? []]);
  }
  const bills: CompactBatch['bills'] = {};
  for (const id of [...byBill.keys()].sort()) {
    const file = instrumentFile(id);
    bills[id] = file ? { subjects: mostCommon(byBill.get(id)!), file } : { subjects: mostCommon(byBill.get(id)!) };
  }
  const searchSubjects = mostCommon(projected.flatMap((p) => p.searches.map((s) => s.subjects ?? [])));
  return {
    about: ABOUT, topic_key: topicKey, season, search_subjects: searchSubjects, bills,
    people: projected.map(({ row, findings, searches }) => ({
      politician_id: row.politician_id, name: row.full_name, level: row.level, state: row.state, scope: row.scope,
      searches: searches.map((s) => {
        if (key(s.subjects ?? []) !== key(searchSubjects)) return s;
        const { subjects: _drop, ...rest } = s;
        return rest;
      }),
      findings: findings.map((f) => {
        if (!f.instrument_id || key(f.subjects ?? []) !== key(bills[f.instrument_id].subjects)) return f;
        const { subjects: _drop, ...rest } = f;
        return rest;
      }),
    })),
  };
}

/** Rebuilds every person's projected findings and searches from a compact batch. */
export function expandCompact(c: CompactBatch): Map<string, { findings: CoderFinding[]; searches: CoderSearch[] }> {
  const out = new Map<string, { findings: CoderFinding[]; searches: CoderSearch[] }>();
  for (const p of c.people) {
    out.set(p.politician_id, {
      findings: p.findings.map((f) => {
        const full = { ...f, subjects: f.subjects ?? (f.instrument_id ? c.bills[f.instrument_id]?.subjects : undefined) };
        const { note, passage, subjects, ...head } = full;
        const o: CoderFinding = { ...head, note } as CoderFinding;
        if (passage !== undefined) o.passage = passage;
        o.subjects = subjects;
        return o;
      }),
      searches: p.searches.map((s) => ({ ...s, subjects: s.subjects ?? c.search_subjects })),
    });
  }
  return out;
}

/** Differences between the store and a compact batch, in plain words; empty means nothing was lost. */
export function roundTripProblems(people: { row: RosterRow; pf: PersonFindings | undefined }[], c: CompactBatch, topicKey: string, season: number, kinds?: ReadonlySet<Finding['kind']>): string[] {
  const out: string[] = [];
  const back = expandCompact(c);
  for (const { row, pf } of people) {
    const want = onTopic(pf, topicKey, kinds).map((f) => projectFinding(f, topicKey));
    const wantS = (pf?.searches ?? []).filter((s) => s.topic_key === topicKey && s.season === season).map(projectSearch);
    const got = back.get(row.politician_id);
    if (!got) { out.push(`${row.full_name}: missing from the compact file`); continue; }
    const gotIds = new Set(got.findings.map((f) => f.id));
    for (const f of want) if (!gotIds.has(f.id)) out.push(`${row.full_name}: finding ${f.id.slice(0, 12)}… lost`);
    if (got.findings.length !== want.length) out.push(`${row.full_name}: ${want.length} findings in the store, ${got.findings.length} in the compact file`);
    if (JSON.stringify(got.findings) !== JSON.stringify(want)) out.push(`${row.full_name}: a finding's fields differ from the store`);
    if (JSON.stringify(got.searches) !== JSON.stringify(wantS)) out.push(`${row.full_name}: a search differs from the store`);
  }
  return out;
}

// ---------- rulings digest ----------

export interface RulingScope { all: boolean; federal: boolean; states: string[] }

function parseScope(tag: string | undefined): RulingScope | undefined {
  if (tag === undefined) return undefined;
  const t = tag.trim().toLowerCase();
  if (t === 'all') return { all: true, federal: false, states: [] };
  if (t === 'federal') return { all: false, federal: true, states: [] };
  const m = /^state:([a-z]{2}(?:\s*,\s*[a-z]{2})*)$/.exec(t);
  if (!m) throw new Error(`bad ruling scope {${tag}}: use {all}, {federal} or {state:xx[,yy]}`);
  return { all: false, federal: false, states: m[1].split(',').map((s) => s.trim()) };
}

const TAG_RE = /\s*\{((?:all|federal|state:[a-zA-Z, ]+))\}\s*/;

export interface FilteredRulings { text: string; kept: number; dropped: string[] }

/**
 * Keeps the rulings a unit needs: `unit` is `federal` or `state:xx`. Headings and paragraphs are kept with
 * their section when any of its bullets is kept (or the section has no bullets and its scope fits); every tag
 * is removed from what the coder reads. Each dropped bullet comes back in `dropped`, for the runner to read.
 */
export function filterRulings(md: string, unit: string): FilteredRulings {
  const isFederal = unit === 'federal';
  const st = /^state:([a-z]{2})$/.exec(unit)?.[1];
  if (!isFederal && !st) throw new Error(`unit must be federal or state:xx, got ${unit}`);
  const fits = (s: RulingScope) => s.all || (isFederal ? s.federal : s.states.includes(st!));

  type Block = { kind: 'head' | 'para' | 'bullet'; lines: string[]; scope?: RulingScope };
  const sections: { head?: Block; scope: RulingScope; blocks: Block[] }[] = [{ scope: { all: true, federal: false, states: [] }, blocks: [] }];
  for (const line of md.split('\n')) {
    const cur = sections[sections.length - 1];
    if (/^#{1,6}\s/.test(line)) {
      const m = TAG_RE.exec(line);
      const scope = parseScope(m?.[1]) ?? { all: true, federal: false, states: [] };
      sections.push({ head: { kind: 'head', lines: [m ? line.replace(TAG_RE, ' ').trimEnd() : line] }, scope, blocks: [] });
    } else if (/^- /.test(line)) {
      const m = /^- \{([^}]+)\}\s*/.exec(line);
      cur.blocks.push({ kind: 'bullet', lines: [m ? `- ${line.slice(m[0].length)}` : line], scope: parseScope(m?.[1]) });
    } else if (/^\s+\S/.test(line) && cur.blocks.length && cur.blocks[cur.blocks.length - 1].kind === 'bullet') {
      cur.blocks[cur.blocks.length - 1].lines.push(line);
    } else {
      const last = cur.blocks[cur.blocks.length - 1];
      if (line.trim() === '' || !last || last.kind !== 'para') cur.blocks.push({ kind: 'para', lines: [line] });
      else last.lines.push(line);
    }
  }
  const out: string[] = [];
  const dropped: string[] = [];
  let kept = 0;
  for (const sec of sections) {
    const bullets = sec.blocks.filter((b) => b.kind === 'bullet');
    const keep = (b: Block) => fits(b.scope ?? sec.scope);
    const anyKept = bullets.length ? bullets.some(keep) : fits(sec.scope);
    for (const b of bullets) if (!keep(b)) dropped.push(b.lines.join(' ').replace(/\s+/g, ' '));
    if (!anyKept) continue;
    if (sec.head) out.push(...sec.head.lines);
    for (const b of sec.blocks) {
      if (b.kind === 'bullet' && !keep(b)) continue;
      if (b.kind === 'bullet') kept++;
      out.push(...b.lines);
    }
  }
  return { text: out.join('\n').replace(/\n{3,}/g, '\n\n').trim() + '\n', kept, dropped };
}

// ---------- collapsed record (round three, adjustment 2) ----------

/** One row of the state's bill table (`bill_table.py`): what a Yes on the bill supports. */
export interface BillTableRow { rung: number | null; deciding_words?: string; why?: string; flag?: string; opus?: string }

/** A roll call the pre-fill wrote in its fixed sentence: `[finding id, date, body, tally, gate]`. */
export type VoteRef = [id: string, date: string, body: string, tally: string, gate: string];
/** A sponsorship the pre-fill wrote in its fixed sentence: `[finding id, date, role]`. */
export type SponsorRef = [id: string, date: string, role: string];

/** One line per bill and act: every roll call or sponsorship of that kind this person has on the bill. */
export interface RecordLine { bill: string; act: string; rung?: number | null; on: (VoteRef | SponsorRef)[] }

export interface CollapsedBill {
  subjects: string[];
  file?: string;
  /** The bill table's reading, stated once per batch. Absent when the table does not list the bill. */
  rung?: number | null;
  deciding_words?: string;
  why?: string;
  /** The URL the bill's record findings share. */
  url?: string;
  /** `date|body` → the roll call's motion text. */
  motions?: Record<string, string>;
  /** What follows "<role> sponsor of <bill> " in a sponsorship's note. */
  sponsor_tail?: string;
  /** What follows "<role> sponsor" in a sponsorship's motion field, when it has one. */
  sponsor_motion_tail?: string;
}

export interface CollapsedPerson extends Omit<CoderPerson, 'findings'> {
  /** Record findings whose note is the pre-fill's fixed sentence, one line per bill and act. */
  record: RecordLine[];
  /** Everything else, word for word: own words, and any record whose note says more than the fixed sentence. */
  findings: CoderFinding[];
}

export interface CollapsedBatch extends Omit<CompactBatch, 'bills' | 'people'> {
  collapsed: true;
  bills: Record<string, CollapsedBill>;
  people: CollapsedPerson[];
}

const COLLAPSED_ABOUT = 'One file per coder batch. "record" holds each person\'s plain roll calls and sponsorships, one line '
  + 'per bill and act: a vote is [finding id, date, chamber, tally yes–no, census gate (none = no gate)]; a sponsorship is '
  + '[finding id, date, role]. Nothing else was said about those acts. "rung" on a line, and "rung", "deciding_words" and '
  + '"why" in "bills", are the state bill table\'s reading of a Yes on that bill (null = no rung); "motions" gives each roll '
  + 'call\'s motion by date and chamber. "findings" holds everything else word for word: the person\'s own words, and any '
  + 'record whose note says more than the plain facts (read those notes: doubts are flagged there). Cite any act by its '
  + 'finding id.';

const VOTE_NOTE = /^(.+?), ([\s\S]*), (\d{4}-\d{2}-\d{2}): (\w+) \(tally ([^)]*)\); census gate: ([\w-]+)\.$/;
const SPONSOR_NOTE = /^(\w+) sponsor of (\S+) ([\s\S]*)$/;
const precisionOf = (date: string) => (date.length === 4 ? 'year' : date.length === 7 ? 'month' : 'day');

function voteParts(f: CoderFinding): { body: string; tally: string } | undefined {
  const m = VOTE_NOTE.exec(f.note);
  if (!m || f.motion === undefined || f.gate === undefined || m[2] !== f.motion || m[3] !== f.date || m[4] !== f.act || m[6] !== f.gate) return undefined;
  return { body: m[1], tally: m[5] };
}
function sponsorParts(f: CoderFinding): { role: string; tail: string; motionTail?: string } | undefined {
  const m = SPONSOR_NOTE.exec(f.note);
  if (!m || m[2] !== f.instrument_id || f.gate !== undefined) return undefined;
  if (f.motion !== undefined && !f.motion.startsWith(`${m[1]} sponsor`)) return undefined;
  return { role: m[1], tail: m[3], motionTail: f.motion?.slice(`${m[1]} sponsor`.length) };
}

/** One record finding, rebuilt from its line. The key order is `projectFinding`'s: the check compares JSON. */
function rebuild(line: RecordLine, ref: VoteRef | SponsorRef, bill: CollapsedBill | undefined): CoderFinding {
  const [id, date] = ref;
  const o = { id, kind: 'record', url: bill?.url ?? '', date, date_precision: precisionOf(date), instrument_id: line.bill, act: line.act } as CoderFinding;
  if (ref.length === 5) {
    const [, , body, tally, gate] = ref;
    o.motion = bill?.motions?.[`${date}|${body}`] ?? '';
    o.gate = gate;
    o.note = `${body}, ${o.motion}, ${date}: ${line.act} (tally ${tally}); census gate: ${gate}.`;
  } else {
    if (bill?.sponsor_motion_tail !== undefined) o.motion = `${ref[2]} sponsor${bill.sponsor_motion_tail}`;
    o.note = `${ref[2]} sponsor of ${line.bill} ${bill?.sponsor_tail ?? ''}`;
  }
  o.subjects = bill?.subjects ?? [];
  return o;
}

const mostCommonText = (xs: string[]): string | undefined => {
  const n = new Map<string, number>();
  for (const x of xs) n.set(x, (n.get(x) ?? 0) + 1);
  return [...n].sort((a, b) => b[1] - a[1])[0]?.[0];
};

/**
 * `compactBatch`, with each person's plain record collapsed to one line per bill and act, and the bill table's
 * reading stated once per bill. A record finding is collapsed only when its line rebuilds to exactly the
 * finding the store holds: any note that says more than the pre-fill's fixed sentence (a doubt, an unverified
 * identity, a version remark) fails that test and stays in `findings`, word for word. California, batch 1: 20
 * people, 1,239 record findings, 658k characters before and about a third of that after.
 */
export function collapseBatch(
  people: { row: RosterRow; pf: PersonFindings | undefined }[], topicKey: string, season: number,
  instrumentFile: (id: string) => string | undefined, table: Record<string, BillTableRow>, kinds?: ReadonlySet<Finding['kind']>,
): CollapsedBatch {
  const c = compactBatch(people, topicKey, season, instrumentFile, kinds);
  const full = expandCompact(c);
  const bills: Record<string, CollapsedBill> = {};
  const recs = c.people.flatMap((p) => full.get(p.politician_id)!.findings.filter((f) => f.kind === 'record' && f.instrument_id));
  for (const [id, b] of Object.entries(c.bills)) {
    const mine = recs.filter((f) => f.instrument_id === id);
    const row = table[id];
    const o: CollapsedBill = { subjects: b.subjects };
    if (b.file) o.file = b.file;
    if (row) { o.rung = row.rung; if (row.deciding_words) o.deciding_words = row.deciding_words; if (row.why) o.why = row.why; }
    const url = mostCommonText(mine.map((f) => f.url));
    if (url !== undefined) o.url = url;
    const motions = new Map<string, string[]>();
    for (const f of mine) { const v = voteParts(f); if (v) motions.set(`${f.date}|${v.body}`, [...(motions.get(`${f.date}|${v.body}`) ?? []), f.motion!]); }
    if (motions.size) o.motions = Object.fromEntries([...motions].sort().map(([k, v]) => [k, mostCommonText(v)!]));
    const sp = mine.flatMap((f) => { const s = sponsorParts(f); return s ? [s] : []; });
    if (sp.length) {
      o.sponsor_tail = mostCommonText(sp.map((s) => s.tail))!;
      const withMotion = sp.filter((s) => s.motionTail !== undefined);
      if (withMotion.length * 2 > sp.length) o.sponsor_motion_tail = mostCommonText(withMotion.map((s) => s.motionTail!))!;
    }
    bills[id] = o;
  }
  const outPeople: CollapsedPerson[] = c.people.map((p) => {
    const lines = new Map<string, RecordLine>();
    const rest: CoderFinding[] = [];
    const compactById = new Map(p.findings.map((f) => [f.id, f]));
    for (const f of full.get(p.politician_id)!.findings) {
      const bill = f.instrument_id ? bills[f.instrument_id] : undefined;
      let ref: VoteRef | SponsorRef | undefined;
      if (f.kind === 'record' && f.instrument_id && f.act) {
        const v = voteParts(f); const s = v ? undefined : sponsorParts(f);
        if (v) ref = [f.id, f.date, v.body, v.tally, f.gate!];
        else if (s) ref = [f.id, f.date, s.role];
      }
      const line: RecordLine | undefined = ref && { bill: f.instrument_id!, act: f.act!, on: [] };
      if (!ref || !line || JSON.stringify(rebuild(line, ref, bill)) !== JSON.stringify(f)) { rest.push(compactById.get(f.id)!); continue; }
      const k = `${f.instrument_id}|${f.act}`;
      if (!lines.has(k)) { const l: RecordLine = { bill: f.instrument_id!, act: f.act! }  as RecordLine; if (table[f.instrument_id!]) l.rung = table[f.instrument_id!].rung; l.on = []; lines.set(k, l); }
      lines.get(k)!.on.push(ref);
    }
    const { findings: _f, ...head } = p;
    return { ...head, record: [...lines.values()], findings: rest };
  });
  return { about: COLLAPSED_ABOUT, collapsed: true, topic_key: c.topic_key, season: c.season, search_subjects: c.search_subjects, bills, people: outPeople };
}

/** Rebuilds every person's projected findings and searches from a collapsed batch (order: lines, then the rest). */
export function expandCollapsed(c: CollapsedBatch): Map<string, { findings: CoderFinding[]; searches: CoderSearch[] }> {
  const asCompact: CompactBatch = {
    about: c.about, topic_key: c.topic_key, season: c.season, search_subjects: c.search_subjects,
    bills: Object.fromEntries(Object.entries(c.bills).map(([k, b]) => [k, { subjects: b.subjects, file: b.file }])),
    people: c.people.map(({ record: _r, ...p }) => p),
  };
  const out = expandCompact(asCompact);
  for (const p of c.people) {
    const lines = p.record.flatMap((l) => l.on.map((ref) => rebuild(l, ref, c.bills[l.bill])));
    out.get(p.politician_id)!.findings.unshift(...lines);
  }
  return out;
}

/**
 * Differences between the store and a collapsed batch; empty means no finding id was lost and every field of
 * every finding, each note included, rebuilds word for word. Order within a person is not compared: the lines
 * group a person's acts by bill.
 */
export function collapsedRoundTripProblems(people: { row: RosterRow; pf: PersonFindings | undefined }[], c: CollapsedBatch, topicKey: string, season: number, kinds?: ReadonlySet<Finding['kind']>): string[] {
  const out: string[] = [];
  const back = expandCollapsed(c);
  for (const { row, pf } of people) {
    const want = onTopic(pf, topicKey, kinds).map((f) => projectFinding(f, topicKey));
    const wantS = (pf?.searches ?? []).filter((s) => s.topic_key === topicKey && s.season === season).map(projectSearch);
    const got = back.get(row.politician_id);
    if (!got) { out.push(`${row.full_name}: missing from the collapsed file`); continue; }
    const gotById = new Map(got.findings.map((f) => [f.id, f]));
    if (gotById.size !== got.findings.length) out.push(`${row.full_name}: a finding id appears twice in the collapsed file`);
    if (got.findings.length !== want.length) out.push(`${row.full_name}: ${want.length} findings in the store, ${got.findings.length} in the collapsed file`);
    for (const f of want) {
      const g = gotById.get(f.id);
      if (!g) out.push(`${row.full_name}: finding ${f.id.slice(0, 12)}… lost`);
      else if (JSON.stringify(g) !== JSON.stringify(f)) out.push(`${row.full_name}: finding ${f.id.slice(0, 12)}… differs from the store (${g.note === f.note ? 'a field' : 'its note'})`);
    }
    if (JSON.stringify(got.searches) !== JSON.stringify(wantS)) out.push(`${row.full_name}: a search differs from the store`);
  }
  return out;
}

/** Every finding id a batch file shows a coder, for either layout (`search_list.py recode` reads the same). */
export function shownIds(c: CompactBatch | CollapsedBatch): Map<string, string[]> {
  const out = new Map<string, string[]>();
  for (const p of c.people as (CoderPerson & { record?: RecordLine[] })[]) {
    out.set(p.politician_id, [...(p.record ?? []).flatMap((l) => l.on.map((r) => r[0])), ...p.findings.map((f) => f.id)]);
  }
  return out;
}
