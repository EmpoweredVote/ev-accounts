ALTER TABLE essentials.politician_images
ADD COLUMN IF NOT EXISTS focal_point VARCHAR(50) DEFAULT NULL;

COMMENT ON COLUMN essentials.politician_images.focal_point IS 'CSS object-position value for image cropping, e.g. center 30%. NULL means use default.';

-- Fix Dorothy Granger headshot cropping (image shows neck/chest with default 'center 20%')
UPDATE essentials.politician_images
SET focal_point = 'center 40%'
WHERE politician_id = (
  SELECT id FROM essentials.politicians
  WHERE first_name = 'Dorothy' AND last_name = 'Granger'
  LIMIT 1
);
