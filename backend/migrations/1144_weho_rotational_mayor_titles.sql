-- 1144: West Hollywood rotational leadership titles (elected by council 2026-01-12)
-- John Heilman -> Mayor (9th rotation), Danny Hang -> Vice Mayor.
-- Title-on-seat pattern (rotational mayor, no LOCAL_EXEC office) per Burbank/Norwalk/Bellflower.
-- Source: weho.org city council page + Beverly Press 2026-01 swearing-in coverage.

UPDATE essentials.offices
SET title = 'Mayor'
WHERE id = '3ad5c4ac-59ff-421e-932a-3222f498b824'  -- John Heilman ea0b6144
  AND title = 'Council Member';

UPDATE essentials.offices
SET title = 'Vice Mayor'
WHERE id = '716e5725-656a-465e-b290-dc0658370c94'  -- Danny Hang 4279801f
  AND title = 'Council Member';
