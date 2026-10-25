#!/usr/bin/env node
/**
 * check-voter-info-live.mjs
 *
 * Fails when the "how to vote" pipeline is refusing to work.
 *
 * WHY THIS EXISTS. `/api/essentials/voter-info` is written to degrade to an
 * empty payload on any upstream failure, so that the UI can always fall back to
 * official links. That is good UI behaviour and terrible operational behaviour:
 * it made an outage indistinguishable from a quiet off-cycle week. Google had
 * been answering 403 on EVERY call — every address, every state, fourteen days
 * before a general election — and nothing reported it. It surfaced only because
 * someone read the Render logs while chasing an unrelated bug.
 *
 * A fallback with no alarm is an outage you hear about from a user. This is the
 * alarm.
 *
 * WHAT IT ASSERTS: that the upstream is reachable and willing to answer, NOT
 * that an election is live. `status: 'no_election'` passes — most of the year
 * there genuinely is none. Only `status: 'unavailable'` fails, which means the
 * upstream refused us, timed out, or no key is configured.
 *
 * Usage:
 *   node scripts/check-voter-info-live.mjs
 *   node scripts/check-voter-info-live.mjs --base http://localhost:10000
 *   node scripts/check-voter-info-live.mjs --json
 */

const argv = process.argv.slice(2);
const asJson = argv.includes('--json');
const base = argv.includes('--base')
  ? argv[argv.indexOf('--base') + 1]
  : 'https://ev-accounts-api.onrender.com';

// Spread across states so one state's quiet period cannot look like an outage,
// and one address in a state that runs elections on a different calendar.
const ADDRESSES = [
  '1600 Pennsylvania Ave NW, Washington, DC 20500',
  '233 S Wacker Dr, Chicago, IL 60606',
  '1 City Hall Sq, Boston, MA 02201',
];

async function probe(address) {
  const url = `${base}/api/essentials/voter-info?address=${encodeURIComponent(address)}`;
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(30_000) });
    if (!res.ok) return { address, ok: false, note: `proxy returned HTTP ${res.status}` };
    const body = await res.json();
    // An older deploy has no `status` field. Treat that as a pass rather than a
    // failure — this check must not go red merely because it shipped first.
    if (typeof body.status !== 'string') {
      return { address, ok: true, status: 'unknown', note: 'deploy predates the status field' };
    }
    return { address, ok: body.status !== 'unavailable', status: body.status };
  } catch (err) {
    return { address, ok: false, note: `could not reach the proxy: ${err.message}` };
  }
}

const results = [];
for (const address of ADDRESSES) results.push(await probe(address));

const failed = results.filter((r) => !r.ok);
if (asJson) {
  console.log(JSON.stringify({ ok: failed.length === 0, base, results }, null, 2));
} else {
  for (const r of results) {
    console.log(`${r.ok ? 'OK  ' : 'FAIL'}  ${r.status ?? '-'}  ${r.address}${r.note ? ` — ${r.note}` : ''}`);
  }
  if (failed.length) {
    console.log('');
    console.log('The voter-info upstream is refusing us, so the "how to vote" card is empty for');
    console.log('everyone. This is NOT an off-cycle quiet period — that reports `no_election`.');
    console.log('');
    console.log('Read the reason: the service now logs it. In the Render logs for ev-accounts-api,');
    console.log('filter on `voterInfo` and look for the text after the status code. Likely causes:');
    console.log('  SERVICE_DISABLED / accessNotConfigured  -> enable the Civic Information API on');
    console.log('      the key\'s Google Cloud project.');
    console.log('  "Requests from referer ... are blocked"  -> the key is HTTP-referrer restricted.');
    console.log('      A server-side call sends no referrer, so a browser Maps key can never work.');
    console.log('      Set an unrestricted or IP-restricted key as GOOGLE_CIVIC_API_KEY.');
    console.log('  API_KEY_SERVICE_BLOCKED                  -> the key\'s API restrictions exclude Civic.');
  }
}

process.exitCode = failed.length ? 1 : 0;
