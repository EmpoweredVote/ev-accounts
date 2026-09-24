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
  connect: {
    Tables: {
      connected_profiles: {
        Row: {
          account_standing: string
          candidate_role: string | null
          completed_onboarding: boolean
          created_at: string
          current_level: number
          deleted_at: string | null
          display_name: string
          gem_balance_blue: number
          gem_balance_red: number
          gem_balance_yellow: number
          gem_reserve_cap: number
          id: string
          legal_name: string | null
          location_consent: boolean | null
          selected_topic_ids: Json
          tolerance_rating: number | null
          total_xp: number
          updated_at: string
          user_id: string
          veracity_rating: number | null
          verification_method: string | null
          verification_rating: number
          verification_status: string
          verified_region: string | null
          vq_hold_until: string | null
          xp: number
        }
        Insert: {
          account_standing?: string
          candidate_role?: string | null
          completed_onboarding?: boolean
          created_at?: string
          current_level?: number
          deleted_at?: string | null
          display_name: string
          gem_balance_blue?: number
          gem_balance_red?: number
          gem_balance_yellow?: number
          gem_reserve_cap?: number
          id?: string
          legal_name?: string | null
          location_consent?: boolean | null
          selected_topic_ids?: Json
          tolerance_rating?: number | null
          total_xp?: number
          updated_at?: string
          user_id: string
          veracity_rating?: number | null
          verification_method?: string | null
          verification_rating?: number
          verification_status?: string
          verified_region?: string | null
          vq_hold_until?: string | null
          xp?: number
        }
        Update: {
          account_standing?: string
          candidate_role?: string | null
          completed_onboarding?: boolean
          created_at?: string
          current_level?: number
          deleted_at?: string | null
          display_name?: string
          gem_balance_blue?: number
          gem_balance_red?: number
          gem_balance_yellow?: number
          gem_reserve_cap?: number
          id?: string
          legal_name?: string | null
          location_consent?: boolean | null
          selected_topic_ids?: Json
          tolerance_rating?: number | null
          total_xp?: number
          updated_at?: string
          user_id?: string
          veracity_rating?: number | null
          verification_method?: string | null
          verification_rating?: number
          verification_status?: string
          verified_region?: string | null
          vq_hold_until?: string | null
          xp?: number
        }
        Relationships: []
      }
      gem_transactions: {
        Row: {
          amount: number
          balance_after: number
          created_at: string
          feature_context: string | null
          gem_type: string
          idempotency_key: string | null
          id: string
          reference_id: string | null
          transaction_type: string
          user_id: string
        }
        Insert: {
          amount: number
          balance_after: number
          created_at?: string
          feature_context?: string | null
          gem_type: string
          idempotency_key?: string | null
          id?: string
          reference_id?: string | null
          transaction_type: string
          user_id: string
        }
        Update: {
          amount?: number
          balance_after?: number
          created_at?: string
          feature_context?: string | null
          gem_type?: string
          idempotency_key?: string | null
          id?: string
          reference_id?: string | null
          transaction_type?: string
          user_id?: string
        }
        Relationships: []
      }
      invite_chains: {
        Row: {
          created_at: string
          id: string
          invite_code_id: string | null
          invitee_id: string
          inviter_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          invite_code_id?: string | null
          invitee_id: string
          inviter_id: string
        }
        Update: {
          created_at?: string
          id?: string
          invite_code_id?: string
          invitee_id?: string
          inviter_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "invite_chains_invite_code_id_fkey"
            columns: ["invite_code_id"]
            isOneToOne: false
            referencedRelation: "invite_codes"
            referencedColumns: ["id"]
          },
        ]
      }
      invite_codes: {
        Row: {
          claimed_at: string | null
          claimed_by: string | null
          code: string
          created_at: string
          created_by: string | null
          expires_at: string | null
          id: string
          is_claimed: boolean
          updated_at: string
        }
        Insert: {
          claimed_at?: string | null
          claimed_by?: string | null
          code: string
          created_at?: string
          created_by?: string | null
          expires_at?: string | null
          id?: string
          is_claimed?: boolean
          updated_at?: string
        }
        Update: {
          claimed_at?: string | null
          claimed_by?: string | null
          code?: string
          created_at?: string
          created_by?: string | null
          expires_at?: string | null
          id?: string
          is_claimed?: boolean
          updated_at?: string
        }
        Relationships: []
      }
      social_relationships: {
        Row: {
          actor_id: string
          connection_type: string
          created_at: string
          id: string
          status: string | null
          target_id: string
          updated_at: string
        }
        Insert: {
          actor_id: string
          connection_type: string
          created_at?: string
          id?: string
          status?: string | null
          target_id: string
          updated_at?: string
        }
        Update: {
          actor_id?: string
          connection_type?: string
          created_at?: string
          id?: string
          status?: string | null
          target_id?: string
          updated_at?: string
        }
        Relationships: []
      }
      verification_sessions: {
        Row: {
          created_at: string
          display_name_draft: string | null
          expires_at: string | null
          home_address_draft: string | null
          id: string
          invite_code_id: string | null
          legal_name_draft: string | null
          region_draft: string | null
          step_reached: string
          updated_at: string
          user_id: string
          verification_method: string | null
        }
        Insert: {
          created_at?: string
          display_name_draft?: string | null
          expires_at?: string | null
          home_address_draft?: string | null
          id?: string
          invite_code_id?: string | null
          legal_name_draft?: string | null
          region_draft?: string | null
          step_reached: string
          updated_at?: string
          user_id: string
          verification_method?: string | null
        }
        Update: {
          created_at?: string
          display_name_draft?: string | null
          expires_at?: string | null
          home_address_draft?: string | null
          id?: string
          invite_code_id?: string | null
          legal_name_draft?: string | null
          region_draft?: string | null
          step_reached?: string
          updated_at?: string
          user_id?: string
          verification_method?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "verification_sessions_invite_code_id_fkey"
            columns: ["invite_code_id"]
            isOneToOne: false
            referencedRelation: "invite_codes"
            referencedColumns: ["id"]
          },
        ]
      }
      tier_promotion_log: {
        Row: {
          admin_email: string
          admin_id: string
          created_at: string
          id: string
          new_tier: string
          note: string | null
          previous_tier: string
          target_user_id: string
        }
        Insert: {
          admin_email: string
          admin_id: string
          created_at?: string
          id?: string
          new_tier: string
          note?: string | null
          previous_tier: string
          target_user_id: string
        }
        Update: {
          admin_email?: string
          admin_id?: string
          created_at?: string
          id?: string
          new_tier?: string
          note?: string | null
          previous_tier?: string
          target_user_id?: string
        }
        Relationships: []
      }
      vq_confirmation_results: {
        Row: {
          idempotency_key: string
          result_json: Json
          created_at: string
        }
        Insert: {
          idempotency_key: string
          result_json: Json
          created_at?: string
        }
        Update: {
          idempotency_key?: string
          result_json?: Json
          created_at?: string
        }
        Relationships: []
      }
      xp_transactions: {
        Row: {
          amount: number
          created_at: string
          id: string
          idempotency_key: string
          metadata: Json | null
          source: string
          user_id: string
        }
        Insert: {
          amount: number
          created_at?: string
          id?: string
          idempotency_key: string
          metadata?: Json | null
          source: string
          user_id: string
        }
        Update: {
          amount?: number
          created_at?: string
          id?: string
          idempotency_key?: string
          metadata?: Json | null
          source?: string
          user_id?: string
        }
        Relationships: []
      }
    }
    Views: {
      connected_profiles_public: {
        Row: {
          account_standing: string | null
          created_at: string | null
          current_level: number | null
          deleted_at: string | null
          display_name: string | null
          gem_balance_blue: number | null
          gem_balance_red: number | null
          gem_balance_yellow: number | null
          gem_reserve_cap: number | null
          id: string | null
          total_xp: number | null
          updated_at: string | null
          user_id: string | null
          veracity_rating: number | null
          verification_method: string | null
          verification_rating: number | null
          verification_status: string | null
          verified_region: string | null
          xp: number | null
        }
        Insert: {
          account_standing?: string | null
          created_at?: string | null
          current_level?: number | null
          deleted_at?: string | null
          display_name?: string | null
          gem_balance_blue?: number | null
          gem_balance_red?: number | null
          gem_balance_yellow?: number | null
          gem_reserve_cap?: number | null
          id?: string | null
          total_xp?: number | null
          updated_at?: string | null
          user_id?: string | null
          veracity_rating?: number | null
          verification_method?: string | null
          verification_rating?: number | null
          verification_status?: string | null
          verified_region?: string | null
          xp?: number | null
        }
        Update: {
          account_standing?: string | null
          created_at?: string | null
          current_level?: number | null
          deleted_at?: string | null
          display_name?: string | null
          gem_balance_blue?: number | null
          gem_balance_red?: number | null
          gem_balance_yellow?: number | null
          gem_reserve_cap?: number | null
          id?: string | null
          total_xp?: number | null
          updated_at?: string | null
          user_id?: string | null
          veracity_rating?: number | null
          verification_method?: string | null
          verification_rating?: number | null
          verification_status?: string | null
          verified_region?: string | null
          xp?: number | null
        }
        Relationships: []
      }
    }
    Functions: {
      adjust_inviter_tolerance_rating: {
        Args: { p_invitee_id: string }
        Returns: undefined
      }
      award_gems: {
        Args: {
          p_user_id: string
          p_gem_type: string
          p_amount: number
          p_idempotency_key: string
          p_transaction_type?: string
          p_source_ref?: string
        }
        Returns: {
          id: string
          user_id: string
          gem_type: string
          amount: number
          idempotency_key: string
          balance_after: number
          created_at: string
          is_duplicate: boolean
        }[]
      }
      award_xp: {
        Args: {
          p_amount: number
          p_idempotency_key: string
          p_metadata?: Json
          p_source: string
          p_user_id: string
        }
        Returns: {
          amount: number
          created_at: string
          current_level: number
          id: string
          idempotency_key: string
          is_duplicate: boolean
          metadata: Json
          source: string
          total_xp: number
          user_id: string
          xp_in_level: number
          xp_to_next_level: number
        }[]
      }
      calculate_level: {
        Args: { p_total_xp: number }
        Returns: {
          level: number
          xp_in_level: number
          xp_to_next_level: number
        }[]
      }
      create_peer_request: {
        Args: { p_actor_id: string; p_target_id: string }
        Returns: {
          actor_id: string
          connection_type: string
          created_at: string
          id: string
          status: string | null
          target_id: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "social_relationships"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      credit_gems: {
        Args: {
          p_amount: number
          p_gem_type: string
          p_source_ref?: string
          p_transaction_type: string
          p_user_id: string
        }
        Returns: {
          amount: number
          balance_after: number
          created_at: string
          feature_context: string | null
          gem_type: string
          id: string
          reference_id: string | null
          transaction_type: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "gem_transactions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      debit_gems: {
        Args: {
          p_amount: number
          p_gem_type: string
          p_source_ref?: string
          p_transaction_type: string
          p_user_id: string
        }
        Returns: {
          amount: number
          balance_after: number
          created_at: string
          feature_context: string | null
          gem_type: string
          id: string
          reference_id: string | null
          transaction_type: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "gem_transactions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      confirm_vq_stance: {
        Args: {
          p_politician_id: string
          p_topic_id: string
          p_confirmed_value: number
          p_correct_users: string[]
          p_incorrect_users: string[]
          p_idempotency_key: string
          p_gems_amount: number
        }
        Returns: Json
      }
      signup_with_invite: {
        Args: {
          p_user_id: string
          p_legal_name: string
          p_invite_code: string
          p_display_name: string
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  empower: {
    Tables: {
      consent_records: {
        Row: {
          consent_given_at: string
          consent_version: string
          consented_items: string[]
          created_at: string
          id: string
          ip_address: string | null
          user_id: string
        }
        Insert: {
          consent_given_at?: string
          consent_version?: string
          consented_items: string[]
          created_at?: string
          id?: string
          ip_address?: string | null
          user_id: string
        }
        Update: {
          consent_given_at?: string
          consent_version?: string
          consented_items?: string[]
          created_at?: string
          id?: string
          ip_address?: string | null
          user_id?: string
        }
        Relationships: []
      }
      empowered_profiles: {
        Row: {
          candidate_page_slug: string | null
          connected_profile_id: string
          created_at: string
          deleted_at: string | null
          demoted_at: string | null
          demotion_reason: Json | null
          empowered_at: string
          id: string
          is_active: boolean
          legal_name: string
          politician_id: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          candidate_page_slug?: string | null
          connected_profile_id: string
          created_at?: string
          deleted_at?: string | null
          demoted_at?: string | null
          demotion_reason?: Json | null
          empowered_at?: string
          id?: string
          is_active?: boolean
          legal_name: string
          politician_id?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          candidate_page_slug?: string | null
          connected_profile_id?: string
          created_at?: string
          deleted_at?: string | null
          demoted_at?: string | null
          demotion_reason?: Json | null
          empowered_at?: string
          id?: string
          is_active?: boolean
          legal_name?: string
          politician_id?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      execute_demotion:
        | { Args: { p_user_id: string }; Returns: undefined }
        | {
            Args: { p_demotion_reason?: Json; p_user_id: string }
            Returns: undefined
          }
      execute_empowerment:
        | {
            Args: {
              p_connected_profile_id: string
              p_legal_name: string
              p_user_id: string
            }
            Returns: {
              candidate_page_slug: string | null
              connected_profile_id: string
              created_at: string
              deleted_at: string | null
              demoted_at: string | null
              demotion_reason: Json | null
              empowered_at: string
              id: string
              is_active: boolean
              legal_name: string
              updated_at: string
              user_id: string
            }
            SetofOptions: {
              from: "*"
              to: "empowered_profiles"
              isOneToOne: true
              isSetofReturn: false
            }
          }
        | {
            Args: {
              p_connected_profile_id: string
              p_legal_name: string
              p_reserved_slug?: string
              p_user_id: string
            }
            Returns: {
              candidate_page_slug: string | null
              connected_profile_id: string
              created_at: string
              deleted_at: string | null
              demoted_at: string | null
              demotion_reason: Json | null
              empowered_at: string
              id: string
              is_active: boolean
              legal_name: string
              updated_at: string
              user_id: string
            }
            SetofOptions: {
              from: "*"
              to: "empowered_profiles"
              isOneToOne: true
              isSetofReturn: false
            }
          }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  inform: {
    Tables: {
      compass_categories: {
        Row: {
          created_at: string
          id: string
          title: string
        }
        Insert: {
          created_at?: string
          id?: string
          title: string
        }
        Update: {
          created_at?: string
          id?: string
          title?: string
        }
        Relationships: []
      }
      compass_change_history: {
        Row: {
          created_at: string
          id: string
          new_value: number
          old_value: number | null
          topic_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          new_value: number
          old_value?: number | null
          topic_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          new_value?: number
          old_value?: number | null
          topic_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "compass_change_history_topic_id_fkey"
            columns: ["topic_id"]
            isOneToOne: false
            referencedRelation: "compass_topics"
            referencedColumns: ["id"]
          },
        ]
      }
      compass_responses: {
        Row: {
          created_at: string
          deleted_at: string | null
          inverted: boolean
          season_id: string
          topic_id: string
          updated_at: string
          user_id: string
          value: number
          visibility: string
          write_in_text: string | null
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          inverted?: boolean
          season_id?: string
          topic_id: string
          updated_at?: string
          user_id: string
          value: number
          visibility?: string
          write_in_text?: string | null
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          inverted?: boolean
          topic_id?: string
          updated_at?: string
          user_id?: string
          value?: number
          visibility?: string
          write_in_text?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "compass_responses_topic_id_fkey"
            columns: ["topic_id"]
            isOneToOne: false
            referencedRelation: "compass_topics"
            referencedColumns: ["id"]
          },
        ]
      }
      compass_stances: {
        Row: {
          id: string
          text: string
          topic_id: string
          value: number
        }
        Insert: {
          id?: string
          text: string
          topic_id: string
          value: number
        }
        Update: {
          id?: string
          text?: string
          topic_id?: string
          value?: number
        }
        Relationships: [
          {
            foreignKeyName: "compass_stances_topic_id_fkey"
            columns: ["topic_id"]
            isOneToOne: false
            referencedRelation: "compass_topics"
            referencedColumns: ["id"]
          },
        ]
      }
      compass_topic_categories: {
        Row: {
          category_id: string
          topic_id: string
        }
        Insert: {
          category_id: string
          topic_id: string
        }
        Update: {
          category_id?: string
          topic_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "compass_topic_categories_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "compass_categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "compass_topic_categories_topic_id_fkey"
            columns: ["topic_id"]
            isOneToOne: false
            referencedRelation: "compass_topics"
            referencedColumns: ["id"]
          },
        ]
      }
      compass_topic_roles: {
        Row: {
          is_required: boolean
          role_scope: string
          topic_id: string
        }
        Insert: {
          is_required?: boolean
          role_scope: string
          topic_id: string
        }
        Update: {
          is_required?: boolean
          role_scope?: string
          topic_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "compass_topic_roles_topic_id_fkey"
            columns: ["topic_id"]
            isOneToOne: false
            referencedRelation: "compass_topics"
            referencedColumns: ["id"]
          },
        ]
      }
      compass_topics: {
        Row: {
          created_at: string
          fc_community_slug: string | null
          id: string
          is_active: boolean | null
          is_live: boolean
          judicial_role: string | null
          office_scope: string | null
          question_text: string
          short_title: string | null
          title: string
          topic_key: string
          updated_at: string
          version: number
          went_live_at: string | null
        }
        Insert: {
          created_at?: string
          fc_community_slug?: string | null
          id?: string
          is_active?: boolean | null
          is_live?: boolean
          judicial_role?: string | null
          office_scope?: string | null
          question_text: string
          short_title?: string | null
          title: string
          topic_key: string
          updated_at?: string
          version?: number
          went_live_at?: string | null
        }
        Update: {
          created_at?: string
          fc_community_slug?: string | null
          id?: string
          is_active?: boolean | null
          is_live?: boolean
          judicial_role?: string | null
          office_scope?: string | null
          question_text?: string
          short_title?: string | null
          title?: string
          topic_key?: string
          updated_at?: string
          version?: number
          went_live_at?: string | null
        }
        Relationships: []
      }
      politician_answers: {
        Row: {
          politician_id: string
          topic_id: string
          value: number
        }
        Insert: {
          politician_id: string
          topic_id: string
          value: number
        }
        Update: {
          politician_id?: string
          topic_id?: string
          value?: number
        }
        Relationships: [
          {
            foreignKeyName: "politician_answers_politician_id_fkey"
            columns: ["politician_id"]
            isOneToOne: false
            referencedRelation: "politicians"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "politician_answers_topic_id_fkey"
            columns: ["topic_id"]
            isOneToOne: false
            referencedRelation: "compass_topics"
            referencedColumns: ["id"]
          },
        ]
      }
      politician_context: {
        Row: {
          politician_id: string
          reasoning: string
          sources: string[]
          topic_id: string
        }
        Insert: {
          politician_id: string
          reasoning: string
          sources?: string[]
          topic_id: string
        }
        Update: {
          politician_id?: string
          reasoning?: string
          sources?: string[]
          topic_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "politician_context_politician_id_fkey"
            columns: ["politician_id"]
            isOneToOne: false
            referencedRelation: "politicians"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "politician_context_topic_id_fkey"
            columns: ["topic_id"]
            isOneToOne: false
            referencedRelation: "compass_topics"
            referencedColumns: ["id"]
          },
        ]
      }
      politicians: {
        Row: {
          chamber_name: string | null
          chamber_name_formal: string | null
          created_at: string
          district_id: string | null
          district_label: string | null
          district_type: string | null
          first_name: string
          full_name: string | null
          government_name: string | null
          id: string
          is_active: boolean
          is_candidate: boolean
          is_vacant: boolean
          last_name: string
          office_title: string | null
          photo_origin_url: string | null
          preferred_name: string | null
          representing_city: string | null
          representing_state: string | null
        }
        Insert: {
          chamber_name?: string | null
          chamber_name_formal?: string | null
          created_at?: string
          district_id?: string | null
          district_label?: string | null
          district_type?: string | null
          first_name: string
          full_name?: string | null
          government_name?: string | null
          id?: string
          is_active?: boolean
          is_candidate?: boolean
          is_vacant?: boolean
          last_name: string
          office_title?: string | null
          photo_origin_url?: string | null
          preferred_name?: string | null
          representing_city?: string | null
          representing_state?: string | null
        }
        Update: {
          chamber_name?: string | null
          chamber_name_formal?: string | null
          created_at?: string
          district_id?: string | null
          district_label?: string | null
          district_type?: string | null
          first_name?: string
          full_name?: string | null
          government_name?: string | null
          id?: string
          is_active?: boolean
          is_candidate?: boolean
          is_vacant?: boolean
          last_name?: string
          office_title?: string | null
          photo_origin_url?: string | null
          preferred_name?: string | null
          representing_city?: string | null
          representing_state?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      compass_responses_current: {
        Row: {
          answered_revision_id: string | null
          created_at: string
          deleted_at: string | null
          inverted: boolean
          season_id: string
          topic_id: string
          updated_at: string
          user_id: string
          value: number
          visibility: string
          write_in_text: string | null
        }
        Relationships: []
      }
      // compass_responses_current minus the answers CC_0061 calls moved or
      // invalidated (CC_0062). Identical Row shape by construction — the view
      // selects the same eleven columns and only drops rows — so a consumer
      // switching to it needs no other change. `deleted_at` stays nullable to
      // mirror the source even though the view filters it to NULL.
      compass_responses_effective: {
        Row: {
          answered_revision_id: string | null
          created_at: string
          deleted_at: string | null
          inverted: boolean
          season_id: string
          topic_id: string
          updated_at: string
          user_id: string
          value: number
          visibility: string
          write_in_text: string | null
        }
        Relationships: []
      }
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      access_requests: {
        Row: {
          id: string
          email: string
          requested_at: string
        }
        Insert: {
          id?: string
          email: string
          requested_at?: string
        }
        Update: {
          id?: string
          email?: string
          requested_at?: string
        }
        Relationships: []
      }
      admin_audit_log: {
        Row: {
          action: string
          actor_id: string
          created_at: string
          details: Json
          id: string
          metadata: Json | null
          target_id: string | null
          target_user_id: string | null
        }
        Insert: {
          action: string
          actor_id: string
          created_at?: string
          details?: Json
          id?: string
          metadata?: Json | null
          target_id?: string | null
          target_user_id?: string | null
        }
        Update: {
          action?: string
          actor_id?: string
          created_at?: string
          details?: Json
          id?: string
          metadata?: Json | null
          target_id?: string | null
          target_user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "admin_audit_log_actor_id_fkey"
            columns: ["actor_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_audit_log_actor_id_fkey"
            columns: ["actor_id"]
            isOneToOne: false
            referencedRelation: "users_public"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_audit_log_target_user_id_fkey"
            columns: ["target_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_audit_log_target_user_id_fkey"
            columns: ["target_user_id"]
            isOneToOne: false
            referencedRelation: "users_public"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_users: {
        Row: {
          created_at: string
          super_admin: boolean
          user_id: string
        }
        Insert: {
          created_at?: string
          super_admin?: boolean
          user_id: string
        }
        Update: {
          created_at?: string
          super_admin?: boolean
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "admin_users_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_users_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users_public"
            referencedColumns: ["id"]
          },
        ]
      }
      calibration_lapse_runs: {
        Row: {
          error_message: string | null
          finished_at: string | null
          run_date: string
          started_at: string
          users_demoted: number
          users_warned_25: number
          users_warned_30: number
        }
        Insert: {
          error_message?: string | null
          finished_at?: string | null
          run_date: string
          started_at?: string
          users_demoted?: number
          users_warned_25?: number
          users_warned_30?: number
        }
        Update: {
          error_message?: string | null
          finished_at?: string | null
          run_date?: string
          started_at?: string
          users_demoted?: number
          users_warned_25?: number
          users_warned_30?: number
        }
        Relationships: []
      }
      notification_events: {
        Row: {
          created_at: string
          event_type: string
          id: string
          metadata: Json | null
          read_at: string | null
          user_id: string
        }
        Insert: {
          created_at?: string
          event_type: string
          id?: string
          metadata?: Json | null
          read_at?: string | null
          user_id: string
        }
        Update: {
          created_at?: string
          event_type?: string
          id?: string
          metadata?: Json | null
          read_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notification_events_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notification_events_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users_public"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          created_at: string
          id: string
          payload: Json
          read_at: string | null
          type: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          payload?: Json
          read_at?: string | null
          type: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          payload?: Json
          read_at?: string | null
          type?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users_public"
            referencedColumns: ["id"]
          },
        ]
      }
      roles: {
        Row: {
          created_at: string
          description: string | null
          id: string
          is_active: boolean
          name: string
          required_tier: string | null
          slug: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name: string
          required_tier?: string | null
          slug: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name?: string
          required_tier?: string | null
          slug?: string
        }
        Relationships: []
      }
      spatial_ref_sys: {
        Row: {
          auth_name: string | null
          auth_srid: number | null
          proj4text: string | null
          srid: number
          srtext: string | null
        }
        Insert: {
          auth_name?: string | null
          auth_srid?: number | null
          proj4text?: string | null
          srid: number
          srtext?: string | null
        }
        Update: {
          auth_name?: string | null
          auth_srid?: number | null
          proj4text?: string | null
          srid?: number
          srtext?: string | null
        }
        Relationships: []
      }
      user_roles: {
        Row: {
          granted_at: string
          id: string
          revoked_at: string | null
          role_id: string
          user_id: string
        }
        Insert: {
          granted_at?: string
          id?: string
          revoked_at?: string | null
          role_id: string
          user_id: string
        }
        Update: {
          granted_at?: string
          id?: string
          revoked_at?: string | null
          role_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_roles_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "roles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_roles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_roles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users_public"
            referencedColumns: ["id"]
          },
        ]
      }
      users: {
        Row: {
          avatar_url: string | null
          created_at: string | null
          deleted_at: string | null
          display_name: string | null
          id: string
          updated_at: string | null
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string | null
          deleted_at?: string | null
          display_name?: string | null
          id: string
          updated_at?: string | null
        }
        Update: {
          avatar_url?: string | null
          created_at?: string | null
          deleted_at?: string | null
          display_name?: string | null
          id?: string
          updated_at?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      geography_columns: {
        Row: {
          coord_dimension: number | null
          f_geography_column: unknown
          f_table_catalog: unknown
          f_table_name: unknown
          f_table_schema: unknown
          srid: number | null
          type: string | null
        }
        Relationships: []
      }
      geometry_columns: {
        Row: {
          coord_dimension: number | null
          f_geometry_column: unknown
          f_table_catalog: string | null
          f_table_name: unknown
          f_table_schema: unknown
          srid: number | null
          type: string | null
        }
        Insert: {
          coord_dimension?: number | null
          f_geometry_column?: unknown
          f_table_catalog?: string | null
          f_table_name?: unknown
          f_table_schema?: unknown
          srid?: number | null
          type?: string | null
        }
        Update: {
          coord_dimension?: number | null
          f_geometry_column?: unknown
          f_table_catalog?: string | null
          f_table_name?: unknown
          f_table_schema?: unknown
          srid?: number | null
          type?: string | null
        }
        Relationships: []
      }
      users_public: {
        Row: {
          avatar_url: string | null
          display_name: string | null
          id: string | null
        }
        Insert: {
          avatar_url?: string | null
          display_name?: string | null
          id?: string | null
        }
        Update: {
          avatar_url?: string | null
          display_name?: string | null
          id?: string | null
        }
        Relationships: []
      }
    }
    Functions: {
      _postgis_deprecate: {
        Args: { newname: string; oldname: string; version: string }
        Returns: undefined
      }
      _postgis_index_extent: {
        Args: { col: string; tbl: unknown }
        Returns: unknown
      }
      _postgis_pgsql_version: { Args: never; Returns: string }
      _postgis_scripts_pgsql_version: { Args: never; Returns: string }
      _postgis_selectivity: {
        Args: { att_name: string; geom: unknown; mode?: string; tbl: unknown }
        Returns: number
      }
      _postgis_stats: {
        Args: { ""?: string; att_name: string; tbl: unknown }
        Returns: string
      }
      _st_3dintersects: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_contains: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_containsproperly: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_coveredby:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _st_covers:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _st_crosses: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_dwithin: {
        Args: {
          geog1: unknown
          geog2: unknown
          tolerance: number
          use_spheroid?: boolean
        }
        Returns: boolean
      }
      _st_equals: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _st_intersects: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_linecrossingdirection: {
        Args: { line1: unknown; line2: unknown }
        Returns: number
      }
      _st_longestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      _st_maxdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      _st_orderingequals: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_overlaps: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_sortablehash: { Args: { geom: unknown }; Returns: number }
      _st_touches: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_voronoi: {
        Args: {
          clip?: unknown
          g1: unknown
          return_polygons?: boolean
          tolerance?: number
        }
        Returns: unknown
      }
      _st_within: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      addauth: { Args: { "": string }; Returns: boolean }
      addgeometrycolumn:
        | {
            Args: {
              catalog_name: string
              column_name: string
              new_dim: number
              new_srid_in: number
              new_type: string
              schema_name: string
              table_name: string
              use_typmod?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              column_name: string
              new_dim: number
              new_srid: number
              new_type: string
              schema_name: string
              table_name: string
              use_typmod?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              column_name: string
              new_dim: number
              new_srid: number
              new_type: string
              table_name: string
              use_typmod?: boolean
            }
            Returns: string
          }
      admin_create_invite: {
        Args: { p_created_by: string; p_recipient_email?: string }
        Returns: Json
      }
      admin_get_account_detail: { Args: { p_user_id: string }; Returns: Json }
      admin_get_cron_log: { Args: { p_page?: number }; Returns: Json }
      admin_get_dashboard_stats: { Args: never; Returns: Json }
      admin_get_invite_tree: {
        Args: { p_root_user_id?: string }
        Returns: Json
      }
      admin_list_accounts: {
        Args: {
          p_page?: number
          p_search?: string
          p_standing?: string
          p_tier?: string
        }
        Returns: Json
      }
      admin_list_invites: { Args: { p_page?: number }; Returns: Json }
      admin_list_politicians: { Args: never; Returns: Json }
      admin_update_politician_answers: {
        Args: { p_answers: Json; p_politician_id: string }
        Returns: undefined
      }
      admin_update_topic: {
        Args: {
          p_is_live?: boolean
          p_question_text?: string
          p_short_title?: string
          p_title?: string
          p_topic_id: string
        }
        Returns: Json
      }
      block_user: {
        Args: { p_actor_id: string; p_target_id: string }
        Returns: undefined
      }
      claim_invite_code: {
        Args: { p_claimant_user_id: string; p_code: string }
        Returns: Json
      }
      complete_connect_flow: { Args: { p_user_id: string }; Returns: Json }
      create_invite_codes: {
        Args: { p_count: number; p_user_id: string }
        Returns: string[]
      }
      cron_record_lapse_error: {
        Args: { p_error: string; p_run_date: string }
        Returns: undefined
      }
      cron_update_lapse_run: {
        Args: {
          p_demoted: number
          p_run_date: string
          p_warned_25: number
          p_warned_30: number
        }
        Returns: undefined
      }
      cron_upsert_lapse_run: { Args: { p_run_date: string }; Returns: boolean }
      disablelongtransactions: { Args: never; Returns: string }
      dropgeometrycolumn:
        | {
            Args: {
              catalog_name: string
              column_name: string
              schema_name: string
              table_name: string
            }
            Returns: string
          }
        | {
            Args: {
              column_name: string
              schema_name: string
              table_name: string
            }
            Returns: string
          }
        | { Args: { column_name: string; table_name: string }; Returns: string }
      dropgeometrytable:
        | {
            Args: {
              catalog_name: string
              schema_name: string
              table_name: string
            }
            Returns: string
          }
        | { Args: { schema_name: string; table_name: string }; Returns: string }
        | { Args: { table_name: string }; Returns: string }
      enablelongtransactions: { Args: never; Returns: string }
      equals: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      follow_user: {
        Args: { p_actor_id: string; p_target_id: string }
        Returns: undefined
      }
      geometry: { Args: { "": string }; Returns: unknown }
      geometry_above: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_below: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_cmp: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      geometry_contained_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_contains: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_contains_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_distance_box: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      geometry_distance_centroid: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      geometry_eq: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_ge: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_gt: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_le: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_left: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_lt: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overabove: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overbelow: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overlaps: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overlaps_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overleft: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overright: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_right: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_same: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_same_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_within: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geomfromewkt: { Args: { "": string }; Returns: unknown }
      get_calibration_lapsed_users:
        | {
            Args: never
            Returns: {
              user_id: string
            }[]
          }
        | {
            Args: { p_days_threshold?: number }
            Returns: {
              days_overdue: number
              overdue_topic_ids: string[]
              user_id: string
            }[]
          }
      get_compass_completeness: {
        Args: { p_role_scope?: string; p_user_id: string }
        Returns: Json
      }
      get_connections: { Args: { p_user_id: string }; Returns: Json }
      get_following: { Args: { p_user_id: string }; Returns: Json }
      get_user_roles: { Args: { p_user_id: string }; Returns: Json }
      gettransactionid: { Args: never; Returns: unknown }
      grant_role: {
        Args: { p_role_slug: string; p_user_id: string }
        Returns: undefined
      }
      insert_notification: {
        Args: { p_payload: Json; p_type: string; p_user_id: string }
        Returns: undefined
      }
      longtransactionsenabled: { Args: never; Returns: boolean }
      populate_geometry_columns:
        | { Args: { tbl_oid: unknown; use_typmod?: boolean }; Returns: number }
        | { Args: { use_typmod?: boolean }; Returns: string }
      postgis_constraint_dims: {
        Args: { geomcolumn: string; geomschema: string; geomtable: string }
        Returns: number
      }
      postgis_constraint_srid: {
        Args: { geomcolumn: string; geomschema: string; geomtable: string }
        Returns: number
      }
      postgis_constraint_type: {
        Args: { geomcolumn: string; geomschema: string; geomtable: string }
        Returns: string
      }
      postgis_extensions_upgrade: { Args: never; Returns: string }
      postgis_full_version: { Args: never; Returns: string }
      postgis_geos_version: { Args: never; Returns: string }
      postgis_lib_build_date: { Args: never; Returns: string }
      postgis_lib_revision: { Args: never; Returns: string }
      postgis_lib_version: { Args: never; Returns: string }
      postgis_libjson_version: { Args: never; Returns: string }
      postgis_liblwgeom_version: { Args: never; Returns: string }
      postgis_libprotobuf_version: { Args: never; Returns: string }
      postgis_libxml_version: { Args: never; Returns: string }
      postgis_proj_version: { Args: never; Returns: string }
      postgis_scripts_build_date: { Args: never; Returns: string }
      postgis_scripts_installed: { Args: never; Returns: string }
      postgis_scripts_released: { Args: never; Returns: string }
      postgis_svn_version: { Args: never; Returns: string }
      postgis_type_name: {
        Args: {
          coord_dimension: number
          geomname: string
          use_new_name?: boolean
        }
        Returns: string
      }
      postgis_version: { Args: never; Returns: string }
      postgis_wagyu_version: { Args: never; Returns: string }
      revoke_role: {
        Args: { p_role_slug: string; p_user_id: string }
        Returns: undefined
      }
      run_empower_preflight: { Args: { p_user_id: string }; Returns: Json }
      soft_delete_user: { Args: { p_user_id: string }; Returns: undefined }
      st_3dclosestpoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_3ddistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_3dintersects: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_3dlongestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_3dmakebox: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_3dmaxdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_3dshortestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_addpoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_angle:
        | { Args: { line1: unknown; line2: unknown }; Returns: number }
        | {
            Args: { pt1: unknown; pt2: unknown; pt3: unknown; pt4?: unknown }
            Returns: number
          }
      st_area:
        | { Args: { geog: unknown; use_spheroid?: boolean }; Returns: number }
        | { Args: { "": string }; Returns: number }
      st_asencodedpolyline: {
        Args: { geom: unknown; nprecision?: number }
        Returns: string
      }
      st_asewkt: { Args: { "": string }; Returns: string }
      st_asgeojson:
        | {
            Args: { geog: unknown; maxdecimaldigits?: number; options?: number }
            Returns: string
          }
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; options?: number }
            Returns: string
          }
        | {
            Args: {
              geom_column?: string
              maxdecimaldigits?: number
              pretty_bool?: boolean
              r: Record<string, unknown>
            }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_asgml:
        | {
            Args: {
              geog: unknown
              id?: string
              maxdecimaldigits?: number
              nprefix?: string
              options?: number
            }
            Returns: string
          }
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; options?: number }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
        | {
            Args: {
              geog: unknown
              id?: string
              maxdecimaldigits?: number
              nprefix?: string
              options?: number
              version: number
            }
            Returns: string
          }
        | {
            Args: {
              geom: unknown
              id?: string
              maxdecimaldigits?: number
              nprefix?: string
              options?: number
              version: number
            }
            Returns: string
          }
      st_askml:
        | {
            Args: { geog: unknown; maxdecimaldigits?: number; nprefix?: string }
            Returns: string
          }
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; nprefix?: string }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_aslatlontext: {
        Args: { geom: unknown; tmpl?: string }
        Returns: string
      }
      st_asmarc21: { Args: { format?: string; geom: unknown }; Returns: string }
      st_asmvtgeom: {
        Args: {
          bounds: unknown
          buffer?: number
          clip_geom?: boolean
          extent?: number
          geom: unknown
        }
        Returns: unknown
      }
      st_assvg:
        | {
            Args: { geog: unknown; maxdecimaldigits?: number; rel?: number }
            Returns: string
          }
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; rel?: number }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_astext: { Args: { "": string }; Returns: string }
      st_astwkb:
        | {
            Args: {
              geom: unknown
              prec?: number
              prec_m?: number
              prec_z?: number
              with_boxes?: boolean
              with_sizes?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              geom: unknown[]
              ids: number[]
              prec?: number
              prec_m?: number
              prec_z?: number
              with_boxes?: boolean
              with_sizes?: boolean
            }
            Returns: string
          }
      st_asx3d: {
        Args: { geom: unknown; maxdecimaldigits?: number; options?: number }
        Returns: string
      }
      st_azimuth:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: number }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: number }
      st_boundingdiagonal: {
        Args: { fits?: boolean; geom: unknown }
        Returns: unknown
      }
      st_buffer:
        | {
            Args: { geom: unknown; options?: string; radius: number }
            Returns: unknown
          }
        | {
            Args: { geom: unknown; quadsegs: number; radius: number }
            Returns: unknown
          }
      st_centroid: { Args: { "": string }; Returns: unknown }
      st_clipbybox2d: {
        Args: { box: unknown; geom: unknown }
        Returns: unknown
      }
      st_closestpoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_collect: { Args: { geom1: unknown; geom2: unknown }; Returns: unknown }
      st_concavehull: {
        Args: {
          param_allow_holes?: boolean
          param_geom: unknown
          param_pctconvex: number
        }
        Returns: unknown
      }
      st_contains: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_containsproperly: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_coorddim: { Args: { geometry: unknown }; Returns: number }
      st_coveredby:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_covers:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_crosses: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_curvetoline: {
        Args: { flags?: number; geom: unknown; tol?: number; toltype?: number }
        Returns: unknown
      }
      st_delaunaytriangles: {
        Args: { flags?: number; g1: unknown; tolerance?: number }
        Returns: unknown
      }
      st_difference: {
        Args: { geom1: unknown; geom2: unknown; gridsize?: number }
        Returns: unknown
      }
      st_disjoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_distance:
        | {
            Args: { geog1: unknown; geog2: unknown; use_spheroid?: boolean }
            Returns: number
          }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: number }
      st_distancesphere:
        | { Args: { geom1: unknown; geom2: unknown }; Returns: number }
        | {
            Args: { geom1: unknown; geom2: unknown; radius: number }
            Returns: number
          }
      st_distancespheroid: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_dwithin: {
        Args: {
          geog1: unknown
          geog2: unknown
          tolerance: number
          use_spheroid?: boolean
        }
        Returns: boolean
      }
      st_equals: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_expand:
        | { Args: { box: unknown; dx: number; dy: number }; Returns: unknown }
        | {
            Args: { box: unknown; dx: number; dy: number; dz?: number }
            Returns: unknown
          }
        | {
            Args: {
              dm?: number
              dx: number
              dy: number
              dz?: number
              geom: unknown
            }
            Returns: unknown
          }
      st_force3d: { Args: { geom: unknown; zvalue?: number }; Returns: unknown }
      st_force3dm: {
        Args: { geom: unknown; mvalue?: number }
        Returns: unknown
      }
      st_force3dz: {
        Args: { geom: unknown; zvalue?: number }
        Returns: unknown
      }
      st_force4d: {
        Args: { geom: unknown; mvalue?: number; zvalue?: number }
        Returns: unknown
      }
      st_generatepoints:
        | { Args: { area: unknown; npoints: number }; Returns: unknown }
        | {
            Args: { area: unknown; npoints: number; seed: number }
            Returns: unknown
          }
      st_geogfromtext: { Args: { "": string }; Returns: unknown }
      st_geographyfromtext: { Args: { "": string }; Returns: unknown }
      st_geohash:
        | { Args: { geog: unknown; maxchars?: number }; Returns: string }
        | { Args: { geom: unknown; maxchars?: number }; Returns: string }
      st_geomcollfromtext: { Args: { "": string }; Returns: unknown }
      st_geometricmedian: {
        Args: {
          fail_if_not_converged?: boolean
          g: unknown
          max_iter?: number
          tolerance?: number
        }
        Returns: unknown
      }
      st_geometryfromtext: { Args: { "": string }; Returns: unknown }
      st_geomfromewkt: { Args: { "": string }; Returns: unknown }
      st_geomfromgeojson:
        | { Args: { "": Json }; Returns: unknown }
        | { Args: { "": Json }; Returns: unknown }
        | { Args: { "": string }; Returns: unknown }
      st_geomfromgml: { Args: { "": string }; Returns: unknown }
      st_geomfromkml: { Args: { "": string }; Returns: unknown }
      st_geomfrommarc21: { Args: { marc21xml: string }; Returns: unknown }
      st_geomfromtext: { Args: { "": string }; Returns: unknown }
      st_gmltosql: { Args: { "": string }; Returns: unknown }
      st_hasarc: { Args: { geometry: unknown }; Returns: boolean }
      st_hausdorffdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_hexagon: {
        Args: { cell_i: number; cell_j: number; origin?: unknown; size: number }
        Returns: unknown
      }
      st_hexagongrid: {
        Args: { bounds: unknown; size: number }
        Returns: Record<string, unknown>[]
      }
      st_interpolatepoint: {
        Args: { line: unknown; point: unknown }
        Returns: number
      }
      st_intersection: {
        Args: { geom1: unknown; geom2: unknown; gridsize?: number }
        Returns: unknown
      }
      st_intersects:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_isvaliddetail: {
        Args: { flags?: number; geom: unknown }
        Returns: Database["public"]["CompositeTypes"]["valid_detail"]
        SetofOptions: {
          from: "*"
          to: "valid_detail"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      st_length:
        | { Args: { geog: unknown; use_spheroid?: boolean }; Returns: number }
        | { Args: { "": string }; Returns: number }
      st_letters: { Args: { font?: Json; letters: string }; Returns: unknown }
      st_linecrossingdirection: {
        Args: { line1: unknown; line2: unknown }
        Returns: number
      }
      st_linefromencodedpolyline: {
        Args: { nprecision?: number; txtin: string }
        Returns: unknown
      }
      st_linefromtext: { Args: { "": string }; Returns: unknown }
      st_linelocatepoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_linetocurve: { Args: { geometry: unknown }; Returns: unknown }
      st_locatealong: {
        Args: { geometry: unknown; leftrightoffset?: number; measure: number }
        Returns: unknown
      }
      st_locatebetween: {
        Args: {
          frommeasure: number
          geometry: unknown
          leftrightoffset?: number
          tomeasure: number
        }
        Returns: unknown
      }
      st_locatebetweenelevations: {
        Args: { fromelevation: number; geometry: unknown; toelevation: number }
        Returns: unknown
      }
      st_longestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_makebox2d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_makeline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_makevalid: {
        Args: { geom: unknown; params: string }
        Returns: unknown
      }
      st_maxdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_minimumboundingcircle: {
        Args: { inputgeom: unknown; segs_per_quarter?: number }
        Returns: unknown
      }
      st_mlinefromtext: { Args: { "": string }; Returns: unknown }
      st_mpointfromtext: { Args: { "": string }; Returns: unknown }
      st_mpolyfromtext: { Args: { "": string }; Returns: unknown }
      st_multilinestringfromtext: { Args: { "": string }; Returns: unknown }
      st_multipointfromtext: { Args: { "": string }; Returns: unknown }
      st_multipolygonfromtext: { Args: { "": string }; Returns: unknown }
      st_node: { Args: { g: unknown }; Returns: unknown }
      st_normalize: { Args: { geom: unknown }; Returns: unknown }
      st_offsetcurve: {
        Args: { distance: number; line: unknown; params?: string }
        Returns: unknown
      }
      st_orderingequals: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_overlaps: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_perimeter: {
        Args: { geog: unknown; use_spheroid?: boolean }
        Returns: number
      }
      st_pointfromtext: { Args: { "": string }; Returns: unknown }
      st_pointm: {
        Args: {
          mcoordinate: number
          srid?: number
          xcoordinate: number
          ycoordinate: number
        }
        Returns: unknown
      }
      st_pointz: {
        Args: {
          srid?: number
          xcoordinate: number
          ycoordinate: number
          zcoordinate: number
        }
        Returns: unknown
      }
      st_pointzm: {
        Args: {
          mcoordinate: number
          srid?: number
          xcoordinate: number
          ycoordinate: number
          zcoordinate: number
        }
        Returns: unknown
      }
      st_polyfromtext: { Args: { "": string }; Returns: unknown }
      st_polygonfromtext: { Args: { "": string }; Returns: unknown }
      st_project: {
        Args: { azimuth: number; distance: number; geog: unknown }
        Returns: unknown
      }
      st_quantizecoordinates: {
        Args: {
          g: unknown
          prec_m?: number
          prec_x: number
          prec_y?: number
          prec_z?: number
        }
        Returns: unknown
      }
      st_reduceprecision: {
        Args: { geom: unknown; gridsize: number }
        Returns: unknown
      }
      st_relate: { Args: { geom1: unknown; geom2: unknown }; Returns: string }
      st_removerepeatedpoints: {
        Args: { geom: unknown; tolerance?: number }
        Returns: unknown
      }
      st_segmentize: {
        Args: { geog: unknown; max_segment_length: number }
        Returns: unknown
      }
      st_setsrid:
        | { Args: { geog: unknown; srid: number }; Returns: unknown }
        | { Args: { geom: unknown; srid: number }; Returns: unknown }
      st_sharedpaths: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_shortestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_simplifypolygonhull: {
        Args: { geom: unknown; is_outer?: boolean; vertex_fraction: number }
        Returns: unknown
      }
      st_split: { Args: { geom1: unknown; geom2: unknown }; Returns: unknown }
      st_square: {
        Args: { cell_i: number; cell_j: number; origin?: unknown; size: number }
        Returns: unknown
      }
      st_squaregrid: {
        Args: { bounds: unknown; size: number }
        Returns: Record<string, unknown>[]
      }
      st_srid:
        | { Args: { geog: unknown }; Returns: number }
        | { Args: { geom: unknown }; Returns: number }
      st_subdivide: {
        Args: { geom: unknown; gridsize?: number; maxvertices?: number }
        Returns: unknown[]
      }
      st_swapordinates: {
        Args: { geom: unknown; ords: unknown }
        Returns: unknown
      }
      st_symdifference: {
        Args: { geom1: unknown; geom2: unknown; gridsize?: number }
        Returns: unknown
      }
      st_symmetricdifference: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_tileenvelope: {
        Args: {
          bounds?: unknown
          margin?: number
          x: number
          y: number
          zoom: number
        }
        Returns: unknown
      }
      st_touches: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_transform:
        | {
            Args: { from_proj: string; geom: unknown; to_proj: string }
            Returns: unknown
          }
        | {
            Args: { from_proj: string; geom: unknown; to_srid: number }
            Returns: unknown
          }
        | { Args: { geom: unknown; to_proj: string }; Returns: unknown }
      st_triangulatepolygon: { Args: { g1: unknown }; Returns: unknown }
      st_union:
        | { Args: { geom1: unknown; geom2: unknown }; Returns: unknown }
        | {
            Args: { geom1: unknown; geom2: unknown; gridsize: number }
            Returns: unknown
          }
      st_voronoilines: {
        Args: { extend_to?: unknown; g1: unknown; tolerance?: number }
        Returns: unknown
      }
      st_voronoipolygons: {
        Args: { extend_to?: unknown; g1: unknown; tolerance?: number }
        Returns: unknown
      }
      st_within: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_wkbtosql: { Args: { wkb: string }; Returns: unknown }
      st_wkttosql: { Args: { "": string }; Returns: unknown }
      st_wrapx: {
        Args: { geom: unknown; move: number; wrap: number }
        Returns: unknown
      }
      unlockrows: { Args: { "": string }; Returns: number }
      updategeometrysrid: {
        Args: {
          catalogn_name: string
          column_name: string
          new_srid_in: number
          schema_name: string
          table_name: string
        }
        Returns: string
      }
      upsert_compass_answer: {
        Args: {
          p_inverted?: boolean
          p_topic_id: string
          p_user_id: string
          p_value: number
          p_write_in_text?: string
        }
        Returns: Json
      }
      uuid_generate_v1: { Args: never; Returns: string }
      uuid_generate_v1mc: { Args: never; Returns: string }
      uuid_generate_v3: {
        Args: { name: string; namespace: string }
        Returns: string
      }
      uuid_generate_v4: { Args: never; Returns: string }
      uuid_generate_v5: {
        Args: { name: string; namespace: string }
        Returns: string
      }
      uuid_nil: { Args: never; Returns: string }
      uuid_ns_dns: { Args: never; Returns: string }
      uuid_ns_oid: { Args: never; Returns: string }
      uuid_ns_url: { Args: never; Returns: string }
      uuid_ns_x500: { Args: never; Returns: string }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      geometry_dump: {
        path: number[] | null
        geom: unknown
      }
      valid_detail: {
        valid: boolean | null
        reason: string | null
        location: unknown
      }
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
  connect: {
    Enums: {},
  },
  empower: {
    Enums: {},
  },
  public: {
    Enums: {},
  },
} as const
