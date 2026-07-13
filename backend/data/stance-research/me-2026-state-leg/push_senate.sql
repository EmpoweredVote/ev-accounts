-- ME Senate stance wave 2026-07-13 - 35 senators, orchestrator-reviewed.
-- Abortion rebuilt from MRTL 2025 scorecard (LD253 funding + LD682, per-senator votes);
-- trans-athletes normalized to chair 1 (ME status quo has no documentation gate);
-- Harrington abortion skipped (mixed 67% record). pid from _ROSTER.csv.
BEGIN;

-- Anne Carney / judicial-access-to-justice=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '0b0e2f33-d54b-486b-abe8-70c30b7c33eb', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='judicial-access-to-justice'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '0b0e2f33-d54b-486b-abe8-70c30b7c33eb', ct.id, $ctx$Carney sponsored LD 2059, signed as emergency legislation in 2026 to prevent a $13 million shortfall that threatened Maine's public-defender system, and separately applauded $22 million in emergency public-defense funding plus $5.6 million for civil legal aid in the FY2026 supplemental budget. Her stated rationale — that access to justice should not depend on ability to pay — matches the low-barriers chair on this scale.$ctx$, ARRAY['https://www.mainesenate.org/governor-signs-sen-carney-bill-to-fund-public-defense-services-protect-constitutional-rights/','https://www.mainesenate.org/sen-anne-carney-applauds-funding-for-public-defense-and-civil-legal-aid-in-supplemental-budget/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='judicial-access-to-justice'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Anne M. Carney / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '0b0e2f33-d54b-486b-abe8-70c30b7c33eb', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '0b0e2f33-d54b-486b-abe8-70c30b7c33eb', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Anne M. Carney's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Bradlee T. Farrin / abortion=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'a49f9cab-2681-4003-a4a7-398c569cbaf5', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'a49f9cab-2681-4003-a4a7-398c569cbaf5', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Bradlee T. Farrin's own recorded roll-call votes, 132nd Legislature), the senator voted FOR the MRTL-supported abortion restrictions, including LD 253 (barring the MaineCare program from covering abortion services) and LD 682 (narrowing legal abortion to a life-of-mother exception and reinstating criminal penalties), and against family-planning funding (LD 143). Narrowing legal abortion to a maternal-life-threat exception matches chair 4 (restrict abortion to cases of rape, incest, or serious threats to the mother's life).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Bradlee T. Farrin / taxes=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'a49f9cab-2681-4003-a4a7-398c569cbaf5', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'a49f9cab-2681-4003-a4a7-398c569cbaf5', ct.id, $ctx$Farrin's official campaign platform (bradfarrin.com) lists "Responsible Spending & Lower Taxes" as a standing priority alongside a pledge to make Maine more "business friendly." This is a general commitment to cutting taxes and restraining spending broadly, without carving out different treatment for wealthy earners or corporations, which best matches chair 4 (cut taxes for everyone, scale back services to match) rather than a narrower loophole-closing position (chair 3).$ctx$, ARRAY['https://bradfarrin.com']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Bradlee T. Farrin / voting-rights=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'a49f9cab-2681-4003-a4a7-398c569cbaf5', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'a49f9cab-2681-4003-a4a7-398c569cbaf5', ct.id, $ctx$Farrin's own on-record comment to The Maine Wire, given shortly before the November 2025 Question 1 voter-ID referendum, states that a standalone photo-ID requirement would have been "a slam dunk" and criticizes the ballot committee for bundling it with absentee-ballot changes rather than running voter ID alone. This directly evidences his own support for a mandatory photo-ID requirement, matching chair 4; he did not specify a position on voter-roll maintenance beyond this.$ctx$, ARRAY['https://www.themainewire.com/2025/11/botched-voter-id-for-maine-effort-tanks-on-election-day/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Bruce Bickford / abortion=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'f1b5eb73-bc60-4e7a-a6b4-2702e8c40238', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'f1b5eb73-bc60-4e7a-a6b4-2702e8c40238', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Bruce Bickford's own recorded roll-call votes, 132nd Legislature), the senator voted FOR the MRTL-supported abortion restrictions, including LD 253 (barring the MaineCare program from covering abortion services) and LD 682 (narrowing legal abortion to a life-of-mother exception and reinstating criminal penalties), and against family-planning funding (LD 143). Narrowing legal abortion to a maternal-life-threat exception matches chair 4 (restrict abortion to cases of rape, incest, or serious threats to the mother's life).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Bruce Bickford / taxes=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'f1b5eb73-bc60-4e7a-a6b4-2702e8c40238', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'f1b5eb73-bc60-4e7a-a6b4-2702e8c40238', ct.id, $ctx$Voted Nay on Roll Call #478 (Jun 12, 2025) and Yea on Roll Call #592 (Jun 16, 2025), opposing LD 1089's millionaire income-tax surcharge for education funding. His own Senate Republican biography credits him with having ushered in two of the largest income tax cuts in Maine's history during prior service on the Taxation Committee, indicating a consistent preference for broad tax-rate reduction over the current system.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-478-ld-1089.pdf','https://legislature.maine.gov/uploads/visual_edit/roll-call-592-ld-1089.pdf','https://mesenategop.com/your-senators/senator-bruce-bickford/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Bruce Bickford / trans-athletes=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'f1b5eb73-bc60-4e7a-a6b4-2702e8c40238', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'f1b5eb73-bc60-4e7a-a6b4-2702e8c40238', ct.id, $ctx$Voted Nay on Roll Call #556 (opposing killing LD 233) and Yea on Roll Call #586 (supporting reviving and passing the bill) on June 16, 2025, consistently supporting the requirement that athletes compete on teams matching sex assigned at birth.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-556-ld-233.pdf','https://legislature.maine.gov/uploads/visual_edit/roll-call-586-ld-233.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Cameron D. Reny / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ceace463-1299-4c49-b5aa-e73af2534e0a', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ceace463-1299-4c49-b5aa-e73af2534e0a', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Cameron D. Reny's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Cameron D. Reny / ai-regulation=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ceace463-1299-4c49-b5aa-e73af2534e0a', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='ai-regulation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ceace463-1299-4c49-b5aa-e73af2534e0a', ct.id, $ctx$Cosponsored LD 1301 (SP 531), "An Act to Prohibit the Use of Artificial Intelligence in the Denial of Health Insurance Claims," which requires that AI-driven medical/utilization review determinations be non-discriminatory, disclosed to enrollees, subject to accountability policies, and that any denial, delay or modification ultimately be made by a qualified clinical peer rather than the algorithm alone. This sector-specific transparency-and-accountability mandate is closest to stance 3 (require developers to disclose risk and be held responsible for harm) rather than a blanket ban or a pre-market government-approval regime.$ctx$, ARRAY['https://legislature.maine.gov/legis/bills/display_ps.asp?LD=1301&snum=132','https://legislature.maine.gov/legis/bills/getPDF.asp?paper=SP0531&item=1&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='ai-regulation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Cameron D. Reny / childcare=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ceace463-1299-4c49-b5aa-e73af2534e0a', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ceace463-1299-4c49-b5aa-e73af2534e0a', ct.id, $ctx$Cosponsored LD 437, directing the Department of Education to pilot placing child care facilities in at least 8 public school administrative units. The pilot must provide free care to families at or below the federal poverty level, sliding-scale fees (including accepting child-care vouchers) for others, and doubles as a training pipeline (an early-childhood-education course for 11th/12th graders) to grow the child-care workforce. This targeted, income-threshold approach paired with provider/workforce training support matches stance 3.$ctx$, ARRAY['https://legislature.maine.gov/legis/bills/display_ps.asp?LD=437&snum=132','https://legislature.maine.gov/legis/bills/getPDF.asp?paper=HP0291&item=1&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Cameron D. Reny / housing=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ceace463-1299-4c49-b5aa-e73af2534e0a', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ceace463-1299-4c49-b5aa-e73af2534e0a', ct.id, $ctx$Sponsored LD 554, "An Act to Encourage Resident-owned Communities and Preserve Affordable Housing Through Tax Deductions," which creates targeted tax deductions/credits to help mobile-home-park and manufactured-housing residents form cooperatives and buy their communities; the bill was signed into law July 1, 2025 (PL ch. 455). This targeted subsidy/tax-incentive approach to affordable housing, rather than direct public housing construction or broad rent regulation, matches stance 3.$ctx$, ARRAY['https://legislature.maine.gov/legis/bills/display_ps.asp?LD=554&snum=132','https://www.mainesenate.org/sen-cameron-renys-bill-to-create-tax-incentives-to-increase-the-supply-of-affordable-housing-in-maine-receives-unanimous-committee-support/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Cameron D. Reny / trans-athletes=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ceace463-1299-4c49-b5aa-e73af2534e0a', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ceace463-1299-4c49-b5aa-e73af2534e0a', ct.id, $ctx$On the Maine Senate's June 12, 2025 Roll Call #494, Reny voted YEA to accept the Judiciary Committee's "Ought Not to Pass" report on LD 1134/LD 868 ("An Act to Prohibit Males from Participating in Female Sports or Using Female Facilities"), helping kill the bill 21-14. Her vote preserved Maine's current policy allowing transgender athletes to compete consistent with their gender identity without new restrictions, matching stance 1 (no restrictions or requirements).$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-494-ld-1134.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=1134&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Chip Curry / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ff20c338-594f-4f9b-b667-08c29dc735b8', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ff20c338-594f-4f9b-b667-08c29dc735b8', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Chip Curry's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Chip Curry / jail-capacity=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ff20c338-594f-4f9b-b667-08c29dc735b8', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ff20c338-594f-4f9b-b667-08c29dc735b8', ct.id, $ctx$Curry voted YEA on Senate Roll Call #246 (May 28, 2025), accepting the majority Ought Not To Pass report that killed LD 1536, which would have reinstated minimum cash bail and expanded pretrial detention authority, rolling back Maine's 2021 bail reform. His vote favored preserving the existing bail-reform framework over expanding detention.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280098308&chamber=S&serialnumber=246','https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1536&SessionID=16','https://www.themainewire.com/2025/04/sen-haggan-wants-judges-and-commissioners-to-have-more-say-over-who-gets-bail/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Chip Curry / taxes=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ff20c338-594f-4f9b-b667-08c29dc735b8', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ff20c338-594f-4f9b-b667-08c29dc735b8', ct.id, $ctx$Curry voted YES on Senate Roll Call #593 (June 16, 2025), accepting the amended Ought To Pass report on LD 1089, a 2% surcharge on income over $1,000,000 dedicated to the state's 55% K-12 education funding obligation. His vote reflects support for a moderate, targeted tax increase on high earners to fund an existing public service commitment.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280097493&chamber=S&serialnumber=593','https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1089&SessionID=16']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Craig V. Hickman / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '838be693-3b76-413d-a37a-f1da2f3f1286', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '838be693-3b76-413d-a37a-f1da2f3f1286', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Craig V. Hickman's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Craig V. Hickman / trans-athletes=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '838be693-3b76-413d-a37a-f1da2f3f1286', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '838be693-3b76-413d-a37a-f1da2f3f1286', ct.id, $ctx$On the Maine Senate's June 12, 2025 Roll Call #494, Hickman voted YEA to accept the Judiciary Committee's "Ought Not to Pass" report on LD 1134/LD 868, which would have required transgender athletes to compete only on teams matching their biological sex. His vote killed the bill 21-14 and preserved the existing policy allowing competition consistent with gender identity, matching stance 1.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-494-ld-1134.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=1134&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- David Haggan / abortion=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'f6fef6fa-30e2-4dac-9bf6-9b0250b24bd3', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'f6fef6fa-30e2-4dac-9bf6-9b0250b24bd3', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (David Haggan's own recorded roll-call votes, 132nd Legislature), the senator voted FOR the MRTL-supported abortion restrictions, including LD 253 (barring the MaineCare program from covering abortion services) and LD 682 (narrowing legal abortion to a life-of-mother exception and reinstating criminal penalties), and against family-planning funding (LD 143). Narrowing legal abortion to a maternal-life-threat exception matches chair 4 (restrict abortion to cases of rape, incest, or serious threats to the mother's life).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- David Haggan / jail-capacity=5
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'f6fef6fa-30e2-4dac-9bf6-9b0250b24bd3', ct.id, 5.0 FROM inform.compass_topics ct WHERE ct.topic_key='jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'f6fef6fa-30e2-4dac-9bf6-9b0250b24bd3', ct.id, $ctx$Haggan was primary sponsor of LD 1536, "An Act to Amend the Laws Governing Bail," which would have reinstated a $60 minimum cash bail requirement and expanded judges'/bail commissioners' authority to hold people pretrial, rolling back Maine's 2021 bail reform; he testified the bill was needed because current bail laws are not working amid rising crime by people released on bail. He voted NAY on Senate Roll Call #246 (May 28, 2025) against killing his own bill, which nonetheless failed 20-14 in the Senate. This reflects prioritizing pretrial detention over release alternatives.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1536&SessionID=16','https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280098308&chamber=S&serialnumber=246','https://www.themainewire.com/2025/04/sen-haggan-wants-judges-and-commissioners-to-have-more-say-over-who-gets-bail/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- David Haggan / taxes=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'f6fef6fa-30e2-4dac-9bf6-9b0250b24bd3', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'f6fef6fa-30e2-4dac-9bf6-9b0250b24bd3', ct.id, $ctx$Haggan voted NO on Senate Roll Call #593 (June 16, 2025), opposing the amended LD 1089, a 2% surcharge on income over $1,000,000 dedicated to K-12 education funding. Opposing this targeted tax increase on high earners indicates a preference for keeping the current tax structure as-is over adding new taxes on the wealthy; no additional evidence of broader tax-cut proposals from him was found.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280097493&chamber=S&serialnumber=593','https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1089&SessionID=16']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Denise Tepler / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '71522fd3-94ba-442a-b52e-50b5f77adfcd', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '71522fd3-94ba-442a-b52e-50b5f77adfcd', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Denise Tepler's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Denise Tepler / taxes=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '71522fd3-94ba-442a-b52e-50b5f77adfcd', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '71522fd3-94ba-442a-b52e-50b5f77adfcd', ct.id, $ctx$Voted Yea on Roll Call #478 and Nay on Roll Call #592 (Jun 2025), both times supporting LD 1089's 4% surcharge on incomes over $1,000,000 to fund public education — a moderate, targeted increase on high earners.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-478-ld-1089.pdf','https://legislature.maine.gov/uploads/visual_edit/roll-call-592-ld-1089.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Denise Tepler / trans-athletes=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '71522fd3-94ba-442a-b52e-50b5f77adfcd', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '71522fd3-94ba-442a-b52e-50b5f77adfcd', ct.id, $ctx$Voted Yea on Roll Call #556 and Nay on Roll Call #586 (Jun 16, 2025), consistently opposing LD 233's requirement that transgender athletes compete on teams matching sex assigned at birth.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-556-ld-233.pdf','https://legislature.maine.gov/uploads/visual_edit/roll-call-586-ld-233.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Donna Bailey / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '514dc276-d1a3-4ca2-9ee0-743684cd4bc9', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '514dc276-d1a3-4ca2-9ee0-743684cd4bc9', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Donna Bailey's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Donna Bailey / healthcare=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '514dc276-d1a3-4ca2-9ee0-743684cd4bc9', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '514dc276-d1a3-4ca2-9ee0-743684cd4bc9', ct.id, $ctx$As Senate chair of the Health Coverage, Insurance and Financial Services Committee, she was primary sponsor of LD 378 'An Act to Strengthen the Health Care System in Maine' (signed into law April 2026) and LD 1018 protecting rural healthcare access from drug-discount-program discrimination, working to regulate and expand coverage within the existing mixed public/private insurance system rather than proposing single-payer or means-tested-only assistance.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=378','https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1018','https://www.mainesenate.org/senator/senator/donna-bailey/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Donna Bailey / taxes=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '514dc276-d1a3-4ca2-9ee0-743684cd4bc9', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '514dc276-d1a3-4ca2-9ee0-743684cd4bc9', ct.id, $ctx$Voted Yea on Senate Roll Call #593 (6/16/2025) to pass LD 1089 as amended, which creates a new state income tax on earnings over $1,000,000 to permanently fund 55% of the state's share of public education costs.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1089','https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280097493&chamber=S&serialnumber=593']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Donna Bailey / trans-athletes=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '514dc276-d1a3-4ca2-9ee0-743684cd4bc9', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '514dc276-d1a3-4ca2-9ee0-743684cd4bc9', ct.id, $ctx$Voted twice in 2025 against restricting transgender athletes to their sex assigned at birth: on LD 1134 (Senate Roll Call #494, 6/12/2025) she voted Yea to accept the 'Ought Not to Pass' report killing the ban, and on LD 233 (Senate Roll Call #586, 6/17/2025) she voted Nay against receding and concurring with the House-passed ban.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1134','https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=233','https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280097524&chamber=S&serialnumber=494']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Henry L. Ingwersen / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'd03913a3-a9d8-44f8-a8af-e07786e1ef2e', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'd03913a3-a9d8-44f8-a8af-e07786e1ef2e', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Henry L. Ingwersen's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Henry L. Ingwersen / taxes=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'd03913a3-a9d8-44f8-a8af-e07786e1ef2e', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'd03913a3-a9d8-44f8-a8af-e07786e1ef2e', ct.id, $ctx$Voted Yea on Senate Roll Call #593 (6/16/2025) to pass LD 1089 as amended, creating a new state income tax on earnings over $1,000,000 to permanently fund 55% of the state's share of public education costs.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1089','https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280097493&chamber=S&serialnumber=593']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Henry L. Ingwersen / trans-athletes=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'd03913a3-a9d8-44f8-a8af-e07786e1ef2e', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'd03913a3-a9d8-44f8-a8af-e07786e1ef2e', ct.id, $ctx$Voted twice in 2025 against restricting transgender athletes to their sex assigned at birth: on LD 1134 (Senate Roll Call #494, 6/12/2025) he voted Yea to accept the 'Ought Not to Pass' report killing the ban, and on LD 233 (Senate Roll Call #586, 6/17/2025) he voted Nay against receding and concurring with the House-passed ban.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1134','https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=233','https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280097524&chamber=S&serialnumber=494']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- James D. Libby / abortion=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'fc62e5af-90bc-42ad-90a5-6d0a586331e8', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'fc62e5af-90bc-42ad-90a5-6d0a586331e8', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (James D. Libby's own recorded roll-call votes, 132nd Legislature), the senator voted FOR the MRTL-supported abortion restrictions, including LD 253 (barring the MaineCare program from covering abortion services) and LD 682 (narrowing legal abortion to a life-of-mother exception and reinstating criminal penalties), and against family-planning funding (LD 143). Narrowing legal abortion to a maternal-life-threat exception matches chair 4 (restrict abortion to cases of rape, incest, or serious threats to the mother's life).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- James D. Libby / climate-change=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'fc62e5af-90bc-42ad-90a5-6d0a586331e8', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'fc62e5af-90bc-42ad-90a5-6d0a586331e8', ct.id, $ctx$In a July 2024 radio address, Libby argued energy policy should be governed by market principles rather than mandates, criticizing Maine's solar subsidy program and opposing government EV mandates and natural-gas bans, while praising Texas's market-driven renewable buildout. This aligns with letting market forces rather than government mandates drive the transition to cleaner energy.$ctx$, ARRAY['https://mesenategop.com/2024/07/29/when-it-comes-to-energy-policy-market-principles-should-be-considered/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- James D. Libby / school-vouchers=5
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'fc62e5af-90bc-42ad-90a5-6d0a586331e8', ct.id, 5.0 FROM inform.compass_topics ct WHERE ct.topic_key='school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'fc62e5af-90bc-42ad-90a5-6d0a586331e8', ct.id, $ctx$In a November 2025 column, Libby praised Arizona's universal education savings account model, saying the money follows the child, and said he has repeatedly sponsored similar school-choice legislation in Maine; he separately voiced support for a fully refundable tax credit for donations to private-school scholarship organizations. This matches support for universal, student-following education funding across public, private, and religious schools.$ctx$, ARRAY['https://mesenategop.com/2025/11/07/republican-vision-for-maine-improving-outcomes-and-increasing-choice-in-education/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- James D. Libby / taxes=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'fc62e5af-90bc-42ad-90a5-6d0a586331e8', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'fc62e5af-90bc-42ad-90a5-6d0a586331e8', ct.id, $ctx$Voted Nay on Roll Call #478 and Yea on Roll Call #592 (Jun 2025), opposing LD 1089's millionaire income-tax surcharge for education funding. Absent other statements calling for broader rate cuts, this vote reflects a preference for keeping the current tax system rather than raising taxes on high earners.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-478-ld-1089.pdf','https://legislature.maine.gov/uploads/visual_edit/roll-call-592-ld-1089.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- James D. Libby / trans-athletes=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'fc62e5af-90bc-42ad-90a5-6d0a586331e8', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'fc62e5af-90bc-42ad-90a5-6d0a586331e8', ct.id, $ctx$Was excused from Roll Call #556 but voted Yea on Roll Call #586 (Jun 16, 2025) to revive and pass LD 233, which requires athletes to compete on teams matching sex assigned at birth in state-funded school sports.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-586-ld-233.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?snum=132&LD=233']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Jeffrey L. Timberlake / abortion=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'f6c4c795-fac0-4b57-8b6e-0ae57515f941', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'f6c4c795-fac0-4b57-8b6e-0ae57515f941', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Jeffrey L. Timberlake's own recorded roll-call votes, 132nd Legislature), the senator voted FOR the MRTL-supported abortion restrictions, including LD 253 (barring the MaineCare program from covering abortion services) and LD 682 (narrowing legal abortion to a life-of-mother exception and reinstating criminal penalties), and against family-planning funding (LD 143). Narrowing legal abortion to a maternal-life-threat exception matches chair 4 (restrict abortion to cases of rape, incest, or serious threats to the mother's life).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Jeffrey L. Timberlake / medicare/aid=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'f6c4c795-fac0-4b57-8b6e-0ae57515f941', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'f6c4c795-fac0-4b57-8b6e-0ae57515f941', ct.id, $ctx$In the same May 9, 2025 address, Timberlake proposed conditioning MaineCare (Medicaid) coverage for 'able-bodied childless adults' on work or community-engagement requirements, while explicitly preserving coverage for seniors, children, and people with disabilities, framing this as needed to control the roughly 25% of the state budget MaineCare consumes. Conditioning eligibility on work requirements is a standard mechanism for narrowing Medicaid rolls, aligning with stance 4 (partially privatize Medicare and reduce Medicaid coverage) more than a cost-control-only reading.$ctx$, ARRAY['https://mesenategop.com/2025/05/09/democrat-budget-shenanigans-continue/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Jeffrey L. Timberlake / taxes=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'f6c4c795-fac0-4b57-8b6e-0ae57515f941', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'f6c4c795-fac0-4b57-8b6e-0ae57515f941', ct.id, $ctx$In a May 9, 2025 Maine Senate Republicans radio address, Timberlake criticized the Democratic majority's supplemental budget for proposing new taxes and fees — including increased tobacco/cannabis taxes, a new 70-cent prescription-fill tax, a 6% ambulance-service tax, and a new hospital inpatient bed fee — stating Republicans "will not support any new or increased taxes and fees," and called for "fiscal discipline" over continued budget growth rather than a "tax and spend" approach. This is an anti-tax-increase, rein-in-spending position without a stated push to cut current rates, most closely matching stance 3 (keep current tax rates, control spending) rather than a broad rate-cut stance.$ctx$, ARRAY['https://mesenategop.com/2025/05/09/democrat-budget-shenanigans-continue/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Jeffrey L. Timberlake / trans-athletes=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'f6c4c795-fac0-4b57-8b6e-0ae57515f941', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'f6c4c795-fac0-4b57-8b6e-0ae57515f941', ct.id, $ctx$On June 16, 2025, Timberlake voted YEA on the motion to recede and concur on LD 233 (Senate Roll Call #586), which would have required Maine school athletes in state-funded programs to compete based on biological sex assigned at birth. Though the motion failed 14-21, Timberlake's own recorded vote directly supports the birth-sex-based team assignment requirement, matching stance 4 exactly.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280095881&chamber=S&serialnumber=586','https://legislature.maine.gov/bills/display_ps.asp?snum=132&LD=233']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Jill C. Duson / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4eda22f0-a6db-485b-9d76-e76cf7a9a716', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4eda22f0-a6db-485b-9d76-e76cf7a9a716', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Jill C. Duson's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Jill C. Duson / civil-rights=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4eda22f0-a6db-485b-9d76-e76cf7a9a716', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4eda22f0-a6db-485b-9d76-e76cf7a9a716', ct.id, $ctx$Primary sponsor of LD 2176, 'An Act to Create a Right to Judicial Review Under the Maine Civil Rights Act for Persons Erroneously Detained,' enacted into law April 22, 2026 without the Governor's signature. The law creates a civil cause of action with damages and attorney's fees for people erroneously detained and bars landlords from disclosing tenant personal information (including immigration status) to intimidate or force eviction, matching stance 2's 'strengthen civil rights enforcement and address systemic discrimination.'$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=2176','https://www.mainesenate.org/sen-duson-introduces-bill-to-bolster-privacy-of-maine-tenants-protect-against-retaliation/','https://www.mainesenate.org/sen-duson-bill-to-strengthen-privacy-rights-of-maine-tenants-becomes-law/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Jill C. Duson / housing=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4eda22f0-a6db-485b-9d76-e76cf7a9a716', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4eda22f0-a6db-485b-9d76-e76cf7a9a716', ct.id, $ctx$Sponsored LD 1721 (2023, 'An Act to Create Transitional Housing Communities for Homeless Populations in the State'), a statewide, publicly funded program creating 400 transitional housing units for families and 500 for individuals plus wraparound services, citing under-resourced local General Assistance systems. This is the clearest housing-production evidence found in her Senate record (from her first term; no superseding 132nd Legislature housing-production bill was found), and its direct public funding of new housing units aligns with stance 2's 'publicly fund new housing.'$ctx$, ARRAY['https://www.mainesenate.org/sen-duson-proposes-bill-to-create-transitional-housing/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Jill C. Duson / immigration=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4eda22f0-a6db-485b-9d76-e76cf7a9a716', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4eda22f0-a6db-485b-9d76-e76cf7a9a716', ct.id, $ctx$As primary sponsor of LD 2176 (enacted April 22, 2026), Duson funded civil legal aid and created civil remedies for people erroneously detained by federal immigration enforcement, specifically citing 'the recent enhanced immigration enforcement surge' as the gap her bill addressed for renters 'especially our immigrant community.' She also co-signed a December 4, 2025 joint statement with five other Democratic legislative leaders defending Maine's Somali immigrant community against federal rhetoric, stating immigration has been foundational to the nation. Together this evidences support for extending public legal resources and protection to immigrant residents regardless of status, matching stance 2.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=2176','https://www.mainesenate.org/democratic-senate-and-house-leaders-affirm-support-for-maines-somali-community-denounce-hateful-rhetoric/','https://www.mainesenate.org/sen-duson-introduces-bill-to-strengthen-civil-liberties-of-maine-residents-bolster-access-to-legal-representation/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Jill C. Duson / judicial-access-to-justice=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4eda22f0-a6db-485b-9d76-e76cf7a9a716', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='judicial-access-to-justice'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4eda22f0-a6db-485b-9d76-e76cf7a9a716', ct.id, $ctx$The same LD 2176 (enacted April 22, 2026, Duson primary sponsor) funds civil legal service providers representing indigent persons wrongfully or erroneously detained by immigration enforcement and creates a judicial-review cause of action for those persons, directly lowering barriers to court access for people who otherwise could not afford representation. This matches stance 2's 'courts shouldn't be a maze that only the wealthy can navigate.'$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=2176','https://www.mainesenate.org/sen-duson-introduces-bill-to-strengthen-civil-liberties-of-maine-residents-bolster-access-to-legal-representation/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='judicial-access-to-justice'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Jill C. Duson / taxes=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4eda22f0-a6db-485b-9d76-e76cf7a9a716', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4eda22f0-a6db-485b-9d76-e76cf7a9a716', ct.id, $ctx$Voted Nay on accepting the minority 'Ought Not to Pass' report and Yea on the majority 'Ought to Pass as Amended' report for LD 1089, a bill establishing a 1% surcharge on income over $1,000,000 to permanently fund 55% of the state's share of public education (Senate roll calls #592-593, June 16, 2025). This is a targeted tax increase on the wealthiest earners to fund a specific public service rather than a broad-based hike on all wealthy people and large corporations, aligning with stance 2's 'moderately raise taxes on wealthy people... to fund existing services.'$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1089','https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280097493&chamber=S&serialnumber=593','https://www.mainesenate.org/sen-duson-earns-perfect-score-from-maine-afl-cio-for-voting-record-supporting-working-families/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Jill C. Duson / trans-athletes=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4eda22f0-a6db-485b-9d76-e76cf7a9a716', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4eda22f0-a6db-485b-9d76-e76cf7a9a716', ct.id, $ctx$Voted Yea to accept the 'Ought Not to Pass' report killing LD 1134 ('An Act to Prohibit Males from Participating in Female Sports or Using Female Facilities'), Senate roll call #494, June 12, 2025, and voted Nay on the motion to recede and concur with the House's amended version of LD 233 (a similar ban tied to school funding), Senate roll call #586, June 16, 2025 -- both votes rejected outright bans on transgender athletes in women's and girls' sports. No public statement specifying a preferred eligibility framework was found, so stance 2 is used as the closest documented chair reflecting consistent opposition to categorical bans without asserting an unrestricted-access position.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1134','https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280097524&chamber=S&serialnumber=494','https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280095881&chamber=S&serialnumber=586']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Joseph M. Baldacci / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '56d01855-0c6d-478e-a74d-61017b0ecb37', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '56d01855-0c6d-478e-a74d-61017b0ecb37', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Joseph M. Baldacci's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Joseph M. Baldacci / homelessness=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '56d01855-0c6d-478e-a74d-61017b0ecb37', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='homelessness'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '56d01855-0c6d-478e-a74d-61017b0ecb37', ct.id, $ctx$Baldacci was primary sponsor of LD 1190, "An Act to Increase State Funding for Emergency Shelters" (132nd Legislature), which sought additional state funding for emergency shelter capacity; the bill was referred to the Housing and Economic Development Committee and placed in Legislative Files (died) on 4/8/2025. Sponsoring dedicated shelter-funding legislation reflects a services/shelter-investment approach rather than an enforcement-first approach, though the bill did not itself address public-camping enforcement.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1190&SessionID=16']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='homelessness'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Joseph M. Baldacci / jail-capacity=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '56d01855-0c6d-478e-a74d-61017b0ecb37', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '56d01855-0c6d-478e-a74d-61017b0ecb37', ct.id, $ctx$Baldacci voted YEA on Senate Roll Call #246 (May 28, 2025), accepting the majority Ought Not To Pass report that killed LD 1536, which would have reinstated minimum cash bail and expanded pretrial detention authority, rolling back Maine's 2021 bail reform. His vote favored preserving the existing bail-reform framework over expanding detention.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280098308&chamber=S&serialnumber=246','https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1536&SessionID=16','https://www.themainewire.com/2025/04/sen-haggan-wants-judges-and-commissioners-to-have-more-say-over-who-gets-bail/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Joseph M. Baldacci / taxes=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '56d01855-0c6d-478e-a74d-61017b0ecb37', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '56d01855-0c6d-478e-a74d-61017b0ecb37', ct.id, $ctx$Baldacci voted YES on Senate Roll Call #593 (June 16, 2025), accepting the amended Ought To Pass report on LD 1089, a 2% surcharge on income over $1,000,000 dedicated to the state's 55% K-12 education funding obligation. His vote reflects support for a moderate, targeted tax increase on high earners to fund an existing public service commitment.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280097493&chamber=S&serialnumber=593','https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1089&SessionID=16']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Joseph Martin / abortion=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '90e18f37-3ae3-4466-8f56-1f1bcecdac7d', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '90e18f37-3ae3-4466-8f56-1f1bcecdac7d', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Joseph Martin's own recorded roll-call votes, 132nd Legislature), the senator voted FOR the MRTL-supported abortion restrictions, including LD 253 (barring the MaineCare program from covering abortion services) and LD 682 (narrowing legal abortion to a life-of-mother exception and reinstating criminal penalties), and against family-planning funding (LD 143). Narrowing legal abortion to a maternal-life-threat exception matches chair 4 (restrict abortion to cases of rape, incest, or serious threats to the mother's life).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Joseph Martin / climate-change=5
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '90e18f37-3ae3-4466-8f56-1f1bcecdac7d', ct.id, 5.0 FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '90e18f37-3ae3-4466-8f56-1f1bcecdac7d', ct.id, $ctx$In a December 2025 column, Martin wrote that climate advocacy drains billions from the economy and 'needs to stop,' framing environmental regulation as an economic drain rather than a policy priority, while promoting lithium mining and continued landfill operations as the state's real economic priorities. This matches rejecting climate policy as an organizing priority in favor of economic growth.$ctx$, ARRAY['https://mesenategop.com/2025/12/19/republican-vision-for-maine-environmental-stewardship-and-economic-opportunity-can-go-hand-in-hand/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Joseph Martin / taxes=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '90e18f37-3ae3-4466-8f56-1f1bcecdac7d', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '90e18f37-3ae3-4466-8f56-1f1bcecdac7d', ct.id, $ctx$Voted Nay on Senate Roll Call #478 (Jun 12, 2025) and Yea on Roll Call #592 (Jun 16, 2025), both times opposing LD 1089's 4% surtax on incomes over $1,000,000 to fund public education. In a June 2026 column he called for 'lower taxes, predictable regulations' and less regulatory burden as the path to a healthier business climate, reflecting a broad tax-cutting posture rather than mere defense of the status quo.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-478-ld-1089.pdf','https://legislature.maine.gov/uploads/visual_edit/roll-call-592-ld-1089.pdf','https://mesenategop.com/2026/06/18/maines-business-climate-is-failing-and-we-know-why/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Joseph Martin / trans-athletes=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '90e18f37-3ae3-4466-8f56-1f1bcecdac7d', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '90e18f37-3ae3-4466-8f56-1f1bcecdac7d', ct.id, $ctx$Voted Nay on Senate Roll Call #556 (Jun 16, 2025), opposing acceptance of the committee's 'ought not to pass' report that would have killed LD 233 (barring trans girls from girls' school sports), then voted Yea on Roll Call #586 the same day to revive and pass the bill. This is a clear, twice-repeated vote in favor of requiring athletes to compete on teams matching sex assigned at birth.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-556-ld-233.pdf','https://legislature.maine.gov/uploads/visual_edit/roll-call-586-ld-233.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Joseph Rafferty / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '738c8451-84e5-4d17-a2eb-7e2de4e075c1', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '738c8451-84e5-4d17-a2eb-7e2de4e075c1', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Joseph Rafferty's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Joseph Rafferty / taxes=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '738c8451-84e5-4d17-a2eb-7e2de4e075c1', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '738c8451-84e5-4d17-a2eb-7e2de4e075c1', ct.id, $ctx$Voted Yea on Senate Roll Call #593 (6/16/2025) to pass LD 1089 as amended, creating a new state income tax on earnings over $1,000,000 to permanently fund 55% of the state's share of public education costs.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1089','https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280097493&chamber=S&serialnumber=593']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Joseph Rafferty / trans-athletes=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '738c8451-84e5-4d17-a2eb-7e2de4e075c1', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '738c8451-84e5-4d17-a2eb-7e2de4e075c1', ct.id, $ctx$Voted twice in 2025 against restricting transgender athletes to their sex assigned at birth: on LD 1134 (Senate Roll Call #494, 6/12/2025) he voted Yea to accept the 'Ought Not to Pass' report killing the ban, and on LD 233 (Senate Roll Call #586, 6/17/2025) he voted Nay against receding and concurring with the House-passed ban.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1134','https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=233','https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280097524&chamber=S&serialnumber=494']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Marianne Moore / abortion=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '26583d91-4019-4832-bc2e-36c0672d878a', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '26583d91-4019-4832-bc2e-36c0672d878a', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Marianne Moore's own recorded roll-call votes, 132nd Legislature), the senator voted FOR the MRTL-supported abortion restrictions, including LD 253 (barring the MaineCare program from covering abortion services) and LD 682 (narrowing legal abortion to a life-of-mother exception and reinstating criminal penalties), and against family-planning funding (LD 143). Narrowing legal abortion to a maternal-life-threat exception matches chair 4 (restrict abortion to cases of rape, incest, or serious threats to the mother's life).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Marianne Moore / voting-rights=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '26583d91-4019-4832-bc2e-36c0672d878a', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '26583d91-4019-4832-bc2e-36c0672d878a', ct.id, $ctx$Moore authored a column supporting Maine's 2025 Question 1 ballot initiative, explicitly defending its voter-ID requirement while emphasizing that the Secretary of State would be required to provide free ID to any voter lacking one, and that absentee/mail voting access would be preserved (90-day advance availability). This is a direct match to the chair calling for standardized voter ID paired with guaranteed free-ID access for all eligible citizens.$ctx$, ARRAY['https://mesenategop.com/2025/10/01/question-1-will-maintain-voting-accessibility-while-increasing-confidence-in-our-elections/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Mark W. Lawrence / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '1d61fa5a-1a71-4d45-9cd5-a0ded08ec7f8', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '1d61fa5a-1a71-4d45-9cd5-a0ded08ec7f8', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Mark W. Lawrence's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Mark W. Lawrence / taxes=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '1d61fa5a-1a71-4d45-9cd5-a0ded08ec7f8', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '1d61fa5a-1a71-4d45-9cd5-a0ded08ec7f8', ct.id, $ctx$Voted Yea on Senate Roll Call #593 (6/16/2025) to pass LD 1089 as amended, creating a new state income tax on earnings over $1,000,000 to permanently fund 55% of the state's share of public education costs.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1089','https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280097493&chamber=S&serialnumber=593']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Mark W. Lawrence / trans-athletes=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '1d61fa5a-1a71-4d45-9cd5-a0ded08ec7f8', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '1d61fa5a-1a71-4d45-9cd5-a0ded08ec7f8', ct.id, $ctx$Voted twice in 2025 against restricting transgender athletes to their sex assigned at birth: on LD 1134 (Senate Roll Call #494, 6/12/2025) he voted Yea to accept the 'Ought Not to Pass' report killing the ban, and on LD 233 (Senate Roll Call #586, 6/17/2025) he voted Nay against receding and concurring with the House-passed ban.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1134','https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=233','https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280097524&chamber=S&serialnumber=494']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Matt A. Harrington / taxes=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4248ed15-3a23-47e7-a24d-6235379b8e43', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4248ed15-3a23-47e7-a24d-6235379b8e43', ct.id, $ctx$In a May 2026 column he argued the state's spending growth (from $7.2B to over $12B in the biennium budget) and repeated tax increases have failed to solve affordability problems, calling instead for broad-based tax relief through federal tax conformity (exempting tips/overtime) rather than more spending; he also voted Nay on Senate Roll Call #593 (6/16/2025) against passing LD 1089's new millionaire income-tax surcharge.$ctx$, ARRAY['https://mesenategop.com/2026/05/19/maine-cannot-tax-and-spend-its-way-to-affordability/','https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280097493&chamber=S&serialnumber=593','https://mesenategop.com/2026/04/09/legislative-democrats-continue-their-years-long-spending-spree/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Matt A. Harrington / trans-athletes=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4248ed15-3a23-47e7-a24d-6235379b8e43', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4248ed15-3a23-47e7-a24d-6235379b8e43', ct.id, $ctx$Voted against efforts to stop bills restricting transgender athletes to their sex assigned at birth: on LD 1134 (Senate Roll Call #494, 6/12/2025) he voted Nay against the 'Ought Not to Pass' report, favoring passage of the ban, and on LD 233 (Senate Roll Call #586, 6/17/2025) he voted Yea to recede and concur with the House-passed ban requiring school athletes to compete according to biological sex.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1134','https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=233','https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280095881&chamber=S&serialnumber=586']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Matthea E. L. Daughtry / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '0ed25b30-633f-45f5-99f1-a32009b134f5', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '0ed25b30-633f-45f5-99f1-a32009b134f5', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Matthea E. L. Daughtry's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Matthea E. L. Daughtry / childcare=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '0ed25b30-633f-45f5-99f1-a32009b134f5', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '0ed25b30-633f-45f5-99f1-a32009b134f5', ct.id, $ctx$Daughtry ran a 2025 statewide childcare listening tour and told the Portland Press Herald the state's early-childhood system gaps were too serious to address from behind a desk; she has since introduced a package of childcare bills including provider stipend protections. This reflects active support for expanding subsidies and provider support for childcare access rather than a market-only or means-tested-only approach.$ctx$, ARRAY['https://www.pressherald.com/2025/09/08/what-lawmakers-are-hearing-about-child-care-in-maine/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Matthea E. L. Daughtry / medicare/aid=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '0ed25b30-633f-45f5-99f1-a32009b134f5', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '0ed25b30-633f-45f5-99f1-a32009b134f5', ct.id, $ctx$As Senate President, Daughtry joined legislative Democrats at a May 2025 State House event opposing federal cuts to MaineCare (Maine's Medicaid program), warning that cuts would be catastrophic for the roughly one in three Mainers who rely on it. This reflects a stance of defending and preserving Medicaid coverage against reduction.$ctx$, ARRAY['https://www.mainesenate.org/maine-legislators-advocate-for-protecting-federal-mainecare-funding-safeguarding-healthcare-access/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Matthea E. L. Daughtry / taxes=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '0ed25b30-633f-45f5-99f1-a32009b134f5', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '0ed25b30-633f-45f5-99f1-a32009b134f5', ct.id, $ctx$Voted Yea on Roll Call #478 (Jun 12, 2025) and Nay on Roll Call #592 (Jun 16, 2025), both times supporting LD 1089's 4% income-tax surcharge on incomes over $1,000,000 to permanently fund public education. This is a moderate, targeted tax increase on high earners rather than a broad restructuring.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-478-ld-1089.pdf','https://legislature.maine.gov/uploads/visual_edit/roll-call-592-ld-1089.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Matthea E. L. Daughtry / trans-athletes=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '0ed25b30-633f-45f5-99f1-a32009b134f5', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '0ed25b30-633f-45f5-99f1-a32009b134f5', ct.id, $ctx$Voted Yea on Roll Call #556 and Nay on Roll Call #586 (Jun 16, 2025), consistently opposing LD 233's requirement that athletes compete on teams matching sex assigned at birth.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-556-ld-233.pdf','https://legislature.maine.gov/uploads/visual_edit/roll-call-586-ld-233.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Mike Tipping / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '653b504d-e5fd-4bc5-ab86-fc2b8129caf5', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '653b504d-e5fd-4bc5-ab86-fc2b8129caf5', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Mike Tipping's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Mike Tipping / jail-capacity=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '653b504d-e5fd-4bc5-ab86-fc2b8129caf5', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '653b504d-e5fd-4bc5-ab86-fc2b8129caf5', ct.id, $ctx$Tipping voted YEA on Senate Roll Call #246 (May 28, 2025), accepting the majority Ought Not To Pass report that killed LD 1536, which would have reinstated minimum cash bail and expanded pretrial detention authority, rolling back Maine's 2021 bail reform. His vote favored preserving the existing bail-reform framework over expanding detention.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280098308&chamber=S&serialnumber=246','https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1536&SessionID=16','https://www.themainewire.com/2025/04/sen-haggan-wants-judges-and-commissioners-to-have-more-say-over-who-gets-bail/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Mike Tipping / taxes=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '653b504d-e5fd-4bc5-ab86-fc2b8129caf5', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '653b504d-e5fd-4bc5-ab86-fc2b8129caf5', ct.id, $ctx$Tipping personally revived LD 1089's 2% millionaire income surcharge for education funding after an initial floor vote to kill it, moving for reconsideration; the Senate then voted 19-16 (Roll Call #593, June 16, 2025) to advance the amended bill, with Tipping voting YES. His procedural intervention plus affirmative vote reflect active support for a moderate, targeted tax increase on high earners to fund an existing state education-funding obligation.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280097493&chamber=S&serialnumber=593','https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1089&SessionID=16','https://www.themainewire.com/2025/06/thanks-to-mike-tipping-proposed-tax-on-maines-millionaires-lives-to-fight-another-day/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Nicole C. Grohoski / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '1c14da77-9b45-478c-85b5-9b2f5dad1481', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '1c14da77-9b45-478c-85b5-9b2f5dad1481', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Nicole C. Grohoski's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Nicole C. Grohoski / climate-change=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '1c14da77-9b45-478c-85b5-9b2f5dad1481', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '1c14da77-9b45-478c-85b5-9b2f5dad1481', ct.id, $ctx$Grohoski was primary sponsor of LD 1730, "An Act Regarding the Beneficial Electrification Policy of the State," which passed both chambers and was signed into law as Chapter 644 on 4/6/2026, promoting a shift toward electrified heating and transportation to reduce fossil-fuel reliance. In an October 2024 candidate questionnaire she emphasized grid-efficiency investments over new generation and stated renewables are already cost-competitive with fossil fuels, reflecting a gradual clean-energy transition rather than an emergency phase-out.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1730&SessionID=16','https://www.bangordailynews.com/profile/nicole-c-grohoski/','https://mainemorningstar.com/2026/01/07/new-bill-could-make-solar-power-more-accessible-to-maine-renters/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Nicole C. Grohoski / jail-capacity=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '1c14da77-9b45-478c-85b5-9b2f5dad1481', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '1c14da77-9b45-478c-85b5-9b2f5dad1481', ct.id, $ctx$On May 28, 2025, Grohoski voted YEA on Senate Roll Call #246, accepting the majority Ought Not To Pass report that killed LD 1536, a bill that would have reinstated a $60 minimum cash bail requirement and expanded judges'/bail commissioners' authority to hold people pretrial, rolling back Maine's 2021 bail reform. Her vote preserved the existing framework that limits pretrial detention rather than expanding it, consistent with reducing the incarcerated population through bail reform rather than building new capacity.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280098308&chamber=S&serialnumber=246','https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1536&SessionID=16','https://www.themainewire.com/2025/04/sen-haggan-wants-judges-and-commissioners-to-have-more-say-over-who-gets-bail/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Nicole C. Grohoski / taxes=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '1c14da77-9b45-478c-85b5-9b2f5dad1481', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '1c14da77-9b45-478c-85b5-9b2f5dad1481', ct.id, $ctx$Grohoski voted YES on Senate Roll Call #593 (June 16, 2025), accepting the amended Ought To Pass report on LD 1089, which imposes a 2% surcharge on income over $1,000,000 to permanently fund 55% of the state's share of K-12 education. As Senate Taxation Committee chair, her vote for this targeted, moderate surcharge on high earners dedicated to an existing state funding obligation aligns with moderately raising taxes on the wealthy to fund existing services.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280097493&chamber=S&serialnumber=593','https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1089&SessionID=16']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Peggy R. Rotundo / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '9e1175bc-2df1-4c7e-808a-fd9f0faa5ea1', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '9e1175bc-2df1-4c7e-808a-fd9f0faa5ea1', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Peggy R. Rotundo's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Peggy R. Rotundo / taxes=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '9e1175bc-2df1-4c7e-808a-fd9f0faa5ea1', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '9e1175bc-2df1-4c7e-808a-fd9f0faa5ea1', ct.id, $ctx$Voted Yea on Roll Call #478 (Jun 12, 2025) in support of LD 1089's 4% surcharge on incomes over $1,000,000 to permanently fund public education (she was excused for the follow-up Roll Call #592 on Jun 16). This is a targeted, moderate tax increase on high earners to fund an existing public service rather than a broad restructuring of the tax code.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-478-ld-1089.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?snum=132&LD=1089']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Peggy R. Rotundo / trans-athletes=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '9e1175bc-2df1-4c7e-808a-fd9f0faa5ea1', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '9e1175bc-2df1-4c7e-808a-fd9f0faa5ea1', ct.id, $ctx$Voted Yea on Roll Call #556 (Jun 16, 2025) to accept the committee's 'ought not to pass' report, killing LD 233's ban on trans athletes in girls' school sports, then voted Nay on Roll Call #586 against reviving the bill. This reflects opposition to a birth-sex participation mandate, consistent with allowing transgender athletes to compete on teams matching gender identity.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-556-ld-233.pdf','https://legislature.maine.gov/uploads/visual_edit/roll-call-586-ld-233.pdf']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Pinny H. Beebe-Center / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'f0e9d708-32bf-4333-b696-d14707dcf468', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'f0e9d708-32bf-4333-b696-d14707dcf468', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Pinny H. Beebe-Center's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Pinny H. Beebe-Center / jail-capacity=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'f0e9d708-32bf-4333-b696-d14707dcf468', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'f0e9d708-32bf-4333-b696-d14707dcf468', ct.id, $ctx$Beebe-Center, who chairs the Criminal Justice and Public Safety Committee, voted YEA on Senate Roll Call #246 (May 28, 2025), accepting the majority Ought Not To Pass report that killed LD 1536, which would have reinstated minimum cash bail and expanded pretrial detention authority, rolling back Maine's 2021 bail reform. Her vote favored preserving the existing bail-reform framework over expanding detention.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280098308&chamber=S&serialnumber=246','https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1536&SessionID=16','https://www.themainewire.com/2025/04/sen-haggan-wants-judges-and-commissioners-to-have-more-say-over-who-gets-bail/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Pinny H. Beebe-Center / taxes=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'f0e9d708-32bf-4333-b696-d14707dcf468', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'f0e9d708-32bf-4333-b696-d14707dcf468', ct.id, $ctx$Beebe-Center voted YES on Senate Roll Call #593 (June 16, 2025), accepting the amended Ought To Pass report on LD 1089, a 2% surcharge on income over $1,000,000 dedicated to the state's 55% K-12 education funding obligation. Her vote reflects support for a moderate, targeted tax increase on high earners to fund an existing public service commitment.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280097493&chamber=S&serialnumber=593','https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1089&SessionID=16']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Rachel Talbot Ross / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ab357826-a155-4d8a-872f-de865129a256', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ab357826-a155-4d8a-872f-de865129a256', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Rachel Talbot Ross's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Rachel Talbot Ross / civil-rights=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ab357826-a155-4d8a-872f-de865129a256', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ab357826-a155-4d8a-872f-de865129a256', ct.id, $ctx$As House Speaker, Talbot Ross introduced legislation (reported by Maine Morning Star, Feb. 2024) to create a civil rights enforcement unit within the Attorney General's office to more fully enforce the Maine Civil Rights Act; the bill advanced out of the Judiciary Committee after being pared back. She also sponsored LD 1202, signed into law in 2026, funding professional development for educators in African American studies. Both actions reflect a strengthen-enforcement, address-systemic-discrimination approach rather than a reparations mandate or a rollback of enforcement.$ctx$, ARRAY['https://mainemorningstar.com/2024/02/22/seeking-full-enforcement-of-maine-civil-rights-act-talbot-ross-proposes-new-unit-in-ags-office/','https://www.mainesenate.org/sen-talbot-ross-bill-to-support-african-american-studies-signed-into-law/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Rachel Talbot Ross / homelessness=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ab357826-a155-4d8a-872f-de865129a256', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='homelessness'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ab357826-a155-4d8a-872f-de865129a256', ct.id, $ctx$Talbot Ross sponsored LD 698, signed into law in 2025, providing $4.47 million in emergency funding to stabilize Maine's homeless shelters, and LD 1910 (2026), which funds 18 new outreach caseworkers and housing-stability workers to connect unhoused people with services and permanent housing. This investment in shelter capacity and outreach workers, without any criminalization component, matches the decriminalize-and-invest chair.$ctx$, ARRAY['https://www.mainesenate.org/new-law-to-stabilize-emergency-shelter-funding-takes-effect/','https://www.mainesenate.org/sen-talbot-ross-bill-to-expand-housing-stability-services-advances-awaits-funding/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='homelessness'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Rachel Talbot Ross / judicial-criminal-justice=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ab357826-a155-4d8a-872f-de865129a256', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='judicial-criminal-justice'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ab357826-a155-4d8a-872f-de865129a256', ct.id, $ctx$Talbot Ross sponsored LD 1911, the 'Clean Slate' bill passed by the Legislature in 2026 to automatically seal criminal records for people who remain crime-free for five years on most Class D/E offenses (excluding stalking and domestic-violence-related crimes), affecting an estimated 123,000 Mainers. Her framing — helping people 'claim their lives back' after paying their debt to society — matches the rehabilitation-focused chair on this scale.$ctx$, ARRAY['https://www.mainesenate.org/maine-legislature-passes-sen-talbot-ross-bill-to-seal-criminal-history-record-information-for-low-level-offenses/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='judicial-criminal-justice'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Rachel Talbot Ross / local-immigration=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ab357826-a155-4d8a-872f-de865129a256', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ab357826-a155-4d8a-872f-de865129a256', ct.id, $ctx$Talbot Ross sponsored LD 2058, signed into law in 2026, which requires municipal and county jails to remain available for criminal detentions but explicitly exempts individuals held solely for civil federal immigration violations without accompanying criminal charges — meaning local jails are not obligated to serve as immigration-holding facilities absent a criminal charge. This deliberate but limited carve-out against using local jail capacity for civil immigration enforcement is closest to a middle chair (avoiding proactive cooperation absent independent justification), short of a full non-cooperation/sanctuary policy. No clean quotable sentence on the immigration rationale specifically was found in the available press release, so no quote is included.$ctx$, ARRAY['https://www.mainesenate.org/governor-signs-sen-talbot-ross-bill-to-strengthen-local-control-for-municipal-and-county-jails/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Richard A. Bennett / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'e73bd689-240f-492a-bf01-f7be307367f8', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'e73bd689-240f-492a-bf01-f7be307367f8', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Richard A. Bennett's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Richard A. Bennett / campaign-finance=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'e73bd689-240f-492a-bf01-f7be307367f8', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='campaign-finance'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'e73bd689-240f-492a-bf01-f7be307367f8', ct.id, $ctx$Bennett's platform states that 'special interests have too much sway over our policies and elections' and pledges to strengthen disclosure laws, make decisions transparent, and ensure dark money and hidden donors can't steer outcomes behind the scenes. This explicit targeting of dark money and hidden donors, beyond simple disclosure, matches stance 2 (strictly limit corporate donations and dark money groups) more than a pure-disclosure-only stance 3.$ctx$, ARRAY['https://bennettforgovernor.com/vision']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='campaign-finance'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Richard A. Bennett / childcare=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'e73bd689-240f-492a-bf01-f7be307367f8', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'e73bd689-240f-492a-bf01-f7be307367f8', ct.id, $ctx$Bennett's platform calls for 'a childcare system that offers affordable options in every community, support for providers so they can stay open and pay a livable wage, and policies that make childcare more accessible' — a significant subsidy and provider-support expansion rather than a fully public universal system or a deregulation/private-market approach. This matches stance 2 (significantly expand subsidies and provider grants for affordability).$ctx$, ARRAY['https://bennettforgovernor.com/vision']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Richard A. Bennett / climate-change=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'e73bd689-240f-492a-bf01-f7be307367f8', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'e73bd689-240f-492a-bf01-f7be307367f8', ct.id, $ctx$Bennett's platform calls for prioritizing energy affordability while investing in efficiency, reliability, and locally controlled power, and moving toward 'true energy independence,' without endorsing a rapid renewable-only phase-out timeline or rejecting climate policy outright. This active-investment, gradual-transition framing matches stance 3 (invest in clean energy while gradually reducing reliance on fossil fuels) more closely than a rapid phase-out (2) or a pure market-forces (4) position.$ctx$, ARRAY['https://bennettforgovernor.com/vision']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Richard A. Bennett / deportation=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'e73bd689-240f-492a-bf01-f7be307367f8', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='deportation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'e73bd689-240f-492a-bf01-f7be307367f8', ct.id, $ctx$Per Portland Press Herald reporting (June 24, 2025), Bennett 'voted with Democrats in favor of a bill that would prevent local and state law enforcement from arresting or detaining people solely for enforcement of federal immigration laws and would limit local agencies' abilities to work with federal immigration officials' — matching LD 1971, which was enacted without the Governor's signature in January 2026. Voting to bar state/local police from assisting federal removal efforts, shielding undocumented residents from that enforcement, aligns with stance 1 (protect undocumented residents from removal) more than any of the more enforcement-forward stances.$ctx$, ARRAY['https://www.pressherald.com/2025/06/24/maine-sen-rick-bennett-announces-run-for-governor-as-an-independent/','https://legislature.maine.gov/bills/display_ps.asp?snum=132&LD=1971']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='deportation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Richard A. Bennett / healthcare=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'e73bd689-240f-492a-bf01-f7be307367f8', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'e73bd689-240f-492a-bf01-f7be307367f8', ct.id, $ctx$Bennett's 2026 gubernatorial campaign platform states Maine's health care system is 'expensive, overly-complicated, and too often out of reach' and calls for making coverage more affordable for every Mainer, with a focus on prevention, primary care, mental health, and addiction treatment. This universal-access framing without an explicit single-payer proposal, and with no stated intent to limit assistance only to the poor, matches stance 2 (affordable coverage for everyone through a mix of public programs and regulated private insurance).$ctx$, ARRAY['https://bennettforgovernor.com/vision']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Richard A. Bennett / housing=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'e73bd689-240f-492a-bf01-f7be307367f8', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'e73bd689-240f-492a-bf01-f7be307367f8', ct.id, $ctx$Bennett's platform proposes doubling the rate of new home construction while streamlining the regulatory process (while keeping labor standards), reviving factory-built housing, and improving aging housing stock — a targeted, permitting-focused approach rather than direct public housing construction or a pure hands-off market approach. This matches stance 3 (targeted incentives such as easier permits and support for affordable projects).$ctx$, ARRAY['https://bennettforgovernor.com/vision']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Richard A. Bennett / taxes=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'e73bd689-240f-492a-bf01-f7be307367f8', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'e73bd689-240f-492a-bf01-f7be307367f8', ct.id, $ctx$Bennett's gubernatorial platform calls for a 'fair, transparent tax system' that eliminates unfair exemptions, provides targeted relief for those most in need, and protects older Mainers from being taxed out of their homes — a loophole-closing, targeted-relief approach rather than broad rate cuts or new taxes on the wealthy. This matches stance 3 (keep current tax rates but close loopholes to ensure fairness) most closely.$ctx$, ARRAY['https://bennettforgovernor.com/vision']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Richard A. Bennett / trans-athletes=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'e73bd689-240f-492a-bf01-f7be307367f8', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'e73bd689-240f-492a-bf01-f7be307367f8', ct.id, $ctx$On June 16, 2025, Bennett cast the sole vote against his then-party (he was still a Republican at the time) on the motion to recede and concur on LD 233 (Senate Roll Call #586), rejecting a requirement that Maine school athletes compete based on biological sex assigned at birth; the Portland Press Herald reported he opposed a 'trio of bills' aimed at restricting transgender athletes that session. His vote clearly rejects mandating birth-sex-based team assignment (stances 4-5); absent further detail on his preferred accommodation framework, the most defensible chair given his documented inclusive positioning is stance 2 (allow competition matching gender identity after basic documentation).$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280095881&chamber=S&serialnumber=586','https://www.pressherald.com/2025/06/24/maine-sen-rick-bennett-announces-run-for-governor-as-an-independent/','https://legislature.maine.gov/bills/display_ps.asp?snum=132&LD=233']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Richard Bradstreet / abortion=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '7a6b6395-3308-4477-88f9-b5cb85722ee1', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '7a6b6395-3308-4477-88f9-b5cb85722ee1', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Richard Bradstreet's own recorded roll-call votes, 132nd Legislature), the senator voted FOR the MRTL-supported abortion restrictions, including LD 253 (barring the MaineCare program from covering abortion services) and LD 682 (narrowing legal abortion to a life-of-mother exception and reinstating criminal penalties), and against family-planning funding (LD 143). Narrowing legal abortion to a maternal-life-threat exception matches chair 4 (restrict abortion to cases of rape, incest, or serious threats to the mother's life).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Richard Bradstreet / housing=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '7a6b6395-3308-4477-88f9-b5cb85722ee1', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '7a6b6395-3308-4477-88f9-b5cb85722ee1', ct.id, $ctx$Cosponsored LD 1498, "An Act to Limit Municipal Impact Fees on Housing Development" (signed into law), which caps what municipalities can charge developers in impact fees, requires fees be proportionate and limited to infrastructure directly abutting a project, and forces municipalities to publish their fee-determination policy. He also cosponsored LD 949 (clarifying manufactured-housing licensing jurisdiction) and LD 1419 (sales-tax exemption for off-site housing construction), and is part-time Executive Director of the Manufactured Housing Association of Maine. This pattern of cutting regulatory/fee burdens on developers to spur housing supply matches stance 4.$ctx$, ARRAY['https://legislature.maine.gov/legis/bills/getPDF.asp?paper=HP0982&item=1&snum=132','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=1498&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Richard Bradstreet / taxes=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '7a6b6395-3308-4477-88f9-b5cb85722ee1', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '7a6b6395-3308-4477-88f9-b5cb85722ee1', ct.id, $ctx$His campaign platform's "Reduce Taxes" plank calls for cutting taxes, fees, and the cost of living broadly rather than targeting relief to any one income group or proposing a flat tax/drastic government shrinkage. This general across-the-board tax-cut commitment matches stance 4.$ctx$, ARRAY['https://www.dickbradstreet.com']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Richard Bradstreet / trans-athletes=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '7a6b6395-3308-4477-88f9-b5cb85722ee1', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '7a6b6395-3308-4477-88f9-b5cb85722ee1', ct.id, $ctx$On the Maine Senate's June 12, 2025 Roll Call #494, Bradstreet voted NAY on the motion to accept the Judiciary Committee's "Ought Not to Pass" report on LD 1134/LD 868, meaning he wanted the bill advanced. The bill's text would "require transgender athletes to compete only on teams matching their biological sex assigned at birth" -- language that matches stance 4 directly.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-494-ld-1134.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=1134&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Russell J. Black / abortion=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '81db75c5-8c48-40f3-8cb1-7220def31e72', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '81db75c5-8c48-40f3-8cb1-7220def31e72', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Russell J. Black's own recorded roll-call votes, 132nd Legislature), the senator voted FOR the MRTL-supported abortion restrictions, including LD 253 (barring the MaineCare program from covering abortion services) and LD 682 (narrowing legal abortion to a life-of-mother exception and reinstating criminal penalties), and against family-planning funding (LD 143). Narrowing legal abortion to a maternal-life-threat exception matches chair 4 (restrict abortion to cases of rape, incest, or serious threats to the mother's life).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Russell J. Black / childcare=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '81db75c5-8c48-40f3-8cb1-7220def31e72', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '81db75c5-8c48-40f3-8cb1-7220def31e72', ct.id, $ctx$Black's platform explicitly proposes expanding childcare access and affordability by loosening Maine's child-to-staff ratio regulations to match national norms, i.e., a deregulation-driven supply-side approach rather than direct public subsidy or universal funding. This matches the chair describing reduced regulation on providers to increase supply and lower costs.$ctx$, ARRAY['https://www.russellblackformaine.com/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Russell J. Black / taxes=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '81db75c5-8c48-40f3-8cb1-7220def31e72', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '81db75c5-8c48-40f3-8cb1-7220def31e72', ct.id, $ctx$Black's campaign platform states a goal of lowering taxes for both individuals and businesses so Mainers keep more of their earnings, with no mention of offsetting cuts via new revenue elsewhere. This is a general tax-cut-for-everyone position without an explicit call to also shrink government itself, matching the chair for cutting taxes broadly rather than the more extreme chair calling for drastically cutting taxes and shrinking government.$ctx$, ARRAY['https://www.russellblackformaine.com/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Scott Cyrway / abortion=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'dc583785-9207-41b7-a790-1bc87e0685de', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'dc583785-9207-41b7-a790-1bc87e0685de', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Scott Cyrway's own recorded roll-call votes, 132nd Legislature), the senator voted FOR the MRTL-supported abortion restrictions, including LD 253 (barring the MaineCare program from covering abortion services) and LD 682 (narrowing legal abortion to a life-of-mother exception and reinstating criminal penalties), and against family-planning funding (LD 143). Narrowing legal abortion to a maternal-life-threat exception matches chair 4 (restrict abortion to cases of rape, incest, or serious threats to the mother's life).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Scott Cyrway / climate-change=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'dc583785-9207-41b7-a790-1bc87e0685de', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'dc583785-9207-41b7-a790-1bc87e0685de', ct.id, $ctx$In his Jan. 2, 2026 radio address, Cyrway criticized $450 million in state-mandated solar subsidies as primarily benefiting out-of-state developers and pledged continued Republican efforts to lower energy costs, without endorsing any renewable-transition timeline or new environmental restrictions. This anti-subsidy, cost-focused stance — opposing government-directed clean-energy spending rather than proposing emissions rules — most closely matches stance 4 (let market forces drive any transition to cleaner energy).$ctx$, ARRAY['https://mesenategop.com/2026/01/02/a-new-year-a-new-legislative-session/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Scott Cyrway / deportation=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'dc583785-9207-41b7-a790-1bc87e0685de', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='deportation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'dc583785-9207-41b7-a790-1bc87e0685de', ct.id, $ctx$In the same Jan. 2, 2026 address, Cyrway explicitly opposed LD 1971 ("An Act to Protect Workers in This State by Clarifying the Relationship of State and Local Law Enforcement Agencies with Federal Immigration Authorities"), which limits local police cooperation with federal immigration enforcement, warning it would stop police from removing dangerous people who are in the country illegally. This tracks his May 2025 op-ed opposing similar Judiciary Committee bills that would "require police to turn a blind eye when they encounter undocumented suspects...engaged in criminal activity." His consistent focus on preserving enforcement against undocumented individuals with criminal involvement matches stance 4 (deport those without legal status, starting with those who have criminal records).$ctx$, ARRAY['https://mesenategop.com/2026/01/02/a-new-year-a-new-legislative-session/','https://legislature.maine.gov/bills/display_ps.asp?snum=132&LD=1971','https://mesenategop.com/2025/05/23/radical-proposals-threaten-maines-public-safety/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='deportation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Scott Cyrway / taxes=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'dc583785-9207-41b7-a790-1bc87e0685de', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'dc583785-9207-41b7-a790-1bc87e0685de', ct.id, $ctx$In a January 2, 2026 Maine Senate Republicans radio address, Cyrway pushed for state tax conformity with federal tax reforms so Mainers could benefit from cuts (noting workers still pay state tax on tips/overtime and seniors lack the full standard-deduction increase), and argued for prioritizing tax-burden reduction over new spending despite a $248 million revenue increase. This continues his 2022 framing of surplus tax dollars as money that "was never the government's to begin with," consistently favoring broad-based tax relief over expanded government, matching stance 4 (reduce tax rates across all income levels).$ctx$, ARRAY['https://mesenategop.com/2026/01/02/a-new-year-a-new-legislative-session/','https://mesenategop.com/2022/05/06/where-have-all-the-surplus-dollars-gone/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Scott Cyrway / trans-athletes=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'dc583785-9207-41b7-a790-1bc87e0685de', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'dc583785-9207-41b7-a790-1bc87e0685de', ct.id, $ctx$On June 16, 2025, Cyrway voted YEA on the motion to recede and concur on LD 233, "An Act to Prohibit Biological Males from Participating in School Athletic Programs and Activities Designated for Females When State Funding Is Provided to the School" (Senate Roll Call #586), which would have required student-athletes to compete based on biological sex assigned at birth. The motion failed 14-21 and the bill died, but Cyrway's own recorded vote directly supports the birth-sex-based team assignment requirement, matching stance 4 exactly.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280095881&chamber=S&serialnumber=586','https://legislature.maine.gov/bills/display_ps.asp?snum=132&LD=233']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Stacey K. Guerin / abortion=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'd435e628-4145-41c3-9dc4-4ff2b91b9acf', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'd435e628-4145-41c3-9dc4-4ff2b91b9acf', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Stacey K. Guerin's own recorded roll-call votes, 132nd Legislature), the senator voted FOR the MRTL-supported abortion restrictions, including LD 253 (barring the MaineCare program from covering abortion services) and LD 682 (narrowing legal abortion to a life-of-mother exception and reinstating criminal penalties), and against family-planning funding (LD 143). Narrowing legal abortion to a maternal-life-threat exception matches chair 4 (restrict abortion to cases of rape, incest, or serious threats to the mother's life).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Stacey K. Guerin / climate-change=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'd435e628-4145-41c3-9dc4-4ff2b91b9acf', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'd435e628-4145-41c3-9dc4-4ff2b91b9acf', ct.id, $ctx$Guerin sponsored LD 32, "An Act to Repeal the Laws Regarding Net Energy Billing" (132nd Legislature, SP 49), and presented testimony that the program has become a "job-killing solar tax" that shifts grid costs onto non-solar ratepayers. Pushing to fully repeal this government-directed renewable cross-subsidy so that solar adoption is priced by ordinary market/grid costs rather than a mandated billing credit aligns with chair 4, "let market forces drive any transition to cleaner energy sources."$ctx$, ARRAY['https://mainemorningstar.com/2025/02/27/many-believe-maines-net-energy-billing-needs-reform-but-diverge-on-whether-to-tweak-or-toss/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Stacey K. Guerin / trans-athletes=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'd435e628-4145-41c3-9dc4-4ff2b91b9acf', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'd435e628-4145-41c3-9dc4-4ff2b91b9acf', ct.id, $ctx$In her own solely-authored Maine Senate Republicans weekly radio address (May 2026), Guerin states that allowing "biological males" to compete in women's sports "undermines opportunities for female athletes," and says she and her GOP colleagues supported legislative proposals this session that the majority declined to advance. This is a direct personal statement backing restriction of competition to a person's biological sex, matching chair 4.$ctx$, ARRAY['https://mesenategop.com/2026/05/01/republican-vision-for-maine-standing-up-for-fairness-in-girls-sports/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Stacy F. Brenner / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '0d01124b-78df-448b-b34a-28f10b39ba8c', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '0d01124b-78df-448b-b34a-28f10b39ba8c', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Stacy F. Brenner's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Stacy F. Brenner / climate-change=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '0d01124b-78df-448b-b34a-28f10b39ba8c', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '0d01124b-78df-448b-b34a-28f10b39ba8c', ct.id, $ctx$Brenner sponsored LD 1870, signed into law in April 2026, directing Maine's DEP to calculate cumulative climate damage costs (1995-2024) from greenhouse gas emissions as the foundation for a future 'climate superfund' program modeled on Vermont and New York that would require major fossil fuel corporations to help pay for climate resilience and adaptation. This polluter-accountability/resilience-funding approach is a real but incremental climate investment rather than a mandated fossil-fuel phase-out or drilling ban, so it maps to the gradual clean-energy-investment chair rather than the more aggressive phase-out chairs.$ctx$, ARRAY['https://www.mainesenate.org/sen-brenner-bill-to-develop-a-climate-superfund-signed-into-law/','https://mainemorningstar.com/2026/01/28/maine-advances-climate-superfund-bill-that-would-ask-fossil-fuel-companies-to-pay/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Susan Bernard / abortion=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4fcdb98d-b61f-499d-8d19-8f9462c907dd', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4fcdb98d-b61f-499d-8d19-8f9462c907dd', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Susan Bernard's own recorded roll-call votes, 132nd Legislature), the senator voted FOR the MRTL-supported abortion restrictions, including LD 253 (barring the MaineCare program from covering abortion services) and LD 682 (narrowing legal abortion to a life-of-mother exception and reinstating criminal penalties), and against family-planning funding (LD 143). Narrowing legal abortion to a maternal-life-threat exception matches chair 4 (restrict abortion to cases of rape, incest, or serious threats to the mother's life).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Susan Bernard / healthcare=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4fcdb98d-b61f-499d-8d19-8f9462c907dd', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4fcdb98d-b61f-499d-8d19-8f9462c907dd', ct.id, $ctx$Same Feb. 16, 2025 radio address: Bernard said GOP amendments aimed at "returning MaineCare back to the program it was meant to be – a safety net to help Maine's most needy residents," paired with work requirements for "healthy adults" and enrollment controls for able-bodied childless adults. This is her own statement describing a policy where the state safety net targets the poorest while others are expected toward work/private coverage, matching chair 4 ("Only help the poorest people afford healthcare and leave everyone else to employers and private insurance").$ctx$, ARRAY['https://mesenategop.com/2025/02/16/republicans-stand-ready-to-make-tough-budget-decisions/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Susan Bernard / medicare/aid=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4fcdb98d-b61f-499d-8d19-8f9462c907dd', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4fcdb98d-b61f-499d-8d19-8f9462c907dd', ct.id, $ctx$In her Feb. 16, 2025 Republican Radio Address (her own statement, delivered in first person as Appropriations Committee Republican lead), Bernard described GOP amendments to freeze MaineCare (Maine's Medicaid program) enrollment for able-bodied childless adults until enrollment fell 10%, add work/training/community-service requirements for working-age recipients, and limit General Assistance to three months in a twelve-month period. She explicitly said Republicans "don't want to gut MaineCare" but want to "rein in" it for sustainability - a reduce-Medicaid-coverage position (chair 4), not the "phase out" of chair 5.$ctx$, ARRAY['https://mesenategop.com/2025/02/16/republicans-stand-ready-to-make-tough-budget-decisions/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Susan Bernard / taxes=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4fcdb98d-b61f-499d-8d19-8f9462c907dd', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4fcdb98d-b61f-499d-8d19-8f9462c907dd', ct.id, $ctx$In a Feb. 13, 2026 Maine Senate Republicans interview, Bernard said Republicans "want to lower taxes" and "sustainable tax relief," criticized the state's $300 rebate checks as not providing "long-term relief," and favored pairing state relief with federal-style cuts (no tax on tips/overtime). She contrasted this with Democrats who "create a problem by spending more and more." This is her own recorded statement, not party inference, and matches cutting taxes while scaling back spending growth (chair 4) rather than a call to eliminate government entirely (chair 5).$ctx$, ARRAY['https://mesenategop.com/2026/02/13/republican-vision-for-maine-real-relief-for-maine-taxpayers/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Teresa S. Pierce / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '69fece92-eade-468e-bf34-82bbac5b3da9', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '69fece92-eade-468e-bf34-82bbac5b3da9', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Teresa S. Pierce's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Teresa S. Pierce / climate-change=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '69fece92-eade-468e-bf34-82bbac5b3da9', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '69fece92-eade-468e-bf34-82bbac5b3da9', ct.id, $ctx$On March 27, 2025 (Roll Call #77), Pierce voted Yea to accept the Ought Not to Pass report on LD 444, which would have repealed Maine's statutory goals for renewable electricity consumption. Her vote preserved the state's existing renewable portfolio standard, consistent with continued investment in clean energy alongside a gradual transition away from fossil fuels rather than an abrupt phase-out or rejection of climate policy.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-77-ld-444.pdf','https://legislature.maine.gov/senate/132nd-roll-calls']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Teresa S. Pierce / healthcare=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '69fece92-eade-468e-bf34-82bbac5b3da9', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '69fece92-eade-468e-bf34-82bbac5b3da9', ct.id, $ctx$Pierce authored LD 1478 in the 131st Legislature (funding continuing through FY2026-27) to secure $3,390,000 in annual state funding for Maine Family Planning, a network of community health centers providing primary, reproductive, and preventive care to underserved and rural Mainers. Her February 2024 op-ed frames this as filling a gap left by stagnant state and unstable federal (Title X) funding for a targeted, needs-based population rather than calling for a universal public system, matching a stance of expanding programs to help people who can't afford care while leaving the existing insurance structure in place for everyone else.$ctx$, ARRAY['https://www.bangordailynews.com/2024/02/27/opinion/opinion-contributor/maine-family-planning-centers-need-funding/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Teresa S. Pierce / immigration=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '69fece92-eade-468e-bf34-82bbac5b3da9', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '69fece92-eade-468e-bf34-82bbac5b3da9', ct.id, $ctx$On June 9, 2025 (Roll Call #400), Pierce voted Yea to accept the Ought Not to Pass report on LD 1707, killing a bill that would have required U.S. citizenship to receive state or local financial assistance. Her vote opposed restricting public-benefits access to citizens only, consistent with keeping public services accessible regardless of immigration status.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-400-ld-1707.pdf','https://legislature.maine.gov/senate/132nd-roll-calls']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Teresa S. Pierce / jail-capacity=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '69fece92-eade-468e-bf34-82bbac5b3da9', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '69fece92-eade-468e-bf34-82bbac5b3da9', ct.id, $ctx$On May 28, 2025 (Roll Call #246), Pierce voted Yea to accept the Ought Not to Pass committee report on LD 1536, killing a Republican-sponsored bill that would have reversed the Legislature's 2021 Maine Bail Code reforms (PL 2021, c. 397), which had reduced financial and administrative barriers to pretrial release for indigent defendants. Her vote preserved the existing bail-reform framework that reduces reliance on cash bail and pretrial detention rather than expanding it.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-246-ld-1536.pdf','https://legislature.maine.gov/legis/bills/getPDF.asp?paper=SP0620&item=1&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Teresa S. Pierce / local-immigration=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '69fece92-eade-468e-bf34-82bbac5b3da9', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '69fece92-eade-468e-bf34-82bbac5b3da9', ct.id, $ctx$The same bill she helped kill on June 9, 2025 (Roll Call #400, LD 1707) would also have required Maine municipalities to ensure proactive compliance with federal immigration enforcement. Pierce's Yea vote to reject the bill opposed mandating that local governments actively cooperate with federal immigration authorities.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-400-ld-1707.pdf','https://legislature.maine.gov/senate/132nd-roll-calls']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Teresa S. Pierce / taxes=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '69fece92-eade-468e-bf34-82bbac5b3da9', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '69fece92-eade-468e-bf34-82bbac5b3da9', ct.id, $ctx$On May 29, 2025 (Roll Call #258), Pierce voted Yea to accept the Ought Not to Pass report on LD 671, which would have abolished Maine's income tax entirely and replaced the budget process with a zero-based budget. Her vote to kill this bill reflects support for retaining the state's existing tax-funded budget system rather than eliminating it, though it does not by itself indicate support for raising rates specifically on high earners.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-258-ld-671.pdf','https://legislature.maine.gov/senate/132nd-roll-calls']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Teresa S. Pierce / voting-rights=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '69fece92-eade-468e-bf34-82bbac5b3da9', ct.id, 2.0 FROM inform.compass_topics ct WHERE ct.topic_key='voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '69fece92-eade-468e-bf34-82bbac5b3da9', ct.id, $ctx$On June 4, 2025 (Roll Call #355), Pierce voted Yea to accept the Ought Not to Pass report on LD 38, which would have required photographic identification for voting in Maine. Her vote rejected imposing a new photo-ID mandate, consistent with keeping voter access broad rather than adding new identification barriers to casting a ballot.$ctx$, ARRAY['https://legislature.maine.gov/uploads/visual_edit/roll-call-355-ld-38.pdf','https://legislature.maine.gov/senate/132nd-roll-calls']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Timothy E. Nangle / abortion=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'b8bac865-38a9-45f7-8641-ebdedf416f30', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'b8bac865-38a9-45f7-8641-ebdedf416f30', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Timothy E. Nangle's own recorded roll-call votes, 132nd Legislature), the senator voted AGAINST every MRTL-supported abortion restriction, including LD 253 (which would have barred the MaineCare program from covering abortion services), LD 682 (narrowing legal abortion to a life-of-mother exception with criminal penalties), and the LD 886/887/1007/1154 procedural-restriction bills, and voted to fund family-planning services (LD 143). Preserving public MaineCare funding and opposing restrictions at every stage matches chair 1 (legal, accessible, and publicly funded at all stages).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Timothy E. Nangle / housing=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'b8bac865-38a9-45f7-8641-ebdedf416f30', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'b8bac865-38a9-45f7-8641-ebdedf416f30', ct.id, $ctx$In November 2025 Nangle introduced LD 2135, "An Act to Provide Funding to Keep Maine Veterans Housed," which funds the existing Veterans Flex Fund (run by Preble Street and the Maine Homeless Veterans Action Committee) to provide veterans emergency rental assistance, landlord incentives, and housing-search outreach; the Veterans and Legal Affairs Committee advanced it unanimously in February 2026. This targeted-subsidy approach for a specific vulnerable population, rather than direct public housing construction, broad rent caps, or a hands-off market approach, matches stance 3.$ctx$, ARRAY['https://www.mainesenate.org/sen-nangle-introduces-bill-to-keep-maine-veterans-housed/','https://www.mainesenate.org/committee-unanimously-advances-sen-nangle-bill-to-keep-maine-veterans-housed/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Timothy E. Nangle / taxes=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'b8bac865-38a9-45f7-8641-ebdedf416f30', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'b8bac865-38a9-45f7-8641-ebdedf416f30', ct.id, $ctx$On Senate Roll Call #593 (6/16/2025), Nangle voted Yea to accept the majority "Ought to Pass as Amended" report on LD 1089, which would permanently fund 55% of the state's share of education by establishing a new tax on incomes over $1,000,000. Advancing a significant new tax targeted at the wealthiest earners specifically to expand public education funding matches stance 1 (significantly raise taxes on wealthy people and large companies to fund more public services).$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280097493&chamber=S&serialnumber=593','https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1089']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Timothy E. Nangle / trans-athletes=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'b8bac865-38a9-45f7-8641-ebdedf416f30', ct.id, 1.0 FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'b8bac865-38a9-45f7-8641-ebdedf416f30', ct.id, $ctx$Nangle voted Yea on Senate Roll Call #494 (6/12/2025) to accept the Judiciary Committee's "Ought Not to Pass" report on LD 1134, which would have required transgender athletes to compete only on teams matching their biological sex, helping kill the bill 21-14. He then voted Nay on Roll Call #586 (6/17/2025) against receding to the House's amended version of the similar LD 233 (barring trans athletes from girls' sports in state-funded programs), keeping that bill dead as well. Both individually recorded votes preserved Maine's status quo allowing transgender athletes to compete consistent with their gender identity without new restrictions, matching stance 1.$ctx$, ARRAY['https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280097524&chamber=S&serialnumber=494','https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280095881&chamber=S&serialnumber=586','https://legislature.maine.gov/LawMakerWeb/summary.asp?LD=1134']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Timothy E. Nangle / transportation-priorities=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'b8bac865-38a9-45f7-8641-ebdedf416f30', ct.id, 3.0 FROM inform.compass_topics ct WHERE ct.topic_key='transportation-priorities'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'b8bac865-38a9-45f7-8641-ebdedf416f30', ct.id, $ctx$As Transportation Committee chair, Nangle's March 2025 mainesenate.org release detailing MDOT's 2025-2027 work plan for his district shows the bulk of itemized investment going to road paving and bridge maintenance (e.g., a Route 202 roundabout, Woodlawn Bridge repairs), while pedestrian/bicycle infrastructure and rapid-transit planning are concentrated in the denser Westbrook/Gorham/Portland corridor rather than applied district-wide. This pattern of road-focused investment with transit and pedestrian additions layered in only where density supports them matches stance 3.$ctx$, ARRAY['https://www.mainesenate.org/sen-nangle-shares-2025-mdot-work-plan-for-state-bridge-and-road-projects/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='transportation-priorities'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Trey L. Stewart / abortion=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '9a76f4d8-61d0-4a4b-a5d2-cff71b608f05', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '9a76f4d8-61d0-4a4b-a5d2-cff71b608f05', ct.id, $ctx$Per the Maine Right to Life 2025 Senate scorecard (Trey L. Stewart's own recorded roll-call votes, 132nd Legislature), the senator voted FOR the MRTL-supported abortion restrictions, including LD 253 (barring the MaineCare program from covering abortion services) and LD 682 (narrowing legal abortion to a life-of-mother exception and reinstating criminal penalties), and against family-planning funding (LD 143). Narrowing legal abortion to a maternal-life-threat exception matches chair 4 (restrict abortion to cases of rape, incest, or serious threats to the mother's life).$ctx$, ARRAY['https://mainerighttolife.org/wp-content/uploads/2025/07/2025-132nd-Senate-Roll-Call.pdf','https://legislature.maine.gov/legis/bills/display_ps.asp?LD=253&snum=132']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Trey L. Stewart / medicare/aid=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '9a76f4d8-61d0-4a4b-a5d2-cff71b608f05', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '9a76f4d8-61d0-4a4b-a5d2-cff71b608f05', ct.id, $ctx$In a Mar. 10, 2026 press release announcing his own sponsored MaineCare integrity/sustainability legislation, Stewart said "MaineCare has a serious sustainability problem" and called for reducing fraud and requiring "healthy adults on the program" to "get off taxpayer-funded healthcare," proposing work/community-engagement requirements and an enrollment freeze/scale-down for able-bodied childless adults until a 10% reduction is reached. His Jan. 30, 2026 State-of-the-State response reinforced this: "As serious allegations of fraud continue to surface, Republicans believe accountability is not optional." This is a reduce-Medicaid-coverage position, matching chair 4.$ctx$, ARRAY['https://mesenategop.com/2026/03/10/sen-stewart-proposes-legislation-to-address-mainecare-integrity-and-sustainability-concerns/','https://mesenategop.com/2026/01/30/senate-republican-response-to-the-governors-state-of-the-state-address/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Trey L. Stewart / school-vouchers=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '9a76f4d8-61d0-4a4b-a5d2-cff71b608f05', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '9a76f4d8-61d0-4a4b-a5d2-cff71b608f05', ct.id, $ctx$In a Nov. 7, 2025 Senate Republican piece, Stewart (as interviewer/co-participant, speaking in his own voice) advocated adopting a federal fully-refundable tax credit for school choice that he said Maine is "missing out on because the Democrats haven't adopted it." This endorses expanding a tax-credit-funded choice mechanism broadly available to families (not means-tested), matching chair 4 ("Expanding voucher eligibility to most families... while maintaining baseline public school funding") rather than a full universal-voucher replacement of public funding (chair 5).$ctx$, ARRAY['https://mesenategop.com/2025/11/07/republican-vision-for-maine-improving-outcomes-and-increasing-choice-in-education/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- Trey L. Stewart / taxes=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '9a76f4d8-61d0-4a4b-a5d2-cff71b608f05', ct.id, 4.0 FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '9a76f4d8-61d0-4a4b-a5d2-cff71b608f05', ct.id, $ctx$Stewart, in his own words across three separate pieces, has repeatedly tied budget support to tax cuts: an Apr. 9, 2026 statement that Republicans "would not support a budget if it does not contain substantive tax relief for Mainers"; his Jan. 30, 2026 Senate Republican response to the Governor citing "no tax on tips, no tax on overtime, a higher standard deduction" and Maine's high property-tax ranking; and his own Nov. 3, 2024 op-ed stating Maine has "the highest property tax burden in the country" after Democrats "raised property taxes last session by repealing property relief for seniors." This consistently matches chair 4 (cut taxes, scale back services) rather than chair 5's call to "drastically cut taxes and shrink government."$ctx$, ARRAY['https://mesenategop.com/2026/04/09/legislative-democrats-continue-their-years-long-spending-spree/','https://mesenategop.com/2026/01/30/senate-republican-response-to-the-governors-state-of-the-state-address/','https://mesenategop.com/2024/11/03/we-do-not-have-to-live-like-this/']::text[] FROM inform.compass_topics ct WHERE ct.topic_key='taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

COMMIT;
