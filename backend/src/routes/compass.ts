import { Router } from 'express';
import { z } from 'zod';
import { adminRpc } from '../lib/supabase.js';
import { requireAuth, optionalAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requestDb } from '../lib/supabase.js';
import {
  promoteCompassImportDraft,
  getCompassCompleteness,
  getCompassTopics,
  getCompassCategories,
  getCompassLenses,
  getCompassPoliticians,
  getCandidates,
  getCandidateAnswers,
  getPoliticianAnswers,
  getPoliticianContext,
  getPoliticianContextAll,
  validateTopicIds,
  isNoPromotedTopicsError,
  saveSelectedTopics,
  resetCompassAnswers,
  compareWithPoliticians,
  getUserVerdicts,
  getBatchPoliticianAnswers,
  getPoliticianCitations,
} from '../lib/compassService.js';
import {
  getUserLenses,
  replaceUserLenses,
  findUnknownTopicIds,
  getRecalibrationFlags,
  isLensKeyConflictError,
} from '../lib/compassUserLensService.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import type { Request, Response } from 'express';

/**
 * Compass routes (read + write).
 *
 * Architecture rules enforced here:
 *   - Service-role client is NOT used in this file — all DB access via compassService
 *   - Public reference data (topics, categories, politicians): compassService (supabaseAnon)
 *   - Owner-read routes (answers, selected-topics): createUserClient (RLS enforced)
 *   - Server-side computations (progress): compassService via RPC
 *   - Write routes (POST /answers): adminRpc (SECURITY DEFINER RPC)
 *   - Write routes (PUT /selected-topics): compassService (createUserClient)
 *
 * Route ordering: specific paths before parameterized paths to prevent
 * Express routing conflicts (e.g., /politicians before /politicians/:id).
 *
 * Anonymous compass mode (optionalAuth + short-circuit guards):
 *   - GET /answers, POST /answers/batch, GET /selected-topics,
 *     PUT /selected-topics, POST /answers all use optionalAuth.
 *   - When !authReq.userId (unauthenticated), these routes return empty data
 *     ([], { topic_ids: [] }, or null) immediately — no DB access.
 *   - Authenticated calls are fully preserved (same path, same logic).
 *   - DELETE /answers/me and GET /progress remain requireAuth (always protected).
 */

const router = Router();

// ---------------------------------------------------------------------------
// Validation schemas
// ---------------------------------------------------------------------------

const batchAnswersSchema = z.object({
  ids: z.array(z.string().uuid()).min(1).max(100),
});

const postAnswerSchema = z.object({
  topic_id: z.string().uuid(),
  value: z.number().multipleOf(0.5).min(0.5).max(5.5),
  write_in_text: z.string().max(500).optional(),
  inverted: z.boolean().optional().default(false),
});

const putSelectedTopicsSchema = z.object({
  topic_ids: z.array(z.string().uuid()).min(0).max(50),
});

// A user lens key is client-generated and GLOBALLY unique, so it can become a
// share link without being rewritten (migration 1849). The `u_` prefix is
// required for one concrete reason: keys from this table and keys from the
// curated inform.compass_lenses table ('local', 'federal', 'judicial') are read
// by the same client-side lens switcher, and a user lens named 'federal' would
// shadow the editorial one. The prefix makes collision impossible rather than
// unlikely.
const userLensKeyRegex = /^u_[a-z0-9]{4,32}$/;

const userLensSchema = z.object({
  key: z.string().regex(userLensKeyRegex, 'Lens key must look like u_7f3a91'),
  name: z.string().trim().min(1).max(60),
  // Max 8 — the compass renders a radar chart and more than 8 axes is
  // unreadable. A product decision, mirrored by a CHECK constraint in 1849.
  // Min 0 — a lens is named before it is filled.
  topic_ids: z.array(z.string().uuid()).min(0).max(8),
  visibility: z.enum(['private', 'unlisted']).optional(),
});

const putMyLensesSchema = z.object({
  // 20 is a payload guard, not a product ceiling. The whole set rides in one
  // request (and, for guests, in the shared ev-context payload), so an unbounded
  // array here is an unbounded payload there.
  lenses: z.array(userLensSchema).min(0).max(20),
});

