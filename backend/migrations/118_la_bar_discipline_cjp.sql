BEGIN;

-- Phase 29-02: Patrick Connolly CJP disciplinary records
-- Two public admonishments confirmed via cjp.ca.gov/decisions_by_judges/
-- Descriptions are plain-language summaries for voter comprehension

INSERT INTO essentials.judicial_disciplinary_records
  (politician_id, record_type, record_date, description, source_url)
VALUES
  ('53fd1ed7-b8f2-4c0b-a973-3592e4457472',
   'Public Admonishment',
   '2016-03-23',
   'Connolly sentenced a defendant more harshly based on his personal belief — unsupported by any trial evidence — that the defendant had lied to his own attorney. He then opened multiple contempt proceedings against the defense lawyer who had challenged his conduct in court. CJP found he abused his authority and violated the defendant''s constitutional rights.',
   'https://cjp.ca.gov/wp-content/uploads/sites/40/2016/08/Connolly_03-23-16.pdf'),
  ('53fd1ed7-b8f2-4c0b-a973-3592e4457472',
   'Public Admonishment',
   '2021-04-02',
   'Two separate incidents: After a jury acquitted a defendant, Connolly told him to his face, ''You''ve been given a gift from God because there is no question in my mind that you are guilty of this crime'' — publicly dismissing the jury''s verdict. Separately, he was sarcastic and hostile toward defense attorneys who requested to appear by phone during COVID after possible exposure.',
   'https://cjp.ca.gov/wp-content/uploads/sites/40/2021/04/Connolly_DO_Pub_Adm_4-2-2021.pdf')
ON CONFLICT (politician_id, record_type, record_date) DO NOTHING;

COMMIT;
