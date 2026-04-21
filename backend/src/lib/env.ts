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
  // Deprecated: replaced by Census Geocoder in Phase 38. Kept optional to avoid
  // startup failures on environments that still have the key set.
  GOOGLE_MAPS_API_KEY: z.string().optional(),
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
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('[startup] Missing or invalid environment variables:');
  console.error(JSON.stringify(parsed.error.flatten().fieldErrors, null, 2));
  process.exit(1);
}

export const env = parsed.data;
