import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.string().default('3000'),
  SUPABASE_URL: z.string().url(),
  SUPABASE_ANON_KEY: z.string().min(1),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  DATABASE_URL: z.string().min(1),
  REDIS_URL: z.string().optional(),
  CORS_ORIGIN: z.string().optional(),
  COOKIE_DOMAIN: z.string().optional().default(''),
  SUPABASE_JWT_SECRET: z.string().optional(),
  // Geocoding was replaced by Census Geocoder in Phase 38, but this key is now
  // reused as the fallback for the Civic Information API (see GOOGLE_CIVIC_API_KEY).
  // Kept optional to avoid startup failures on environments without it.
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
  QUEST_SERVICE_KEY: z.string().optional(),
  TRIVIA_SERVICE_KEY: z.string().optional(),
  LISTENING_XP_KEY: z.string().optional(),
  ADMIN_SERVICE_KEY: z.string().optional(),
  ESSENTIALS_SERVICE_KEY: z.string().optional(),
  // VQ_SERVICE_KEY: used by Validation Quests to POST crowd-verified officeholder
  // data to /api/essentials/ingest/quest-verified. Optional: absent = 401 on ingest.
  VQ_SERVICE_KEY: z.string().optional(),
  // Gem service keys — JSON map: { "key": ["yellow"] }. Optional: absent = no gem award endpoints active.
  GEMS_SERVICE_KEYS: z.string().optional(),
  // Campaign finance adapter keys — all optional; absent = feature degraded but server still starts.
  // FEC_API_KEY: register free at api.data.gov/signup/ for 1000 req/hr limit.
  FEC_API_KEY: z.string().optional(),
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
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('[startup] Missing or invalid environment variables:');
  console.error(JSON.stringify(parsed.error.flatten().fieldErrors, null, 2));
  process.exit(1);
}

export const env = parsed.data;
