-- Phase 120 import verification -- SELECT only, no writes
SELECT
  p.full_name,
  p.slug,
  p.bio_text IS NOT NULL                                AS has_bio,
  length(p.bio_text)                                    AS bio_length,
  pi.url IS NOT NULL                                    AS has_cdn_photo,
  pi.url                                                AS cdn_url,
  pi.url LIKE 'https://kxsdzaojfaibhuzmclfq.supabase.co%' AS cdn_url_valid,
  r.position_name                                       AS race
FROM essentials.race_candidates rc
JOIN essentials.races r ON r.id = rc.race_id
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.politicians p ON p.id = rc.politician_id
LEFT JOIN essentials.politician_images pi
  ON pi.politician_id = p.id AND pi.type = 'default'
WHERE e.election_date = '2026-05-05'
  AND e.state = 'IN'
  AND rc.politician_id IS NOT NULL
  AND rc.candidate_status = 'active'
  AND r.id IN (
    SELECT race_id FROM essentials.race_candidates
    WHERE candidate_status = 'active'
    GROUP BY race_id HAVING COUNT(*) > 1
  )
ORDER BY r.position_name, p.last_name;
