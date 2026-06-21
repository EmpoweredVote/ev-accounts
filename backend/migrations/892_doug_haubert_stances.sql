-- Migration 892: Doug Haubert (Long Beach City Prosecutor, -700052) — evidence-only compass stances
-- Phase 142 Wave 4. AUDIT-ONLY (raw SQL; NOT in schema_migrations). 5 placements (incl. 2 judicial), 100% citation. 2026-06-19.

BEGIN;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, d.value
FROM (VALUES
  ('judicial-prosecution-priorities',2),('judicial-criminal-justice',2),('jail-capacity',2),
  ('homelessness',3),('homelessness-response',3)
) AS d(topic_key, value)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = -700052
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, d.reasoning, d.sources::text[]
FROM (VALUES
  ('judicial-prosecution-priorities', $$Haubert is a national leader in court diversion who created PAD, LEAD, restorative justice and CSW programs for nonviolent/first-time offenders, while still prosecuting and enforcing the law when public safety requires (gangs, DV).$$, ARRAY['https://cityprosecutordoughaubert.com/meet-the-city-prosecutor/','https://cityprosecutordoughaubert.com/restorative-justice/','https://cyc.lbpost.com/2022-long-beach-city-prosecutor/doug-haubert/']),
  ('judicial-criminal-justice', $$His restorative justice and diversion programs emphasize repairing harm, treatment and second chances (dismissal with no conviction on completion, RISE post-conviction relief), giving offenders a fair chance to make things right rather than pure punishment.$$, ARRAY['https://cityprosecutordoughaubert.com/restorative-justice/','https://cityprosecutordoughaubert.com/rise/','https://cityprosecutordoughaubert.com/pad-and-lead-programs/']),
  ('jail-capacity', $$Created the PAD diversion program stating 'some people suffering from mental illness and substance abuse need help, not incarceration,' and supports bail reform (though not full elimination of cash bail), favoring diversion over incarceration.$$, ARRAY['https://cityprosecutordoughaubert.com/pad-and-lead-programs/','https://cyc.lbpost.com/2022-long-beach-city-prosecutor/doug-haubert/']),
  ('homelessness', $$States he makes every effort to provide recovery/shelter options (PAD residential treatment) but 'will continue to enforce the law, within constitutional limits' including in encampments — services-first with enforcement available.$$, ARRAY['https://cyc.lbpost.com/2022-long-beach-city-prosecutor/doug-haubert/','https://cityprosecutordoughaubert.com/pad-and-lead-programs/']),
  ('homelessness-response', $$His primary city homelessness strategy pairs diversion to residential treatment/recovery (PAD, LEAD housing for 300+) with continued enforcement of the law within constitutional limits.$$, ARRAY['https://cityprosecutordoughaubert.com/pad-and-lead-programs/','https://cityprosecutordoughaubert.com/law-enforcement-assisted-diversion/','https://cyc.lbpost.com/2022-long-beach-city-prosecutor/doug-haubert/'])
) AS d(topic_key, reasoning, sources)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = -700052
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