const compareSchema = z.object({
  politician_ids: z.array(z.string().uuid()).min(1).max(50),
});

const batchPoliticianAnswersSchema = z.object({
  topic_ids: z.array(z.string().uuid()).min(1).max(100),
});

// New format: { verdicts: [{ quote_id, supported, rank, session_size }] }
const postVerdictsNewSchema = z.object({
  verdicts: z.array(
    z.object({
      quote_id: z.string().uuid(),
      supported: z.boolean(),
      rank: z.number().int().min(1).nullable(),
      session_size: z.number().int().min(1),
    })
  ).min(1).max(200),
});

// Legacy format (Go backend / Read & Rank): [{ quote_id, verdict: "agreed"|"disagreed" }]
const postVerdictsLegacySchema = z.array(
  z.object({
    quote_id: z.string().uuid(),
    verdict: z.enum(['agreed', 'disagreed']),
  })
).min(1).max(200);

const VALID_ROLE_SCOPES = ['city_council', 'state_legislature', 'us_congress', 'president'] as const;

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// ---------------------------------------------------------------------------
// GET /api/compass/topics
// Auth: optional — works unauthenticated
// Returns all live topics with nested stances, categories, and role scopes.
// ---------------------------------------------------------------------------

router.get('/topics', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const result = await getCompassTopics();
    res.status(200).json(result);
  } catch (err) {
    console.error('[GET /compass/topics] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/compass/categories
// Auth: optional — works unauthenticated
// Returns all categories with their nested live topics.
// ---------------------------------------------------------------------------

router.get('/categories', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const result = await getCompassCategories();
    res.status(200).json(result);
  } catch (err) {
    console.error('[GET /compass/categories] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/compass/lenses
// Auth: optional — works unauthenticated
// Returns active lenses (Local/Federal/Judicial) with ordered topicIds and the
// per-office auto-apply scope. Shared source of truth for Compass + Essentials.
// ---------------------------------------------------------------------------

router.get('/lenses', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const result = await getCompassLenses();
    res.status(200).json(result);
  } catch (err) {
    console.error('[GET /compass/lenses] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/compass/my-lenses
// Auth: optional — unauthenticated returns 200 []
// The caller's own custom lenses, each with the topics they should recalibrate.
//
// Guests get [] and no DB access, matching every other optionalAuth route here.
// That is not a degraded mode: a guest's lenses live client-side and ride in the
// shared ev-context payload until sign-in promotes them via PUT.
//
// `needsRecalibration` is computed per lens rather than returned as one flat list
// because the same topic can sit in several lenses and the prompt belongs next to
// each of them. See compassUserLensService for the rule — in short, an editorial
// or clarifying edit can never raise a flag (ADR 0006 §2 keeps the version
// stable), and a substantive one only raises it when the rungs at or beside the
// user's own answer actually moved.
// ---------------------------------------------------------------------------

router.get('/my-lenses', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const authReq = req as AuthenticatedRequest;
  if (!authReq.userId) { res.status(200).json([]); return; }

  try {
    const lenses = await getUserLenses(authReq.userId);

    // One flags query for the union of every lens's topics, then partitioned
    // per lens. One round trip regardless of how many lenses the user has.
    const allTopicIds = [...new Set(lenses.flatMap(l => l.topicIds))];
    const flags = await getRecalibrationFlags(authReq.userId, allTopicIds);
    const flagsByTopic = new Map(flags.map(f => [f.topicId, f]));

    res.status(200).json(
      lenses.map(lens => ({
        ...lens,
        needsRecalibration: lens.topicIds
          .map(id => flagsByTopic.get(id))
          .filter((f): f is NonNullable<typeof f> => f !== undefined),
      }))
    );
  } catch (err) {
    console.error('[GET /compass/my-lenses] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// PUT /api/compass/my-lenses
// Auth: optional — unauthenticated returns 200 []
// Replaces the caller's entire lens set. Body: { lenses: [...] }.
//
// Whole-set replace so a guest's local collection promotes in one atomic request
// on sign-in. Lenses absent from the body are deleted.
//
// 🔴 THIS DOES NOT VALIDATE AGAINST THE OPEN SEASON, AND THE DIFFERENCE FROM
// PUT /selected-topics IS DELIBERATE. That route 422s any topic outside the
// season's question set, which is right for the live compass. Applying it here
// would mean a season rollover empties a lens the user built and named — data
// loss dressed as validation. A lens may hold a topic this season does not ask;
// GET reports it as 'not_asked_this_season' and the user decides. What a lens may
// not hold is an id that names no topic at all, which is what is checked here.
// ---------------------------------------------------------------------------

router.put('/my-lenses', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const authReq = req as AuthenticatedRequest;
  if (!authReq.userId) { res.status(200).json([]); return; }

  const parsed = putMyLensesSchema.safeParse(req.body);
  if (!parsed.success) {
    const firstIssue = parsed.error.issues[0];
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: firstIssue?.message ?? 'Invalid request body',
    });
    return;
  }

  const { lenses } = parsed.data;

  // Zod validates each lens in isolation and cannot see a key repeated across
  // two of them. Left unchecked the upsert loop would silently collapse them
  // into one row and return fewer lenses than were sent, which reads as data
  // loss to the caller.
  const keys = lenses.map(l => l.key);
  const duplicateKeys = [...new Set(keys.filter((k, i) => keys.indexOf(k) !== i))];
  if (duplicateKeys.length > 0) {
    res.status(422).json({
      code: 'DUPLICATE_LENS_KEYS',
      message: `Lens keys must be unique within a request: ${duplicateKeys.join(', ')}`,
      duplicate_keys: duplicateKeys,
    });
    return;
  }

  try {
    const unknownIds = await findUnknownTopicIds(lenses.flatMap(l => l.topic_ids));
    if (unknownIds.length > 0) {
      res.status(422).json({
        code: 'UNKNOWN_TOPIC_IDS',
        message: `The following topic IDs do not exist: ${unknownIds.join(', ')}`,
        invalid_ids: unknownIds,
      });
      return;
    }

    const saved = await replaceUserLenses(authReq.userId, lenses);
    res.status(200).json(saved);
  } catch (err) {
    // Someone else already holds one of these keys. 409, not 422: the body is
    // well-formed and the caller did nothing wrong — the key is simply taken,
    // and the client's move is to regenerate it and retry, which is a conflict's
    // meaning and not a validation failure's.
    if (isLensKeyConflictError(err)) {
      res.status(409).json({
        code: err.code,
        message: 'One or more lens keys are already in use. Generate new keys and retry.',
        conflicting_keys: err.keys,
      });
      return;
    }
    console.error('[PUT /compass/my-lenses] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// DELETE /api/compass/answers/me
// Auth: required
// Soft-deletes all of the user's compass responses and clears selected_topic_ids.
// Idempotent — returns 200 even when the user has no responses.
// Optional: ?full=true — admin-only flag that also resets completed_onboarding.
// Delegates to reset_compass_answers SECURITY DEFINER RPC for atomicity.
// ---------------------------------------------------------------------------

router.delete(
  '/answers/me',
  requireAuth,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;
    const fullReset = req.query.full === 'true';

    if (fullReset) {
      // requireAdmin is async middleware — invoke it manually for conditional check
      await new Promise<void>((resolve, reject) => {
        requireAdmin(req, res, (err?: unknown) => {
          if (err) reject(err); else resolve();
        });
      }).catch(() => {
        // requireAdmin already sent the 403 response
      });
      // If requireAdmin sent a response, res.headersSent will be true
      if (res.headersSent) return;
    }

    try {
      await resetCompassAnswers(authReq.userId, fullReset);
      res.status(200).json({ reset: true });
    } catch (err) {
      console.error('[DELETE /compass/answers/me] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/compass/answers
// Auth: optional — unauthenticated returns 200 []
// Returns user's own compass responses including the inverted field.
// Triggers lazy promotion of compass_import_draft on first call (non-fatal).
// Uses createUserClient — RLS enforces owner-only access to compass_responses.
// ---------------------------------------------------------------------------

router.get('/answers', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const authReq = req as AuthenticatedRequest;
  if (!authReq.userId) { res.status(200).json([]); return; }

  try {
    // Lazy promotion — non-fatal if it fails (draft preserved for retry)
    await promoteCompassImportDraft(authReq.userId);

    const db = requestDb(authReq.accessToken);
    const { data, error } = await db
      .schema('inform')
      .from('compass_responses')
      .select('topic_id, value, write_in_text, visibility, inverted, created_at, updated_at')
      .is('deleted_at', null);

    if (error) {
      console.error('[GET /compass/answers] Supabase error:', error);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
      return;
    }

    res.status(200).json(data ?? []);
  } catch (err) {
    console.error('[GET /compass/answers] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/compass/answers/batch
// Auth: optional — unauthenticated returns 200 []
// Returns answers for a specific list of topic IDs.
// Body: { ids: string[] } — array of topic UUID strings (1-100 items).
// Uses createUserClient — RLS enforces owner-only access.
// ---------------------------------------------------------------------------

router.post('/answers/batch', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const authReq = req as AuthenticatedRequest;
  if (!authReq.userId) { res.status(200).json([]); return; }

  const parsed = batchAnswersSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: parsed.error.issues[0]?.message ?? 'Invalid request body',
    });
    return;
  }

  try {
    const db = requestDb(authReq.accessToken);
    const { data, error } = await db
      .schema('inform')
      .from('compass_responses')
      .select('topic_id, value, write_in_text')
      .in('topic_id', parsed.data.ids)
      .is('deleted_at', null);

    if (error) {
      console.error('[POST /compass/answers/batch] Supabase error:', error);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
      return;
    }

    res.status(200).json(data ?? []);
  } catch (err) {
    console.error('[POST /compass/answers/batch] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/compass/selected-topics
// Auth: optional — unauthenticated returns 200 []
// Returns flat array of topic IDs (Go-parity response shape).
// Uses createUserClient — RLS enforces owner-only access to connected_profiles.
// Returns empty array if user has not completed the Connect flow (no 403).
// ---------------------------------------------------------------------------

router.get(
  '/selected-topics',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;
    if (!authReq.userId) { res.status(200).json([]); return; }

    try {
      const db = requestDb(authReq.accessToken);
      const { data, error } = await db
        .schema('connect')
        .from('connected_profiles')
        .select('selected_topic_ids')
        .eq('user_id', authReq.userId)
        .maybeSingle();

      if (error) {
        console.error('[GET /compass/selected-topics] Supabase error:', error);
        res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
        return;
      }

      // No connected profile — return empty array (Go backend returns [] for no selections)
      if (!data) {
        res.status(200).json([]);
        return;
      }

      res.status(200).json(data.selected_topic_ids ?? []);
    } catch (err) {
      console.error('[GET /compass/selected-topics] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/compass/progress
// Auth: required
// Returns calibration completeness score.
// Optional query param: ?role= (city_council|state_legislature|us_congress|president)
// When role is provided, only counts topics required for that role scope.
// When role is absent, counts all live topics.
// ---------------------------------------------------------------------------

router.get('/progress', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const authReq = req as AuthenticatedRequest;

  try {
    const roleParam = typeof req.query.role === 'string' ? req.query.role : undefined;

    if (roleParam !== undefined && !(VALID_ROLE_SCOPES as readonly string[]).includes(roleParam)) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: `Invalid role. Must be one of: ${VALID_ROLE_SCOPES.join(', ')}`,
      });
      return;
    }

    const progress = await getCompassCompleteness(authReq.userId, roleParam);
    res.status(200).json(progress);
  } catch (err) {
    console.error('[GET /compass/progress] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/compass/compare
// Auth: required
// Computes proximity-based alignment scores between the calling user and one
// or more politicians. Only topics where BOTH user and politician have answers
// are included. Body: { politician_ids: string[] } (1-50 UUIDs).
// Returns: { politicians: CompareResult[] }
// ---------------------------------------------------------------------------

router.post('/compare', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const authReq = req as AuthenticatedRequest;

  const parsed = compareSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: parsed.error.issues[0]?.message ?? 'Invalid request body',
    });
    return;
  }

  try {
    const politicians = await compareWithPoliticians(authReq.userId, parsed.data.politician_ids);
    res.status(200).json({ politicians });
  } catch (err) {
    console.error('[POST /compass/compare] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/compass/verdicts
// Auth: required
// Returns the calling user's compass verdicts (Read & Rank judgments).
// Optional query param: ?politician_id=<uuid> — filters to quotes by that politician.
// ---------------------------------------------------------------------------

router.get('/verdicts', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const authReq = req as AuthenticatedRequest;

  let politicianId: string | undefined;
  if (typeof req.query.politician_id === 'string') {
    if (!UUID_REGEX.test(req.query.politician_id)) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: 'Invalid politician_id format',
      });
      return;
    }
    politicianId = req.query.politician_id;
  }

  try {
    const verdicts = await getUserVerdicts(authReq.userId, politicianId);
    res.status(200).json(verdicts);
  } catch (err) {
    console.error('[GET /compass/verdicts] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/compass/verdicts
// Auth: required
// Atomically upserts a batch of verdicts for the calling user.
// Body: { verdicts: [{ quote_id, supported, rank, session_size }] } (1-200 items).
// Delegates to the upsert_compass_verdicts SECURITY DEFINER RPC for atomicity.
// Returns: { upserted: number }
// ---------------------------------------------------------------------------

router.post('/verdicts', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const authReq = req as AuthenticatedRequest;

  // Try new format first: { verdicts: [{ quote_id, supported, rank, session_size }] }
  const newParsed = postVerdictsNewSchema.safeParse(req.body);
  if (newParsed.success) {
    try {
      const { error } = await adminRpc('upsert_compass_verdicts', {
        p_user_id: authReq.userId,
        p_verdicts: newParsed.data.verdicts,
      });
      if (error) throw new Error(error.message);
      res.status(200).json({ upserted: newParsed.data.verdicts.length });
      return;
    } catch (err) {
      console.error('[POST /compass/verdicts] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
      return;
    }
  }

  // Try legacy format: [{ quote_id, verdict: "agreed"|"disagreed" }]
  const legacyParsed = postVerdictsLegacySchema.safeParse(req.body);
  if (legacyParsed.success) {
    // Convert legacy format to RPC format
    const verdicts = legacyParsed.data.map((v) => ({
      quote_id: v.quote_id,
      supported: v.verdict === 'agreed',
      rank: null,
      session_size: legacyParsed.data.length,
    }));

    try {
      const { error } = await adminRpc('upsert_compass_verdicts', {
        p_user_id: authReq.userId,
        p_verdicts: verdicts,
      });
      if (error) throw new Error(error.message);
      res.status(200).json({ upserted: verdicts.length });
      return;
    } catch (err) {
      console.error('[POST /compass/verdicts] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
      return;
    }
  }

  // Neither format matched
  res.status(422).json({
    code: 'VALIDATION_ERROR',
    message: 'Invalid request body. Expected { verdicts: [...] } or [{ quote_id, verdict }]',
  });
});

// ---------------------------------------------------------------------------
// GET /api/compass/candidates/:id/answers
// Auth: optional — public, no PII
// Returns topic/value pairs for a candidate identified by race_candidates.id.
// Returns 404 if the candidateId is not found or has no empowered_profile.
// IMPORTANT: registered BEFORE /politicians routes to avoid Express routing
// conflicts where "candidates" might be captured as a :id param.
// ---------------------------------------------------------------------------

router.get(
  '/candidates/:id/answers',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    try {
      const candidateId = req.params.id as string;
      if (!UUID_REGEX.test(candidateId)) {
        res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid candidate ID format' });
        return;
      }

      const data = await getCandidateAnswers(candidateId);
      if (data === null) {
        res.status(404).json({ code: 'NOT_FOUND', message: 'Candidate not found or has no compass answers' });
        return;
      }
      res.status(200).json(data);
    } catch (err) {
      console.error('[GET /compass/candidates/:id/answers] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/compass/politicians
// Auth: optional — works unauthenticated
// Returns all active politicians ordered by name.
// Optional query param: include_candidates=true — merges active election
// candidates (with compass answers via empowered_profile) into the result.
// When include_candidates=true, all records include is_candidate and is_incumbent
// fields; incumbents get is_candidate:false, is_incumbent:true.
// ---------------------------------------------------------------------------

router.get('/politicians', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const includeCandidates = req.query.include_candidates === 'true';

    if (!includeCandidates) {
      const data = await getCompassPoliticians();
      res.status(200).json(data);
      return;
    }

    // Merge incumbents and candidates in parallel
    const [incumbents, candidates] = await Promise.all([
      getCompassPoliticians(),
      getCandidates(),
    ]);

    const incumbentsWithFlags = incumbents.map((p) => ({
      ...p,
      is_candidate: false,
      is_incumbent: true,
    }));

    res.status(200).json([...incumbentsWithFlags, ...candidates]);
  } catch (err) {
    console.error('[GET /compass/politicians] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/compass/politicians/:id/answers/batch
// Auth: optional — unauthenticated returns 200 []
// Returns a politician's answers filtered to the supplied list of topic IDs.
// Efficient for fetching only the topics the client cares about.
// Body: { topic_ids: string[] } (1-100 UUIDs).
// IMPORTANT: must be registered BEFORE /politicians/:id/answers to prevent
// Express from capturing "batch" as the :id param segment.
// ---------------------------------------------------------------------------

router.post(
  '/politicians/:id/answers/batch',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;
    if (!authReq.userId) { res.status(200).json([]); return; }

    const politicianId = req.params.id as string;
    if (!UUID_REGEX.test(politicianId)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid politician ID format' });
      return;
    }

    const parsed = batchPoliticianAnswersSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: parsed.error.issues[0]?.message ?? 'Invalid request body',
      });
      return;
    }

    try {
      const answers = await getBatchPoliticianAnswers(politicianId, parsed.data.topic_ids);
      res.status(200).json(answers);
    } catch (err) {
      console.error('[POST /compass/politicians/:id/answers/batch] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/compass/politicians/:id/answers
// Auth: optional — works unauthenticated
// Returns a politician's stances on all topics they have answered.
// Validates UUID format; returns empty array if politician has no answers.
// ---------------------------------------------------------------------------

router.get(
  '/politicians/:id/answers',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    try {
      const politicianId = req.params.id as string;

      if (!UUID_REGEX.test(politicianId)) {
        res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid politician ID format' });
        return;
      }

      const data = await getPoliticianAnswers(politicianId);
      res.status(200).json(data);
    } catch (err) {
      console.error('[GET /compass/politicians/:id/answers] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/compass/politicians/:id/context
// Auth: optional — works unauthenticated
// Returns all context rows for a politician (all topics in one call).
// Used by contributor editors to pre-populate source URL fields.
// MUST be registered before /politicians/:id/:topicId/context.
// ---------------------------------------------------------------------------

router.get(
  '/politicians/:id/context',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    try {
      const politicianId = req.params.id as string;
      if (!UUID_REGEX.test(politicianId)) {
        res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid politician ID' });
        return;
      }
      const data = await getPoliticianContextAll(politicianId);
      res.status(200).json(data);
    } catch (err) {
      console.error('[GET /compass/politicians/:id/context] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/compass/politicians/:id/citations
// Auth: optional — public data, no login required
// Returns all citation blocks for a politician grouped by topic.
// Returns [] (HTTP 200) when the politician has no evidence — not a 404.
// MUST be registered BEFORE /politicians/:id/:topicId/context to prevent
// Express from capturing "citations" as the :topicId param segment.
// ---------------------------------------------------------------------------

router.get(
  '/politicians/:id/citations',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    const politicianId = req.params.id as string;
    try {
      if (!UUID_REGEX.test(politicianId)) {
        res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid politician ID' });
        return;
      }

      const citations = await getPoliticianCitations(politicianId);
      res.status(200).json(citations);
    } catch (err) {
      console.error(`[GET /compass/politicians/${politicianId}/citations] error:`, err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Internal server error' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/compass/politicians/:id/:topicId/context
// Auth: optional — works unauthenticated
// Returns reasoning and sources for a politician's stance on a topic.
// Returns 404 if no context record exists (context is optional, answers are not).
// ---------------------------------------------------------------------------

router.get(
  '/politicians/:id/:topicId/context',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    try {
      const politicianId = req.params.id as string;
      const topicId = req.params.topicId as string;

      if (!UUID_REGEX.test(politicianId) || !UUID_REGEX.test(topicId)) {
        res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid ID format' });
        return;
      }

      const data = await getPoliticianContext(politicianId, topicId);

      if (!data) {
        res.status(404).json({ code: 'NOT_FOUND', message: 'No context found for this politician and topic' });
        return;
      }

      res.status(200).json(data);
    } catch (err) {
      console.error('[GET /compass/politicians/:id/:topicId/context] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

// ---------------------------------------------------------------------------
// POST /api/compass/answers
// Auth: optional — unauthenticated returns 200 null
// Upserts a single compass response and atomically appends to change_history.
// Entire operation runs in a SECURITY DEFINER RPC (upsert_compass_answer).
// change_history record is ALWAYS inserted — even first calibration (old_value=NULL)
// and same-value recalibration. It is a full audit log.
// ---------------------------------------------------------------------------

router.post('/answers', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const authReq = req as AuthenticatedRequest;
  if (!authReq.userId) { res.status(200).json(null); return; }

  const parsed = postAnswerSchema.safeParse(req.body);
  if (!parsed.success) {
    const firstIssue = parsed.error.issues[0];
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: firstIssue?.message ?? 'Invalid request body',
    });
    return;
  }

  const { topic_id, value, write_in_text, inverted } = parsed.data;

  try {
    const { data, error } = await adminRpc('upsert_compass_answer', {
      p_user_id: authReq.userId,
      p_topic_id: topic_id,
      p_value: value,
      p_write_in_text: write_in_text ?? null,
      p_inverted: inverted,
    });

    if (error) {
      if (error.message === 'TOPIC_NOT_FOUND') {
        res.status(404).json({ code: 'TOPIC_NOT_FOUND', message: 'Topic not found or not live' });
        return;
      }
      throw new Error(error.message);
    }

    res.status(200).json(data);
  } catch (err) {
    console.error('[POST /compass/answers] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// ---------------------------------------------------------------------------
// PUT /api/compass/selected-topics
// Auth: optional — unauthenticated returns 200 []
// Saves the user's selected topic IDs after server-side validation.
// Validates ALL submitted IDs exist and are live before storing.
// Returns flat array (Go-parity response shape).
// ---------------------------------------------------------------------------

router.put(
  '/selected-topics',
  optionalAuth,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;
    if (!authReq.userId) { res.status(200).json([]); return; }

    const parsed = putSelectedTopicsSchema.safeParse(req.body);
    if (!parsed.success) {
      const firstIssue = parsed.error.issues[0];
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: firstIssue?.message ?? 'Invalid request body',
      });
      return;
    }

    const { topic_ids } = parsed.data;

    try {
      const invalidIds = await validateTopicIds(topic_ids);
      if (invalidIds.length > 0) {
        res.status(422).json({
          code: 'INVALID_TOPIC_IDS',
          // "not live" was the old gate. The gate is now the open season's
          // question set, so say that — a topic can exist, be perfectly live,
          // and still not be one this season asks.
          message:
            'The following topic IDs are not among the questions this season asks: ' +
            invalidIds.join(', '),
          invalid_ids: invalidIds,
        });
        return;
      }

      const connected = await saveSelectedTopics(authReq.accessToken, authReq.userId, topic_ids);
      if (!connected) {
        // Go backend returns empty array, not 403
        res.status(200).json([]);
        return;
      }

      res.status(200).json(topic_ids);
    } catch (err) {
      // No season is open, so there is nothing to validate the selection
      // against. The request is fine; the service cannot serve it. 503, not the
      // 500 this used to be — and definitely not a 422 blaming the caller's
      // topic ids, which is what a naive "everything is invalid" check produces.
      if (isNoPromotedTopicsError(err)) {
        console.error('[PUT /compass/selected-topics] no promoted topics:', err.message);
        res.status(503).json({
          code: err.code,
          message: 'Compass topics are unavailable right now — no season is open.',
        });
        return;
      }
      console.error('[PUT /compass/selected-topics] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  }
);

export default router;
