/**
 * pdfOcrPipeline.ts — Reusable PDF → Claude Vision → structured JSON pipeline.
 *
 * Purpose:
 *   Converts scanned campaign finance PDFs (which have no text layer) into structured
 *   ContributionRow arrays using Claude Vision (Haiku — cheapest vision model, ~$0.001/page).
 *   Designed for local government forms (Indiana CFA-4, California 460, NY CF-02, etc.)
 *   where no programmatic data source exists.
 *
 * Contract:
 *   - Pure I/O module: PDF in → structured JSON out. NO database access.
 *   - Caller is responsible for normalization (normalizeDonorName), DB writes, and cleanup.
 *   - Caller passes a tmp dir; this module writes PNGs there. Caller handles cleanup.
 *   - One Claude API call per page — keeps prompts small and errors isolated.
 *
 * Usage:
 *   import { pdfToPageImages, extractContributionsFromImages, ContributionRow } from './lib/pdfOcrPipeline.js';
 *
 *   const tmpDir = os.tmpdir() + '/cfa-ocr-' + crypto.randomUUID();
 *   fs.mkdirSync(tmpDir, { recursive: true });
 *   const pages = await pdfToPageImages('/path/to/report.pdf', tmpDir);
 *   const result = await extractContributionsFromImages(pages, { candidateName: 'Peter Iversen', jurisdictionHint: 'Indiana Monroe County CFA-4 form' });
 *   // result.contributions — array of ContributionRow (medium/high confidence only if filtered by caller)
 *   // result.totalCostUsd  — estimated Claude Vision cost for this PDF
 *   fs.rmSync(tmpDir, { recursive: true, force: true });
 *
 * Cost estimate (claude-haiku-4-5, as of May 2026):
 *   ~$1.00/MTok input, ~$5.00/MTok output
 *   A typical CFA-4 page: ~2,000 input tokens (image) + ~500 output tokens = ~$0.0045/page
 *   10 pages per candidate × 7 candidates = ~$0.32 for full Monroe County ingest
 *
 * Error handling:
 *   - pdfToPageImages throws if pdftoppm is not on PATH (advises install).
 *   - extractContributionsFromImages never throws on page-level failures — pushes warnings
 *     and continues to remaining pages. Partial results are returned.
 */

import * as fs from 'fs';
import * as path from 'path';
import { spawnSync } from 'child_process';
import Anthropic from '@anthropic-ai/sdk';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/**
 * A single contribution row extracted from a scanned campaign finance form.
 * All fields come directly from Claude Vision — caller is responsible for normalization.
 */
export interface ContributionRow {
  donorName: string;          // Raw, unnormalized — caller runs normalizeDonorName()
  donorAddress: string | null;
  donorOccupation: string | null;
  donorEmployer: string | null;
  donorType: 'individual' | 'corporation' | 'pac' | 'unknown';
  amount: number;             // Dollars (positive); fractional cents OK (e.g., 50.00)
  contributionDate: string;   // YYYY-MM-DD
  scheduleType: 'A-1' | 'A-2' | 'A-4' | 'unknown';
  confidence: 'high' | 'medium' | 'low';
  pageNumber: number;
  reasonForLowConfidence?: string;
}

/**
 * Aggregated result from processing all pages of one PDF (or a batch of pages).
 */
export interface ExtractionResult {
  contributions: ContributionRow[];
  pagesProcessed: number;
  totalCostUsd: number;
  warnings: string[];
}

// ---------------------------------------------------------------------------
// Path resolution helpers
// ---------------------------------------------------------------------------

/**
 * Known installation paths for pdftoppm on Windows (winget + common installs).
 * Falls back to PATH lookup first; these are checked in order if PATH fails.
 */
