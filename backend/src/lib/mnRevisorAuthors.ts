/**
 * Minnesota Revisor author lists — attribution by the legislature's own member link.
 *
 * A Revisor bill page (revisor.mn.gov/bills/…) prints its authors by family name only: "Jones",
 * "Lee, F.", "Anderson, P. E.". For a family name on COMMON_LAST_NAMES the name-proximity test needs a
 * title ("Rep.", "Sen.") before the name, which an author list never prints, so a true sponsorship by a
 * Jones, a Lee or an Anderson verified nothing (gun-policy mn-01, 2026-11-19: 15 seats).
 *
 * Each author name on the page links to that member's own record (house.mn.gov/members/profile/<id> or
 * mnsenate.gov/…member_bio.html?leg_id=<id>). The id is the Legislative Reference Library's legislator id,
 * and lrl.mn.gov/legdb/fulldetail?ID=<id> titles the record with the member's name. This check accepts
 * the person as an author only when:
 *   1. an author link in the page's Authors block carries the person's family name as its label, and
 *   2. the LRL record that link points to is titled with the person's full name or one of their
 *      alternate names — exactly, after case, accent and punctuation folding. A quoted nickname in the
 *      LRL title ('Andrew "Andy" Smith') counts as a first name.
 *
 * A middle initial is NOT dropped on either side: "Paul Anderson" does not match the LRL's
 * "Paul H. Anderson". That keeps a namesake from another chamber (former Sen. Paul T. Anderson, whose
 * bills the Open States dump once credited to Rep. Paul Anderson) from being accepted by name alone.
 * Such a person stays for human review, or gets the LRL form added as an alternate name.
 */
import { robotsAllows, EMPOWERED_VOTE_UA, HTTP_TIMEOUT_MS } from './verificationFetch.js';
import { MN_LRL } from './memberIds.js';

export interface AuthorLink {
  label: string;
  chamber: 'house' | 'senate';
  id: string;
}

export interface MemberNames {
  fullName: string;
  lastName: string;
  aliases?: string[];
  /** Stored member ids by id_type (CA_0401). With an 'mn-lrl' id the check compares ids only. */
  memberIds?: Record<string, string[]>;
}

export function isRevisorBillUrl(url: string): boolean {
  try {
    const u = new URL(url);
    return /(^|\.)revisor\.mn\.gov$/i.test(u.hostname) && u.pathname.startsWith('/bills/');
  } catch {
    return false;
  }
}

const decode = (s: string): string =>
  s.replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&#39;|&apos;/g, "'")
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&nbsp;/g, ' ')
    .replace(/&#(\d+);/g, (_, n) => String.fromCodePoint(Number(n)));

/** Author links inside the page's "Authors" block only (not names in the actions table). */
export function parseRevisorAuthorLinks(html: string): AuthorLink[] {
  const start = html.search(/<h2>\s*Authors\b/i);
  if (start < 0) return [];
  const rest = html.slice(start);
  const end = rest.search(/<\/ul>/i);
  const block = end < 0 ? rest : rest.slice(0, end);
  const out: AuthorLink[] = [];
  const re = /<a\s[^>]*href="([^"]+)"[^>]*>([^<]+)<\/a>/gi;
  for (let m = re.exec(block); m; m = re.exec(block)) {
    const href = decode(m[1]);
    const label = decode(m[2]).replace(/\s+/g, ' ').trim();
    const house = /house\.(?:leg\.state\.)?mn(?:\.gov)?\/members\/profile\/(\d+)/i.exec(href);
    const senate = /(?:mnsenate\.gov|senate\.mn)\/members\/member_bio\.html\?(?:[^"]*&)?leg_id=(\d+)/i.exec(href);
    if (house) out.push({ label, chamber: 'house', id: house[1] });
    else if (senate) out.push({ label, chamber: 'senate', id: senate[1] });
  }
  return out;
}

/** The member's name from an LRL legislator record ("Katie Jones - Legislator Record - …"). */
export function lrlNameFromHtml(html: string): string | null {
  const t = /<title>([\s\S]*?)<\/title>/i.exec(html);
  if (!t) return null;
  const name = decode(t[1]).replace(/\s+/g, ' ').split(' - Legislator Record')[0].trim();
  return name && name !== t[1].trim() ? name : null;
}

/** 'Andrew "Andy" Smith' → ['Andrew Smith', 'Andy Smith']; 'Patricia "Patti, Pat" Anderson' → three. */
export function lrlNameForms(lrlName: string): string[] {
  const q = /^(\S+)\s+"([^"]+)"\s+(.+)$/.exec(lrlName);
  if (!q) return [lrlName];
  const [, first, nicks, rest] = q;
  return [`${first} ${rest}`, ...nicks.split(',').map((n) => `${n.trim()} ${rest}`)];
}

