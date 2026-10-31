/**
 * billStatus.ts — parse one govinfo BILLSTATUS XML file into a row for essentials.legislative_bills.
 *
 * Pure functions, no I/O. The status rules and field choices match the 2026-10-30 federal
 * reload (backend/scripts/federal-bills/federal_bills_dryrun.py), so refreshed rows look like
 * the loaded ones.
 *
 * Antipartisan rule: a sponsor's party and name are never read or stored. Only the bioguide id
 * is kept, to link the bill to one of our politicians.
 */
import * as cheerio from 'cheerio';

export type FederalBillType = 'HR' | 'S' | 'HJRES' | 'SJRES' | 'HRES' | 'SRES' | 'HCONRES' | 'SCONRES';

export const FEDERAL_BILL_TYPES: FederalBillType[] =
  ['HR', 'S', 'HJRES', 'SJRES', 'HRES', 'SRES', 'HCONRES', 'SCONRES'];

const TYPE_SLUG: Record<FederalBillType, string> = {
  HR: 'house-bill', S: 'senate-bill', HJRES: 'house-joint-resolution', SJRES: 'senate-joint-resolution',
  HRES: 'house-resolution', SRES: 'senate-resolution', HCONRES: 'house-concurrent-resolution',
  SCONRES: 'senate-concurrent-resolution',
};

/** Simple resolutions: one chamber's vote is final. */
const SIMPLE_RESOLUTIONS: ReadonlySet<string> = new Set(['HRES', 'SRES']);

/** One chamber's floor passage: "Passed House ...", "Passed Senate ...", "Passed/agreed to in House: ...". */
const CHAMBER_PASS = /^(Passed|Agreed to)[^:]*?\b(House|Senate)\b/i;

export interface FederalBill {
  externalId: string; // <congress>-<TYPE>-<number>, e.g. 119-HR-1347
  congress: number;
  type: string;
  number: string; // "HR 1347"
  title: string;
  summary: string;
  rawStatus: string;
  statusLabel: 'Introduced' | 'In Committee' | 'Reported' | 'Passed' | 'Signed';
  introducedAt: string | null;
  passedAt: string | null;
  signedAt: string | null;
  topicTags: string[];
  url: string;
  sponsorBioguide: string;
  cosponsorBioguides: string[];
}

export function ordinal(n: number): string {
  const suffix = n % 100 >= 11 && n % 100 <= 13 ? 'th' : ({ 1: 'st', 2: 'nd', 3: 'rd' } as Record<number, string>)[n % 10] ?? 'th';
  return `${n}${suffix}`;
}

/** The Congress in session on a date. A Congress starts on January 3 of every odd year. */
export function currentCongress(now: Date = new Date()): number {
  let year = now.getUTCFullYear();
  if (year % 2 === 1 && now.getUTCMonth() === 0 && now.getUTCDate() < 3) year -= 1;
  return Math.floor((year - 1789) / 2) + 1;
}

export function congressStart(congress: number): Date {
  return new Date(Date.UTC(1789 + 2 * (congress - 1), 0, 3));
}

export function congressEnd(congress: number): Date {
  return new Date(Date.UTC(1789 + 2 * congress, 0, 3));
}

export function stripHtml(s: string): string {
  return s
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&#39;/g, "'")
    .replace(/\s+/g, ' ').trim();
}

/**
 * Signed = became law. Passed = it actually passed: both chambers for bills, joint and
 * concurrent resolutions; the one chamber for simple resolutions. A bill that passed only
 * one chamber keeps its stage label (it has not passed yet).
 */
export function statusOf(
  type: string, latestAction: string, hasLaw: boolean, chambersPassed: ReadonlySet<string>,
): FederalBill['statusLabel'] {
  if (hasLaw) return 'Signed';
  if (chambersPassed.size >= (SIMPLE_RESOLUTIONS.has(type) ? 1 : 2)) return 'Passed';
  if (/reported/i.test(latestAction)) return 'Reported';
  if (/referred to|committee/i.test(latestAction)) return 'In Committee';
  return 'Introduced';
}

/** "119-HR-1347" from a congress.gov style bill. */
export function externalIdFor(congress: number, type: string, number: string): string {
  return `${congress}-${type.toUpperCase()}-${number}`;
}

export function congressGovUrl(congress: number, type: FederalBillType, number: string): string {
  return `https://www.congress.gov/bill/${ordinal(congress)}-congress/${TYPE_SLUG[type]}/${number}`;
}

/**
 * Parse one BILLSTATUS file. `fallback` supplies congress/type/number from the file name for the
 * few older files that use the `billNumber` / `billType` tags or omit one of them.
 * Returns null for a file with no <bill>.
 */
export function parseBillStatus(
  xml: string, fallback: { congress: number; type: FederalBillType; number: string },
): FederalBill | null {
  const $ = cheerio.load(xml, { xmlMode: true });
  const bill = $('billStatus > bill').first();
  if (!bill.length) return null;
  const text = (sel: string, from = bill) => from.find(sel).first().text().trim();
  const child = (name: string) => bill.children(name).first().text().trim();

  const congress = Number(child('congress')) || fallback.congress;
  const type = (child('type') || child('billType') || fallback.type).toUpperCase() as FederalBillType;
  const num = child('number') || child('billNumber') || fallback.number;

  const latest = text('> latestAction > text');
  const laws = bill.children('laws').children('item').toArray();
  let lawDate = '';
  let passedAt = '';
  const chambers = new Set<string>();
  bill.children('actions').children('item').each((_, el) => {
    const a = $(el);
    const date = text('> actionDate', a);
    const t = text('> text', a);
    if (text('> type', a) === 'BecameLaw' && t.includes('Signed')) lawDate = date;
    const m = CHAMBER_PASS.exec(t);
    if (m) {
      chambers.add(m[2].toLowerCase());
      if (date > passedAt) passedAt = date;
    }
  });

  const summaries = bill.children('summaries').children('summary').toArray()
    .map((el) => ({ updated: text('> updateDate', $(el)), body: text('> text', $(el)) }))
    .sort((a, b) => a.updated.localeCompare(b.updated));
  const summary = summaries.length ? stripHtml(summaries[summaries.length - 1].body).slice(0, 4000) : '';

  const tags: string[] = [];
  const addTag = (n: string) => { if (n && !tags.includes(n)) tags.push(n); };
  addTag(text('> policyArea > name'));
  bill.find('subjects > legislativeSubjects > item > name').each((_, el) => addTag($(el).text().trim()));

  const statusLabel = statusOf(type, latest, laws.length > 0, chambers);
  const sponsor = bill.children('sponsors').children('item').first();
  const cosponsors = bill.children('cosponsors').children('item').toArray()
    .filter((el) => !text('> sponsorshipWithdrawnDate', $(el)))
    .map((el) => text('> bioguideId', $(el)))
    .filter(Boolean);

  return {
    externalId: externalIdFor(congress, type, num),
    congress, type,
    number: `${type} ${num}`,
    title: child('title'),
    summary,
    rawStatus: latest,
    statusLabel,
    introducedAt: child('introducedDate') || null,
    passedAt: (statusLabel === 'Passed' || statusLabel === 'Signed') && passedAt ? passedAt : null,
    signedAt: laws.length > 0 && lawDate ? lawDate : null,
    topicTags: tags.slice(0, 10),
    url: congressGovUrl(congress, type, num),
    sponsorBioguide: sponsor.length ? text('> bioguideId', sponsor) : '',
    cosponsorBioguides: [...new Set(cosponsors)].sort(),
  };
}