const WINDOWS_POPPLER_PATHS = [
  // winget install poppler (most common — winget places it here)
  `${process.env.LOCALAPPDATA}\\Microsoft\\WinGet\\Packages\\oschwartz10612.Poppler_Microsoft.Winget.Source_8wekyb3d8bbwe`,
  // Chocolatey
  'C:\\ProgramData\\chocolatey\\bin',
  // Manual install convention
  'C:\\Program Files\\poppler\\bin',
  'C:\\poppler\\bin',
];

/**
 * Finds the pdftoppm binary, checking PATH first then common Windows locations.
 * Returns the full path to the binary, or null if not found.
 */
function findPdftoppm(): string | null {
  // Try PATH first (works if shell restarted after winget install)
  const onPath = spawnSync('pdftoppm', ['-v'], { encoding: 'utf8', shell: false });
  if (onPath.status === 0 || (onPath.stderr && onPath.stderr.includes('version'))) {
    return 'pdftoppm'; // On PATH — just use the name
  }

  // Search common Windows paths (winget installs don't update bash PATH immediately)
  for (const basePath of WINDOWS_POPPLER_PATHS) {
    if (!basePath) continue;
    try {
      // For winget, the actual exe is nested under a versioned subdirectory
      if (basePath.includes('WinGet')) {
        if (!fs.existsSync(basePath)) continue;
        const entries = fs.readdirSync(basePath);
        for (const entry of entries) {
          const exePath = path.join(basePath, entry, 'Library', 'bin', 'pdftoppm.exe');
          if (fs.existsSync(exePath)) return exePath;
        }
      } else {
        const exePath = path.join(basePath, 'pdftoppm.exe');
        if (fs.existsSync(exePath)) return exePath;
      }
    } catch {
      // Ignore access errors; try next path
    }
  }

  return null;
}

// ---------------------------------------------------------------------------
// pdfToPageImages
// ---------------------------------------------------------------------------

/**
 * Converts a PDF to individual PNG files using pdftoppm (from the poppler suite).
 *
 * @param pdfPath   Absolute path to the input PDF file.
 * @param outputDir Directory where PNG files will be written. Must already exist.
 *                  Files are named: page-1.png, page-2.png, page-3.png, ...
 * @returns         Array of absolute PNG file paths in page order.
 * @throws          Error with actionable message if pdftoppm is not found or fails.
 */
export async function pdfToPageImages(pdfPath: string, outputDir: string): Promise<string[]> {
  const pdftoppm = findPdftoppm();

  if (!pdftoppm) {
    throw new Error(
      'pdftoppm not found on PATH or in common installation directories.\n' +
      'Install poppler with: winget install poppler\n' +
      'After install, restart your shell or use the full path.\n' +
      'On macOS: brew install poppler\n' +
      'On Linux: apt-get install poppler-utils'
    );
  }

  // Prefix for output files: outputDir/page → generates page-1.png, page-2.png, etc.
  const outputPrefix = path.join(outputDir, 'page');

  const result = spawnSync(pdftoppm, ['-r', '200', '-png', pdfPath, outputPrefix], {
    encoding: 'utf8',
    // No shell: false is default — we want the actual binary
  });

  if (result.error) {
    throw new Error(`pdftoppm failed to start: ${result.error.message}`);
  }

  if (result.status !== 0) {
    const stderr = result.stderr?.trim() ?? '';
    throw new Error(
      `pdftoppm exited with code ${result.status} for ${path.basename(pdfPath)}.\n` +
      (stderr ? `stderr: ${stderr}` : 'No error output from pdftoppm.')
    );
  }

  // Collect generated PNGs — pdftoppm uses zero-padded page numbers
  const allFiles = fs.readdirSync(outputDir);
  const pngFiles = allFiles
    .filter(f => f.startsWith('page') && f.endsWith('.png'))
    .sort((a, b) => {
      // Sort numerically: page-1.png, page-2.png, page-10.png (not lexicographic)
      const numA = parseInt(a.match(/(\d+)/)?.[1] ?? '0', 10);
      const numB = parseInt(b.match(/(\d+)/)?.[1] ?? '0', 10);
      return numA - numB;
    })
    .map(f => path.join(outputDir, f));

  if (pngFiles.length === 0) {
    throw new Error(
      `pdftoppm ran successfully but produced 0 PNG files for ${path.basename(pdfPath)}.\n` +
      `Output dir: ${outputDir}\n` +
      `Files in dir: ${allFiles.join(', ') || '(empty)'}`
    );
  }

  return pngFiles;
}

