-- 1295_ut_sd18_mccay_primary_loss_cull.sql
-- UT headshot-sweep reconciliation (2026-07-09): incumbent Sen. Daniel McCay (R) LOST the
--   June 23, 2026 Republican primary for Utah State Senate District 18 to Doug Fiefia
--   69.5%-30.5% (Ballotpedia "Utah State Senate District 18", primary results section,
--   fetched 2026-07-09 via /wiki/api.php parse). His race_candidates row was still
--   candidate_status='active' + is_incumbent=true, surfacing him as an active 2026
--   candidate on /elections. This sets his status to 'withdrawn' (the project's existing
--   inactive value: active/filed/withdrawn — same convention as mig 1204's AZ cull).
--
--   Deliberately NOT touched:
--   - politicians row + his officeholder records: McCay remains the SITTING senator for
--     SD-18 until the term ends (Jan 2027) — officials surfaces must keep him.
--   - rc.is_incumbent stays true: factually correct (he is the incumbent of the seat);
--     the withdrawn status alone removes him from active-candidate surfaces.
--   - The 10 other UT primary losers in .planning/todos/2026-07-09-ut-primary-losers-cull.md
--     (challengers, no incumbency impact) are left for the batch cull.
--
--   General: Doug Fiefia (R) vs A. Dane Anderson (D) — both active with photos.
--
-- Idempotent: guarded by candidate_status <> 'withdrawn'; re-run is a 0-row no-op.
BEGIN;

UPDATE essentials.race_candidates rc
SET candidate_status = 'withdrawn'
FROM essentials.politicians p, essentials.races r
WHERE rc.politician_id = p.id
  AND rc.race_id = r.id
  AND p.first_name = 'Daniel' AND p.last_name = 'McCay'
  AND r.position_name = 'Utah State Senate District 18'
  AND rc.candidate_status <> 'withdrawn';

COMMIT;
