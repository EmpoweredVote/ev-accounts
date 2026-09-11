import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.string().default('3000'),
  SUPABASE_URL: z.string().url(),
  SUPABASE_ANON_KEY: z.string().min(1),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  // SUPABASE_PUBLISHABLE_KEY: the sb_publishable_... replacement for the legacy
  // anon key. Optional during the migration — supabaseAnon and createUserClient
  // prefer it and fall back to SUPABASE_ANON_KEY, so this can be set in Render
  // before the legacy anon key is disabled and no deploy has to line up with it.
  // Legacy anon and service_role keys are removed by Supabase in late 2026.
  SUPABASE_PUBLISHABLE_KEY: z.string().optional(),
  // READRANK_TOKEN_SECRET: HMAC secret for the Read & Rank blind candidateToken.
  // REQUIRED, and deliberately not optional: it previously fell back to
  // SUPABASE_SERVICE_ROLE_KEY, which is an API key, is readable by every member
  // of the Supabase organisation, and was publicly leaked (ev-cto watchlist #38).
  // Anyone holding it could compute every candidate token and de-anonymise the
  // blind ballot without playing it. This must be an independent random secret
  // with no other job. Rotating it only changes tokens issued from then on --
  // computeRaceMatch matches on quote_id and never reads the token.
  READRANK_TOKEN_SECRET: z.string().min(1),
  DATABASE_URL: z.string().min(1),
  REDIS_URL: z.string().optional(),
  CORS_ORIGIN: z.string().optional(),
  COOKIE_DOMAIN: z.string().optional().default(''),
  SUPABASE_JWT_SECRET: z.string().optional(),
  // Geocoding was replaced by Census Geocoder in Phase 38 and does NOT use this key —
  // its zero-match fallback is the USDOT National Address Database, which needs no key
  // (see geocodingService.ts). This is now only the fallback for the Civic Information
  // API (see GOOGLE_CIVIC_API_KEY). Kept optional to avoid startup failures without it.
  GOOGLE_MAPS_API_KEY: z.string().optional(),
  // GOOGLE_CIVIC_API_KEY: powers /api/essentials/voter-info (Google Civic
  // Information API voterInfoQuery — VIP voting locations + sample-ballot URLs).
  // Optional — if unset, voterInfoService falls back to GOOGLE_MAPS_API_KEY (same
  // Google Cloud key as Places). Absent entirely = voter-info returns a safe empty
  // payload and the UI hides the card. Requires the Civic Information API enabled
  // on the project and a key NOT restricted to HTTP referrers (server-side call).
  GOOGLE_CIVIC_API_KEY: z.string().optional(),
  // XP service keys — one per feature repo. Optional: undefined key = not in
  // SERVICE_KEY_MAP = 401 on all requests from that repo. Kept optional so
  // existing integration tests (health, auth, account) don't break at startup.
  TRIVIA_SERVICE_KEY: z.string().optional(),
  LISTENING_XP_KEY: z.string().optional(),
  ADMIN_SERVICE_KEY: z.string().optional(),
  ESSENTIALS_SERVICE_KEY: z.string().optional(),
  // Campaign finance adapter keys — all optional; absent = feature degraded but server still starts.
  // FEC_API_KEY: register free at api.data.gov/signup/ for 1000 req/hr limit.
  FEC_API_KEY: z.string().optional(),
  // CONGRESS_GOV_API_KEY: free api.data.gov key (register at https://api.congress.gov)
  // for the congress.gov official-API verification tier (congressAdapter). Optional —
  // absent = the adapter is a no-op and congress.gov URLs fall through to the fetch
  // ladder (tier 1 → Wayback), today's behavior. Lives in the Render dashboard, never in git.
  CONGRESS_GOV_API_KEY: z.string().optional(),
  // ADMIN_INGEST_TOKEN: pre-shared token for POST /admin/ingest/:adapter.
  ADMIN_INGEST_TOKEN: z.string(),
  // SQS_INGEST_QUEUE_URL: optional SQS queue URL for EventBridge-triggered ingestion.
  SQS_INGEST_QUEUE_URL: z.string().optional(),
  // SOCRATA_APP_TOKEN: optional app token for LA Socrata API requests.
  SOCRATA_APP_TOKEN: z.string().optional(),
  // ANTHROPIC_API_KEY: powers the v2.1 Claude candidate discovery agent (discoveryAgentRunner).
  // Optional: absent = discovery endpoints return 503. Web search must be enabled org-wide
  // in the Claude Console before this works (console.anthropic.com/settings/privacy).
  ANTHROPIC_API_KEY: z.string().optional(),
  // Feedback pipeline (quick-260428-fp1) — all optional so server starts without them in dev.
  // LINEAR_API_KEY: Personal API key from linear.app Settings → API.
  LINEAR_API_KEY: z.string().optional(),
  // LINEAR_TEAM_ID: UUID from Linear Settings → General → Team ID.
  LINEAR_TEAM_ID: z.string().optional(),
  // LINEAR_PROJECT_ID: UUID from the project URL in Linear (/project/<uuid>).
  LINEAR_PROJECT_ID: z.string().optional(),
  // RESEND_API_KEY: API key from resend.com for transactional email (admin
  // notifications etc.). Not used by the feedback path — feedback emails
  // are sent natively by Linear via project subscribers.
  RESEND_API_KEY: z.string().optional(),
  // LOGIN_URL: base URL of the login frontend. Used as the base for auth email
  // redirect URLs (confirmation, password reset). Defaults to production URL.
  LOGIN_URL: z.string().url().default('https://login.empowered.vote'),
  // WorkOS AuthKit (Supabase Auth → WorkOS migration, decision 0002).
  // WORKOS_CLIENT_ID enables acceptance of WorkOS-issued access tokens as a
  // second issuer during the migration window. Absent = Supabase-only, today's
  // behavior. The client id is public, not a secret; the WorkOS API key is NOT
  // needed here — token verification uses the public JWKS.
  WORKOS_CLIENT_ID: z.string().optional(),
  // Overrides for custom auth domains. Defaults derive from WORKOS_CLIENT_ID
  // (see src/lib/tokenIdentity.ts).
  WORKOS_ISSUER: z.string().url().optional(),
  WORKOS_JWKS_URL: z.string().url().optional(),
  // WORKOS_API_KEY: server-side WorkOS secret. Needed by the new-signup
  // provisioning endpoint (POST /api/auth/workos/provision) and by WorkOS-first
  // signup, both of which write external_id back to WorkOS. Absent = those
  // paths return 503; token verification never uses it. Lives in the Render
  // dashboard, never in git.
  WORKOS_API_KEY: z.string().optional(),
  // AUTHKIT_PRIMARY: cutover switch for WHERE NEW CREDENTIALS ARE CREATED.
  //   'false'/absent — POST /api/auth/signup creates a Supabase user holding
  //     the password (today's behavior).
  //   'true'  — signup creates the WorkOS user holding the password and a
  //     Supabase shadow row whose only credential is a random unknowable hash
  //     (Supabase writes one even with no password given; it is cleared by the
  //     gated batch null step at cutover). New accounts hold no USABLE Supabase
  //     credential (PRIVACY-ARCHITECTURE property A).
  // Flip together with the frontends' VITE_AUTHKIT_ONLY: with this false and
  // the UI AuthKit-only, new signups could not sign in; with this true and the
  // UI classic-only, they could not either.
  AUTHKIT_PRIMARY: z.enum(['true', 'false']).default('false'),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('[startup] Missing or invalid environment variables:');
  console.error(JSON.stringify(parsed.error.flatten().fieldErrors, null, 2));
  process.exit(1);
}

export const env = parsed.data;
