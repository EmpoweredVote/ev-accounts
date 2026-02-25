import { Response, NextFunction } from 'express';
import type { AuthenticatedRequest } from './auth.js';
import { supabaseAdmin } from '../lib/supabase.js';

// Note: supabaseAdmin is used here intentionally — tier guards are trusted server-side
// checks, not user-facing data reads. The architecture enforcement test scans only
// src/routes/ for supabaseAdmin usage; src/middleware/ is excluded by design.

export async function requireConnected(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const { data, error } = await supabaseAdmin
    .schema('connect')
    .from('connected_profiles')
    .select('id, verification_status')
    .eq('user_id', req.userId)
    .maybeSingle();

  if (error || !data) {
    res.status(403).json({ error: 'Connected account required' });
    return;
  }

  if (data.verification_status !== 'verified') {
    res.status(403).json({ error: 'Verified Connected account required' });
    return;
  }

  next();
}

export async function requireEmpowered(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const { data, error } = await supabaseAdmin
    .schema('empower')
    .from('empowered_profiles')
    .select('id, is_active')
    .eq('user_id', req.userId)
    .maybeSingle();

  if (error || !data || !data.is_active) {
    res.status(403).json({ error: 'Active Empowered account required' });
    return;
  }

  next();
}