// ---------------------------------------------------------------------------
// Vision extraction helpers
// ---------------------------------------------------------------------------

const HAIKU_MODEL = 'claude-haiku-4-5-20251001';
// Used only when the pinned snapshot above is rejected as unknown: the Haiku 4.5 alias, which keeps resolving
// if that dated snapshot is ever retired. (Was 'claude-3-5-haiku-latest' — Claude Haiku 3.5, retired 2026-02-19,
// so the fallback itself would have failed.)
const HAIKU_FALLBACK = 'claude-haiku-4-5';

// Cost per token (USD) — Haiku 4.5 pricing (approximate)
const COST_PER_INPUT_TOKEN = 1.0 / 1_000_000;  // $1.00/MTok
const COST_PER_OUTPUT_TOKEN = 5.0 / 1_000_000; // $5.00/MTok

const SYSTEM_PROMPT = `You are extracting contribution rows from a scanned campaign finance report page.

Return ONLY valid JSON — no markdown, no explanation, no code fences.
If a field is unreadable or missing, use null.
Set confidence='low' with reasonForLowConfidence for any row where you are uncertain about name, amount, or date.
Skip lines that are NOT contributions: totals, subtotals, summaries, section headers, expenditure schedules (Schedule B / E / F), cover page fields, candidate info blocks.

JSON schema for your response:
{
  "contributions": [
    {
      "donorName": "string",
      "donorAddress": "string or null",
      "donorOccupation": "string or null",
      "donorEmployer": "string or null",
      "donorType": "individual | corporation | pac | unknown",
      "amount": number,
      "contributionDate": "YYYY-MM-DD",
      "scheduleType": "A-1 | A-2 | A-4 | unknown",
      "confidence": "high | medium | low",
      "reasonForLowConfidence": "string or omit if not low"
    }
  ],
  "warnings": ["string"]
}`;

function buildUserPrompt(
  candidateName: string,
  jurisdictionHint: string,
  pageNumber: number,
  totalPages: number
): string {
  return (
    `Candidate: ${candidateName}. ` +
    `Jurisdiction: ${jurisdictionHint}. ` +
    `Page ${pageNumber} of ${totalPages}.\n\n` +
    `Extract every contribution row visible on this page.\n\n` +
    `Schedule types:\n` +
    `  A-1 = individual contributors\n` +
    `  A-2 = corporate or business contributors\n` +
    `  A-4 = PAC/committee contributors\n` +
    `  (use 'unknown' if schedule label is not visible)\n\n` +
    `Date format: YYYY-MM-DD. ` +
    `If only month/day is visible, infer year from filing context — ` +
    `this is a 2026 pre-primary report; contributions are likely from 2025 or 2026.\n\n` +
    `Amount is dollars as a number (not a string). Positive values only.\n\n` +
    `Address: combine street + city + state + zip into a single string, or null if not present.\n\n` +
    `Return ONLY the JSON object. Do not include any explanation or markdown.`
  );
}

/**
 * Strips markdown code fences from a string, if present.
 * Claude sometimes wraps JSON in ```json ... ``` despite instructions.
 */
