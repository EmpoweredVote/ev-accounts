import { createClient } from '@supabase/supabase-js';
// Import Database type when generated (Plan 01-03). For now, use generic.

// Anon client: respects RLS — use in route handlers for user requests
export const supabaseAnon = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!
);

// Service role client: bypasses RLS — use ONLY in background jobs and admin operations
// NEVER use in route handlers responding to user requests
export const supabaseService = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  { auth: { persistSession: false } }
);
