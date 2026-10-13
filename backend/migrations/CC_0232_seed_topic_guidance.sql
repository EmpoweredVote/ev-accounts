-- CC_0232 — the editorial seed for `CC_0231`.`guidance`: one line per promoted topic.
--
-- Applies with `DATABASE_URL` (`ev_api`) — DML only, no DDL. `CC_0231` must be applied first.
--
--
-- ══ THE RULE EVERY LINE FOLLOWS ══════════════════════════════════════════════════════════════
--
-- Name the AXIS, never a point on it. This line sits directly above five options a person is
-- about to choose between, on a product whose whole claim is that it does not push. A gloss
-- that leans is worse than no gloss at all, because it leans at the exact moment of choosing.
--
-- So each line states the two ends and stops. "Whether the greater risk is ineligible votes
-- cast, or eligible voters turned away" is the shape: both halves are a real position somebody
-- holds, and neither is the sensible-sounding one. A line that could be read as the right
-- answer has failed, and gets rewritten rather than softened.
--
--
-- ══ 🔴 WHY THIS WRITES EVERY REVISION OF THE TOPIC, HISTORY INCLUDED ═════════════════════════
--
-- The revision a voter is served is NOT simply the season's pin: `seasonService.servedRevision
-- Lateral` resolves the pin to the HIGHEST published-or-superseded revision of the pin's
-- VERSION. So the row that ends up on screen is not knowable from `season_revision_id` alone,
-- and a seed that guessed wrong would leave the line blank with nothing to show for it.
--
-- Writing all of them is safe in a way a `public_note` backfill would NOT be. `public_note` is
-- a claim about a specific edit and belongs only to the revision that made it; `guidance` is a
-- claim about what the QUESTION asks, which is the same sentence whichever revision of that
-- question you happen to be reading. Nothing that existed is overwritten either way — the
-- column was created empty one migration ago.

BEGIN;

WITH g(topic_key, guidance) AS (VALUES
  ('2020-election',                    'Whether the certified result settled the question, or whether real doubts about it remain.'),
  ('abortion',                         'Where the decision sits: with the person, with doctors working inside limits, or with the state.'),
  ('education-ai',                     'Whether AI is a tool students should learn to use, or something coursework should keep out.'),
  ('ai-regulation',                    'Whether the risk worth guarding against is harm from AI, or the cost of slowing it down.'),
  ('border-security',                  'What should happen at the moment of crossing, and how much of the answer is enforcement.'),
  ('campaign-finance',                 'Whether limiting political money protects elections, or restricts political speech.'),
  ('cannabis-policy',                  'How far legalization should go, and what the state keeps hold of if it does.'),
  ('education-charter-authorization',  'Whether new charters add options for families, or draw from what district schools already have.'),
  ('childcare',                        'Who carries the cost of childcare, and whether the shortage is a price problem or a supply one.'),
  ('city-sanitation',                  'How much a community should spend on visible cleanliness, and whose job it is to keep it.'),
  ('civil-rights',                     'Whether government should act on unequal outcomes, or apply the same rules and stop there.'),
  ('climate-change',                   'How fast to push clean energy, and how much public money should do the pushing.'),
  ('judicial-access-to-justice',       'Whether the courts should be easier to reach, or whether limits are what keep them working.'),
  ('judicial-criminal-justice',        'Whether the response to crime is punishment, or changing what led to it.'),
  ('education-curriculum',             'Who decides what schools teach on contested subjects: educators, parents, or the state.'),
  ('data-centers',                     'Whether data centers are investment worth courting, or a load on power and water to limit.'),
  ('defense-spending',                 'Whether the military budget is sized to real threats, or crowding out everything else.'),
  ('deportation',                      'Who should be removed, and whether enforcement sorts by conduct or applies across the board.'),
  ('economic-development',             'Whether public incentives buy jobs worth the cost, or subsidize what would have happened anyway.'),
  ('local-environment',                'What gives way when building and preservation collide.'),
  ('fossil-fuels',                     'Whether fossil fuels are a bridge worth keeping for now, or the thing to move off fastest.'),
  ('judicial-government-deference',    'How much benefit of the doubt courts owe elected officials and the agencies they run.'),
  ('growth-and-development',           'Whether growth should be welcomed, steered, or slowed.'),
  ('gun-policy',                       'Where the balance falls between access to firearms and restrictions meant to reduce harm.'),
  ('healthcare',                       'How much of healthcare government should guarantee, and how much the market should set.'),
  ('homelessness',                     'Whether people sleeping in public are met with services, with enforcement, or with both.'),
  ('homelessness-response',            'How much a community should spend on housing and services, and what it expects back.'),
  ('housing',                          'Whether affordability comes from building more, from protecting tenants, or from the market alone.'),
  ('judicial-interpretation',          'Whether law means what it meant when written, or shifts with the present.'),
  ('israel-military-aid',              'Whether aid should continue as it is, carry conditions, or end.'),
  ('jail-capacity',                    'Whether crowding calls for more capacity, or for sending fewer people in.'),
  ('judicial-transparency',            'How much of what courts do should be open, weighed against privacy and the case itself.'),
  ('local-immigration',                'How closely local police should work with federal immigration enforcement.'),
  ('medicare/aid',                     'Whether these programs should be expanded, held steady, or restructured to control their cost.'),
  ('military-intervention',            'When force abroad is warranted, and what has to be true before it is.'),
  ('minimum-wage',                     'Whether raising the floor lifts workers, or prices some of them out of a job.'),
  ('misinformation',                   'Who should act on false content online: the platforms, government, or no one.'),
  ('judicial-police-accountability',   'Whether the office''s first duty is to defend its own employees or to hold them to account.'),
  ('education-school-police',          'Whether officers in schools make students safer, or change what school is.'),
  ('judicial-prosecution-priorities',  'Whether the office measures itself in convictions won, or in outcomes that hold.'),
  ('judicial-bail-pretrial',           'How much a judge should take the prosecution''s word for it.'),
  ('public-safety-approach',           'What a community funds as public safety, and who answers the call.'),
  ('ranked-choice-voting',             'Whether changing how votes are counted improves representation, or complicates it.'),
  ('redistricting',                    'Who draws the lines, and what they are allowed to take into account.'),
  ('religious-freedom',                'What happens when a religious conviction and an anti-discrimination rule point opposite ways.'),
  ('rent-regulation',                  'Whether capping rents protects tenants, or shrinks what there is to rent.'),
  ('residential-zoning',               'Whether density is the answer to housing cost, or neighborhood character is worth holding on to.'),
  ('same-sex-marriage',                'What legal recognition these marriages should carry, and how settled that recognition is.'),
  ('education-school-budget',          'Whether schools should ask taxpayers for more, or work within what they already have.'),
  ('education-equity-programs',        'Whether closing gaps calls for targeted programs, or the same treatment for every student.'),
  ('education-library-books',          'Who decides what belongs on the shelf when a book is challenged.'),
  ('school-vouchers',                  'Whether public money should follow the student, or stay with public schools.'),
  ('social-security',                  'Whether the shortfall is closed by raising revenue, trimming benefits, or changing the structure.'),
  ('education-gender-identity',        'What a school owes the student, and what it owes the parents, when the two point different ways.'),
  ('tariffs',                          'Whether tariffs protect domestic industry, or cost more than they protect.'),
  ('taxes',                            'Whether to collect and spend more or less, and who carries the difference.'),
  ('trans-athletes',                   'Where eligibility should be drawn, and on what basis.'),
  ('transportation-priorities',        'Whether investment should go to roads, to transit, or to both at once.'),
  ('ukraine-support',                  'Whether support should continue, grow, narrow, or end.'),
  ('voting-rights',                    'Whether the greater risk is ineligible votes cast, or eligible voters turned away.')
)
UPDATE inform.compass_topic_revisions r
   SET guidance = g.guidance
  FROM g
  JOIN inform.compass_topics t ON t.topic_key = g.topic_key
 WHERE r.topic_id = t.id
   AND r.guidance IS DISTINCT FROM g.guidance;

-- Every promoted topic must have come out of that with a line. A topic_key typo would otherwise
-- land as a silently blank gloss on one question out of sixty, which is exactly the kind of
-- thing nobody notices until a season later.
DO $$
DECLARE v_missing INT;
BEGIN
  SELECT count(*) INTO v_missing
    FROM inform.compass_topics_promoted p
    JOIN inform.compass_topic_revisions r ON r.topic_id = p.id AND r.is_current
   WHERE COALESCE(btrim(r.guidance), '') = '';
  IF v_missing > 0 THEN
    RAISE EXCEPTION 'GUIDANCE_INCOMPLETE: % promoted topics still have no guidance', v_missing;
  END IF;
END $$;

COMMIT;
