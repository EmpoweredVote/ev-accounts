# Phase 102 — Research Notes

Generated: 2026-06-06 (Plan 02 Task 1 pre-flight)

---

## Scope

| Metric | Value |
|--------|-------|
| Total flagged candidate count | 3 |
| Total weak stances | 19 (Dooley 6 + Shoffner 5 + Alme 8) |
| Classification breakdown | all weak_only — none have unsourced stances per Plan 01 |
| — unsourced_only | 0 |
| — weak_only | 3 candidates |
| — both | 0 |

All 3 candidates have stance context rows with at least one non-blank URL (homepage-only). None have missing context rows. The remediation task is to upgrade each weak source to a specific (non-homepage) URL, or delete the stance if no real source is found.

---

## Candidates to Research

| full_name | politician_id (UUID) | state | party | affected_topic_keys |
|-----------|---------------------|-------|-------|---------------------|
| Derek Dooley | b841a475-41b4-4f19-9ad1-13769b1f4eef | GA | Republican | abortion, civil-rights, climate-change, healthcare, immigration, voting-rights |
| Hallie Shoffner | a7307f34-90ca-4d29-8698-4898ed3de05c | AR | Democratic | campaign-finance, climate-change, economic-development, housing, taxes |
| Kurt Alme | 0f8bb5ea-8d89-4cfb-9291-04b54c128b82 | MT | Republican | abortion, fossil-fuels, religious-freedom, same-sex-marriage, social-security, tariffs, trans-athletes, voting-rights |

**DB verification (live query 2026-06-06):**
- All 3 politician_ids confirmed present in `essentials.politicians`
- All 3 are `is_active = true`, `is_incumbent = false`
- DB `full_name` values match the CSV exactly: "Derek Dooley", "Hallie Shoffner", "Kurt Alme" — no middle-initial discrepancies

**Note on Kurt Alme:** The DB contains 13 total stance rows for Alme. Only 8 are homepage-only. The remaining 5 have both homepage AND a real specific source URL — those 5 are NOT in the affected_topic_keys list and must NOT be re-researched. Research scope is strictly the 8 homepage-only topics listed above (102-RESEARCH.md Assumption A4).

---

## Special-Case Topics

**Hallie Shoffner — `economic-development` topic inclusion:**

