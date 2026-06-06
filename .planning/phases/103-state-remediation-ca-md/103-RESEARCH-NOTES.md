# Phase 103 — Research Notes (Plan 02 Pre-flight)

Generated: 2026-06-06 (Task 1 pre-flight)

---

## Scope

| Metric | Value |
|--------|-------|
| Total flagged CA politician count | 11 |
| Total flagged stance count | 18 (6 unsourced + 12 weak) |
| — unsourced_only | 3 politicians |
| — weak_only | 8 politicians |
| — both | 0 |

**No plan split required.** 11 politicians ≤ 25 threshold per 103-RESEARCH.md Plan 02 Sizing Guidelines. Single Plan 02 covers all 11.

Total flagged stance count = sum of affected_topic_keys across all CSV rows:
- Gavin Newsom: 4 (medicare/aid, redistricting, religious-freedom, same-sex-marriage)
- Juan Carrillo: 1 (childcare)
- Lisa Calderon: 1 (campaign-finance)
- Akilah Weber Pierson: 1 (fossil-fuels)
- Caroline Menjivar: 1 (homelessness)
- Catherine Stefani: 1 (immigration)
- Eloise Gómez Reyes: 3 (campaign-finance, religious-freedom, ukraine-support)
- Gregg Hart: 1 (homelessness)
- Henry Stern: 3 (religious-freedom, social-security, ukraine-support)
- Natasha Johnson: 1 (school-vouchers)
- Rob Bonta: 1 (ukraine-support)
Total: 4+1+1+1+1+1+3+1+3+1+1 = **18 flagged stances** ✓

---

## Politicians to Research

DB verification (live query 2026-06-06): All 11 politician_ids confirmed present in `essentials.politicians`, all `is_active = true`. Full_name values match CSV exactly — no middle-initial discrepancies.

| full_name (DB-canonical) | politician_id | district_type | party | affected_topic_keys | classification |
|--------------------------|---------------|---------------|-------|---------------------|----------------|
| Akilah Weber Pierson | e5470008-3c0d-4970-a485-053621d8f0a6 | STATE_UPPER | Democratic | fossil-fuels | weak_only |
| Caroline Menjivar | 4baa73c2-d38b-4d07-894f-1577d5ba43a3 | STATE_UPPER | Democratic | homelessness | weak_only |
| Catherine Stefani | 0649630c-bd6d-40fe-8f66-e026e6f6c83e | STATE_LOWER | Democratic | immigration | weak_only |
| Eloise Gómez Reyes | 1571da4a-b832-4792-917c-184c155b1700 | STATE_UPPER | Democratic | campaign-finance,religious-freedom,ukraine-support | weak_only |
| Gavin Newsom | f26309c8-2525-49b2-bdaf-62980cbb1853 | STATE_EXEC | Democratic | medicare/aid,redistricting,religious-freedom,same-sex-marriage | unsourced_only |
| Gregg Hart | 21940b7c-2424-47e9-a649-077b0f827c2c | STATE_LOWER | Democratic | homelessness | weak_only |
| Henry Stern | f3671de4-514f-441c-8ad4-4a9ab7c65ae6 | STATE_UPPER | Democratic | religious-freedom,social-security,ukraine-support | weak_only |
| Juan Carrillo | b959d608-5674-467e-a1c8-3572c76a729b | STATE_LOWER | Democratic | childcare | unsourced_only |
| Lisa Calderon | 0afa998d-94e9-4af4-ba00-256c38869398 | STATE_LOWER | Democratic | campaign-finance | unsourced_only |
| Natasha Johnson | 3f200d93-74aa-4191-a275-77b64ff5b219 | STATE_LOWER | Republican | school-vouchers | weak_only |
| Rob Bonta | 8b183a30-3afb-4d9e-aa40-aa2ad2c674aa | STATE_EXEC | Democratic | ukraine-support | weak_only |

**Note:** Gavin Newsom (f26309c8-2525-49b2-bdaf-62980cbb1853) confirmed as STATE_EXEC per Plan 01 pre-flight. Statewide executives in scope per CONTEXT.md D-02.

---

## Source-Append vs Overwrite Map

Per CONTEXT.md D-05: for pairs where an existing context row has non-empty sources (even homepage-only), use ARRAY_CAT in the migration ON CONFLICT clause. For pairs where the context row exists but sources = [] (empty), use PLAIN_OVERWRITE (no prior history to preserve).

Live DB verification query run 2026-06-06 against all 18 flagged (politician_id, topic_key) pairs:

