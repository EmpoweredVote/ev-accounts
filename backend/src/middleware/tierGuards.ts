import { Request, Response, NextFunction } from 'express';
import type { AuthenticatedRequest } from './auth.js';
import { supabaseAdmin } from '../lib/supabase.js';

// Note: supabaseAdmin is used here intentionally — tier guards are trusted server-side
// checks, not user-facing data reads. The architecture enforcement test scans only
// src/routes/ for supabaseAdmin usage; src/middleware/ is excluded by design.
//
// 🔴 THE TWO connected_profiles GUARDS MUST AGREE ABOUT deleted_at. requireInform
// passes when the row is ABSENT and requireConnected passes when it is PRESENT
// and verified, so any condition one of them counts and the other does not
// produces a user both refuse. That limbo has no exit and the product has already
// shipped it once, via admin promotions stuck at verification_status='pending'
// (fixed in migration 1851).
//
// The suspension check in middleware/auth.ts deliberately does NOT filter
// deleted_at, and that asymmetry is intentional: it refuses a suspended account,
// so ignoring deleted_at fails closed there while honouring it would let a
// suspension be lifted by soft-deleting the profile.

export async function requireConnected(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authReq = req as AuthenticatedRequest;
  const { data, error } = await supabaseAdmin
    .schema('connect')
    .from('connected_profiles')
    .select('id, verification_status')
    .eq('user_id', authReq.userId)
    // A soft-deleted profile must not grant Connected access. Nothing writes
    // deleted_at today, so this changes no behaviour now — it makes sure the
    // column means something the day it is used, in the fail-closed direction.
    .is('deleted_at', null)
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
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authReq = req as AuthenticatedRequest;
  const { data, error } = await supabaseAdmin
    .schema('empower')
    .from('empowered_profiles')
    .select('id, is_active')
    .eq('user_id', authReq.userId)
    .maybeSingle();

  if (error || !data || !data.is_active) {
    res.status(403).json({ error: 'Active Empowered account required' });
    return;
  }

  next();
}

export async function requireInform(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authReq = req as AuthenticatedRequest;
  const { data } = await supabaseAdmin
    .schema('connect')
    .from('connected_profiles')
    .select('id')
    .eq('user_id', authReq.userId)
    // Must agree with requireConnected above, or a soft-deleted profile leaves
    // the user in limbo: refused Connected (not verified / not present) AND
    // refused Inform (a row exists). That state has no exit, and we have already
    // shipped it once — see migration 1851 and the admin-promotion 'pending' bug.
    .is('deleted_at', null)
    .maybeSingle();

  if (data) {
    res.status(403).json({ error: 'Inform-tier account required' });
    return;
  }

  next();
}
