import { z } from 'zod';
import type { QuestType, QuestStatus, PriorityLevel, GemType, RewardReason, Source, AdminActionType } from './custom.js';
import type { CredibilityChangeResult } from '../services/credibility.js';

// ============================================================
// REQUEST SCHEMAS (Zod)
// ============================================================

export const createQuestSchema = z.object({
  type: z.enum(['official', 'fact', 'policy']),
  question_text: z.string().min(10).max(500),
  difficulty_tier: z.number().int().min(1).max(5),
  geographic_scope: z.string().min(1),
  jurisdiction_name: z.string().optional(),  // matches a district name from accounts /api/account/me/jurisdiction
  correct_answer: z.string().optional(),      // required for yellow quests; NULL for red quests
  politician_id: z.string().uuid().optional(),   // stance quests only — links to inform.politicians
  topic_id: z.string().uuid().optional(),         // stance quests only — links to compass topic
  confirmed_value: z.number().optional(), // decimal stance value set by consensus engine at finalization (supports e.g. 3.5)
  jurisdiction_geometry: z
    .object({
      lat: z.number().min(-90).max(90),
      lng: z.number().min(-180).max(180),
    })
    .optional(),
  priority_level: z.enum(['high', 'standard', 'low']).default('standard'),
  gem_reward_override: z.number().int().min(30).optional(),
});

export type CreateQuestRequest = z.infer<typeof createQuestSchema>;

// ============================================================
// RESPONSE TYPES
// ============================================================

export interface QuestResponse {
  id: string;
  type: QuestType;
  question_text: string;
  difficulty_tier: number;
  geographic_scope: string;
  xp_reward: number;
  gem_reward: number;
  priority_level: PriorityLevel;
  status: QuestStatus;
  submission_count: number;
  is_bounty: boolean;
  gem_type: 'yellow' | 'red';
  politician_id: string | null;
  topic_id: string | null;
  confirmed_value: number | null;
  created_at: string;
  updated_at: string;
}

export interface ErrorResponse {
  error: string;
}

export interface ValidationErrorResponse {
  error: {
    code: 'VALIDATION_ERROR';
    message: string;
    details: z.ZodIssue[];
  };
}

// ============================================================
// SUBMISSION SCHEMAS (Zod v4)
// ============================================================

// z.url() — Zod v4 standalone validator (z.string().url() is deprecated in v4)
export const sourceSchema = z.object({
  url: z.url(),
  source_type: z.enum(['official_gov', 'news', 'database', 'other']),
  retrieved_date: z.string().date(),
  description: z.string().min(1).max(500),
});

export const createSubmissionSchema = z.object({
  quest_id: z.string().uuid(),
  answer_text: z.string().min(1).max(2000),
  sources: z.array(sourceSchema).min(1).max(1000),
});

export type CreateSubmissionRequest = z.infer<typeof createSubmissionSchema>;

// AI agents must provide at least 2 sources (vs 1 for human submissions)
export const createAiSubmissionSchema = z.object({
  quest_id: z.string().uuid(),
  answer_text: z.string().min(1).max(2000),
  sources: z.array(sourceSchema).min(2).max(1000),
});

export type CreateAiSubmissionRequest = z.infer<typeof createAiSubmissionSchema>;

// ============================================================
// SUBMISSION RESPONSE TYPES
// ============================================================

export interface YellowQuestResult {
  outcome: 'correct' | 'incorrect';
  correct_answer: string;
  vr_delta: number;       // delta requested (+3 or -10)
  new_vr?: number;        // new_rating from adjust-vr response (omitted if call failed)
  gems_awarded?: number;  // total gems awarded (present only on correct outcome, 3 = 1 answer + 2 source)
}

export interface SubmissionSuccessResponse {
  submission_id: string;
  quest_name: string;
  answer_text: string;
  sources: Array<{
    url: string;
    source_type: string;
    retrieved_date: string;
    description: string;
  }>;
  xp_awarded: number;
  submitted_at: string;
  is_update: boolean;
  quarantined?: boolean;
  credibility: CredibilityChangeResult;
  yellow_quest_result?: YellowQuestResult;  // present only for Yellow quests
}

export interface SubmissionErrorResponse {
  error: {
    code: string;
    message: string;
    action: string;
  };
  credibility?: Pick<CredibilityChangeResult, 'current_score' | 'change' | 'reason'>;
}

