/**
 * custom.ts
 * Application-level types for Validation Quests.
 * These types are NOT generated from the database schema — they are application constructs
 * (response shapes, payload types, constants, domain aliases) that survive database.types.ts regeneration.
 *
 * Import from this file for: feed types, notification payloads, reward types, admin types,
 * domain union types, and the DIFFICULTY_REWARDS constant.
 */

// ============================================================
// DOMAIN UNION TYPES (application aliases for DB enum values)
// ============================================================

export type QuestStatus = 'active' | 'consensus_reached' | 'under_review' | 'archived';
export type QuestType = 'official' | 'fact' | 'policy';
export type PriorityLevel = 'high' | 'standard' | 'low';
export type SubmitterType = 'human_connected' | 'human_empowered' | 'ai_agent';
export type ConfidenceLevel = 'high' | 'moderate' | 'low' | 'conflicting';
export type RestrictionState = 'none' | 'warning' | 'limited' | 'suspended' | 'review_required';
export type UserAction = 'acknowledged' | 'contested_with_evidence' | 'ignored';
export type SubmissionOutcome = 'correct' | 'incorrect' | 'pending';

// ============================================================
// SHARED APPLICATION TYPES
// ============================================================

export interface Source {
  url: string;
  source_type: 'official_gov' | 'news' | 'database' | 'other';
  retrieved_date: string;
  description: string;
}

// Educational feedback shown to submitters after consensus resolves.
// Stored in verification_submissions.feedback (JSONB).
export interface EducationalFeedback {
  correct_answer: string;
  sources: Source[];
  research_tips: string;
}

// ============================================================
// NESTED PROFILE TYPES
// ============================================================

// Accuracy rates by rolling time window. Values are 0-100.
export interface AccuracyByTimeframe {
  last7d: number;
  last30d: number;
  allTime: number;
}

// Accuracy rate per difficulty tier (key = difficulty_tier as string "1"–"5"). Values are 0-100.
export type AccuracyByDifficultyTier = Record<string, number>;

// ============================================================
// DIFFICULTY TIER REWARD MAPPING
// ============================================================

export const DIFFICULTY_REWARDS: Record<number, { gems: number; xp: number }> = {
  1: { gems: 10, xp: 15 },
  2: { gems: 15, xp: 20 },
  3: { gems: 20, xp: 30 },
  4: { gems: 30, xp: 45 },
  5: { gems: 50, xp: 75 },
};

// ============================================================
// FEED TYPES (Phase 4)
// ============================================================

// Note: geographic_scope is intentionally excluded per CONTEXT.md minimal card decision.
// The Postgres RPC returns geographic_scope internally, but client-facing cards show
// only question text + gem reward (no geographic tag in v1).
export interface FeedItem {
  quest_id: string;
  question_text: string;
  gem_type: 'yellow' | 'red';
  gem_count: number;
  composite_score: number;
  score_breakdown: {
    geo: number;
    difficulty: number;
    confidence: number;
    bounty: number;
  };
}

export interface RotationInfo {
  next_rotation_at: string;  // ISO 8601 UTC
  slot_count: number;        // how many slots this user has (3 or 5)
  slots_used: number;        // active assigned quests count
}

export interface CompletedSlot {
  quest_id: string;
  question_text: string;
  gem_type: 'yellow' | 'red';
  submitted_at: string;  // ISO 8601
}

export interface FeedResponse {
  quests: FeedItem[];
  completed_slots: CompletedSlot[];
  cached: boolean;
  is_onboarding: boolean;
  rotation_info: RotationInfo;
  has_location: boolean;
  verification_rating: number | null;
  red_gem_quests_unlocked: boolean;
}

export interface BountyBoardResponse {
  high_priority: FeedItem[];
  pending_submissions: PendingSubmission[];
  earned_bounties: EarnedBounty[];
}

export interface PendingSubmission {
  submission_id: string;
  quest_id: string;
  question_text: string;
  answer_text: string;
  submitted_at: string;
}

export interface EarnedBounty {
  submission_id: string;
  quest_id: string;
  question_text: string;
  gem_reward: number;
  gem_type: 'yellow' | 'red';
  outcome: 'correct';
  finalized_at: string | null;
}

// ============================================================
// PHASE 5 TYPES — Rewards, Transparency, and Contestation
// ============================================================

export type GemType = 'yellow' | 'red';
export type GemQuestType = 'yellow' | 'red'; // quest classification: yellow=training, red=discovery
export type RewardReason = 'correct_submission' | 'early_bonus' | 'correct_answer' | 'valid_source';
export type ContestStatus = 'pending' | 'under_review' | 'resolved_upheld' | 'resolved_overturned';

// TABLE: gem_reward_events
// Records gem awards post-consensus-finalization. UNIQUE (user_id, quest_id, gem_type, reason)
// prevents duplicate gem grants if the reward job is retried.
export interface GemRewardEvent {
  id: string;
  user_id: string;
  gem_type: GemType;
  amount: number;
  quest_id: string;
  reason: RewardReason;
  confidence_level_at_reward: string;
  timestamp: string;
}

// TABLE: quest_contests
// Filed by users who believe a finalized consensus answer is incorrect.
export interface QuestContest {
  id: string;
  quest_id: string;
  filed_by: string;
  source_url: string;
  explanation: string;
  proposed_answer: string;
  status: ContestStatus;
  admin_resolution: string | null;  // nullable: admin's documented reasoning
  resolved_by: string | null;       // nullable: admin user_id who resolved
  resolved_at: string | null;       // nullable: when admin resolved
  created_at: string;
  updated_at: string;
}

// ============================================================
// PHASE 6 TYPES — Notification System
// ============================================================

// Notification payload shapes (stored as JSONB in user_notifications.payload)

export interface CorrectNotificationPayload {
  outcome: 'correct';
  correct_answer: string;
  gems: {
    yellow: number;       // from gem_reward_events WHERE gem_type='yellow'
    red: number;          // from gem_reward_events WHERE gem_type='red' AND reason='correct_submission'
    early_bonus: number;  // from gem_reward_events WHERE reason='early_bonus'; 0 if not early
  };
}

export interface IncorrectNotificationPayload {
  outcome: 'incorrect';
  correct_answer: string;
  authoritative_sources: Source[];
  research_tip: string;   // from verification_submissions.feedback.research_tips
}

export type NotificationPayload = CorrectNotificationPayload | IncorrectNotificationPayload;

// ============================================================
// PHASE 7 TYPES — Admin Tools and Quest Seeding
// ============================================================

export type AdminActionType =
  | 'quest_created'
  | 'quest_override'
  | 'contest_approved'
  | 'contest_rejected'
  | 'age_waiver_granted'
  | 'user_suspended'
  | 'user_unsuspended'
  | 'bulk_import';

// TABLE: admin_override_log
// Audit trail for all administrative actions. Deny-all RLS — accessible via service role only.
export interface AdminOverrideLog {
  id: string;
  admin_user_id: string;
  action_type: AdminActionType;
  target_type: 'quest' | 'contest' | 'user' | 'bulk';
  target_id: string;
  reasoning: string;
  metadata: Record<string, unknown>;
  created_at: string;
}
