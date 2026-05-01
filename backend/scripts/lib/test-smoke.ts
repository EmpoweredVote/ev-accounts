import 'dotenv/config';
import * as fs from 'fs';
import * as os from 'os';
import * as crypto from 'crypto';
import * as path from 'path';
import { pdfToPageImages, extractContributionsFromImages } from './pdfOcrPipeline.js';

async function main() {
  // Use Goodrich (10 pages, likely has contributions, not in 14 pre-loaded)
  const pdfPath = "C:/Transparent Motivations/Data Drop/Bloomington, IN/OneDrive_2026-04-26/Pre-Primary Campaign Finance Reports 2026/Goodrich, Jeremy/CFA-4_Pre-Primary2026.pdf";
  const tmpDir = path.join(os.tmpdir(), 'cfa-ocr-' + crypto.randomUUID());
  fs.mkdirSync(tmpDir, { recursive: true });
  
  console.log('Converting Goodrich PDF to images...');
  const pages = await pdfToPageImages(pdfPath, tmpDir);
  console.log(`Pages generated: ${pages.length}`);
  
  // Test just pages 2-3 (skip cover)
  const testPages = pages.slice(1, 3);
  console.log(`Running Vision OCR on pages 2-3...`);
  const result = await extractContributionsFromImages(testPages, {
    candidateName: 'Jeremy Goodrich',
    jurisdictionHint: 'Indiana Monroe County CFA-4 form'
  });
  
  console.log(`\nExtracted ${result.contributions.length} contributions`);
  console.log(`Cost: $${result.totalCostUsd.toFixed(4)}`);
  result.warnings.forEach(w => console.log('  WARN:', w));
  result.contributions.forEach((c, i) => {
    console.log(`  [${i+1}] pg${c.pageNumber} | ${c.donorName} | $${c.amount} | ${c.contributionDate} | conf:${c.confidence}`);
  });
  
  fs.rmSync(tmpDir, { recursive: true, force: true });
  
  if (result.contributions.length < 1) {
    console.error('FAIL: Expected contributions on pages 2-3');
    process.exit(1);
  }
  console.log('\nSMOKE TEST PASSED');
}

main().catch(err => { console.error('FATAL:', err); process.exit(1); });
