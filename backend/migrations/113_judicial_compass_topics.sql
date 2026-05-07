-- Migration 113: Judicial Compass Topics (Universal + Role-Specific)
--
-- Phase 27 — Judicial Compass DB
--
-- Part A (Plan 27-01): 4 universal topics applicable to ALL legal candidates
--   (judges AND City Attorney/DA alike). judicial_role = NULL for all 4.
--
-- Part B (Plan 27-02): 4 role-specific topics added to this file.
--   (judiciary-specific or city_attorney_da-specific)
--
-- Each DO $$ block is fully idempotent — returns early if topic_key already exists
-- with is_live=true. This file is safe to re-run.
--
-- Depends on: migration 112 (judicial_role column + expanded role_scope constraint)

BEGIN;

-- ============================================================
-- Topic 1: Criminal Justice Approach
-- Universal — applies to all judicial candidates
-- ============================================================
DO $$
DECLARE v_id UUID;
BEGIN
  IF EXISTS (SELECT 1 FROM inform.compass_topics WHERE topic_key = 'judicial-criminal-justice' AND is_live = true) THEN RETURN; END IF;
  INSERT INTO inform.compass_topics (topic_key, title, short_title, question_text, is_live, went_live_at, judicial_role)
    VALUES ('judicial-criminal-justice', 'Criminal Justice Approach', 'Criminal Justice', 'When someone breaks the law, what matters most?', true, now(), NULL)
    RETURNING id INTO v_id;
  INSERT INTO inform.compass_stances (topic_id, value, text) VALUES
    (v_id, 1, 'Helping the person change their life and stay out of trouble in the future.'),
    (v_id, 2, 'Giving the person a fair chance to make things right — through treatment, community service, or restitution.'),
    (v_id, 3, 'A mix: some accountability, some support, depending on what happened.'),
    (v_id, 4, 'Making sure others think twice before doing the same thing.'),
    (v_id, 5, 'Punishing the behavior. Society needs to know that breaking the law has real consequences.');
  INSERT INTO inform.compass_topic_roles (topic_id, role_scope, is_required)
    VALUES (v_id, 'judicial', true);
END $$;

-- ============================================================
-- Topic 2: Access to Justice
-- Universal — applies to all judicial candidates
-- ============================================================
DO $$
DECLARE v_id UUID;
BEGIN
  IF EXISTS (SELECT 1 FROM inform.compass_topics WHERE topic_key = 'judicial-access-to-justice' AND is_live = true) THEN RETURN; END IF;
  INSERT INTO inform.compass_topics (topic_key, title, short_title, question_text, is_live, went_live_at, judicial_role)
    VALUES ('judicial-access-to-justice', 'Access to Justice', 'Court Access', 'Should it be easy or hard to take someone to court?', true, now(), NULL)
    RETURNING id INTO v_id;
  INSERT INTO inform.compass_stances (topic_id, value, text) VALUES
    (v_id, 1, 'Easy. Courts exist for everyone — not just people with expensive lawyers. Low barriers mean more access to justice.'),
    (v_id, 2, 'Accessible. Some basic requirements are fine, but courts shouldn''t be a maze that only the wealthy can navigate.'),
    (v_id, 3, 'Reasonable standards that keep out frivolous cases without blocking legitimate ones.'),
    (v_id, 4, 'Higher bars are fine. Too much litigation clogs the system and costs everyone money.'),
    (v_id, 5, 'Hard. Most disputes should be settled privately. Courts should be a last resort, not a first option.');
  INSERT INTO inform.compass_topic_roles (topic_id, role_scope, is_required)
    VALUES (v_id, 'judicial', true);
END $$;

-- ============================================================
-- Topic 3: Prosecutorial/Judicial Discretion
-- Universal — applies to all judicial candidates
-- ============================================================
DO $$
DECLARE v_id UUID;
BEGIN
  IF EXISTS (SELECT 1 FROM inform.compass_topics WHERE topic_key = 'judicial-government-deference' AND is_live = true) THEN RETURN; END IF;
  INSERT INTO inform.compass_topics (topic_key, title, short_title, question_text, is_live, went_live_at, judicial_role)
    VALUES ('judicial-government-deference', 'Judicial & Prosecutorial Discretion', 'Government Deference', 'When government and a citizen clash, who gets the benefit of the doubt?', true, now(), NULL)
    RETURNING id INTO v_id;
  INSERT INTO inform.compass_stances (topic_id, value, text) VALUES
    (v_id, 1, 'The citizen, almost always. Government has lawyers, money, and power. Regular people need courts to level the playing field.'),
    (v_id, 2, 'The citizen usually — unless the government has clear legal authority on its side.'),
    (v_id, 3, 'Neither side automatically. Look at the facts and apply the law evenly.'),
    (v_id, 4, 'The government usually — it represents everyone, and its decisions deserve respect unless clearly wrong.'),
    (v_id, 5, 'The government, unless it has obviously overreached. Officials make decisions for good reasons — courts shouldn''t second-guess them constantly.');
  INSERT INTO inform.compass_topic_roles (topic_id, role_scope, is_required)
    VALUES (v_id, 'judicial', true);
END $$;

-- ============================================================
-- Topic 4: Transparency in Legal Proceedings
-- Universal — applies to all judicial candidates
-- ============================================================
DO $$
DECLARE v_id UUID;
BEGIN
  IF EXISTS (SELECT 1 FROM inform.compass_topics WHERE topic_key = 'judicial-transparency' AND is_live = true) THEN RETURN; END IF;
  INSERT INTO inform.compass_topics (topic_key, title, short_title, question_text, is_live, went_live_at, judicial_role)
    VALUES ('judicial-transparency', 'Transparency in Legal Proceedings', 'Legal Transparency', 'How much should the public know about what happens in court?', true, now(), NULL)
    RETURNING id INTO v_id;
  INSERT INTO inform.compass_stances (topic_id, value, text) VALUES
    (v_id, 1, 'Everything possible should be public — hearings, evidence, rulings, and the reasoning behind them. Secrecy breeds injustice.'),
    (v_id, 2, 'Default to open proceedings. Sealing records or closing hearings requires a compelling, documented reason.'),
    (v_id, 3, 'Balance openness with legitimate needs for privacy — protect victims, seal juvenile records, but keep the courtroom open as a rule.'),
    (v_id, 4, 'Courts should protect sensitive information broadly — personal details, ongoing investigations, and anything that could prejudice a fair trial.'),
    (v_id, 5, 'The law is complicated. Public access to proceedings can distort outcomes. Broad judicial discretion to limit access protects the integrity of the process.');
  INSERT INTO inform.compass_topic_roles (topic_id, role_scope, is_required)
    VALUES (v_id, 'judicial', true);
END $$;

-- Part B (Plan 27-02 topics will be appended here)

COMMIT;