export interface AiSubmissionSuccessResponse {
  submission_id: string;
  quest_name: string;
  answer_text: string;
  sources: Array<{
    url: string;
    source_type: string;
    retrieved_date: string;
    description: string;
  }>;
  submitted_at: string;
  submitter_type: 'ai_agent';
  is_update: boolean;
}

// ============================================================
// PHASE 5 SCHEMAS AND RESPONSE TYPES
// ============================================================

// Contest submission schema (Zod v4 — z.url() is the standalone validator)
// ============================================================
// ADMIN SCHEMAS (Zod) — Phase 7
// ============================================================

// Admin quest creation: extends createQuestSchema with gem_quest_type and bridging_waived
export const createAdminQuestSchema = createQuestSchema.extend({
  gem_quest_type: z.enum(['yellow', 'red']).default('red'),
  bridging_waived: z.boolean().default(false),
}).superRefine((data, ctx) => {
  if (data.gem_quest_type === 'yellow' && !data.correct_answer) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'correct_answer is required for yellow quests',
      path: ['correct_answer'],
    });
  }
});
export type CreateAdminQuestRequest = z.infer<typeof createAdminQuestSchema>;

// Bulk import: array of admin quest objects
export const adminBulkQuestSchema = z.array(createAdminQuestSchema);
export type AdminBulkQuestRequest = z.infer<typeof adminBulkQuestSchema>;

// Age waiver: reasoning required for audit trail
export const ageWaiverSchema = z.object({
  reasoning: z.string().min(10).max(1000),
});
export type AgeWaiverRequest = z.infer<typeof ageWaiverSchema>;

// Suspend/unsuspend: reasoning required for audit trail
export const suspendSchema = z.object({
  reasoning: z.string().min(10).max(1000),
});
export type SuspendRequest = z.infer<typeof suspendSchema>;

// Suppress unused import warning — AdminActionType used by consumers of this module
export type { AdminActionType };

// Admin quest override (ADMIN-03)
export const adminOverrideSchema = z.object({
  canonical_answer: z.string().min(1),
  reasoning: z.string().min(10).max(2000),
});
export type AdminOverrideRequest = z.infer<typeof adminOverrideSchema>;

// Contestation resolution (ADMIN-05)
export const resolveContestSchema = z.object({
  decision: z.enum(['approve', 'reject']),
  reasoning: z.string().min(10).max(2000),
});
export type ResolveContestRequest = z.infer<typeof resolveContestSchema>;

export const createContestSchema = z.object({
  quest_id: z.string().uuid(),
  source_url: z.url(),
  explanation: z.string().min(20).max(2000),
  proposed_answer: z.string().min(1).max(2000),
});
export type CreateContestRequest = z.infer<typeof createContestSchema>;

// ---- History endpoint types ----

export interface HistoryCard {
  quest_id: string;
  question_text: string;
  user_answer: string;
  outcome: 'correct' | 'incorrect' | 'pending';
  gems_earned: { gem_type: GemType; amount: number; reason: RewardReason }[];
  correct_answer: string | null;       // only present when user was incorrect
  authoritative_source: Source | null;
  confidence_level: string | null;
  submitted_at: string;
}

export interface HistoryResponse {
  submissions: HistoryCard[];
  page: number;
  page_size: number;
  total: number;
}

export interface UserSummaryResponse {
  accuracy_percentage: number | null;
  total_submissions: number;
}

// ---- Transparency endpoint types ----

export interface NamedVerifier {
  user_id: string;
  display_name: string;
}

export interface TransparencyBreakdown {
  status: 'consensus_reached';
  total_submissions: number;
  alignment_percentage: number;
  human_count: number;
  ai_count: number;
  authoritative_sources: Source[];
  named_verifiers: NamedVerifier[];    // Empowered correct submitters as {user_id, display_name} objects
  connected_verifier_count: number;    // Connected correct submitters as aggregate count
  user_submission: { answer: string; outcome: string } | null; // requesting user's own submission
  consensus_answer: string;
  user_has_contested: boolean;
}

export interface TransparencyVerifying {
  status: 'verifying';
  submission_count: number;
}

export type TransparencyResponse = TransparencyBreakdown | TransparencyVerifying;

// ---- Contest response types ----

export interface ContestSuccessResponse {
  contest_id: string;
  quest_id: string;
  status: 'pending';
  message: string;
}

export interface ContestErrorResponse {
  error: {
    code: string;
    message: string;
  };
}
