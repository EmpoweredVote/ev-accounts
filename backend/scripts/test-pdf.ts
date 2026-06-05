import fs from 'fs';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const pdfParse = require('pdf-parse');

const buf = fs.readFileSync('C:/Transparent Motivations/Data Drop/Bloomington, IN/OneDrive_2026-04-26/Pre-Primary Campaign Finance Reports 2026/Deckard, Trent/CFA-4_Pre-Primary2026.pdf');
const result = await pdfParse(buf);
console.log(result.text.substring(0, 5000));
