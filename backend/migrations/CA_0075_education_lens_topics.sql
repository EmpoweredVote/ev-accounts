-- CA_0075_education_lens_topics.sql
-- Author: Chris Andrews (CA_ namespace, Andrews' slot)
-- NUMBERING: origin/master carries slots 0070..0074 (the 0072 and 0073 slots are the
--   economic-development and homelessness migrations). CA_0075 + CA_0076 are the next free
--   slots for this education-lens pair. Applied to prod 2026-08-31 via psql.
--
-- =============================================================================
-- CA_0075: Education (school board) lens — 8 new compass topics, STAGED + UNPINNED
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- WHAT THIS ADDS
--   Eight voter-facing compass topics for the Education / school-board lens, each on a
--   single monotonic 1..5 axis (value 1 = progressive/autonomy pole, value 5 =
--   conservative/control pole, matching the corpus convention). All are created STAGED
--   (is_live=false) and UNPINNED, so they show on NO voter surface until a season pins
--   them. topic_keys are frozen under the `education-` namespace (essentials.quotes joins
--   on topic_key).
--
--   Topics (final set, after candidate-evidence validation — 47 candidates / 26 states):
--     education-school-budget          School Budget            (NEW; absorbs teacher-pay)
--     education-curriculum             Curriculum Content       (NEW)
--     education-equity-programs        School Equity Programs
--     education-gender-identity        Student Gender Identity
--     education-library-books          School Library Books
--     education-school-police          Police in Schools
--     education-charter-authorization  Charter Schools
--     education-ai                     AI in Schools
--   Dropped from the original 9 drafts: education-discipline (bundles into other votes),
--   education-teacher-pay (valence — absorbed by School Budget), education-school-closures.
--
-- WHY IT IS BUILT THIS WAY (two deliberate points)
--
--   1. topic_key repointing. inform.admin_create_topic_with_revision derives topic_key as
--      lower(replace(short_title,' ','-')) — e.g. 'School Budget' -> 'school-budget'. We
--      want the `education-` namespace, so after each create we UPDATE the key to
--      'education-*'. No quotes exist for these yet, so re-freezing the key is safe. (The
--      derived keys and all 8 'education-*' targets were verified collision-free against the
--      48 live topics on 2026-08-31.)
--
--   2. NO role_scope rows. These topics are scoped to school offices ENTIRELY through the
--      education LENS (CA_0076: auto_district_types = {SCHOOL, STATE_BOARD_EDUCATION} plus
--      the lens's compass_lens_topics list), NOT through inform.compass_topic_roles.
--      compass_topic_roles.role_scope is constrained by chk_role_scope_tier to
--      federal|state|local|judicial ONLY — there is no 'school_board' tier, and
--      compassService reads only those four. (An earlier draft of this migration tried to
--      insert role_scope='school_board' and correctly failed the CHECK; that was removed.)
--      p_role_scopes is therefore NULL and the topics carry zero role rows, which is valid:
--      the season-gated promoted view + the lens's topic list govern display, not role tiers.
--
-- HOW IT IS CREATED
--   Through the ADR 0004 revision model, via inform.admin_create_topic_with_revision
--   (CA_0026). The RPC writes all five layers atomically — identity row, legacy 1..5 ladder
--   (5:5 parity), a founding v1 revision (revision=1, version=1, change_class='substantive',
--   status='published', is_current=true, rung_map=NULL), and the five stance revisions.
--
-- STAGED, NOT LIVE. is_live=false and no season pins any of these, so they show on NO voter
--   surface. Each goes live only when a DRAFT season pins it (inform.admin_season_add_topic)
--   and that season OPENS.
--
-- IDEMPOTENT: each create runs only when its 'education-*' key is absent. Post-verify gate
--   asserts the full shape either way. To revert: delete the 8 topic rows (revisions/stances
--   cascade). No existing object is altered.
-- =============================================================================

BEGIN;

-- ── 1. Create the 8 topics, repoint keys to education-* (no role rows: scoped via the lens) ────────
DO $$
DECLARE
  v_actor   uuid := '854fbc06-40fc-458d-b523-20ef8e5ad1b2';  -- Chris Andrews
  v_spec    jsonb;
  v_key     text;
  v_derived text;
BEGIN
  FOR v_spec IN
    SELECT value FROM jsonb_array_elements($json$
    [
      {
        "key": "education-school-budget",
        "title": "School Budget and Spending Priorities",
        "short_title": "School Budget",
        "question": "How should schools set spending levels and decide whether to raise more revenue?",
        "stances": [
          {"value":1,"text":"Raise taxes to significantly increase school funding"},
          {"value":2,"text":"Increase funding modestly to keep pace with costs, without raising taxes"},
          {"value":3,"text":"Hold funding flat at current levels"},
          {"value":4,"text":"Cut administrative overhead to lower costs while protecting classroom funding"},
          {"value":5,"text":"Cut school funding significantly to reduce the taxes residents pay"}
        ]
      },
      {
        "key": "education-curriculum",
        "title": "Curriculum and Contested Topics",
        "short_title": "Curriculum Content",
        "question": "How should schools handle contested topics like race, gender, and history in what they teach?",
        "stances": [
          {"value":1,"text":"Require lessons that center race, gender, and social justice as themes across the curriculum"},
          {"value":2,"text":"Teach an honest account of racism, injustice, and diverse identities as part of the core curriculum"},
          {"value":3,"text":"Present contested social and historical topics as open questions, giving competing viewpoints equal weight"},
          {"value":4,"text":"Keep the curriculum focused on core academics and leave contested social topics to families"},
          {"value":5,"text":"Prohibit lessons on race, gender, or sexuality that the community considers divisive or age-inappropriate"}
        ]
      },
      {
        "key": "education-equity-programs",
        "title": "Equity and Inclusion Programs in Schools",
        "short_title": "School Equity Programs",
        "question": "How should schools address gaps in achievement and opportunity between groups of students?",
        "stances": [
          {"value":1,"text":"Fund dedicated equity offices and staff to close gaps between student groups"},
          {"value":2,"text":"Require equity training for staff and set measurable goals to close gaps between groups"},
          {"value":3,"text":"Measure results for each student group and steer extra support to those falling behind"},
          {"value":4,"text":"Offer the same supports to every struggling student, without grouping them by race or identity"},
          {"value":5,"text":"Eliminate equity programs, training, and staff from the district"}
        ]
      },
      {
        "key": "education-gender-identity",
        "title": "Parental Notification and Transgender Students",
        "short_title": "Student Gender Identity",
        "question": "What should schools do when a student uses a different name or gender identity at school than at home?",
        "stances": [
          {"value":1,"text":"Use the student's chosen name and pronouns, and keep their gender identity from parents unless the student agrees to share it"},
          {"value":2,"text":"Use the student's chosen name and pronouns, and tell parents only if they directly ask"},
          {"value":3,"text":"Tell parents when a student changes their name or gender at school, unless staff believe it would put the student in danger"},
          {"value":4,"text":"Require staff to notify parents whenever a student asks to be treated as a different gender at school"},
          {"value":5,"text":"Require written parental permission before staff use a student's chosen name or pronouns"}
        ]
      },
      {
        "key": "education-library-books",
        "title": "School Library Books and Instructional Materials",
        "short_title": "School Library Books",
        "question": "How should schools handle challenges to books in libraries and classrooms?",
        "stances": [
          {"value":1,"text":"Keep every book available and let professional librarians and educators curate the collection"},
          {"value":2,"text":"Keep challenged books available to all, while letting parents limit what their own child can borrow"},
          {"value":3,"text":"Remove a challenged book only if a review committee of educators and parents finds it unsuitable"},
          {"value":4,"text":"Pull any book a parent challenges until it has been reviewed"},
          {"value":5,"text":"Remove any book a parent or community member reports as inappropriate, for all students"}
        ]
      },
      {
        "key": "education-school-police",
        "title": "Police in Schools",
        "short_title": "Police in Schools",
        "question": "What role should police officers play in schools?",
        "stances": [
          {"value":1,"text":"Remove police officers from schools and rely on counselors and mental health staff"},
          {"value":2,"text":"Keep officers out of schools and call them only when a serious crime occurs"},
          {"value":3,"text":"Bring in a shared or part-time officer with a limited, clearly defined role"},
          {"value":4,"text":"Place a dedicated officer in every school for safety, but bar them from routine discipline"},
          {"value":5,"text":"Place an officer in every school with authority to handle discipline and make arrests on campus"}
        ]
      },
      {
        "key": "education-charter-authorization",
        "title": "Charter Schools",
        "short_title": "Charter Schools",
        "question": "How should the board handle charter schools that want to open in the district?",
        "stances": [
          {"value":1,"text":"Stop authorizing new charter schools and move to close existing ones"},
          {"value":2,"text":"Approve new charters rarely, only when a school is clearly failing students"},
          {"value":3,"text":"Judge each charter application on its own merits"},
          {"value":4,"text":"Welcome charters and approve strong applications to expand family options"},
          {"value":5,"text":"Convert failing district schools into charters run by independent operators"}
        ]
      },
      {
        "key": "education-ai",
        "title": "Artificial Intelligence in Schools",
        "short_title": "AI in Schools",
        "question": "What role should artificial intelligence play in classrooms and student work?",
        "stances": [
          {"value":1,"text":"Prohibit artificial intelligence tools in student work and classroom instruction"},
          {"value":2,"text":"Restrict artificial intelligence to teacher planning and administrative use, keeping it out of student work"},
          {"value":3,"text":"Permit students to use artificial intelligence on designated assignments, with disclosure required"},
          {"value":4,"text":"Encourage broad classroom use of artificial intelligence with light guidelines and teacher discretion"},
          {"value":5,"text":"Let teachers and students use artificial intelligence freely, without restrictions"}
        ]
      }
    ]
    $json$::jsonb)
  LOOP
    v_key     := v_spec->>'key';
    v_derived := lower(replace(v_spec->>'short_title', ' ', '-'));

    IF EXISTS (SELECT 1 FROM inform.compass_topics WHERE topic_key = v_key) THEN
      RAISE NOTICE 'CA_0075: % already present — create skipped', v_key;
      CONTINUE;
    END IF;

    -- create via the revision-model RPC; NULL role scopes (education is lens-scoped, CA_0076)
    PERFORM inform.admin_create_topic_with_revision(
      v_spec->>'title',
      v_spec->>'question',
      v_spec->>'short_title',
      false,                 -- staged
      v_spec->'stances',
      v_actor,
      NULL                   -- no role rows: chk_role_scope_tier has no 'school_board'; lens scopes these
    );

    -- repoint the derived key into the education- namespace
    UPDATE inform.compass_topics SET topic_key = v_key WHERE topic_key = v_derived;

    RAISE NOTICE 'CA_0075: created % (staged, lens-scoped)', v_key;
  END LOOP;
END $$;

-- ── 2. Post-verify gate. Any wrong shape RAISEs and aborts the whole transaction. ─────────────────
DO $$
DECLARE
  v_key    text;
  v_topic  uuid;
  v_n      int;
  v_keys   text[] := ARRAY[
    'education-school-budget','education-curriculum','education-equity-programs',
    'education-gender-identity','education-library-books','education-school-police',
    'education-charter-authorization','education-ai'
  ];
BEGIN
  FOREACH v_key IN ARRAY v_keys
  LOOP
    SELECT id INTO v_topic FROM inform.compass_topics WHERE topic_key = v_key;
    IF v_topic IS NULL THEN
      RAISE EXCEPTION 'CA_0075: topic % is missing after create', v_key;
    END IF;

    -- staged, not live
    IF (SELECT is_live FROM inform.compass_topics WHERE id = v_topic) THEN
      RAISE EXCEPTION 'CA_0075: % is_live=true (must be staged)', v_key;
    END IF;

    -- exactly one published/current v1 substantive revision, rung_map NULL
    SELECT count(*) INTO v_n FROM inform.compass_topic_revisions
     WHERE topic_id = v_topic AND is_current AND status = 'published'
       AND revision = 1 AND version = 1 AND change_class = 'substantive' AND rung_map IS NULL;
    IF v_n <> 1 THEN
      RAISE EXCEPTION 'CA_0075: % expected 1 published/current v1 substantive revision, got %', v_key, v_n;
    END IF;

    -- five distinct stance-revision values on the current revision
    SELECT count(DISTINCT sr.value) INTO v_n
      FROM inform.compass_stance_revisions sr
      JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id
     WHERE r.topic_id = v_topic AND r.is_current;
    IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0075: % expected 5 stance revisions, got %', v_key, v_n; END IF;

    -- five legacy stances (corpus 5:5 invariant)
    SELECT count(*) INTO v_n FROM inform.compass_stances WHERE topic_id = v_topic;
    IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0075: % expected 5 legacy stances, got %', v_key, v_n; END IF;

    -- zero role rows (education is lens-scoped; no school_board tier exists)
    SELECT count(*) INTO v_n FROM inform.compass_topic_roles WHERE topic_id = v_topic;
    IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0075: % expected 0 role rows, got %', v_key, v_n; END IF;

    -- must NOT be live: no season pins it, so the season-gated promoted view must not list it
    IF EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE id = v_topic) THEN
      RAISE EXCEPTION 'CA_0075: % leaked into an open season before being pinned', v_key;
    END IF;
  END LOOP;

  RAISE NOTICE 'CA_0075 OK — 8 education topics staged (each: 1 published/current v1, 5 rungs, 5 legacy, 0 role rows, not promoted). Lens wiring in CA_0076.';
END $$;

COMMIT;
