import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const OTR = process.env.OTR_ROOT || resolve(here, '..', '..', '..', '..', '..', 'on-the-record');  // sibling checkout
const SPANS = {
  gates: resolve(OTR, '.claude/skills/audit-quotes/CHECKS.md'),
  deid:  resolve(OTR, '.claude/skills/publish-quotes/EDITORIAL.md'),
  note:  resolve(OTR, '.claude/skills/publish-quotes/EDITORIAL.md'),
};

export function extractSpan(name) {
  const file = SPANS[name];
  if (!file) throw new Error(`unknown span: ${name}`);
  const src = readFileSync(file, 'utf8');
  const re = new RegExp(`<!--\\s*inject:${name}:start\\s*-->([\\s\\S]*?)<!--\\s*inject:${name}:end\\s*-->`);
  const m = src.match(re);
  if (!m) throw new Error(`span '${name}' not found in ${file} — is the inject fence present?`);
  return m[1].trim();
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const names = process.argv.slice(2);
  for (const n of names) console.log(`### INJECT: ${n}\n\n${extractSpan(n)}\n`);
}
