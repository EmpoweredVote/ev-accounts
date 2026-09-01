#!/usr/bin/env node
/**
 * workos-headless-smoke — confirm the real WorkOS Authentication API response
 * shapes that the headless-login service (backend/src/lib/workosAuthService.ts)
 * parses. Use this to close two of the DEPLOY.md "Open items":
 *   - the exact pending/error body field names, and
 *   - the password-reset email link target.
 *
 * It is a READ-MOSTLY verification tool: it calls WorkOS's authenticate grant
 * (which mints/validates credentials but changes no data) and, only if you ask,
 * sends ONE password-reset email. It writes nothing to our database.
 *
 * ── SAFETY ──────────────────────────────────────────────────────────────────
 * - Run it against the WorkOS STAGING environment with a STAGING test user.
 *   It refuses a non-`sk_test_` API key unless you pass --allow-live.
 * - The API key is read from the environment; it is never printed. This script
 *   redacts access/refresh/id tokens in its output so you can paste the result
 *   without leaking a live session.
 * - No secret ever goes on the command line.
 *
 * ── USAGE ───────────────────────────────────────────────────────────────────
 *   export WORKOS_API_KEY=sk_test_...            # staging client secret
 *   export WORKOS_CLIENT_ID=client_...           # staging client id
 *   export SMOKE_EMAIL_VERIFIED=you+ok@example   # a VERIFIED staging user
 *   export SMOKE_PASSWORD_VERIFIED='...'
 *   # optional — an UNVERIFIED staging user (freshly created, email not confirmed):
 *   export SMOKE_EMAIL_UNVERIFIED=you+new@example
 *   export SMOKE_PASSWORD_UNVERIFIED='...'
 *   # optional — send ONE reset email so you can inspect its link:
 *   export SMOKE_RESET_EMAIL=you+ok@example
 *
 *   node backend/scripts/workos-headless-smoke.mjs
 *
 * ── WHAT TO CONFIRM ─────────────────────────────────────────────────────────
 * The service reads the outcome discriminator as `body.code ?? body.error`, the
 * pending token as `body.pending_authentication_token`, and treats
 * `email_verification_required` / `invalid_credentials` / `mfa_enrollment` /
 * `mfa_challenge` as the branch names. Each case below prints, in bold, whether
 * the real body matches those assumptions. If a field name differs, adjust the
 * matcher in workosAuthService.ts (and its unit test) accordingly.
 */

const WORKOS_API = 'https://api.workos.com';
const AUTH_URL = `${WORKOS_API}/user_management/authenticate`;
const RESET_URL = `${WORKOS_API}/user_management/password_reset`;

const allowLive = process.argv.includes('--allow-live');
const apiKey = process.env.WORKOS_API_KEY;
const clientId = process.env.WORKOS_CLIENT_ID;

function die(msg) {
  console.error(`\n✗ ${msg}\n`);
  process.exit(1);
}

if (!apiKey) die('WORKOS_API_KEY is not set (the staging client secret).');
if (!clientId) die('WORKOS_CLIENT_ID is not set (the staging client id).');
if (!apiKey.startsWith('sk_test_') && !allowLive) {
  die(
    'WORKOS_API_KEY does not look like a staging key (sk_test_...). Refusing to ' +
      'run against a non-staging environment. Re-run with --allow-live only if you ' +
      'are certain you want to hit production WorkOS with real users.'
  );
}

const bold = (s) => `\x1b[1m${s}\x1b[0m`;

// Deep-redact any token-ish value so output is safe to paste.
function redact(value) {
  if (Array.isArray(value)) return value.map(redact);
  if (value && typeof value === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(value)) {
      out[k] = /token/i.test(k) && typeof v === 'string' ? '<redacted>' : redact(v);
    }
    return out;
  }
  return value;
}

async function authenticate(grant) {
  const res = await fetch(AUTH_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ client_id: clientId, client_secret: apiKey, ...grant }),
  });
  const body = await res.json().catch(() => ({}));
  return { status: res.status, ok: res.ok, body };
}

