// Print a saved Legistar matter-text JSON: the enforcement section and whether it carries
// amendment marks. Usage: node _read_matter_text.mjs <file.json> [search phrase]
import fs from 'node:fs';
const d = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const phrase = process.argv[3] || '(c) Prohibited acts';
const p = (d.MatterTextPlain || '').replace(/\s+/g, ' ');
const i = p.indexOf(phrase);
console.log(p.slice(i < 0 ? 0 : i, (i < 0 ? 0 : i) + 2600));
const r = d.MatterTextRtf || '';
// 🔴 MatterTextPlain hides the strikethrough. If the RTF carries no \strike and no \ul, this text
// is NOT an amendment-marked version and says nothing about what the council changed.
console.log('\n=== amendment marks in the RTF ===');
console.log('\\strike present :', /\\strike(?![a-z])/.test(r));
console.log('\\ul present     :', /\\ul(?![a-z])/.test(r));
console.log('version         :', d.MatterTextVersion);
