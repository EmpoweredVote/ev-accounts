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

-- ============================================================
-- Topic 5: Judicial Interpretation
-- Judge-specific — judicial_role = 'judge'
-- ============================================================
DO $$
DECLARE v_id UUID;
BEGIN
  IF EXISTS (SELECT 1 FROM inform.compass_topics WHERE topic_key = 'judicial-interpretation' AND is_live = true) THEN RETURN; END IF;
  INSERT INTO inform.compass_topics (topic_key, title, short_title, question_text, is_live, went_live_at, judicial_role)
    VALUES ('judicial-interpretation', 'Judicial Interpretation', 'Interpretation', 'Does the law change with the times, or does it mean what it said when it was written?', true, now(), 'judge')
    RETURNING id INTO v_id;
  INSERT INTO inform.compass_stances (topic_id, value, text) VALUES
    (v_id, 1, 'Courts should reconsider old rulings when we know more or society has changed. Keeping bad precedent alive is its own injustice.'),
    (v_id, 2, 'Laws were written for a purpose. When the exact words don''t fit a new situation, look at what the law was trying to accomplish.'),
    (v_id, 3, 'Follow the text closely, but use some common sense about what lawmakers were trying to do.'),
    (v_id, 4, 'The law means what it says. Use original intent to fill gaps, but don''t stretch the meaning.'),
    (v_id, 5, 'A judge''s job is to apply the law as written — not rewrite it. If society has changed, pass a new law. That''s what elections are for.');
  INSERT INTO inform.compass_topic_roles (topic_id, role_scope, is_required)
    VALUES (v_id, 'judicial', true);
END $$;

-- ============================================================
-- Topic 6: Bail and Pretrial Decisions
-- Judge-specific — judicial_role = 'judge'
-- ============================================================
DO $$
DECLARE v_id UUID;
BEGIN
  IF EXISTS (SELECT 1 FROM inform.compass_topics WHERE topic_key = 'judicial-bail-pretrial' AND is_live = true) THEN RETURN; END IF;
  INSERT INTO inform.compass_topics (topic_key, title, short_title, question_text, is_live, went_live_at, judicial_role)
    VALUES ('judicial-bail-pretrial', 'Bail and Pretrial Decisions', 'Bail & Pretrial', 'Should a judge trust what prosecutors say, or watch them closely?', true, now(), 'judge')
    RETURNING id INTO v_id;
  INSERT INTO inform.compass_stances (topic_id, value, text) VALUES
    (v_id, 1, 'Watch closely. Prosecutors have enormous power and real incentives to win. A judge''s job is to make sure that power is used fairly.'),
    (v_id, 2, 'Be skeptical. Hold prosecution to strict standards — especially on evidence handling and plea deals.'),
    (v_id, 3, 'Treat both sides equally and let the process work.'),
    (v_id, 4, 'Give prosecutors reasonable deference. They''re trained professionals representing the public.'),
    (v_id, 5, 'Trust prosecutors. They represent the community and have already screened the case — judges shouldn''t second-guess that judgment.');
  INSERT INTO inform.compass_topic_roles (topic_id, role_scope, is_required)
    VALUES (v_id, 'judicial', true);
END $$;

-- ============================================================
-- Topic 7: Prosecution Priorities
-- City Attorney/DA-specific — judicial_role = 'city_attorney_da'
-- ============================================================
DO $$
DECLARE v_id UUID;
BEGIN
  IF EXISTS (SELECT 1 FROM inform.compass_topics WHERE topic_key = 'judicial-prosecution-priorities' AND is_live = true) THEN RETURN; END IF;
  INSERT INTO inform.compass_topics (topic_key, title, short_title, question_text, is_live, went_live_at, judicial_role)
    VALUES ('judicial-prosecution-priorities', 'Prosecution Priorities', 'Prosecution', 'Does the office try to put people away, or find better solutions?', true, now(), 'city_attorney_da')
    RETURNING id INTO v_id;
  INSERT INTO inform.compass_stances (topic_id, value, text) VALUES
    (v_id, 1, 'Prosecution should be a last resort. Connecting people to treatment, housing, or job programs does more good than a criminal record.'),
    (v_id, 2, 'Use diversion when it''s available and makes sense. Reserve prosecution for when community safety actually requires it.'),
    (v_id, 3, 'Strong cases get prosecuted. Diversion is used when there''s a clear benefit — it''s a judgment call every time.'),
    (v_id, 4, 'Prosecute all solid cases. Declination is the exception and needs a strong reason.'),
    (v_id, 5, 'The office enforces the law — not social policy. If a case is prosecutable, prosecute it. Courts figure out the rest.');
  INSERT INTO inform.compass_topic_roles (topic_id, role_scope, is_required)
    VALUES (v_id, 'judicial', true);
END $$;

-- ============================================================
-- Topic 8: Police Accountability
-- City Attorney/DA-specific — judicial_role = 'city_attorney_da'
-- ============================================================
DO $$
DECLARE v_id UUID;
BEGIN
  IF EXISTS (SELECT 1 FROM inform.compass_topics WHERE topic_key = 'judicial-police-accountability' AND is_live = true) THEN RETURN; END IF;
  INSERT INTO inform.compass_topics (topic_key, title, short_title, question_text, is_live, went_live_at, judicial_role)
    VALUES ('judicial-police-accountability', 'Police Accountability', 'Police Accountability', 'When city employees do wrong, does the office defend them or hold them accountable?', true, now(), 'city_attorney_da')
    RETURNING id INTO v_id;
  INSERT INTO inform.compass_stances (topic_id, value, text) VALUES
    (v_id, 1, 'Investigate independently. The office works for the public — not the officials it''s supposed to keep accountable.'),
    (v_id, 2, 'Settle valid claims quickly and pursue real accountability. Defending misconduct wastes money and public trust.'),
    (v_id, 3, 'Represent the city fairly while acknowledging when claims have merit.'),
    (v_id, 4, 'Defend city employees vigorously. That''s the job. Settlements invite more lawsuits.'),
    (v_id, 5, 'The client is the city government. Defending its employees and decisions — aggressively when needed — is the core function.');
  INSERT INTO inform.compass_topic_roles (topic_id, role_scope, is_required)
    VALUES (v_id, 'judicial', true);
END $$;

COMMIT;
