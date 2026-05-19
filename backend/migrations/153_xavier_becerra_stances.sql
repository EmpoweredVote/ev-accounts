-- Migration 153: Xavier Becerra stances (17 topics)
-- Former CA AG (2017-2021), Biden HHS Secretary (2021-2025), 2026 CA Governor candidate
-- Politician ID: 0f74219c-7d10-4d29-85fe-0f1d834df8a7
-- Research date: 2026-05-16

DO $$
DECLARE
  v_pid UUID := '0f74219c-7d10-4d29-85fe-0f1d834df8a7';
BEGIN

  -- politician_answers
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
    (v_pid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1),  -- abortion
    (v_pid, '666bf03d-81fc-4138-ab15-69ae734c9023', 4),  -- ai-regulation
    (v_pid, '92730f69-ae57-401c-8ad1-2d07834a895d', 2),  -- campaign-finance
    (v_pid, '0bc588c6-39e1-4084-b5de-cac909b8b762', 2),  -- civil-rights
    (v_pid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2),  -- climate-change
    (v_pid, '4559b513-0fd8-4ed1-babd-f3b554162f40', 2),  -- data-centers
    (v_pid, '44905f3b-e105-4f6c-afc7-5d223813dbac', 2),  -- deportation
    (v_pid, 'a22215c3-6693-4bc2-b248-01aebba14570', 2),  -- fossil-fuels
    (v_pid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2),  -- healthcare
    (v_pid, '4938766b-b45a-46e3-93bd-b8b30651271a', 2),  -- homelessness
    (v_pid, '669cac97-66a6-4087-b036-936fbe62efb3', 2),  -- housing
    (v_pid, '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2),  -- immigration
    (v_pid, '48cc9585-ec22-4f53-8d42-6839828dd36f', 2),  -- redistricting
    (v_pid, '6b9ba6d9-1001-43f5-b073-4d37130696fd', 3),  -- religious-freedom
    (v_pid, '00b95a6a-75db-4521-b523-3326bba938de', 1),  -- school-vouchers
    (v_pid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2),  -- trans-athletes
    (v_pid, '24e9212c-b011-422a-865c-093e35050901', 2)   -- ukraine-support
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

  -- politician_context
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
    (v_pid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
      'Becerra has a lifelong 100% NARAL and 100% Planned Parenthood rating. His 2026 campaign states "I know that abortion access is health care" and pledges California will "lead when it comes to protecting access to abortion." As HHS Secretary he ensured Planned Parenthood funding reached dependent clinics. He voted against the Prenatal Non-Discrimination Act (PRENDA) and argued against religious exemptions from ACA contraception coverage.',
      ARRAY['https://www.xavierbecerra2026.com/rights','https://www.ontheissues.org/Xavier_Becerra.htm']),

    (v_pid, '666bf03d-81fc-4138-ab15-69ae734c9023',
      'Becerra''s AI platform calls for mandatory safety laws, "firm guardrails around real harms," transparency in automated decision-making, and mandatory independent audits of all AI systems deployed by state agencies. He supports requiring data centers to use clean energy and mandating worker protections. His stance emphasizes active monitoring, mandatory auditing, and regulatory enforcement — aligning with closely monitor AI development and require government approval before releasing advanced AI systems.',
      ARRAY['https://www.xavierbecerra2026.com/ai']),

    (v_pid, '92730f69-ae57-401c-8ad1-2d07834a895d',
      'Becerra voted YES on banning soft money contributions and has consistently supported campaign finance disclosure and restrictions on dark money. His position per OnTheIssues: support automatic voter registration and campaign finance disclosure. He supports strict limits on corporate money in politics.',
      ARRAY['https://www.ontheissues.org/Xavier_Becerra.htm']),

    (v_pid, '0bc588c6-39e1-4084-b5de-cac909b8b762',
      'Becerra holds a 100% NAACP rating and consistently supports affirmative action and addressing systemic discrimination. As California AG he created an environmental justice bureau in 2018 and fought Trump administration rollbacks of civil rights protections. His campaign pledges to protect LGBTQ+ rights and voting rights.',
      ARRAY['https://www.ontheissues.org/Xavier_Becerra.htm','https://en.wikipedia.org/wiki/Xavier_Becerra']),

    (v_pid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
      'Becerra holds a 90% LCV lifetime rating. As California AG he created an environmental justice bureau. His 2026 campaign calls for treating clean energy as a public investment, stating "California can fight climate change, strengthen reliability, and make energy more affordable for everyone." He supported 50% clean/carbon-free electricity by 2030.',
      ARRAY['https://www.xavierbecerra2026.com/','https://www.ontheissues.org/Xavier_Becerra.htm']),

    (v_pid, '4559b513-0fd8-4ed1-babd-f3b554162f40',
      'Becerra''s AI policy platform explicitly states that data centers must "use clean energy and cover their own energy costs" and that ratepayers must be protected from bearing infrastructure expansion costs. This directly aligns with requiring data centers to fund their own dedicated power generation and barring utilities from passing data center infrastructure costs to residential customers.',
      ARRAY['https://www.xavierbecerra2026.com/ai']),

    (v_pid, '44905f3b-e105-4f6c-afc7-5d223813dbac',
      'As California AG Becerra led 21 AGs defending DACA against Trump and opposed ICE overreach and family separations. His 2026 campaign frames his mission as "stopping ICE overreach" and "protecting Dreamers from deportation." His congressional record shows a 0% FAIR rating. His position is to deport only those committing serious crimes while providing legal status to DACA-eligible and long-term residents.',
      ARRAY['https://www.xavierbecerra2026.com/','https://www.ontheissues.org/Xavier_Becerra.htm','https://en.wikipedia.org/wiki/Xavier_Becerra']),

    (v_pid, 'a22215c3-6693-4bc2-b248-01aebba14570',
      'As California AG Becerra consistently challenged Trump administration fossil fuel rollbacks and obtained a preliminary injunction blocking Trump''s water diversion operations. His 2026 climate platform calls for treating clean energy as a public investment and transitions away from fossil fuels. His 90% LCV rating reflects a strong anti-fossil-fuel stance aligned with stopping new permits.',
      ARRAY['https://en.wikipedia.org/wiki/Xavier_Becerra','https://www.ontheissues.org/Xavier_Becerra.htm']),

    (v_pid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
      'Becerra supports moving "toward Medicare for All" as a long-term goal while advocating for a strengthened Medi-Cal and ACA as immediate steps. His 2026 campaign states he will "deliver affordable care without debt or delays" and "strengthen Medi-Cal." As HHS Secretary he negotiated Medicare drug prices achieving 38–79% discounts on 10 medications in 2023. He stops short of full single-payer as a near-term proposal.',
      ARRAY['https://www.xavierbecerra2026.com/healthcare','https://www.ontheissues.org/Xavier_Becerra.htm']),

    (v_pid, '4938766b-b45a-46e3-93bd-b8b30651271a',
      'Becerra''s 2026 campaign frames homelessness as "a moral emergency and a policy failure" and emphasizes Housing First with treatment: "permanent housing paired with behavioral health and addiction services where needed." He proposes prevention-focused rental assistance, expanded shelter capacity, and full implementation of Proposition 1 mental health reforms.',
      ARRAY['https://www.xavierbecerra2026.com/homelessness']),

    (v_pid, '669cac97-66a6-4087-b036-936fbe62efb3',
      'Becerra''s 2026 housing platform calls for a Day 1 executive order declaring a housing emergency, reforming exclusionary zoning, expanding by-right approvals near transit, supporting "missing middle" housing, funding 40,000 approved affordable units, and enforcing cities'' housing element commitments. He states: "For too long, California simply hasn''t built enough homes." He also supports renter protections and rent stabilization.',
      ARRAY['https://www.xavierbecerra2026.com/housing']),

    (v_pid, '4e2c69ce-591e-4197-9cd5-7aceff79d390',
      'Becerra has a 0% FAIR rating, voted NO on building a border fence, supported DACA, opposed the Muslim ban and family separations, and led a 21-AG coalition defending DACA in court. His 2026 campaign includes fighting ICE overreach and protecting Dreamers. He supports significantly increasing legal pathways and citizenship options.',
      ARRAY['https://www.ontheissues.org/Xavier_Becerra.htm','https://en.wikipedia.org/wiki/Xavier_Becerra','https://www.xavierbecerra2026.com/']),

    (v_pid, '48cc9585-ec22-4f53-8d42-6839828dd36f',
      'Becerra supported establishment of California''s Citizens Redistricting Commission as a congressional member and consistently backed anti-gerrymandering reforms. His overall government reform voting record — YES on banning soft money, supporting campaign finance disclosure — is consistent with support for fair redistricting via independent commissions.',
      ARRAY['https://www.ontheissues.org/Xavier_Becerra.htm']),

    (v_pid, '6b9ba6d9-1001-43f5-b073-4d37130696fd',
      'Becerra''s record shows balance: as HHS Secretary he defended the ACA contraception mandate and argued against broad religious exemptions for organizations providing public services. However he has not called for eliminating religious exemptions entirely. His position — that religious freedom should not override civil rights laws in employment and housing, but should be balanced against equal treatment — aligns with a balancing approach.',
      ARRAY['https://en.wikipedia.org/wiki/Xavier_Becerra','https://www.ontheissues.org/Xavier_Becerra.htm']),

    (v_pid, '00b95a6a-75db-4521-b523-3326bba938de',
      'Becerra holds a 100% NEA rating and explicitly stated opposition to "private and religious school voucher programs." In Congress he voted NO on vouchers for private/parochial schools. OnTheIssues records his position as: "Oppose private and religious school voucher programs."',
      ARRAY['https://www.ontheissues.org/Xavier_Becerra.htm']),

    (v_pid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
      'Becerra has a 100% HRC rating and explicitly supports transgender student and adult protections. As HHS Secretary he reinstated transgender healthcare nondiscrimination protections and defended Title IX gender identity interpretations. His position supports transgender individuals in public life without imposing extraordinary barriers.',
      ARRAY['https://www.ontheissues.org/Xavier_Becerra.htm','https://en.wikipedia.org/wiki/Xavier_Becerra']),

    (v_pid, '24e9212c-b011-422a-865c-093e35050901',
      'Becerra left Congress in 2017, before the 2022 Russia-Ukraine war, but served as a Biden cabinet secretary throughout the Ukraine conflict and the administration''s aid policy. No direct Ukraine floor votes or statements located. His consistent opposition to isolationism and alignment with Biden''s foreign policy consensus supports scoring at continue providing current levels of military and economic aid. Lower-confidence inference from administration membership.',
      ARRAY['https://en.wikipedia.org/wiki/Xavier_Becerra'])

  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

END $$;
