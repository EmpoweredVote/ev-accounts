/**
 * maLegislatureAdapter — source-specific verification tier for Massachusetts House roll-call PDFs
 * (malegislature.gov/RollCall/<General Court>/HouseRollCall<n>.pdf).
 *
 * The plain tier would extract the PDF's text, which interleaves four columns of vote marks and
 * surnames: no snippet in it can tie a name to a vote. This tier reads the PDF's positioned text and
 * returns the fixed render of maRollCallEvidence.ts instead, which lists members under their vote and
 * prints no party. A canonical line ("Massachusetts House roll call 135 (193rd General Court), H.4885 -
 * On acceptance of the report: Kilcoyne voted Yea.") verifies against that render.
 *
 * It returns null — a clean fall-through to the generic ladder — for any other URL, and when the PDF
 * cannot be fetched or does not read cleanly (a misread grid fails closed in readMaRollCall, and the
 * generic tier then serves the plain text, against which no vote line can verify).
 *
 * The site is public; there is no key. The fetch uses the caller's honest user-agent and is placed
 * AFTER the robots.txt gate in verificationFetch.ts, like any live fetch of a public site.
 */
import { extractPdfItems, looksLikePdfBytes } from '../pdfText.js';
import { parseMaRollCallUrl, readMaRollCall, renderMaRollCall } from '../maRollCallEvidence.js';

export type FetchLike = (url: string, init?: RequestInit) => Promise<Response>;
export interface MaDeps {
  fetchImpl?: FetchLike;
  userAgent?: string;
}

const HTTP_TIMEOUT_MS = 15_000;

/** The render of a Massachusetts House roll-call PDF, or null (not one, unreachable, or unreadable). */
export async function fetchMaRollCallText(url: string, deps: MaDeps = {}): Promise<string | null> {
  const ref = parseMaRollCallUrl(url);
  if (!ref) return null;
  let buf: Uint8Array;
  try {
    const res = await (deps.fetchImpl ?? fetch)(url.trim(), {
      redirect: 'follow',
      signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
      headers: { ...(deps.userAgent ? { 'user-agent': deps.userAgent } : {}), accept: 'application/pdf' },
    });
    if (!res.ok) return null;
    buf = new Uint8Array(await res.arrayBuffer());
  } catch {
    return null;
  }
  return renderMaRollCallBytes(buf, url);
}

/** Render PDF bytes already in hand (the batch tool reads a saved copy through this). */
export async function renderMaRollCallBytes(buf: Uint8Array, url: string): Promise<string | null> {
  const ref = parseMaRollCallUrl(url);
  if (!ref || !looksLikePdfBytes(buf)) return null;
  try {
    const r = readMaRollCall(await extractPdfItems(buf), ref.court);
    // The roll number the PDF prints must be the one the URL names.
    return r && r.rollNum === ref.rollNum ? renderMaRollCall(r) : null;
  } catch {
    return null;
  }
}