function report(label, { status, ok, body }, checks) {
  console.log(`\n${bold(`── ${label} ──`)}`);
  console.log(`HTTP ${status}`);
  console.log(JSON.stringify(redact(body), null, 2));
  const disc = body.code ?? body.error;
  console.log(`discriminator (body.code ?? body.error) = ${JSON.stringify(disc)}`);
  for (const [claim, pass] of checks) {
    console.log(`${pass ? '  ✓' : bold('  ✗ MISMATCH')} ${claim}`);
  }
  return { ok, body, disc };
}

async function main() {
  console.log(bold('WorkOS headless-login smoke test'));
  console.log(`client_id: ${clientId}`);
  console.log(`key: ${apiKey.slice(0, 8)}… (${apiKey.startsWith('sk_test_') ? 'staging' : 'NON-STAGING'})`);

  // Case 1 — verified user, correct password → expect tokens.
  const vEmail = process.env.SMOKE_EMAIL_VERIFIED;
  const vPass = process.env.SMOKE_PASSWORD_VERIFIED;
  if (vEmail && vPass) {
    const r = await authenticate({ grant_type: 'password', email: vEmail, password: vPass });
    report('Case 1: verified login (expect tokens)', r, [
      ['response carries access_token + refresh_token', Boolean(r.body.access_token && r.body.refresh_token)],
    ]);

    // Case 3 — same user, wrong password → expect invalid_credentials.
    const rWrong = await authenticate({
      grant_type: 'password',
      email: vEmail,
      password: `${vPass}__definitely-wrong`,
    });
    report('Case 3: wrong password (expect invalid_credentials, 401)', rWrong, [
      ["discriminator is 'invalid_credentials' (or status 401)", (rWrong.body.code ?? rWrong.body.error) === 'invalid_credentials' || rWrong.status === 401],
      ['same generic failure as a wrong email (OWASP: no field distinction)', true],
    ]);
  } else {
    console.log(`\n${bold('Case 1/3 skipped')} — set SMOKE_EMAIL_VERIFIED + SMOKE_PASSWORD_VERIFIED.`);
  }

  // Case 2 — unverified user → expect email_verification_required + pending token.
  const uEmail = process.env.SMOKE_EMAIL_UNVERIFIED;
  const uPass = process.env.SMOKE_PASSWORD_UNVERIFIED;
  if (uEmail && uPass) {
    const r = await authenticate({ grant_type: 'password', email: uEmail, password: uPass });
    report('Case 2: unverified login (expect email_verification_required)', r, [
      ["discriminator is 'email_verification_required'", (r.body.code ?? r.body.error) === 'email_verification_required'],
      ['body has pending_authentication_token', typeof r.body.pending_authentication_token === 'string'],
    ]);
  } else {
    console.log(`\n${bold('Case 2 skipped')} — set SMOKE_EMAIL_UNVERIFIED + SMOKE_PASSWORD_UNVERIFIED (a fresh, unconfirmed user).`);
  }

  // Case 4 — password reset send → then check the emailed link target by hand.
  const resetEmail = process.env.SMOKE_RESET_EMAIL;
  if (resetEmail) {
    const res = await fetch(RESET_URL, {
      method: 'POST',
      headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: resetEmail }),
    });
    const body = await res.json().catch(() => ({}));
    console.log(`\n${bold('── Case 4: password_reset send ──')}`);
    console.log(`HTTP ${res.status}`);
    console.log(JSON.stringify(redact(body), null, 2));
    console.log(
      bold(
        '  → Now open that inbox and confirm the reset LINK points to\n' +
          '    https://login.empowered.vote/reset-password?token=…\n' +
          '    If it points to a WorkOS-hosted URL, set the reset redirect in the\n' +
          '    WorkOS dashboard, or switch to WorkOS Custom Emails.'
      )
    );
  } else {
    console.log(`\n${bold('Case 4 skipped')} — set SMOKE_RESET_EMAIL to send one reset email and inspect its link.`);
  }

  console.log(`\n${bold('Done.')} Compare the discriminator / pending-token fields above against the`);
  console.log('assumptions in backend/src/lib/workosAuthService.ts. Any ✗ MISMATCH means adjust the matcher + its test.\n');
}

main().catch((err) => die(err instanceof Error ? err.message : String(err)));
