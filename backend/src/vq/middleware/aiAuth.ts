/**
 * aiAuth.ts
 * AI agent authentication middleware.
 *
 * Authenticates via `x-api-key` header matched against SHA-256 hashed key
 * stored in `validation_quests.ai_agent_credentials`.
 *
 * Sets on req:
 *   req.agentId      — ai_agent_credentials.id (used as user_id on submissions)
 *   req.agentName    — ai_agent_credentials.agent_name (for logging)
 *   req.isAiAgent    — true (so route handlers can branch if needed)
 */

import { createHash } from 'node:crypto';
import { supabaseService } from '../lib/supabase.js';
import { logger } from '../lib/logger.js';

export async function requireAiApiKey(req: any, res: any, next: any) {
  const apiKey = req.headers['x-api-key'];

  if (!apiKey || typeof apiKey !== 'string') {
    return res.status(401).json({ error: 'Missing x-api-key header' });
  }

  // SHA-256 hash the raw API key for lookup
  const keyHash = createHash('sha256').update(apiKey).digest('hex');

  const { data, error } = await supabaseService
    .schema('validation_quests')
    .from('ai_agent_credentials')
    .select('id, agent_name, is_active, rate_limit_per_hour')
    .eq('api_key_hash', keyHash)
    .eq('is_active', true)
    .maybeSingle();

  if (error) {
    logger.error('Failed to look up AI agent credentials', { error: error.message });
    return res.status(401).json({ error: 'Invalid or inactive API key' });
  }

  if (!data) {
    return res.status(401).json({ error: 'Invalid or inactive API key' });
  }

  req.agentId = data.id;
  req.agentName = data.agent_name;
  req.isAiAgent = true;

  next();
}
