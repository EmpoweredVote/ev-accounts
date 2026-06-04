import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';

const SRC = fs.readFileSync(
  path.resolve(__dirname, '../src/lib/essentialsService.ts'),
  'utf-8',
);

// Strip SQL/code comments so grep counts don't self-invalidate.
// This prevents a comment that mentions "finance_summary" from satisfying the assertions.
function stripComments(s: string): string {
  return s
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/^\s*\/\/.*$/gm, '')
    .replace(/--.*$/gm, '');
}
const SRC_NC = stripComments(SRC);

describe('essentialsService finance_summary surface (FINA-03)', () => {
  it('PoliticianFlatRecord interface declares finance_summary', () => {
    // Scoped match: starts at PoliticianFlatRecord, non-greedy up to next export interface or end of block
    const match = /export interface PoliticianFlatRecord\s*\{([\s\S]*?)(?=\nexport |\nfunction |\nconst |\nclass )/.exec(SRC_NC);
    expect(match, 'PoliticianFlatRecord interface not found in source').toBeTruthy();
    const interfaceBody = match![1];
    expect(interfaceBody).toMatch(/finance_summary\s*:/i);
  });

  it('PoliticianDetail interface declares finance_summary', () => {
    // Scoped match: starts at PoliticianDetail, non-greedy up to next export or function
    const match = /export interface PoliticianDetail\s*\{([\s\S]*?)(?=\nexport |\nfunction |\nconst |\nclass )/.exec(SRC_NC);
    expect(match, 'PoliticianDetail interface not found in source').toBeTruthy();
    const interfaceBody = match![1];
    expect(interfaceBody).toMatch(/finance_summary\s*:/i);
  });

  it('getPoliticiansFlatList SELECT references p.finance_summary', () => {
    // Scoped: find the SELECT clause inside getPoliticiansFlatList (from function def to closing backtick of queryText)
    const fnMatch = /export async function getPoliticiansFlatList[\s\S]*?const queryText\s*=\s*`([\s\S]*?)`/.exec(SRC_NC);
    expect(fnMatch, 'getPoliticiansFlatList queryText not found').toBeTruthy();
    const selectClause = fnMatch![1];
    expect(selectClause).toMatch(/p\.finance_summary/);
  });

  it('getPoliticianById SELECT references p.finance_summary', () => {
    // Scoped: find the SELECT clause inside getPoliticianById (from function def to closing backtick of baseQuery)
    const fnMatch = /export async function getPoliticianById[\s\S]*?const baseQuery\s*=\s*`([\s\S]*?)`/.exec(SRC_NC);
    expect(fnMatch, 'getPoliticianById baseQuery not found').toBeTruthy();
    const selectClause = fnMatch![1];
    expect(selectClause).toMatch(/p\.finance_summary/);
  });

  it('row mappers project finance_summary into the returned record', () => {
    // Both mappers (getPoliticiansFlatList row.map and getPoliticianById return object) must contain
    // finance_summary: row.finance_summary — allow optional ?? null or JSON.parse wrapper (Pitfall 6)
    expect(SRC_NC).toMatch(/finance_summary:\s*row\.finance_summary/);
  });
});
