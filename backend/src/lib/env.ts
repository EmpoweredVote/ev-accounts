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
  SUPABASE_JWT_SECRET: z.string().optional(),
  // Google Maps Geocoding API — server-side only; used by geocodingService.ts
  GOOGLE_MAPS_API_KEY: z.string().min(1),
  // XP service keys — one per feature repo. Optional: undefined key = not in
  // SERVICE_KEY_MAP = 401 on all requests from that repo. Kept optional so
  // existing integration tests (health, auth, account) don't break at startup.
  QUEST_SERVICE_KEY: z.string().optional(),
  TRIVIA_SERVICE_KEY: z.string().optional(),
  ADMIN_SERVICE_KEY: z.string().optional(),
  ESSENTIALS_SERVICE_KEY: z.string().optional(),
  // Gem service keys — JSON map: { "key": ["yellow"] }. Optional: absent = no gem award endpoints active.
  GEMS_SERVICE_KEYS: z.string().optional(),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('[startup] Missing or invalid environment variables:');
  console.error(JSON.stringify(parsed.error.flatten().fieldErrors, null, 2));
  process.exit(1);
}

export const env = parsed.data;
