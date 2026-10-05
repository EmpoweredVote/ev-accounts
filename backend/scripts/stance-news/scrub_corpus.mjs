// Redact third-party secrets from scraped corpus files, in place.
// Usage: node scrub_corpus.mjs [slug ...]      (no slug = every corpus under SWEEP_OUT)
//
// 🔴🔴 WHY THIS EXISTS. A news page carries other people's keys. GitHub push protection rejected a
// whole push because a scraped MinnPost election-results page embedded a **Mapbox secret access
// token** in its map widget, and the sweep stored the page text verbatim. Committing a corpus
// publishes whatever the publisher left in their HTML.
// ▶ Never allowlist such a secret: it is not ours to disclose. Redact it and keep the corpus.
// ▶ Run this after every sweep, BEFORE committing. `sweep_duluth.mjs` now calls the same redactor.
import fs from 'node:fs';
import path from 'node:path';

const ROOT = process.env.SWEEP_OUT || 'data/stance-news';

// Each pattern is a token FORM, not a guess at a value.
export const SECRET_PATTERNS = [
  [/\b[ps]k\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}(?:\.[A-Za-z0-9_-]{10,})?/g, '[REDACTED-MAPBOX-TOKEN]'],
  [/\beyJ[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{15,}/g, '[REDACTED-JWT]'],
  [/\bAIza[0-9A-Za-z_-]{35}/g, '[REDACTED-GOOGLE-API-KEY]'],
  [/\bgh[pousr]_[A-Za-z0-9]{36,}/g, '[REDACTED-GITHUB-TOKEN]'],
  [/\bsk_(?:live|test)_[A-Za-z0-9]{20,}/g, '[REDACTED-STRIPE-KEY]'],
  [/\bAKIA[0-9A-Z]{16}\b/g, '[REDACTED-AWS-KEY-ID]'],
  [/\bxox[baprs]-[A-Za-z0-9-]{10,}/g, '[REDACTED-SLACK-TOKEN]'],
];

export function scrubText(s) {
  let n = 0;
  for (const [re, rep] of SECRET_PATTERNS) {
    s = s.replace(re, () => { n++; return rep; });
  }
  return { text: s, redactions: n };
}

const invokedDirectly = process.argv[1] && import.meta.url.endsWith(process.argv[1].replace(/\\/g, '/').split('/').pop());
if (invokedDirectly) {
  const slugs = process.argv.slice(2).length
    ? process.argv.slice(2)
    : fs.readdirSync(ROOT).filter((d) => fs.statSync(path.join(ROOT, d)).isDirectory());
  let files = 0, touched = 0, total = 0;
  for (const slug of slugs) {
    const dir = path.join(ROOT, slug);
    for (const f of fs.readdirSync(dir)) {
      if (!f.endsWith('.txt')) continue;
      files++;
      const p = path.join(dir, f);
      const { text, redactions } = scrubText(fs.readFileSync(p, 'utf8'));
      if (!redactions) continue;
      fs.writeFileSync(p, text);
      touched++; total += redactions;
      console.log(`${slug}/${f}: ${redactions} redaction(s)`);
    }
  }
  console.log(`\nscanned ${files} files across ${slugs.length} corpora | ${touched} files changed | ${total} redactions`);
  // 🔴 A zero is only a finding once the patterns are known to fire. The Mapbox case is the control.
  if (!total) console.log('no secrets found — confirm the patterns still fire before trusting this zero');
}