export const foldName = (s: string): string =>
  s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()
    .replace(/[^a-z0-9 ]+/g, ' ').replace(/\s+/g, ' ').trim();

/** The family name a Revisor label carries: "Lee, F." → "lee"; "Kotyza-Witthuhn" → "kotyza witthuhn". */
const labelFamily = (label: string): string => foldName(label.split(',')[0]);

export function lrlNameMatches(lrlName: string, names: MemberNames): boolean {
  const ours = new Set([names.fullName, ...(names.aliases ?? [])].map(foldName).filter(Boolean));
  return lrlNameForms(lrlName).some((f) => ours.has(foldName(f)));
}

const lrlUrl = (id: string): string => `https://www.lrl.mn.gov/legdb/fulldetail?ID=${id}`;

/** Raw HTML, robots-checked, with the project's own user-agent. Throws on a refusal or a non-2xx. */
export async function fetchRawHtml(url: string): Promise<string> {
  if (!(await robotsAllows(url))) throw Object.assign(new Error('robots_disallowed'), { code: 'robots_disallowed' });
  const res = await fetch(url, {
    redirect: 'follow',
    signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
    headers: { 'user-agent': EMPOWERED_VOTE_UA, accept: 'text/html,application/xhtml+xml' },
  });
  if (!res.ok) throw new Error('HTTP ' + res.status);
  return await res.text();
}

/**
 * Returns a check for verifyEvidence's `memberLinkCheck`: true when the Revisor bill page at `url` lists
 * the person as an author by member link. Pages and LRL records are cached for the batch; any fetch
 * failure answers false (the source then stays failed, as before).
 */
export function createRevisorAuthorCheck(
  fetchHtml: (url: string) => Promise<string> = fetchRawHtml,
): (url: string, names: MemberNames) => Promise<boolean> {
  const pages = new Map<string, Promise<AuthorLink[]>>();
  const members = new Map<string, Promise<string | null>>();
  const links = (url: string) => {
    if (!pages.has(url)) pages.set(url, fetchHtml(url).then(parseRevisorAuthorLinks, () => []));
    return pages.get(url)!;
  };
  const member = (id: string) => {
    if (!members.has(id)) members.set(id, fetchHtml(lrlUrl(id)).then(lrlNameFromHtml, () => null));
    return members.get(id)!;
  };
  return async (url, names) => {
    if (!isRevisorBillUrl(url)) return false;
    // By id (CA_0401): a person whose LRL id we hold is an author exactly when an author link carries that
    // id. No name is read and no LRL record is fetched, so a namesake can never pass — and a stored id that
    // is not on the page is a firm "no", never a fall-through to the name path below.
    const lrlIds = names.memberIds?.[MN_LRL];
    if (lrlIds?.length) return (await links(url)).some((l) => lrlIds.includes(l.id));
    const family = foldName(names.lastName);
    for (const link of await links(url)) {
      if (labelFamily(link.label) !== family) continue;
      const lrl = await member(link.id);
      if (lrl && lrlNameMatches(lrl, names)) return true;
    }
    return false;
  };
}
