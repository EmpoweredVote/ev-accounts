// GENERATED — do not edit manually.
// Regenerate with: npx supabase gen types typescript --linked --schema validation_quests > backend/src/types/database.types.ts
// Run from project root after any schema migration.
// Application types (FeedItem, NotificationPayload, DIFFICULTY_REWARDS, etc.) live in custom.ts.

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "12.2.3 (519615d)"
  }
  validation_quests: {
    Tables: {
      admin_override_log: {
        Row: {
          action_type: string
          admin_user_id: string
          created_at: string
          id: string
          metadata: Json
          reasoning: string
          target_id: string
          target_type: string
        }
        Insert: {
          action_type: string
          admin_user_id: string
          created_at?: string
          id?: string
          metadata?: Json
          reasoning: string
          target_id: string
          target_type: string
        }
        Update: {
          action_type?: string
          admin_user_id?: string
          created_at?: string
          id?: string
          metadata?: Json
          reasoning?: string
          target_id?: string
          target_type?: string
        }
        Relationships: []
      }
      ai_agent_credentials: {
        Row: {
          agent_name: string
          api_key_hash: string
          created_at: string
          id: string
          is_active: boolean
          rate_limit_per_hour: number
        }
        Insert: {
          agent_name: string
          api_key_hash: string
          created_at?: string
          id?: string
          is_active?: boolean
          rate_limit_per_hour?: number
        }
        Update: {
          agent_name?: string
          api_key_hash?: string
          created_at?: string
          id?: string
          is_active?: boolean
          rate_limit_per_hour?: number
        }
        Relationships: []
      }
      consensus_records: {
        Row: {
          ai_count: number
          alignment_percentage: number
          answer_distribution: Json
          authoritative_sources: Json
          bridging_waived: boolean
          confidence_level: string
          consensus_answer: string
          consensus_date: string
          finalized_at: string | null
          human_count: number
          human_percentage: number
          id: string
          last_verified_date: string
          quest_id: string
          threshold_met_at: string | null
          total_submissions: number
        }
        Insert: {
          ai_count: number
          alignment_percentage: number
          answer_distribution?: Json
          authoritative_sources?: Json
          bridging_waived?: boolean
          confidence_level: string
          consensus_answer: string
          consensus_date?: string
          finalized_at?: string | null
          human_count: number
          human_percentage: number
          id?: string
          last_verified_date?: string
          quest_id: string
          threshold_met_at?: string | null
          total_submissions: number
        }
        Update: {
          ai_count?: number
          alignment_percentage?: number
          answer_distribution?: Json
          authoritative_sources?: Json
          bridging_waived?: boolean
          confidence_level?: string
          consensus_answer?: string
          consensus_date?: string
          finalized_at?: string | null
          human_count?: number
          human_percentage?: number
          id?: string
          last_verified_date?: string
          quest_id?: string
          threshold_met_at?: string | null
          total_submissions?: number
        }
        Relationships: []
      }
      gem_reward_events: {
        Row: {
          amount: number
          confidence_level_at_reward: string
          gem_type: string
          id: string
          quest_id: string
          reason: string
          timestamp: string
          user_id: string
        }
        Insert: {
          amount: number
          confidence_level_at_reward: string
          gem_type: string
          id?: string
          quest_id: string
          reason: string
          timestamp?: string
          user_id: string
        }
        Update: {
          amount?: number
          confidence_level_at_reward?: string
          gem_type?: string
          id?: string
          quest_id?: string
          reason?: string
          timestamp?: string
          user_id?: string
        }
        Relationships: []
      }
      quest_assignments: {
        Row: {
          assigned_at: string
          id: string
          quest_id: string
          user_id: string
        }
        Insert: {
          assigned_at?: string
          id?: string
          quest_id: string
          user_id: string
        }
        Update: {
          assigned_at?: string
          id?: string
          quest_id?: string
          user_id?: string
        }
        Relationships: []
      }
      quest_contests: {
        Row: {
          admin_resolution: string | null
          created_at: string
          explanation: string
          filed_by: string
          id: string
          proposed_answer: string
          quest_id: string
          resolved_at: string | null
          resolved_by: string | null
          source_url: string
          status: string
          updated_at: string
        }
        Insert: {
          admin_resolution?: string | null
          created_at?: string
          explanation: string
          filed_by: string
          id?: string
          proposed_answer: string
          quest_id: string
          resolved_at?: string | null
          resolved_by?: string | null
          source_url: string
          status?: string
          updated_at?: string
        }
        Update: {
          admin_resolution?: string | null
          created_at?: string
          explanation?: string
          filed_by?: string
          id?: string
          proposed_answer?: string
          quest_id?: string
          resolved_at?: string | null
          resolved_by?: string | null
          source_url?: string
          status?: string
          updated_at?: string
        }
        Relationships: []
      }
      user_notification_preferences: {
        Row: {
          enabled: boolean
          updated_at: string
          user_id: string
        }
        Insert: {
          enabled?: boolean
          updated_at?: string
          user_id: string
        }
        Update: {
          enabled?: boolean
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      user_notifications: {
        Row: {
          created_at: string
          id: string
          is_read: boolean
          payload: Json
          quest_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          is_read?: boolean
          payload: Json
          quest_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          is_read?: boolean
          payload?: Json
          quest_id?: string
          user_id?: string
        }
        Relationships: []
      }
      user_veracity_profiles: {
        Row: {
          accuracy_by_difficulty_tier: Json
          accuracy_by_timeframe: Json
          accuracy_rate: number | null
          age_waiver_granted: boolean
          correct_submissions: number
          created_at: string
          credibility_infraction_count: number
          credibility_score: number
          daily_incorrect_count: number
          daily_incorrect_reset_at: string | null
          incorrect_submissions: number
          pending_submissions: number
          restriction_reason: string | null
          restriction_state: string
          submission_weight: number
          total_submissions: number
          updated_at: string
          user_id: string
        }
        Insert: {
          accuracy_by_difficulty_tier?: Json
          accuracy_by_timeframe?: Json
          accuracy_rate?: number | null
          age_waiver_granted?: boolean
          correct_submissions?: number
          created_at?: string
          credibility_infraction_count?: number
          credibility_score?: number
          daily_incorrect_count?: number
          daily_incorrect_reset_at?: string | null
          incorrect_submissions?: number
          pending_submissions?: number
          restriction_reason?: string | null
          restriction_state?: string
          submission_weight?: number
          total_submissions?: number
          updated_at?: string
          user_id: string
        }
        Update: {
          accuracy_by_difficulty_tier?: Json
          accuracy_by_timeframe?: Json
          accuracy_rate?: number | null
          age_waiver_granted?: boolean
          correct_submissions?: number
          created_at?: string
          credibility_infraction_count?: number
          credibility_score?: number
          daily_incorrect_count?: number
          daily_incorrect_reset_at?: string | null
          incorrect_submissions?: number
          pending_submissions?: number
          restriction_reason?: string | null
          restriction_state?: string
          submission_weight?: number
          total_submissions?: number
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      veracity_event_logs: {
        Row: {
          created_at: string
          delta: number | null
          event_type: string
          id: string
          new_weight: number | null
          previous_weight: number | null
          quest_id: string | null
          user_action: string | null
          user_id: string
        }
        Insert: {
          created_at?: string
          delta?: number | null
          event_type: string
          id?: string
          new_weight?: number | null
          previous_weight?: number | null
          quest_id?: string | null
          user_action?: string | null
          user_id: string
        }
        Update: {
          created_at?: string
          delta?: number | null
          event_type?: string
          id?: string
          new_weight?: number | null
          previous_weight?: number | null
          quest_id?: string | null
          user_action?: string | null
          user_id?: string
        }
        Relationships: []
      }
      verification_quests: {
        Row: {
          bridging_waived: boolean
          confirmed_value: number | null
          correct_answer: string | null
          created_at: string
          created_by: string
          difficulty_tier: number
          gem_quest_type: string
          gem_reward: number
          geographic_scope: string
          id: string
          jurisdiction_geometry: unknown
          jurisdiction_name: string | null
          pinned: boolean
          politician_id: string | null
          priority_level: Database["validation_quests"]["Enums"]["priority_level"]
          promoted_to_yellow_at: string | null
          question_text: string
          status: Database["validation_quests"]["Enums"]["quest_status"]
          submission_count: number
          topic_id: string | null
          type: Database["validation_quests"]["Enums"]["quest_type"]
          updated_at: string
          xp_reward: number
        }
        Insert: {
          bridging_waived?: boolean
          confirmed_value?: number | null
          correct_answer?: string | null
          created_at?: string
          created_by: string
          difficulty_tier: number
          gem_quest_type?: string
          gem_reward: number
          geographic_scope: string
          id?: string
          jurisdiction_geometry?: unknown
          jurisdiction_name?: string | null
          pinned?: boolean
          politician_id?: string | null
          priority_level?: Database["validation_quests"]["Enums"]["priority_level"]
          promoted_to_yellow_at?: string | null
          question_text: string
          status?: Database["validation_quests"]["Enums"]["quest_status"]
          submission_count?: number
          topic_id?: string | null
          type: Database["validation_quests"]["Enums"]["quest_type"]
          updated_at?: string
          xp_reward: number
        }
        Update: {
          bridging_waived?: boolean
          confirmed_value?: number | null
          correct_answer?: string | null
          created_at?: string
          created_by?: string
          difficulty_tier?: number
          gem_quest_type?: string
          gem_reward?: number
          geographic_scope?: string
          id?: string
          jurisdiction_geometry?: unknown
          jurisdiction_name?: string | null
          pinned?: boolean
          politician_id?: string | null
          priority_level?: Database["validation_quests"]["Enums"]["priority_level"]
          promoted_to_yellow_at?: string | null
          question_text?: string
          status?: Database["validation_quests"]["Enums"]["quest_status"]
          submission_count?: number
          topic_id?: string | null
          type?: Database["validation_quests"]["Enums"]["quest_type"]
          updated_at?: string
          xp_reward?: number
        }
        Relationships: []
      }
      verification_submissions: {
        Row: {
          answer_history: Json
          answer_text: string
          created_at: string
          feedback: Json | null
          id: string
          included_in_consensus: boolean
          normalized_answer: string | null
          outcome: string | null
          quest_id: string
          sources: Json
          status: string
          submission_weight: number
          submitter_type: string
          updated_at: string | null
          user_id: string
          veracity_suspended: boolean
        }
        Insert: {
          answer_history?: Json
          answer_text: string
          created_at?: string
          feedback?: Json | null
          id?: string
          included_in_consensus?: boolean
          normalized_answer?: string | null
          outcome?: string | null
          quest_id: string
          sources?: Json
          status?: string
          submission_weight?: number
          submitter_type: string
          updated_at?: string | null
          user_id: string
          veracity_suspended?: boolean
        }
        Update: {
          answer_history?: Json
          answer_text?: string
          created_at?: string
          feedback?: Json | null
          id?: string
          included_in_consensus?: boolean
          normalized_answer?: string | null
          outcome?: string | null
          quest_id?: string
          sources?: Json
          status?: string
          submission_weight?: number
          submitter_type?: string
          updated_at?: string | null
          user_id?: string
          veracity_suspended?: boolean
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      get_onboarding_feed: {
        Args: {
          p_max_radius_m?: number
          p_user_id: string
          p_user_lat: number
          p_user_lng: number
        }
        Returns: {
          bounty_score: number
          composite_score: number
          confidence_score: number
          difficulty_score: number
          gem_reward: number
          gem_type: string
          geo_score: number
          geographic_scope: string
          quest_id: string
          question_text: string
        }[]
      }
      get_personalized_feed: {
        Args: {
          p_max_radius_m?: number
          p_user_id: string
          p_user_lat: number
          p_user_lng: number
          p_veracity_rate: number
        }
        Returns: {
          bounty_score: number
          composite_score: number
          confidence_score: number
          difficulty_score: number
          gem_reward: number
          gem_type: string
          geo_score: number
          geographic_scope: string
          quest_id: string
          question_text: string
        }[]
      }
    }
    Enums: {
      priority_level: "high" | "standard" | "low"
      quest_status: "active" | "consensus_reached" | "under_review" | "archived"
      quest_type: "official" | "fact" | "policy"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  validation_quests: {
    Enums: {
      priority_level: ["high", "standard", "low"],
      quest_status: ["active", "consensus_reached", "under_review", "archived"],
      quest_type: ["official", "fact", "policy"],
    },
  },
} as const

// ============================================================
// CONVENIENCE RE-EXPORTS — backward compatibility for direct imports
// These allow existing code to continue importing table row types directly
// without needing to use the Database['validation_quests']['Tables']['...']['Row'] syntax.
// ============================================================

export type VerificationQuest = Database['validation_quests']['Tables']['verification_quests']['Row'];
export type VerificationSubmission = Database['validation_quests']['Tables']['verification_submissions']['Row'];
export type ConsensusRecord = Database['validation_quests']['Tables']['consensus_records']['Row'];
export type UserVeracityProfile = Database['validation_quests']['Tables']['user_veracity_profiles']['Row'];
export type VeracityEventLog = Database['validation_quests']['Tables']['veracity_event_logs']['Row'];
export type QuestAssignment = Database['validation_quests']['Tables']['quest_assignments']['Row'];
export type AiAgentCredential = Database['validation_quests']['Tables']['ai_agent_credentials']['Row'];
export type UserNotification = Database['validation_quests']['Tables']['user_notifications']['Row'];
export type UserNotificationPreference = Database['validation_quests']['Tables']['user_notification_preferences']['Row'];
export type AdminOverrideLogRow = Database['validation_quests']['Tables']['admin_override_log']['Row'];
export type GemRewardEventRow = Database['validation_quests']['Tables']['gem_reward_events']['Row'];
export type QuestContestRow = Database['validation_quests']['Tables']['quest_contests']['Row'];

// Insert types
export type VerificationQuestInsert = Database['validation_quests']['Tables']['verification_quests']['Insert'];
export type VerificationSubmissionInsert = Database['validation_quests']['Tables']['verification_submissions']['Insert'];
export type ConsensusRecordInsert = Database['validation_quests']['Tables']['consensus_records']['Insert'];
export type UserVeracityProfileInsert = Database['validation_quests']['Tables']['user_veracity_profiles']['Insert'];
export type VeracityEventLogInsert = Database['validation_quests']['Tables']['veracity_event_logs']['Insert'];
export type UserNotificationInsert = Database['validation_quests']['Tables']['user_notifications']['Insert'];
