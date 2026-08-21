#!/usr/bin/env node
/**
 * Validate the Colorado Springs stance wave before any DB write.
 *
 * Checks the things that are cheap to get wrong and expensive to ship:
 *   - every full_name is in the verified cohort (no fuzzy matching, no strangers)
 *   - every topic_key exists AND belongs to that person's scale (a local official cannot
 *     hold a state-only topic, and vice versa)
 *   - value is an integer 1-5 that exists on that topic's ladder
 *   - reasoning is present and non-trivial (it is PUBLIC, voter-facing text)
 *   - quote_text ⇒ editor_note (essentials.quotes requires it; the audit hard-fails without)
 *   - no duplicate (person, topic) rows, within or across files
 *   - no U+FFFD / mojibake in any voter-facing field
 *
 * Usage: node validate-wave.mjs [--json]
 */
import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { parse } from 'csv-parse/sync';

const HERE = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));

const cohort = JSON.parse(await readFile(path.join(HERE, 'cohort.json'), 'utf8'));
const byName = new Map(cohort.map((c) => [c.full_name, c]));
const scales = {
  local: JSON.parse(await readFile(path.join(HERE, 'scale-local.json'), 'utf8')),
  state: JSON.parse(await readFile(path.join(HERE, 'scale-state.json'), 'utf8')),
};
const ladder = {};
for (const [scope, topics] of Object.entries(scales)) {
  ladder[scope] = new Map(topics.map((t) => [t.topic_key, t]));
}

const files = (await readdir(HERE)).filter((f) => /^out-.*\.csv$/.test(f)).sort();
const problems = [];
const seen = new Map();
let total = 0;
const perPerson = new Map();

for (const f of files) {
  let rows;
  try {
    rows = parse(await readFile(path.join(HERE, f), 'utf8'), {
      columns: true, skip_empty_lines: true, bom: true, relax_column_count: false,
    });
  } catch (e) {
    problems.push({ sev: 'high', file: f, msg: `CSV PARSE FAILED — ${e.message.slice(0, 120)}` });
    continue;
  }
  rows.forEach((r, i) => {
    const at = `${f}:${i + 2}`;
    total++;
    const name = (r.full_name || '').trim();
    const person = byName.get(name);
    if (!person) {
      problems.push({ sev: 'high', file: f, msg: `row ${at}: full_name "${name}" is not in the verified cohort` });
      return;
    }
    perPerson.set(name, (perPerson.get(name) || 0) + 1);

    const key = (r.topic_key || '').trim();
    const t = ladder[person.scale].get(key);
    if (!t) {
      const otherScale = person.scale === 'local' ? 'state' : 'local';
      const wrongScale = ladder[otherScale].has(key);
      problems.push({
        sev: 'high', file: f,
        msg: `row ${at}: ${name} — topic_key "${key}" ${wrongScale
          ? `belongs to the ${otherScale} scale, but this person is on the ${person.scale} scale`
          : `is not a live topic on the ${person.scale} scale`}`,
      });
      return;
    }

    const dupKey = `${name}::${key}`;
    if (seen.has(dupKey)) {
      problems.push({ sev: 'high', file: f, msg: `row ${at}: duplicate (${name}, ${key}) — also at ${seen.get(dupKey)}` });
    } else seen.set(dupKey, at);

    const v = Number(r.value);
    if (!Number.isInteger(v) || !t.stances.some((s) => Number(s.value) === v)) {
      problems.push({ sev: 'high', file: f, msg: `row ${at}: ${name}/${key} — value "${r.value}" is not a valid chair on this ladder` });
    }

    const reasoning = (r.reasoning || '').trim();
    if (reasoning.length < 40) {
      problems.push({ sev: 'high', file: f, msg: `row ${at}: ${name}/${key} — reasoning is missing or too short (${reasoning.length} chars); this text is public` });
    }

    const quote = (r.quote_text || '').trim();
    const note = (r.editor_note || '').trim();
    if (quote && !note) {
      problems.push({ sev: 'high', file: f, msg: `row ${at}: ${name}/${key} — has quote_text but no editor_note (DB requires it)` });
    }
    if (quote && /…$|\.\.\.$/.test(quote)) {
      problems.push({ sev: 'medium', file: f, msg: `row ${at}: ${name}/${key} — quote ends in a trailing ellipsis` });
    }
    if (!(r.source_url_1 || '').trim()) {
      problems.push({ sev: 'high', file: f, msg: `row ${at}: ${name}/${key} — no source_url_1` });
    }

    for (const field of ['reasoning', 'quote_text', 'editor_note']) {
      if ((r[field] || '').includes('�')) {
        problems.push({ sev: 'high', file: f, msg: `row ${at}: ${name}/${key} — ${field} contains a U+FFFD replacement char (encoding corruption in public text)` });
      }
    }
  });
}

const high = problems.filter((p) => p.sev === 'high');
const med = problems.filter((p) => p.sev === 'medium');

if (process.argv.includes('--json')) {
  console.log(JSON.stringify({ files: files.length, total, people: perPerson.size, problems }, null, 1));
} else {
  console.log(`files=${files.length}  rows=${total}  people=${perPerson.size}`);
  console.log([...perPerson.entries()].sort((a, b) => b[1] - a[1]).map(([n, c]) => `  ${String(c).padStart(3)}  ${n}`).join('\n'));
  console.log(`\nFINDINGS high=${high.length} medium=${med.length}`);
  for (const p of [...high, ...med]) console.log(`  [${p.sev}] ${p.msg}`);
  if (!problems.length) console.log('  none — wave is clean');
}
process.exit(high.length ? 1 : 0);