function stripCodeFences(raw: string): string {
  return raw
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/\s*```\s*$/, '')
    .trim();
}

/**
 * Validates and coerces a parsed contribution row from Claude's response.
 * Returns null if the row is fundamentally unusable (e.g., missing donorName AND amount).
 */
function validateRow(raw: Record<string, unknown>, pageNumber: number): ContributionRow | null {
  const donorName = typeof raw.donorName === 'string' && raw.donorName.trim()
    ? raw.donorName.trim()
    : null;

  const amount = typeof raw.amount === 'number' && isFinite(raw.amount) && raw.amount > 0
    ? raw.amount
    : null;

  // Both donorName and amount must be present for the row to be useful
  if (!donorName || amount === null) return null;

  const scheduleType = ['A-1', 'A-2', 'A-4'].includes(raw.scheduleType as string)
    ? (raw.scheduleType as 'A-1' | 'A-2' | 'A-4')
    : 'unknown';

  const confidence = ['high', 'medium', 'low'].includes(raw.confidence as string)
    ? (raw.confidence as 'high' | 'medium' | 'low')
    : 'medium';

  const donorType = ['individual', 'corporation', 'pac', 'unknown'].includes(raw.donorType as string)
    ? (raw.donorType as 'individual' | 'corporation' | 'pac' | 'unknown')
    : 'unknown';

  // Validate/clean contributionDate — must be YYYY-MM-DD
  let contributionDate = typeof raw.contributionDate === 'string' ? raw.contributionDate.trim() : '';
  if (!/^\d{4}-\d{2}-\d{2}$/.test(contributionDate)) {
    // Try to parse common formats
    const d = new Date(contributionDate);
    if (!isNaN(d.getTime())) {
      contributionDate = d.toISOString().slice(0, 10);
    } else {
      contributionDate = '2026-01-01'; // Fallback with low confidence
    }
  }

  return {
    donorName,
    donorAddress: typeof raw.donorAddress === 'string' ? raw.donorAddress.trim() || null : null,
    donorOccupation: typeof raw.donorOccupation === 'string' ? raw.donorOccupation.trim() || null : null,
    donorEmployer: typeof raw.donorEmployer === 'string' ? raw.donorEmployer.trim() || null : null,
    donorType,
    amount,
    contributionDate,
    scheduleType,
    confidence,
    pageNumber,
    ...(confidence === 'low' && raw.reasonForLowConfidence
      ? { reasonForLowConfidence: String(raw.reasonForLowConfidence) }
      : {}),
  };
}

// ---------------------------------------------------------------------------
// extractContributionsFromImages
// ---------------------------------------------------------------------------

/**
 * Processes an array of PNG page images through Claude Vision to extract contribution rows.
 *
 * @param imagePaths  Array of absolute PNG file paths (one per page), in page order.
 * @param opts        candidateName: displayed in the Vision prompt for context.
 *                    jurisdictionHint: optional form type hint (e.g., "Indiana CFA-4 form").
 * @returns           Aggregated ExtractionResult across all pages.
 *
 * @notes
 *   - One Anthropic API call per page.
 *   - Never throws for page-level failures — pushes to warnings and continues.
 *   - Requires ANTHROPIC_API_KEY in process.env.
 */
export async function extractContributionsFromImages(
  imagePaths: string[],
  opts: { candidateName: string; jurisdictionHint?: string }
): Promise<ExtractionResult> {
  const { candidateName, jurisdictionHint = 'local US campaign finance form' } = opts;

  if (!process.env.ANTHROPIC_API_KEY) {
    throw new Error(
      'ANTHROPIC_API_KEY is not set in process.env.\n' +
      'Add it to your .env file: ANTHROPIC_API_KEY=sk-ant-...'
    );
  }

  const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

  const allContributions: ContributionRow[] = [];
  const warnings: string[] = [];
  let totalInputTokens = 0;
  let totalOutputTokens = 0;
  const totalPages = imagePaths.length;

  for (let i = 0; i < imagePaths.length; i++) {
    const imagePath = imagePaths[i];
    const pageNumber = i + 1;

    // Read and base64-encode the PNG
    let imageBase64: string;
    try {
      imageBase64 = fs.readFileSync(imagePath).toString('base64');
    } catch (err: any) {
      warnings.push(`Page ${pageNumber}: Failed to read image file: ${err.message}`);
      continue;
    }

    // Build the message with image content block
    let response: Awaited<ReturnType<typeof client.messages.create>>;
    let modelUsed = HAIKU_MODEL;
    try {
      response = await client.messages.create({
        model: HAIKU_MODEL,
        max_tokens: 2048,
        system: SYSTEM_PROMPT,
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'image',
                source: {
                  type: 'base64',
                  media_type: 'image/png',
                  data: imageBase64,
                },
              },
              {
                type: 'text',
                text: buildUserPrompt(candidateName, jurisdictionHint, pageNumber, totalPages),
              },
            ],
          },
        ],
      });
    } catch (err: any) {
      // If model not found, try fallback
      if (err.status === 404 || (err.message && err.message.includes('model'))) {
        modelUsed = HAIKU_FALLBACK;
        try {
          response = await client.messages.create({
            model: HAIKU_FALLBACK,
            max_tokens: 2048,
            system: SYSTEM_PROMPT,
            messages: [
              {
                role: 'user',
                content: [
                  {
                    type: 'image',
                    source: {
                      type: 'base64',
                      media_type: 'image/png',
                      data: imageBase64,
                    },
                  },
                  {
                    type: 'text',
                    text: buildUserPrompt(candidateName, jurisdictionHint, pageNumber, totalPages),
                  },
                ],
              },
            ],
          });
        } catch (err2: any) {
          warnings.push(`Page ${pageNumber}: Anthropic API error (both models failed): ${err2.message}`);
          continue;
        }
      } else {
        warnings.push(`Page ${pageNumber}: Anthropic API error: ${err.message}`);
        continue;
      }
    }

    // Track token usage
    if (response.usage) {
      totalInputTokens += response.usage.input_tokens ?? 0;
      totalOutputTokens += response.usage.output_tokens ?? 0;
    }

    // Extract text content from response
    const textContent = response.content
      .filter(block => block.type === 'text')
      .map(block => (block as { type: 'text'; text: string }).text)
      .join('');

    // Strip code fences and parse JSON
    let parsed: { contributions?: unknown[]; warnings?: unknown[] };
    try {
      const cleaned = stripCodeFences(textContent);
      parsed = JSON.parse(cleaned);
    } catch (err: any) {
      warnings.push(
        `Page ${pageNumber}: Failed to parse Claude response as JSON: ${err.message}. ` +
        `Raw response (first 200 chars): ${textContent.slice(0, 200)}`
      );
      continue;
    }

    // Collect page-level warnings from Claude
    if (Array.isArray(parsed.warnings)) {
      for (const w of parsed.warnings) {
        if (typeof w === 'string') warnings.push(`Page ${pageNumber} (Claude): ${w}`);
      }
    }

    // Validate and collect contribution rows
    if (Array.isArray(parsed.contributions)) {
      for (const rawRow of parsed.contributions) {
        if (typeof rawRow !== 'object' || rawRow === null) continue;
        const row = validateRow(rawRow as Record<string, unknown>, pageNumber);
        if (row) {
          allContributions.push(row);
        } else {
          warnings.push(
            `Page ${pageNumber}: Row skipped — missing donorName or valid amount. ` +
            `Raw: ${JSON.stringify(rawRow).slice(0, 100)}`
          );
        }
      }
    } else {
      warnings.push(`Page ${pageNumber}: Claude response had no 'contributions' array.`);
    }
  }

  const totalCostUsd =
    totalInputTokens * COST_PER_INPUT_TOKEN +
    totalOutputTokens * COST_PER_OUTPUT_TOKEN;

  return {
    contributions: allContributions,
    pagesProcessed: imagePaths.length,
    totalCostUsd,
    warnings,
  };
}
