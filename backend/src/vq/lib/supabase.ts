import { createClient } from '@supabase/supabase-js';
import { env } from '../../lib/env.js';
// Import Database type when generated (Plan 01-03). For now, use generic.

// Anon/public client: respects RLS — use in route handlers for user requests.
// Prefer the new publishable key (sb_publishable_...); fall back to the legacy
// SUPABASE_ANON_KEY. The legacy anon JWT is disabled on the project, so without
// the publishable fallback this client 401s on every request. Mirrors the
// PUBLIC_API_KEY selection in lib/supabase.ts.
export const supabaseAnon = createClient(
  env.SUPABASE_URL.trim(),
  (env.SUPABASE_PUBLISHABLE_KEY ?? env.SUPABASE_ANON_KEY).trim()
);

// Service role client: bypasses RLS — use ONLY in background jobs and admin operations
// NEVER use in route handlers responding to user requests
export const supabaseService = createClient(
  env.SUPABASE_URL.trim(),
  env.SUPABASE_SERVICE_ROLE_KEY.trim(),
  { auth: { persistSession: false } }
);