| politician_id | topic_key | has_context_row | current_sources | migration_treatment |
|---------------|-----------|-----------------|-----------------|---------------------|
| f26309c8-2525-49b2-bdaf-62980cbb1853 | medicare/aid | yes | [] (empty) | PLAIN_OVERWRITE |
| f26309c8-2525-49b2-bdaf-62980cbb1853 | redistricting | yes | [] (empty) | PLAIN_OVERWRITE |
| f26309c8-2525-49b2-bdaf-62980cbb1853 | religious-freedom | yes | [] (empty) | PLAIN_OVERWRITE |
| f26309c8-2525-49b2-bdaf-62980cbb1853 | same-sex-marriage | yes | [] (empty) | PLAIN_OVERWRITE |
| b959d608-5674-467e-a1c8-3572c76a729b | childcare | yes | [] (empty) | PLAIN_OVERWRITE |
| 0afa998d-94e9-4af4-ba00-256c38869398 | campaign-finance | yes | [] (empty) | PLAIN_OVERWRITE |
| e5470008-3c0d-4970-a485-053621d8f0a6 | fossil-fuels | yes | [https://sd39.senate.ca.gov] | ARRAY_CAT |
| 4baa73c2-d38b-4d07-894f-1577d5ba43a3 | homelessness | yes | [https://sd20.senate.ca.gov/] | ARRAY_CAT |
| 0649630c-bd6d-40fe-8f66-e026e6f6c83e | immigration | yes | [https://sd22.senate.ca.gov/] | ARRAY_CAT |
| 1571da4a-b832-4792-917c-184c155b1700 | campaign-finance | yes | [https://sd29.senate.ca.gov] | ARRAY_CAT |
| 1571da4a-b832-4792-917c-184c155b1700 | religious-freedom | yes | [https://sd29.senate.ca.gov] | ARRAY_CAT |
| 1571da4a-b832-4792-917c-184c155b1700 | ukraine-support | yes | [https://sd29.senate.ca.gov] | ARRAY_CAT |
| 21940b7c-2424-47e9-a649-077b0f827c2c | homelessness | yes | [https://gregghart.org/] | ARRAY_CAT |
| f3671de4-514f-441c-8ad4-4a9ab7c65ae6 | religious-freedom | yes | [https://sd27.senate.ca.gov] | ARRAY_CAT |
| f3671de4-514f-441c-8ad4-4a9ab7c65ae6 | social-security | yes | [https://sd27.senate.ca.gov] | ARRAY_CAT |
| f3671de4-514f-441c-8ad4-4a9ab7c65ae6 | ukraine-support | yes | [https://sd27.senate.ca.gov] | ARRAY_CAT |
| 3f200d93-74aa-4191-a275-77b64ff5b219 | school-vouchers | yes | [https://natashajohnsonforassembly.com] | ARRAY_CAT |
| 8b183a30-3afb-4d9e-aa40-aa2ad2c674aa | ukraine-support | yes | [https://oag.ca.gov] | ARRAY_CAT |

**Summary:** 6 PLAIN_OVERWRITE (unsourced — empty sources array), 12 ARRAY_CAT (weak-sourced — homepage URL in sources, must preserve history per CONTEXT.md D-05).

---

## Live Stance Scale

**Fetched at:** 2026-06-06 (Task 1 pre-flight, SKILL.md Step 0 query)
**Live topic count: 44** (confirmed — matches SKILL.md update 2026-06-02)
**Query:** `SELECT t.id, t.topic_key, t.title, t.question_text, json_agg(...) AS stances FROM inform.compass_topics t JOIN inform.compass_stances s ON s.topic_id = t.id WHERE t.is_live = true GROUP BY ... ORDER BY t.topic_key`

```
abortion (id: af2fdfd6-02c4-49df-b09c-cf8536f4773f)
Question: "What legal framework should govern abortion access?"
  1 = "ensure abortion is legal, accessible, and publicly funded at all stages of pregnancy."
  2 = "keep abortion legal and accessible through the second trimester with rare exceptions afterward."
  3 = "allow abortion in the first trimester and in cases of rape, incest, or maternal health risks."
  4 = "restrict abortion to only cases involving rape, incest, or serious threats to the mother's life."
  5 = "ban abortion completely with no exceptions and impose criminal penalties for providers and patients."

ai-regulation (id: 666bf03d-81fc-4138-ab15-69ae734c9023)
Question: "How much should government oversee artificial intelligence development and deployment?"
  1 = "Allow AI companies to develop and deploy technology freely without government interference"
  2 = "Suggest AI safety guidelines but let companies choose whether to follow them"
  3 = "Require AI developers to disclose risks and be held responsible when their systems cause harm"
  4 = "Require safety testing and ban high-risk AI uses in areas like hiring, healthcare, and policing"
  5 = "Impose strict approval requirements and ban AI systems that could cause serious harm"

campaign-finance (id: 92730f69-ae57-401c-8ad1-2d07834a895d)
Question: "What rules should govern money in political campaigns and elections?"
  1 = "ban all private money in politics and publicly fund campaigns"
  2 = "strictly limit corporate donations and dark money groups"
  3 = "require full disclosure of all political donations"
  4 = "reduce restrictions on political donations and spending"
  5 = "eliminate all campaign finance laws and limits"

childcare (id: c1ac1330-47f7-44ec-baf3-c913d926b97c)
Question: "How should government address the cost and availability of childcare?"
  1 = "Establishing publicly funded universal childcare so that all families have access regardless of income"
  2 = "Significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families"
  3 = "Offering targeted tax credits and subsidies for families below a set income threshold while supporting providers through training and facility grants"
  4 = "Reducing regulations on childcare providers to increase supply and lower costs, with limited subsidies reserved for the lowest-income families"
  5 = "Leaving childcare to the private market and families, with no government subsidies or mandates that increase costs for providers and taxpayers"

city-sanitation (id: 7687de4f-4d0b-462a-b803-bdfb23b16b42)
Question: "How should your city approach street cleanliness and sanitation?"
  1 = "Significantly expand sanitation staffing, cleaning frequency, and free community disposal access; treat poor conditions as a services failure"
  2 = "Increase sanitation crews and prioritize historically underserved neighborhoods to equalize cleanliness citywide"
  3 = "Maintain current sanitation services while enforcing anti-dumping laws for businesses and large property owners"
  4 = "Rely primarily on enforcement of anti-littering and property maintenance laws; hold residents and businesses responsible"
  5 = "Privatize sanitation services and require residents and businesses to contract for cleanup directly"

civil-rights (id: 0bc588c6-39e1-4084-b5de-cac909b8b762)
Question: "What role should government play in addressing racial and social inequality?"
  1 = "mandate racial equity requirements in all institutions and provide reparations"
  2 = "strengthen civil rights enforcement and address systemic discrimination"
  3 = "maintain current civil rights laws while promoting equal opportunity"
  4 = "limit federal civil rights enforcement to clear cases of discrimination"
  5 = "eliminate affirmative action and all race-based government programs"

climate-change (id: f1e44d66-5d27-4b51-b54f-b7ace86f6a3c)
Question: "What priority should climate change receive in energy and economic policy?"
  1 = "declare a climate emergency and ban all activities that increase carbon emissions"
  2 = "rapidly transition to renewable energy and phase out fossil fuels by 2030"
  3 = "invest in clean energy while gradually reducing reliance on fossil fuels"
  4 = "let market forces drive any transition to cleaner energy sources"
  5 = "reject climate change policies and focus on economic growth instead"

data-centers (id: 4559b513-0fd8-4ed1-babd-f3b554162f40)
Question: "How should government manage the growth of large-scale data centers?"
  1 = "Imposing a moratorium on new data center construction until energy infrastructure can support demand without raising costs for residential ratepayers"
  2 = "Requiring data centers to fund their own dedicated power generation and barring utilities from passing data center infrastructure costs to residential customers"
  3 = "Allowing data center development with impact assessments, energy cost-sharing agreements, and community benefit requirements before approval"
  4 = "Encouraging data center development through streamlined permitting while requiring transparency about projected energy demand and rate impacts"
  5 = "Welcoming data center investment with competitive incentives and minimal regulatory barriers, trusting that economic growth and tax revenue will benefit all residents"

deportation (id: 44905f3b-e105-4f6c-afc7-5d223813dbac)
Question: "Who should be deported, and how aggressively?"
  1 = "Stop deportations entirely and protect undocumented residents from removal"
  2 = "Only deport people convicted of serious violent crimes"
  3 = "Focus deportation on recent arrivals while leaving long-term residents in place"
  4 = "Deport everyone without legal status, starting with those who have criminal records"
  5 = "Move quickly to deport all undocumented people regardless of how long they've lived here or family ties"

economic-development (id: eb3d1247-0de1-4b7f-baec-7259861efd53)
Question: "How should your city attract businesses and support economic development?"
  1 = "No corporate tax incentives; invest in public services and infrastructure to attract business organically"
  2 = "Small business support and local entrepreneur programs only; avoid large corporate subsidies"
  3 = "Targeted incentives for specific industries with community benefit agreements and job quality requirements"
  4 = "Compete actively for major employers with significant tax abatements and infrastructure investment"
  5 = "Offer maximum incentives to attract any large employer; economic growth is the top city priority"

fossil-fuels (id: a22215c3-6693-4bc2-b248-01aebba14570)
Question: "What role should fossil fuels play in the nation's energy future?"
  1 = "immediately ban all new fossil fuel drilling and extraction"
  2 = "stop issuing new permits for fossil fuel drilling"
  3 = "maintain current levels of fossil fuel production with existing environmental regulations"
  4 = "expand fossil fuel drilling permits"
  5 = "remove environmental restrictions and maximize fossil fuel extraction"

growth-and-development (id: fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4)
Question: "How should your city manage population growth and new development?"
  1 = "Impose growth limits; require voter approval for major annexations or large-scale developments"
  2 = "Allow growth only where existing infrastructure can support it; slow approvals until capacity catches up"
  3 = "Plan proactively — invest in infrastructure ahead of growth to support responsible expansion"
  4 = "Streamline permitting, reduce fees, and actively recruit development to grow the city's tax base"
  5 = "Remove regulatory barriers to development entirely; let market demand determine growth pace"

healthcare (id: e8dad4a8-eb93-4931-91f5-d8fb5d7dd529)
Question: "What role should government play in healthcare access?"
  1 = "Make healthcare free and available to everyone, paid for and run by the public sector"
  2 = "Make sure everyone has affordable coverage through a mix of public programs and regulated private insurance"
  3 = "Help people who can't afford care and expand programs for seniors and low-income residents, while keeping private insurance for everyone else"
  4 = "Only help the poorest people afford healthcare and leave everyone else to employers and private insurance"
  5 = "Stay out of healthcare entirely and let private markets handle all coverage decisions"

homelessness (id: 4938766b-b45a-46e3-93bd-b8b30651271a)
Question: "How should government address people sleeping or camping in public spaces?"
  1 = "Protecting the right to sleep in public spaces and redirecting enforcement budgets toward permanent supportive housing and mental health services"
  2 = "Decriminalizing public sleeping while investing in shelter capacity, outreach workers, and voluntary service connections"
  3 = "Allowing enforcement only when adequate shelter beds are available, with citations diverting people to services rather than the criminal justice system"
  4 = "Prohibiting encampments on public property with graduated warnings and penalties, while requiring jurisdictions to maintain basic shelter options"
  5 = "Banning public camping and sleeping with criminal penalties to maintain public safety and order, relying on existing social services for those who seek help"

homelessness-response (id: 6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f)
Question: "What should be your city's primary strategy for addressing homelessness?"
  1 = "Housing-first: provide permanent supportive housing with no preconditions; avoid criminalization entirely"
  2 = "Expand shelter capacity and services as the primary strategy; use enforcement only after services are offered"
  3 = "Invest in outreach, shelter, and mental health services while enforcing reasonable public space rules"
  4 = "Enforce anti-camping ordinances as the primary tool while maintaining basic outreach programs"
  5 = "Prioritize strict enforcement of trespassing and camping bans; minimize city spending on homeless services"

housing (id: 669cac97-66a6-4087-b036-936fbe62efb3)
Question: "What role should government play in making sure people can afford housing?"
  1 = "Directly build and operate public housing so anyone who needs a home can get one"
  2 = "Use rent caps, require new developments to include affordable units, and publicly fund new housing"
  3 = "Offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits"
  4 = "Cut regulations and zoning rules so private developers can build more housing"
  5 = "Stay out of housing entirely and let the market decide prices and supply"

immigration (id: 4e2c69ce-591e-4197-9cd5-7aceff79d390)
Question: "How welcoming or restrictive should government be toward immigrants?"
  1 = "Make it easier for immigrants to come here legally, and let all immigrants — including undocumented residents — fully use public services"
  2 = "Keep legal immigration open and let most residents use public services regardless of legal status"
  3 = "Keep immigration levels and rules about where they are now"
  4 = "Make it harder to immigrate legally and limit public services to people with legal status"
  5 = "Stop most legal immigration and block public services for anyone without legal status"

jail-capacity (id: c267e137-0ff9-4e7d-9d13-e3cea1756cd0)
Question: "How should government respond to jail overcrowding and criminal justice demand?"
  1 = "Redirecting incarceration funding into community-based mental health, addiction, housing, and restorative justice programs to shrink the jail system"
  2 = "Reducing the incarcerated population through pretrial diversion, bail reform, and treatment alternatives rather than building new capacity"
  3 = "Upgrading jail facilities only as needed to meet constitutional standards, without expanding overall capacity"
  4 = "Building additional jail capacity to address overcrowding and facility deficiencies"
  5 = "Expanding jail capacity and enforcement as the primary response to crime, prioritizing detention over alternatives"

judicial-access-to-justice (id: 9d45acaf-1ba4-4cb8-95e1-5ed985223b91)
Question: "Should it be easy or hard to take someone to court?"
  1 = "Easy. Courts exist for everyone — not just people with expensive lawyers. Low barriers mean more access to justice."
  2 = "Accessible. Some basic requirements are fine, but courts shouldn't be a maze that only the wealthy can navigate."
  3 = "Reasonable standards that keep out frivolous cases without blocking legitimate ones."
  4 = "Higher bars are fine. Too much litigation clogs the system and costs everyone money."
  5 = "Hard. Most disputes should be settled privately. Courts should be a last resort, not a first option."

judicial-bail-pretrial (id: 1fab5edf-6151-4da0-9704-a7f2113ba54c)
Question: "Should a judge trust what prosecutors say, or watch them closely?"
  1 = "Watch closely. Prosecutors have enormous power and real incentives to win. A judge's job is to make sure that power is used fairly."
  2 = "Be skeptical. Hold prosecution to strict standards — especially on evidence handling and plea deals."
  3 = "Treat both sides equally and let the process work."
  4 = "Give prosecutors reasonable deference. They're trained professionals representing the public."
  5 = "Trust prosecutors. They represent the community and have already screened the case — judges shouldn't second-guess that judgment."

judicial-criminal-justice (id: 9db07b16-1076-4b7d-ad89-ebe7b51f4336)
Question: "When someone breaks the law, what matters most?"
  1 = "Helping the person change their life and stay out of trouble in the future."
  2 = "Giving the person a fair chance to make things right — through treatment, community service, or restitution."
  3 = "A mix: some accountability, some support, depending on what happened."
  4 = "Making sure others think twice before doing the same thing."
  5 = "Punishing the behavior. Society needs to know that breaking the law has real consequences."

judicial-government-deference (id: e5e48f0e-8f3a-40e1-8080-889fea389603)
Question: "When government and a citizen clash, who gets the benefit of the doubt?"
  1 = "The citizen, almost always. Government has lawyers, money, and power. Regular people need courts to level the playing field."
  2 = "The citizen usually — unless the government has clear legal authority on its side."
  3 = "Neither side automatically. Look at the facts and apply the law evenly."
  4 = "The government usually — it represents everyone, and its decisions deserve respect unless clearly wrong."
  5 = "The government, unless it has obviously overreached. Officials make decisions for good reasons — courts shouldn't second-guess them constantly."

judicial-interpretation (id: 448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee)
Question: "Does the law change with the times, or does it mean what it said when it was written?"
  1 = "Courts should reconsider old rulings when we know more or society has changed. Keeping bad precedent alive is its own injustice."
  2 = "Laws were written for a purpose. When the exact words don't fit a new situation, look at what the law was trying to accomplish."
  3 = "Follow the text closely, but use some common sense about what lawmakers were trying to do."
  4 = "The law means what it says. Use original intent to fill gaps, but don't stretch the meaning."
  5 = "A judge's job is to apply the law as written — not rewrite it. If society has changed, pass a new law. That's what elections are for."

judicial-police-accountability (id: 7bad33eb-e93e-4d94-8822-97212d49bde5)
Question: "When city employees do wrong, does the office defend them or hold them accountable?"
  1 = "Investigate independently. The office works for the public — not the officials it's supposed to keep accountable."
  2 = "Settle valid claims quickly and pursue real accountability. Defending misconduct wastes money and public trust."
  3 = "Represent the city fairly while acknowledging when claims have merit."
  4 = "Defend city employees vigorously. That's the job. Settlements invite more lawsuits."
  5 = "The client is the city government. Defending its employees and decisions — aggressively when needed — is the core function."

judicial-prosecution-priorities (id: abb99d95-cbb1-4617-8f8b-f220ef6028ca)
Question: "Does the office try to put people away, or find better solutions?"
  1 = "Prosecution should be a last resort. Connecting people to treatment, housing, or job programs does more good than a criminal record."
  2 = "Use diversion when it's available and makes sense. Reserve prosecution for when community safety actually requires it."
  3 = "Strong cases get prosecuted. Diversion is used when there's a clear benefit — it's a judgment call every time."
  4 = "Prosecute all solid cases. Declination is the exception and needs a strong reason."
  5 = "The office enforces the law — not social policy. If a case is prosecutable, prosecute it. Courts figure out the rest."

judicial-transparency (id: 6674d87e-999d-433a-aab7-3f626f59fd5f)
Question: "How much should the public know about what happens in court?"
  1 = "Everything possible should be public — hearings, evidence, rulings, and the reasoning behind them. Secrecy breeds injustice."
  2 = "Default to open proceedings. Sealing records or closing hearings requires a compelling, documented reason."
  3 = "Balance openness with legitimate needs for privacy — protect victims, seal juvenile records, but keep the courtroom open as a rule."
  4 = "Courts should protect sensitive information broadly — personal details, ongoing investigations, and anything that could prejudice a fair trial."
  5 = "The law is complicated. Public access to proceedings can distort outcomes. Broad judicial discretion to limit access protects the integrity of the process."

local-environment (id: 1935979c-b290-42e4-baa5-8cb0138b4ffa)
Question: "How should your city balance new development with environmental preservation?"
  1 = "Require significant green space, tree preservation, and environmental review before approving any development"
  2 = "Protect existing parks and tree canopy strictly; require developers to fully offset any environmental impact"
  3 = "Apply consistent environmental standards while giving developers reasonable flexibility on implementation"
  4 = "Allow developers to pay fees in lieu of on-site preservation; prioritize economic activity over green space"
  5 = "Remove local environmental restrictions beyond what state and federal law requires"

local-immigration (id: b9ccee94-ad96-4f10-b655-889d8e5abe92)
Question: "How should your city's police department relate to federal immigration enforcement?"
  1 = "Refuse all ICE detainers; prohibit city employees from sharing immigration status information with federal agencies"
  2 = "Comply only with court-ordered detainers; protect undocumented crime victims and witnesses from referral"
  3 = "Follow federal law as required but do not use city resources for proactive immigration enforcement"
  4 = "Honor ICE detainers and share information proactively when federal agencies request it"
  5 = "Direct city police to actively assist with immigration enforcement and support federal detention operations"

medicare/aid (id: cab61e8a-64fe-4bbd-bc08-fe9914d0091b)
Question: "How should Medicare and Medicaid be funded and structured?"
  1 = "expand Medicare to cover everyone regardless of age"
  2 = "lower Medicare age to 55 and expand Medicaid significantly"
  3 = "improve current programs while controlling costs"
  4 = "partially privatize Medicare and reduce Medicaid coverage"
  5 = "phase out both programs and use private insurance only"

misinformation (id: ddd65d64-9dc7-4208-a30f-59f4b9c0653d)
Question: "What responsibility do platforms and government have in combating online misinformation?"
  1 = "require platforms to remove all false information and regulate algorithms"
  2 = "mandate fact-checking and transparency in how algorithms promote content"
  3 = "encourage voluntary standards for combating misinformation online"
  4 = "protect free speech online and prevent government censorship"
  5 = "ban any government involvement in content moderation decisions"

public-safety-approach (id: e9ebefcd-c496-45e8-b816-a79f8442ba85)
Question: "How should your city fund and operate public safety services?"
  1 = "Redirect a significant portion of the police budget to social services, mental health, and community programs"
  2 = "Maintain current police staffing but shift non-violent calls to unarmed mental health co-responders"
  3 = "Keep current public safety funding while adding crisis response teams for mental health and addiction calls"
  4 = "Increase police staffing, equipment, and pay to improve response times and deter crime"
  5 = "Make expanding the police budget the top city spending priority over other municipal services"

redistricting (id: 48cc9585-ec22-4f53-8d42-6839828dd36f)
Question: "Who should draw electoral district boundaries and how should they be determined?"
  1 = "independent citizens' commissions with no elected officials involved at any level."
  2 = "independent redistricting commissions with equal representation from both major parties."
  3 = "bipartisan legislative committees with strict rules requiring supermajority approval."
  4 = "state legislatures with court oversight to prevent extreme partisan bias."
  5 = "the party that controls the state legislature without outside interference."

religious-freedom (id: 6b9ba6d9-1001-43f5-b073-4d37130696fd)
Question: "What role should religion play in government, public institutions, and policymaking?"
  1 = "strictly separate religion from all public institutions and prohibit religious exemptions from civil rights laws."
  2 = "protect religious freedom while ensuring it doesn't override anti-discrimination protections in employment and housing."
  3 = "balance protecting religious practices with maintaining equal treatment under the law for all citizens."
  4 = "protect religious freedom and allow faith-based exemptions from laws that conflict with sincere religious beliefs."
  5 = "strongly protect religious freedom and allow religious organizations complete autonomy in their operations and hiring practices."

rent-regulation (id: c308e8e8-caac-44f5-ab04-dbfecf40bbe2)
Question: "What role should your city play in regulating rents and protecting tenants?"
  1 = "Expand rent control to all rental units with strong tenant protections and just-cause eviction requirements"
  2 = "Strengthen existing rent stabilization and extend coverage to more units"
  3 = "Maintain current tenant protections while allowing market rents for new construction"
  4 = "Limit rent regulations to subsidized units; allow market rents broadly"
  5 = "Oppose rent control entirely; rents should be set by the market without government intervention"

residential-zoning (id: d4f18138-a2e0-4110-b925-7387d9d0d16d)
Question: "What should guide decisions about housing density and neighborhood character in your city?"
  1 = "Protect existing neighborhood character strictly; require community votes before any rezoning"
  2 = "Allow modest density increases (duplexes, accessory units) with strong design review and neighborhood input"
  3 = "Allow multifamily and mixed-use near commercial corridors while protecting most residential zones"
  4 = "Upzone broadly to allow multifamily by right; streamline approvals and reduce parking requirements"
  5 = "Eliminate single-family-only zoning; allow any housing type on any lot citywide"

same-sex-marriage (id: c5ab4eab-702f-49b8-9277-8ea53f3835c6)
Question: "What legal recognition should same-sex marriages receive?"
  1 = "require all states to recognize same-sex marriages and provide full federal benefits and protections."
  2 = "allow same-sex marriage nationwide while protecting some organizations' right to decline participation."
  3 = "let each state decide its own same-sex marriage laws without federal interference."
  4 = "recognize civil unions for same-sex couples but reserve marriage for opposite-sex couples."
  5 = "make same-sex marriage illegal and define marriage as only between one man and one woman."

school-vouchers (id: 00b95a6a-75db-4521-b523-3326bba938de)
Question: "What role should vouchers and school choice play in the public education system?"
  1 = "Fully funding public schools and eliminating voucher programs that divert taxpayer money to private institutions"
  2 = "Prioritizing public school funding while restricting vouchers to low-income families who lack adequate local options"
  3 = "Funding public schools at current levels while allowing means-tested voucher programs with accountability requirements for participating private schools"
  4 = "Expanding voucher eligibility to most families so parents can choose the school that best fits their child, while maintaining baseline public school funding"
  5 = "Providing universal vouchers so that education funding follows the student to any school — public, private, or religious — chosen by the family"

social-security (id: 87d20824-a6e9-407b-983c-65440084a0ab)
Question: "How should Social Security be funded and structured for the future?"
  1 = "expand Social Security benefits significantly and remove the income cap on payroll taxes to fund it."
  2 = "increase Social Security benefits modestly while raising taxes on higher earners to strengthen the program."
  3 = "make small adjustments to both benefits and taxes to keep Social Security stable for future generations."
  4 = "gradually raise the retirement age and reduce benefits for higher earners to save Social Security."
  5 = "transition Social Security to private investment accounts that individuals control themselves."

tariffs (id: 683c8084-2281-4920-a07c-18439b2dd413)
Question: "How should trade policy balance domestic industry with global commerce?"
  1 = "eliminate all tariffs and pursue completely free trade with every country."
  2 = "reduce most tariffs while keeping some on products that harm the environment."
  3 = "use tariffs selectively to protect key American industries and jobs."
  4 = "increase tariffs on countries that don't trade fairly with America."
  5 = "impose high tariffs on all imports to bring manufacturing back to America."

taxes (id: f7e5678d-dadd-4556-a2fc-446e24642ceb)
Question: "How should government balance what it collects in taxes against what it spends on public services?"
  1 = "Significantly raise taxes on wealthy people and large companies to fund more public services"
  2 = "Moderately raise taxes on wealthy people and large companies to fund existing services"
  3 = "Keep the current tax system mostly as-is with small adjustments to close unfair loopholes"
  4 = "Cut taxes for everyone and scale back public services to match"
  5 = "Drastically cut taxes and shrink government so people and businesses keep more of their money"

trans-athletes (id: d1618b9c-0b9e-45af-b986-bb33d270b8e4)
Question: "How should sports leagues determine eligibility for transgender athletes?"
  1 = "allow all transgender athletes to compete on teams matching their gender identity without any restrictions or requirements."
  2 = "should allow transgender athletes to compete on teams matching their gender identity after completing basic documentation of their transition."
  3 = "create separate transgender divisions or allow case-by-case decisions based on individual circumstances and sport requirements."
  4 = "require transgender athletes to compete only on teams matching their biological sex assigned at birth."
  5 = "completely ban all transgender athletes from competing in any organized sports competitions."

transportation-priorities (id: ba59337e-30e2-4aba-a39a-426b3366eb27)
Question: "Where should your city focus its transportation investment?"
  1 = "Prioritize pedestrian infrastructure, cycling networks, and public transit; reduce parking requirements citywide"
  2 = "Invest equally in roads and multimodal options; require bike lanes and sidewalks on all new road projects"
  3 = "Maintain roads while selectively adding transit connections and pedestrian improvements where density supports it"
  4 = "Focus on road capacity and traffic flow; transportation investment should serve the majority who drive"
  5 = "Prioritize highway access and abundant free parking as the foundation of local transportation policy"

ukraine-support (id: 24e9212c-b011-422a-865c-093e35050901)
Question: "What level of military and financial support should be provided to Ukraine?"
  1 = "significantly increase military aid to Ukraine and commit to supporting them until complete victory over Russia"
  2 = "continue providing current levels of military and economic aid to help Ukraine defend itself."
  3 = "provide limited humanitarian aid to Ukraine while encouraging diplomatic negotiations to end the war."
  4 = "reduce aid to Ukraine and focus American resources on domestic priorities instead."
  5 = "end all aid to Ukraine immediately and stay completely out of the conflict."

voting-rights (id: d1792200-1d3b-4955-a0b7-0e6980d7a7b2)
Question: "How should voter access be balanced with election security?"
  1 = "automatically register all eligible citizens to vote and allow online voting"
  2 = "expand early voting periods and make mail-in voting available to all voters without requiring an excuse"
  3 = "standardize voter ID requirements while ensuring free IDs are available to all eligible citizens"
  4 = "require photo ID for voting and regularly update voter rolls to remove inactive registrations"
  5 = "mandate in-person voting with strict photo ID and eliminate mail-in voting except for military overseas"
```

---

## Migration Number

**DEVIATION from plan:** Plan 02 assumed MAX(version) = 269. Live DB query returned **MAX(version) = 277** (additional migrations were applied between Phase 102 close and Phase 103 Plan 02 execution).

- Live MAX(version) at pre-flight: **277**
- Next available migration number: **278**
- Migration filename to use: `supabase/migrations/20260606000003_278_ca_state_source_remediation.sql`
- Date prefix: 20260606000003 (one-greater-than 20260606000002, the Phase 102 House migration)

**ABORT condition:** If at Task 3 write time, MAX(version) is ≥ 278, abort and surface the conflict. Re-verify at write time per 103-RESEARCH.md Pitfall 3.

---

## Dispatch Plan

**ONE researcher agent at a time, max 2 concurrent — never batch CA politicians into a single agent prompt.** Per MEMORY.md rate-limit feedback: mass launches cause rate limit hits with empty output.

Default is ONE at a time. Only run 2 in parallel if explicitly requested by operator, accepting the rate-limit risk. This plan uses sequential dispatch (one at a time).

**Dispatch order: alphabetical by full_name (DB-canonical).**

| Order | full_name | politician_id | district_type | topics in scope | agent #|
|-------|-----------|---------------|---------------|-----------------|--------|
| 1 | Akilah Weber Pierson | e5470008-3c0d-4970-a485-053621d8f0a6 | STATE_UPPER | fossil-fuels | Agent 1 |
| 2 | Caroline Menjivar | 4baa73c2-d38b-4d07-894f-1577d5ba43a3 | STATE_UPPER | homelessness | Agent 2 |
| 3 | Catherine Stefani | 0649630c-bd6d-40fe-8f66-e026e6f6c83e | STATE_LOWER | immigration | Agent 3 |
| 4 | Eloise Gómez Reyes | 1571da4a-b832-4792-917c-184c155b1700 | STATE_UPPER | campaign-finance,religious-freedom,ukraine-support | Agent 4 |
| 5 | Gavin Newsom | f26309c8-2525-49b2-bdaf-62980cbb1853 | STATE_EXEC | medicare/aid,redistricting,religious-freedom,same-sex-marriage | Agent 5 |
| 6 | Gregg Hart | 21940b7c-2424-47e9-a649-077b0f827c2c | STATE_LOWER | homelessness | Agent 6 |
| 7 | Henry Stern | f3671de4-514f-441c-8ad4-4a9ab7c65ae6 | STATE_UPPER | religious-freedom,social-security,ukraine-support | Agent 7 |
| 8 | Juan Carrillo | b959d608-5674-467e-a1c8-3572c76a729b | STATE_LOWER | childcare | Agent 8 |
| 9 | Lisa Calderon | 0afa998d-94e9-4af4-ba00-256c38869398 | STATE_LOWER | campaign-finance | Agent 9 |
| 10 | Natasha Johnson | 3f200d93-74aa-4191-a275-77b64ff5b219 | STATE_LOWER | school-vouchers | Agent 10 |
| 11 | Rob Bonta | 8b183a30-3afb-4d9e-aa40-aa2ad2c674aa | STATE_EXEC | ukraine-support | Agent 11 |

**Output file for all agents:** `backend/data/stance-research/2026-06-06-ca-state-remediation.csv`

Each agent appends to the same file. After every agent completes, run:
`grep -c "^full_name,topic_key" backend/data/stance-research/2026-06-06-ca-state-remediation.csv`
Must always return 1 (exactly one header row).

**City-level topic note:** The affected_topic_keys list for CA politicians does NOT include city-level topics (homelessness topic IS the state-level "Criminalization of Homelessness" topic with ID 4938766b, NOT the city-level "homelessness-response" topic 6fbf39ae). Per 103-RESEARCH.md Pitfall 6: for existing stances, city-level skip rule does NOT apply — research must either find a real source or flag for deletion. No stances in the target list are on true city-only topics (transportation-priorities, economic-development, etc.).

---

## Task 2 Research Logs (per-politician)

*To be populated as each agent completes. One subsection per politician.*

---

*Phase: 103-state-remediation-ca-md*
*Pre-flight generated: 2026-06-06*
