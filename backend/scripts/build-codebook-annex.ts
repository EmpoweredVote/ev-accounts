/**
 * build-codebook-annex.ts — writes docs/codebook/annex/<topic_key>.md skeletons for a batch's
 * topics.json. NEVER overwrites an existing annex (a person's guidance lives there).
 *   npx tsx scripts/build-codebook-annex.ts --dir data/stance-research/<batch> --season "Season 2"
 */
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { renderAnnexSkeleton, annexPath, type AnnexTopic } from './lib/codebookAnnex.js';

const arg = (name: string): string | undefined => {
  const i = process.argv.indexOf(name);
  return i > 0 ? process.argv[i + 1] : undefined;
};
const dir = arg('--dir');
const season = arg('--season');
if (!dir || !season) {
  console.error('usage: --dir <batch dir> --season "<season name>"');
  process.exit(2);
}
const repoRoot = resolve(process.cwd(), '..');
const topics = JSON.parse(readFileSync(join(dir, 'topics.json'), 'utf8')) as AnnexTopic[];
let wrote = 0;
for (const t of topics) {
  const p = annexPath(repoRoot, t.topic_key);
  if (existsSync(p)) {
    console.log(`keep   ${p}`);
    continue;
  }
  mkdirSync(dirname(p), { recursive: true });
  writeFileSync(p, renderAnnexSkeleton(t, season));
  console.log(`wrote  ${p}`);
  wrote++;
}
console.log(`${wrote} new annex skeleton(s); ${topics.length - wrote} kept`);