The SKILL.md city-level skip list includes `economic-development`. However, that skip rule applies to **new stance creation** for state/federal candidates. Shoffner already has an existing `economic-development` stance (value=2, source=https://www.hallieshoffner.com — homepage-only). This is a **remediation** scenario: the existing stance must be either upgraded to a real specific source URL or deleted if no real source is found. Per 102-RESEARCH.md Open Question 2 resolution: include `economic-development` in Shoffner's research agent topic list.

---

## Live Stance Scale

**Fetched at:** 2026-06-06 (Task 1 pre-flight)
**Query:** SKILL.md Step 0 — `inform.compass_topics JOIN inform.compass_stances WHERE is_live = true AND topic_key = ANY(...)` (16 topics relevant to the 3 candidates)
**Topic count in scope:** 16 distinct topics across 3 candidates

```json
[
  {
    "id": "af2fdfd6-02c4-49df-b09c-cf8536f4773f",
    "topic_key": "abortion",
    "title": "Reproductive Rights and Abortion Access",
    "question_text": "What legal framework should govern abortion access?",
    "stances": [
      {"value": 1, "text": "ensure abortion is legal, accessible, and publicly funded at all stages of pregnancy."},
      {"value": 2, "text": "keep abortion legal and accessible through the second trimester with rare exceptions afterward."},
      {"value": 3, "text": "allow abortion in the first trimester and in cases of rape, incest, or maternal health risks."},
      {"value": 4, "text": "restrict abortion to only cases involving rape, incest, or serious threats to the mother's life."},
      {"value": 5, "text": "ban abortion completely with no exceptions and impose criminal penalties for providers and patients."}
    ]
  },
  {
    "id": "92730f69-ae57-401c-8ad1-2d07834a895d",
    "topic_key": "campaign-finance",
    "title": "Campaign Finance Reform",
    "question_text": "What rules should govern money in political campaigns and elections?",
    "stances": [
      {"value": 1, "text": "ban all private money in politics and publicly fund campaigns"},
      {"value": 2, "text": "strictly limit corporate donations and dark money groups"},
      {"value": 3, "text": "require full disclosure of all political donations"},
      {"value": 4, "text": "reduce restrictions on political donations and spending"},
      {"value": 5, "text": "eliminate all campaign finance laws and limits"}
    ]
  },
  {
    "id": "0bc588c6-39e1-4084-b5de-cac909b8b762",
    "topic_key": "civil-rights",
    "title": "Civil Rights and Social Justice",
    "question_text": "What role should government play in addressing racial and social inequality?",
    "stances": [
      {"value": 1, "text": "mandate racial equity requirements in all institutions and provide reparations"},
      {"value": 2, "text": "strengthen civil rights enforcement and address systemic discrimination"},
      {"value": 3, "text": "maintain current civil rights laws while promoting equal opportunity"},
      {"value": 4, "text": "limit federal civil rights enforcement to clear cases of discrimination"},
      {"value": 5, "text": "eliminate affirmative action and all race-based government programs"}
    ]
  },
  {
    "id": "f1e44d66-5d27-4b51-b54f-b7ace86f6a3c",
    "topic_key": "climate-change",
    "title": "Climate Change and Environmental Protection",
    "question_text": "What priority should climate change receive in energy and economic policy?",
    "stances": [
      {"value": 1, "text": "declare a climate emergency and ban all activities that increase carbon emissions"},
      {"value": 2, "text": "rapidly transition to renewable energy and phase out fossil fuels by 2030"},
      {"value": 3, "text": "invest in clean energy while gradually reducing reliance on fossil fuels"},
      {"value": 4, "text": "let market forces drive any transition to cleaner energy sources"},
      {"value": 5, "text": "reject climate change policies and focus on economic growth instead"}
    ]
  },
  {
    "id": "eb3d1247-0de1-4b7f-baec-7259861efd53",
    "topic_key": "economic-development",
    "title": "Economic Development Incentives",
    "question_text": "How should your city attract businesses and support economic development?",
    "stances": [
      {"value": 1, "text": "No corporate tax incentives; invest in public services and infrastructure to attract business organically"},
      {"value": 2, "text": "Small business support and local entrepreneur programs only; avoid large corporate subsidies"},
      {"value": 3, "text": "Targeted incentives for specific industries with community benefit agreements and job quality requirements"},
      {"value": 4, "text": "Compete actively for major employers with significant tax abatements and infrastructure investment"},
      {"value": 5, "text": "Offer maximum incentives to attract any large employer; economic growth is the top city priority"}
    ]
  },
  {
    "id": "a22215c3-6693-4bc2-b248-01aebba14570",
    "topic_key": "fossil-fuels",
    "title": "Fossil Fuel Policy",
    "question_text": "What role should fossil fuels play in the nation's energy future?",
    "stances": [
      {"value": 1, "text": "immediately ban all new fossil fuel drilling and extraction"},
      {"value": 2, "text": "stop issuing new permits for fossil fuel drilling"},
      {"value": 3, "text": "maintain current levels of fossil fuel production with existing environmental regulations"},
      {"value": 4, "text": "expand fossil fuel drilling permits"},
      {"value": 5, "text": "remove environmental restrictions and maximize fossil fuel extraction"}
    ]
  },
  {
    "id": "e8dad4a8-eb93-4931-91f5-d8fb5d7dd529",
    "topic_key": "healthcare",
    "title": "Healthcare Access",
    "question_text": "What role should government play in healthcare access?",
    "stances": [
      {"value": 1, "text": "Make healthcare free and available to everyone, paid for and run by the public sector"},
      {"value": 2, "text": "Make sure everyone has affordable coverage through a mix of public programs and regulated private insurance"},
      {"value": 3, "text": "Help people who can't afford care and expand programs for seniors and low-income residents, while keeping private insurance for everyone else"},
      {"value": 4, "text": "Only help the poorest people afford healthcare and leave everyone else to employers and private insurance"},
      {"value": 5, "text": "Stay out of healthcare entirely and let private markets handle all coverage decisions"}
    ]
  },
  {
    "id": "669cac97-66a6-4087-b036-936fbe62efb3",
    "topic_key": "housing",
    "title": "Affordable Housing",
    "question_text": "What role should government play in making sure people can afford housing?",
    "stances": [
      {"value": 1, "text": "Directly build and operate public housing so anyone who needs a home can get one"},
      {"value": 2, "text": "Use rent caps, require new developments to include affordable units, and publicly fund new housing"},
      {"value": 3, "text": "Offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits"},
      {"value": 4, "text": "Cut regulations and zoning rules so private developers can build more housing"},
      {"value": 5, "text": "Stay out of housing entirely and let the market decide prices and supply"}
    ]
  },
  {
    "id": "4e2c69ce-591e-4197-9cd5-7aceff79d390",
    "topic_key": "immigration",
    "title": "Immigration and Treatment of Immigrants",
    "question_text": "How welcoming or restrictive should government be toward immigrants?",
    "stances": [
      {"value": 1, "text": "Make it easier for immigrants to come here legally, and let all immigrants — including undocumented residents — fully use public services"},
      {"value": 2, "text": "Keep legal immigration open and let most residents use public services regardless of legal status"},
      {"value": 3, "text": "Keep immigration levels and rules about where they are now"},
      {"value": 4, "text": "Make it harder to immigrate legally and limit public services to people with legal status"},
      {"value": 5, "text": "Stop most legal immigration and block public services for anyone without legal status"}
    ]
  },
  {
    "id": "6b9ba6d9-1001-43f5-b073-4d37130696fd",
    "topic_key": "religious-freedom",
    "title": "Religious Freedom",
    "question_text": "What role should religion play in government, public institutions, and policymaking?",
    "stances": [
      {"value": 1, "text": "strictly separate religion from all public institutions and prohibit religious exemptions from civil rights laws."},
      {"value": 2, "text": "protect religious freedom while ensuring it doesn't override anti-discrimination protections in employment and housing."},
      {"value": 3, "text": "balance protecting religious practices with maintaining equal treatment under the law for all citizens."},
      {"value": 4, "text": "protect religious freedom and allow faith-based exemptions from laws that conflict with sincere religious beliefs."},
      {"value": 5, "text": "strongly protect religious freedom and allow religious organizations complete autonomy in their operations and hiring practices."}
    ]
  },
  {
    "id": "c5ab4eab-702f-49b8-9277-8ea53f3835c6",
    "topic_key": "same-sex-marriage",
    "title": "Same-Sex Marriage",
    "question_text": "What legal recognition should same-sex marriages receive?",
    "stances": [
      {"value": 1, "text": "require all states to recognize same-sex marriages and provide full federal benefits and protections."},
      {"value": 2, "text": "allow same-sex marriage nationwide while protecting some organizations' right to decline participation."},
      {"value": 3, "text": "let each state decide its own same-sex marriage laws without federal interference."},
      {"value": 4, "text": "recognize civil unions for same-sex couples but reserve marriage for opposite-sex couples."},
      {"value": 5, "text": "make same-sex marriage illegal and define marriage as only between one man and one woman."}
    ]
  },
  {
    "id": "87d20824-a6e9-407b-983c-65440084a0ab",
    "topic_key": "social-security",
    "title": "Social Security",
    "question_text": "How should Social Security be funded and structured for the future?",
    "stances": [
      {"value": 1, "text": "expand Social Security benefits significantly and remove the income cap on payroll taxes to fund it."},
      {"value": 2, "text": "increase Social Security benefits modestly while raising taxes on higher earners to strengthen the program."},
      {"value": 3, "text": "make small adjustments to both benefits and taxes to keep Social Security stable for future generations."},
      {"value": 4, "text": "gradually raise the retirement age and reduce benefits for higher earners to save Social Security."},
      {"value": 5, "text": "transition Social Security to private investment accounts that individuals control themselves."}
    ]
  },
  {
    "id": "683c8084-2281-4920-a07c-18439b2dd413",
    "topic_key": "tariffs",
    "title": "United States Tariff Policy",
    "question_text": "How should trade policy balance domestic industry with global commerce?",
    "stances": [
      {"value": 1, "text": "eliminate all tariffs and pursue completely free trade with every country."},
      {"value": 2, "text": "reduce most tariffs while keeping some on products that harm the environment."},
      {"value": 3, "text": "use tariffs selectively to protect key American industries and jobs."},
      {"value": 4, "text": "increase tariffs on countries that don't trade fairly with America."},
      {"value": 5, "text": "impose high tariffs on all imports to bring manufacturing back to America."}
    ]
  },
  {
    "id": "f7e5678d-dadd-4556-a2fc-446e24642ceb",
    "topic_key": "taxes",
    "title": "Taxation and Public Spending",
    "question_text": "How should government balance what it collects in taxes against what it spends on public services?",
    "stances": [
      {"value": 1, "text": "Significantly raise taxes on wealthy people and large companies to fund more public services"},
      {"value": 2, "text": "Moderately raise taxes on wealthy people and large companies to fund existing services"},
      {"value": 3, "text": "Keep the current tax system mostly as-is with small adjustments to close unfair loopholes"},
      {"value": 4, "text": "Cut taxes for everyone and scale back public services to match"},
      {"value": 5, "text": "Drastically cut taxes and shrink government so people and businesses keep more of their money"}
    ]
  },
  {
    "id": "d1618b9c-0b9e-45af-b986-bb33d270b8e4",
    "topic_key": "trans-athletes",
    "title": "Transgender Athletes",
    "question_text": "How should sports leagues determine eligibility for transgender athletes?",
    "stances": [
      {"value": 1, "text": "allow all transgender athletes to compete on teams matching their gender identity without any restrictions or requirements."},
      {"value": 2, "text": "should allow transgender athletes to compete on teams matching their gender identity after completing basic documentation of their transition."},
      {"value": 3, "text": "create separate transgender divisions or allow case-by-case decisions based on individual circumstances and sport requirements."},
      {"value": 4, "text": "require transgender athletes to compete only on teams matching their biological sex assigned at birth."},
      {"value": 5, "text": "completely ban all transgender athletes from competing in any organized sports competitions."}
    ]
  },
  {
    "id": "d1792200-1d3b-4955-a0b7-0e6980d7a7b2",
    "topic_key": "voting-rights",
    "title": "Voting Rights and Electoral Integrity",
    "question_text": "How should voter access be balanced with election security?",
    "stances": [
      {"value": 1, "text": "automatically register all eligible citizens to vote and allow online voting"},
      {"value": 2, "text": "expand early voting periods and make mail-in voting available to all voters without requiring an excuse"},
      {"value": 3, "text": "standardize voter ID requirements while ensuring free IDs are available to all eligible citizens"},
      {"value": 4, "text": "require photo ID for voting and regularly update voter rolls to remove inactive registrations"},
      {"value": 5, "text": "mandate in-person voting with strict photo ID and eliminate mail-in voting except for military overseas"}
    ]
  }
]
```

---

## Dispatch Plan

**3 sequential agent dispatches — one per candidate. No parallel launches.**

Per MEMORY.md rate-limit rule and Phase 101 D-02: dispatch ONE research-stances agent at a time. Wait for each agent's CSV write to complete before dispatching the next. Never launch agents in parallel.

| Order | Candidate | State | Party | Topics in Scope | Agent Dispatch |
|-------|-----------|-------|-------|-----------------|----------------|
| 1 | Derek Dooley | GA | Republican | abortion, civil-rights, climate-change, healthcare, immigration, voting-rights (6 topics) | Task 2 — Agent 1 |
| 2 | Hallie Shoffner | AR | Democratic | campaign-finance, climate-change, economic-development, housing, taxes (5 topics) | Task 2 — Agent 2 |
| 3 | Kurt Alme | MT | Republican | abortion, fossil-fuels, religious-freedom, same-sex-marriage, social-security, tariffs, trans-athletes, voting-rights (8 topics) | Task 2 — Agent 3 |

**Output file for all 3 agents:** `backend/data/stance-research/2026-06-06-candidate-remediation.csv`

Each agent appends to the same file. After every agent completes, verify the CSV has exactly one header row (no duplicate headers).

**Current DB values (from 102-TRIAGE-REPORT.md) — all sources are homepage-only:**

| Candidate | topic_key | current_value | current_source (homepage-only) |
|-----------|-----------|---------------|-------------------------------|
| Derek Dooley | abortion | 4.0 | https://dooleyforgeorgia.com/ |
| Derek Dooley | civil-rights | 4.0 | https://dooleyforgeorgia.com/ |
| Derek Dooley | climate-change | 4.0 | https://dooleyforgeorgia.com/ |
| Derek Dooley | healthcare | 4.0 | https://dooleyforgeorgia.com/ |
| Derek Dooley | immigration | 4.0 | https://dooleyforgeorgia.com/ |
| Derek Dooley | voting-rights | 4.0 | https://dooleyforgeorgia.com/ |
| Hallie Shoffner | campaign-finance | 2.0 | https://www.hallieshoffner.com |
| Hallie Shoffner | climate-change | 2.0 | https://www.hallieshoffner.com |
| Hallie Shoffner | economic-development | 2.0 | https://www.hallieshoffner.com |
| Hallie Shoffner | housing | 2.0 | https://www.hallieshoffner.com |
| Hallie Shoffner | taxes | 2.0 | https://www.hallieshoffner.com |
| Kurt Alme | abortion | 5.0 | https://almeforsenate.com/ |
| Kurt Alme | fossil-fuels | 5.0 | https://almeforsenate.com/ |
| Kurt Alme | religious-freedom | 5.0 | https://almeforsenate.com/ |
| Kurt Alme | same-sex-marriage | 5.0 | https://almeforsenate.com/ |
| Kurt Alme | social-security | 4.0 | https://almeforsenate.com/ |
| Kurt Alme | tariffs | 4.0 | https://almeforsenate.com/ |
| Kurt Alme | trans-athletes | 4.0 | https://almeforsenate.com/ |
| Kurt Alme | voting-rights | 4.0 | https://almeforsenate.com/ |
