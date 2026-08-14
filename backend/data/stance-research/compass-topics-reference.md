# Compass Topics Reference

**GENERATED FILE - DO NOT HAND-EDIT.** Regenerate with:

```
node scripts/gen-compass-topics-reference.mjs
```

Source of truth: `inform.compass_stances` joined to `inform.compass_topics` (is_live AND is_active).
44 live topics. The chair text below is verbatim from the database - it is what the voter sees.

## The rule for seating anyone in a chair

A chair requires evidence describing **THAT chair**. The five chairs are five distinct stances, not
a polarization rating. Direction is not a chair: evidence that establishes only pro/anti under-
determines which of the two or three chairs on that side the person occupies, and seating them anyway
is an unevidenced voter-facing claim.

- A polarization score, an endorsement grade, or an advocacy-group rating is **never** a chair.
- "Least extreme option the reasoning supports" is a **tiebreaker, not evidence**. Reaching for it is
  the signal that the row is not evidenced.
- The honest alternative to a guessed chair is a **blank spoke**. A blank spoke is a correct answer.
- A citation to legislation the member CO-SPONSORED can only ever evidence the chair that legislation
  describes. Co-sponsorship counts as much as authorship.
- Before calling a chair pair unevidenceable, check *which word* differs between them:
  **pace/magnitude only** (taxes 1 "significantly raise" vs 2 "moderately raise") cannot be settled by
  a sponsorship - blank it; an **end-state** difference (climate 2 "phase out" vs 3 "gradually reducing
  reliance on") is elimination vs reduction and can be evidenced.
- Consistency check: the same instrument cannot seat two co-sponsors in two different chairs.

## Orientation: read chair 1, every time

**Do not assume 1 = progressive.** The prevailing convention is *chair 1 = maximum government action,
chair 5 = minimum*, which is a different axis from left-to-right, and several ladders do not follow
either reading:

- **Reversed** - `ai-regulation` chair 1 is "allow AI companies to develop freely" and chair 5 is the
  ban. `tariffs` chair 1 is complete free trade. On these, the pro-regulation politician is at the
  HIGH chair.
- **Off-axis** - on `residential-zoning` (chair 5 eliminates single-family-only zoning),
  `growth-and-development`, and `housing` chair 4 ("cut regulations so private developers can build"),
  the deregulatory and the progressive-housing positions sit at the SAME end. `housing` chair 4 is
  right for a YIMBY and wrong for a tenant-protection member: same chair, opposite verdicts, decided
  per row.
- **Not an intervention axis at all** - `judicial-government-deference` chair 1 is "the citizen,
  almost always". No political lexicon maps onto it; do not scan it with one.
- `misinformation` chair 5 ("ban any government involvement in content moderation") is a free-speech
  position held across the spectrum.

Orientation is **not** stored on `compass_topics`, so nothing in the code derives it and no scan can
infer it. The authoritative test is the chair text printed below. Read chair 1 and chair 5 and decide
which end your evidence describes before picking a number.

## Output format

Emit the chair number **1-5 directly**, matching the option number below. Apply scripts use
`parseInt(value)` with no conversion formula. CSV: `politician_id,topic_id,topic_key,value,notes`;
keep notes under 120 chars and use semicolons, not commas.

## Scope

`office_scope` is NULL on every live topic, so scope is a judgment call, not a lookup. Pick the topics
the office actually acts on. `data-centers`, `local-immigration` and `transportation-priorities` are
live and are usually the WRONG choice for a federal or statewide official and the RIGHT choice for a
city or county one. (An earlier version of this file listed those three as deprecated. They are not.)

---

## Topics

### abortion
**Title:** Abortion
**Question:** What legal framework should govern abortion access?
**Chairs (verbatim):**
- 1 = ensure abortion is legal, accessible, and publicly funded at all stages of pregnancy.
- 2 = keep abortion legal and accessible through the second trimester with rare exceptions afterward.
- 3 = allow abortion in the first trimester and in cases of rape, incest, or maternal health risks.
- 4 = restrict abortion to only cases involving rape, incest, or serious threats to the mother's life.
- 5 = ban abortion completely with no exceptions and impose criminal penalties for providers and patients.

---

### ai-regulation
**Title:** AI Oversight
**Question:** How much should government oversee artificial intelligence development and deployment?
**Chairs (verbatim):**
- 1 = Allow AI companies to develop and deploy technology freely without government interference
- 2 = Suggest AI safety guidelines but let companies choose whether to follow them
- 3 = Require AI developers to disclose risks and be held responsible when their systems cause harm
- 4 = Require safety testing and ban high-risk AI uses in areas like hiring, healthcare, and policing
- 5 = Impose strict approval requirements and ban AI systems that could cause serious harm

---

### campaign-finance
**Title:** Campaign Finance
**Question:** What rules should govern money in political campaigns and elections?
**Chairs (verbatim):**
- 1 = ban all private money in politics and publicly fund campaigns
- 2 = strictly limit corporate donations and dark money groups
- 3 = require full disclosure of all political donations
- 4 = reduce restrictions on political donations and spending
- 5 = eliminate all campaign finance laws and limits

---

### childcare
**Title:** Childcare
**Question:** How should government address the cost and availability of childcare?
**Chairs (verbatim):**
- 1 = Establishing publicly funded universal childcare so that all families have access regardless of income
- 2 = Significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families
- 3 = Offering targeted tax credits and subsidies for families below a set income threshold while supporting providers through training and facility grants
- 4 = Reducing regulations on childcare providers to increase supply and lower costs, with limited subsidies reserved for the lowest-income families
- 5 = Leaving childcare to the private market and families, with no government subsidies or mandates that increase costs for providers and taxpayers

---

### city-sanitation
**Title:** City Sanitation and Cleanliness
**Question:** How should your community approach street cleanliness and sanitation?
**Chairs (verbatim):**
- 1 = Significantly expand sanitation staffing, cleaning frequency, and free community disposal access; treat poor conditions as a services failure
- 2 = Increase sanitation crews and prioritize historically underserved neighborhoods to equalize cleanliness communitywide
- 3 = Maintain current sanitation services while enforcing anti-dumping laws for businesses and large property owners
- 4 = Rely primarily on enforcement of anti-littering and property maintenance laws; hold residents and businesses responsible
- 5 = Privatize sanitation services and require residents and businesses to contract for cleanup directly

---

### civil-rights
**Title:** Civil Rights
**Question:** What role should government play in addressing racial and social inequality?
**Chairs (verbatim):**
- 1 = mandate racial equity requirements in all institutions and provide reparations
- 2 = strengthen civil rights enforcement and address systemic discrimination
- 3 = maintain current civil rights laws while promoting equal opportunity
- 4 = limit federal civil rights enforcement to clear cases of discrimination
- 5 = eliminate affirmative action and all race-based government programs

---

### climate-change
**Title:** Climate Change
**Question:** What priority should climate change receive in energy and economic policy?
**Chairs (verbatim):**
- 1 = declare a climate emergency and ban all activities that increase carbon emissions
- 2 = rapidly transition to renewable energy and phase out fossil fuels by 2030
- 3 = invest in clean energy while gradually reducing reliance on fossil fuels
- 4 = let market forces drive any transition to cleaner energy sources
- 5 = reject climate change policies and focus on economic growth instead

---

### data-centers
**Title:** Data Centers
**Question:** How should government manage the growth of large-scale data centers?
**Chairs (verbatim):**
- 1 = Imposing a moratorium on new data center construction until energy infrastructure can support demand without raising costs for residential ratepayers
- 2 = Requiring data centers to fund their own dedicated power generation and barring utilities from passing data center infrastructure costs to residential customers
- 3 = Allowing data center development with impact assessments, energy cost-sharing agreements, and community benefit requirements before approval
- 4 = Encouraging data center development through streamlined permitting while requiring transparency about projected energy demand and rate impacts
- 5 = Welcoming data center investment with competitive incentives and minimal regulatory barriers, trusting that economic growth and tax revenue will benefit all residents

---

### deportation
**Title:** Deportation
**Question:** Who should be deported, and how aggressively?
**Chairs (verbatim):**
- 1 = Stop deportations entirely and protect undocumented residents from removal
- 2 = Only deport people convicted of serious violent crimes
- 3 = Focus deportation on recent arrivals while leaving long-term residents in place
- 4 = Deport everyone without legal status, starting with those who have criminal records
- 5 = Move quickly to deport all undocumented people regardless of how long they've lived here or family ties

---

### economic-development
**Title:** Economic Development Incentives
**Question:** How should government attract businesses and support economic development?
**Chairs (verbatim):**
- 1 = No corporate tax incentives; invest in public services and infrastructure to attract business organically
- 2 = Small business support and local entrepreneur programs only; avoid large corporate subsidies
- 3 = Targeted incentives for specific industries with community benefit agreements and job quality requirements
- 4 = Compete actively for major employers with significant tax abatements and infrastructure investment
- 5 = Offer maximum incentives to attract any large employer; economic growth is the top priority

---

### fossil-fuels
**Title:** Fossil Fuels
**Question:** What role should fossil fuels play in the nation's energy future?
**Chairs (verbatim):**
- 1 = immediately ban all new fossil fuel drilling and extraction
- 2 = stop issuing new permits for fossil fuel drilling
- 3 = maintain current levels of fossil fuel production with existing environmental regulations
- 4 = expand fossil fuel drilling permits
- 5 = remove environmental restrictions and maximize fossil fuel extraction

---

### growth-and-development
**Title:** Growth and Development Pace
**Question:** How should government manage population growth and new development?
**Chairs (verbatim):**
- 1 = Impose growth limits; require voter approval for major annexations or large-scale developments
- 2 = Allow growth only where existing infrastructure can support it; slow approvals until capacity catches up
- 3 = Plan proactively — invest in infrastructure ahead of growth to support responsible expansion
- 4 = Streamline permitting, reduce fees, and actively recruit development to grow the tax base
- 5 = Remove regulatory barriers to development entirely; let market demand determine growth pace

---

### healthcare
**Title:** Healthcare
**Question:** What role should government play in healthcare access?
**Chairs (verbatim):**
- 1 = Make healthcare free and available to everyone, paid for and run by the public sector
- 2 = Make sure everyone has affordable coverage through a mix of public programs and regulated private insurance
- 3 = Help people who can't afford care and expand programs for seniors and low-income residents, while keeping private insurance for everyone else
- 4 = Only help the poorest people afford healthcare and leave everyone else to employers and private insurance
- 5 = Stay out of healthcare entirely and let private markets handle all coverage decisions

---

### homelessness
**Title:** Homelessness
**Question:** How should government address people sleeping or camping in public spaces?
**Chairs (verbatim):**
- 1 = Protecting the right to sleep in public spaces and redirecting enforcement budgets toward permanent supportive housing and mental health services
- 2 = Decriminalizing public sleeping while investing in shelter capacity, outreach workers, and voluntary service connections
- 3 = Allowing enforcement only when adequate shelter beds are available, with citations diverting people to services rather than the criminal justice system
- 4 = Prohibiting encampments on public property with graduated warnings and penalties, while requiring jurisdictions to maintain basic shelter options
- 5 = Banning public camping and sleeping with criminal penalties to maintain public safety and order, relying on existing social services for those who seek help

---

### homelessness-response
**Title:** Homelessness Response
**Question:** What should be your community's primary strategy for addressing homelessness?
**Chairs (verbatim):**
- 1 = Housing-first: provide permanent supportive housing with no preconditions; avoid criminalization entirely
- 2 = Expand shelter capacity and services as the primary strategy; use enforcement only after services are offered
- 3 = Invest in outreach, shelter, and mental health services while enforcing reasonable public space rules
- 4 = Enforce anti-camping ordinances as the primary tool while maintaining basic outreach programs
- 5 = Prioritize strict enforcement of trespassing and camping bans; minimize public spending on homeless services

---

### housing
**Title:** Housing
**Question:** What role should government play in making sure people can afford housing?
**Chairs (verbatim):**
- 1 = Directly build and operate public housing so anyone who needs a home can get one
- 2 = Use rent caps, require new developments to include affordable units, and publicly fund new housing
- 3 = Offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits
- 4 = Cut regulations and zoning rules so private developers can build more housing
- 5 = Stay out of housing entirely and let the market decide prices and supply

---

### immigration
**Title:** Immigration
**Question:** How welcoming or restrictive should government be toward immigrants?
**Chairs (verbatim):**
- 1 = Make it easier for immigrants to come here legally, and let all immigrants — including undocumented residents — fully use public services
- 2 = Keep legal immigration open and let most residents use public services regardless of legal status
- 3 = Keep immigration levels and rules about where they are now
- 4 = Make it harder to immigrate legally and limit public services to people with legal status
- 5 = Stop most legal immigration and block public services for anyone without legal status

---

### jail-capacity
**Title:** Jail Capacity
**Question:** How should government respond to jail overcrowding and criminal justice demand?
**Chairs (verbatim):**
- 1 = Redirecting incarceration funding into community-based mental health, addiction, housing, and restorative justice programs to shrink the jail system
- 2 = Reducing the incarcerated population through pretrial diversion, bail reform, and treatment alternatives rather than building new capacity
- 3 = Upgrading jail facilities only as needed to meet constitutional standards, without expanding overall capacity
- 4 = Building additional jail capacity to address overcrowding and facility deficiencies
- 5 = Expanding jail capacity and enforcement as the primary response to crime, prioritizing detention over alternatives

---

### judicial-access-to-justice
**Title:** Court Access
**Question:** Should it be easy or hard to take someone to court?
**Chairs (verbatim):**
- 1 = Easy. Courts exist for everyone — not just people with expensive lawyers. Low barriers mean more access to justice.
- 2 = Accessible. Some basic requirements are fine, but courts shouldn't be a maze that only the wealthy can navigate.
- 3 = Reasonable standards that keep out frivolous cases without blocking legitimate ones.
- 4 = Higher bars are fine. Too much litigation clogs the system and costs everyone money.
- 5 = Hard. Most disputes should be settled privately. Courts should be a last resort, not a first option.

---

### judicial-bail-pretrial
**Judicial role:** judge
**Title:** Bail & Pretrial
**Question:** Should a judge trust what prosecutors say, or watch them closely?
**Chairs (verbatim):**
- 1 = Watch closely. Prosecutors have enormous power and real incentives to win. A judge's job is to make sure that power is used fairly.
- 2 = Be skeptical. Hold prosecution to strict standards — especially on evidence handling and plea deals.
- 3 = Treat both sides equally and let the process work.
- 4 = Give prosecutors reasonable deference. They're trained professionals representing the public.
- 5 = Trust prosecutors. They represent the community and have already screened the case — judges shouldn't second-guess that judgment.

---

### judicial-criminal-justice
**Title:** Criminal Justice
**Question:** When someone breaks the law, what matters most?
**Chairs (verbatim):**
- 1 = Helping the person change their life and stay out of trouble in the future.
- 2 = Giving the person a fair chance to make things right — through treatment, community service, or restitution.
- 3 = A mix: some accountability, some support, depending on what happened.
- 4 = Making sure others think twice before doing the same thing.
- 5 = Punishing the behavior. Society needs to know that breaking the law has real consequences.

---

### judicial-government-deference
**Title:** Government Deference
**Question:** When government and a citizen clash, who gets the benefit of the doubt?
**Chairs (verbatim):**
- 1 = The citizen, almost always. Government has lawyers, money, and power. Regular people need courts to level the playing field.
- 2 = The citizen usually — unless the government has clear legal authority on its side.
- 3 = Neither side automatically. Look at the facts and apply the law evenly.
- 4 = The government usually — it represents everyone, and its decisions deserve respect unless clearly wrong.
- 5 = The government, unless it has obviously overreached. Officials make decisions for good reasons — courts shouldn't second-guess them constantly.

---

### judicial-interpretation
**Title:** Interpretation
**Question:** Does the law change with the times, or does it mean what it said when it was written?
**Chairs (verbatim):**
- 1 = Courts should reconsider old rulings when we know more or society has changed. Keeping bad precedent alive is its own injustice.
- 2 = Laws were written for a purpose. When the exact words don't fit a new situation, look at what the law was trying to accomplish.
- 3 = Follow the text closely, but use some common sense about what lawmakers were trying to do.
- 4 = The law means what it says. Use original intent to fill gaps, but don't stretch the meaning.
- 5 = A judge's job is to apply the law as written — not rewrite it. If society has changed, pass a new law. That's what elections are for.

---

### judicial-police-accountability
**Judicial role:** city_attorney_da
**Title:** Police Accountability
**Question:** When government employees do wrong, does the office defend them or hold them accountable?
**Chairs (verbatim):**
- 1 = Investigate independently. The office works for the public — not the officials it's supposed to keep accountable.
- 2 = Settle valid claims quickly and pursue real accountability. Defending misconduct wastes money and public trust.
- 3 = Represent the government fairly while acknowledging when claims have merit.
- 4 = Defend government employees vigorously. That's the job. Settlements invite more lawsuits.
- 5 = The client is the government. Defending its employees and decisions — aggressively when needed — is the core function.

---

### judicial-prosecution-priorities
**Judicial role:** city_attorney_da
**Title:** Prosecution
**Question:** Does the office try to put people away, or find better solutions?
**Chairs (verbatim):**
- 1 = Prosecution should be a last resort. Connecting people to treatment, housing, or job programs does more good than a criminal record.
- 2 = Use diversion when it's available and makes sense. Reserve prosecution for when community safety actually requires it.
- 3 = Strong cases get prosecuted. Diversion is used when there's a clear benefit — it's a judgment call every time.
- 4 = Prosecute all solid cases. Declination is the exception and needs a strong reason.
- 5 = The office enforces the law — not social policy. If a case is prosecutable, prosecute it. Courts figure out the rest.

---

### judicial-transparency
**Title:** Legal Transparency
**Question:** How much should the public know about what happens in court?
**Chairs (verbatim):**
- 1 = Everything possible should be public — hearings, evidence, rulings, and the reasoning behind them. Secrecy breeds injustice.
- 2 = Default to open proceedings. Sealing records or closing hearings requires a compelling, documented reason.
- 3 = Balance openness with legitimate needs for privacy — protect victims, seal juvenile records, but keep the courtroom open as a rule.
- 4 = Courts should protect sensitive information broadly — personal details, ongoing investigations, and anything that could prejudice a fair trial.
- 5 = The law is complicated. Public access to proceedings can distort outcomes. Broad judicial discretion to limit access protects the integrity of the process.

---

### local-environment
**Title:** Environmental Protection vs. Development
**Question:** How should your community balance new development with environmental preservation?
**Chairs (verbatim):**
- 1 = Require significant green space, tree preservation, and environmental review before approving any development
- 2 = Protect existing parks and tree canopy strictly; require developers to fully offset any environmental impact
- 3 = Apply consistent environmental standards while giving developers reasonable flexibility on implementation
- 4 = Allow developers to pay fees in lieu of on-site preservation; prioritize economic activity over green space
- 5 = Remove local environmental restrictions beyond what state and federal law requires

---

### local-immigration
**Title:** Local Immigration Enforcement
**Question:** How should your community's law enforcement relate to federal immigration enforcement?
**Chairs (verbatim):**
- 1 = Refuse all ICE detainers; prohibit local employees from sharing immigration status information with federal agencies
- 2 = Comply only with court-ordered detainers; protect undocumented crime victims and witnesses from referral
- 3 = Follow federal law as required but do not use local resources for proactive immigration enforcement
- 4 = Honor ICE detainers and share information proactively when federal agencies request it
- 5 = Direct local police to actively assist with immigration enforcement and support federal detention operations

---

### medicare/aid
**Title:** Medicare/aid
**Question:** How should Medicare and Medicaid be funded and structured?
**Chairs (verbatim):**
- 1 = expand Medicare to cover everyone regardless of age
- 2 = lower Medicare age to 55 and expand Medicaid significantly
- 3 = improve current programs while controlling costs
- 4 = partially privatize Medicare and reduce Medicaid coverage
- 5 = phase out both programs and use private insurance only

---

### misinformation
**Title:** Misinformation
**Question:** What responsibility do platforms and government have in combating online misinformation?
**Chairs (verbatim):**
- 1 = require platforms to remove all false information and regulate algorithms
- 2 = mandate fact-checking and transparency in how algorithms promote content
- 3 = encourage voluntary standards for combating misinformation online
- 4 = protect free speech online and prevent government censorship
- 5 = ban any government involvement in content moderation decisions

---

### public-safety-approach
**Title:** Public Safety Approach
**Question:** How should your community fund and operate public safety services?
**Chairs (verbatim):**
- 1 = Redirect a significant portion of the police budget to social services, mental health, and community programs
- 2 = Maintain current police staffing but shift non-violent calls to unarmed mental health co-responders
- 3 = Keep current public safety funding while adding crisis response teams for mental health and addiction calls
- 4 = Increase police staffing, equipment, and pay to improve response times and deter crime
- 5 = Make expanding the police budget the top spending priority over other services

---

### redistricting
**Title:** Redistricting
**Question:** Who should draw electoral district boundaries and how should they be determined?
**Chairs (verbatim):**
- 1 = independent citizens' commissions with no elected officials involved at any level.
- 2 = independent redistricting commissions with equal representation from both major parties.
- 3 = bipartisan legislative committees with strict rules requiring supermajority approval.
- 4 = state legislatures with court oversight to prevent extreme partisan bias.
- 5 = the party that controls the state legislature without outside interference.

---

### religious-freedom
**Title:** Religious Freedom
**Question:** What role should religion play in government, public institutions, and policymaking?
**Chairs (verbatim):**
- 1 = strictly separate religion from all public institutions and prohibit religious exemptions from civil rights laws.
- 2 = protect religious freedom while ensuring it doesn't override anti-discrimination protections in employment and housing.
- 3 = balance protecting religious practices with maintaining equal treatment under the law for all citizens.
- 4 = protect religious freedom and allow faith-based exemptions from laws that conflict with sincere religious beliefs.
- 5 = strongly protect religious freedom and allow religious organizations complete autonomy in their operations and hiring practices.

---

### rent-regulation
**Title:** Rent Regulation
**Question:** What role should government play in regulating rents and protecting tenants?
**Chairs (verbatim):**
- 1 = Expand rent control to all rental units with strong tenant protections and just-cause eviction requirements
- 2 = Strengthen existing rent stabilization and extend coverage to more units
- 3 = Maintain current tenant protections while allowing market rents for new construction
- 4 = Limit rent regulations to subsidized units; allow market rents broadly
- 5 = Oppose rent control entirely; rents should be set by the market without government intervention

---

### residential-zoning
**Title:** Residential Zoning
**Question:** What should guide decisions about housing density and neighborhood character in your community?
**Chairs (verbatim):**
- 1 = Protect existing neighborhood character strictly; require community votes before any rezoning
- 2 = Allow modest density increases (duplexes, accessory units) with strong design review and neighborhood input
- 3 = Allow multifamily and mixed-use near commercial corridors while protecting most residential zones
- 4 = Upzone broadly to allow multifamily by right; streamline approvals and reduce parking requirements
- 5 = Eliminate single-family-only zoning; allow any housing type on any lot communitywide

---

### same-sex-marriage
**Title:** Same-Sex Marriage
**Question:** What legal recognition should same-sex marriages receive?
**Chairs (verbatim):**
- 1 = require all states to recognize same-sex marriages and provide full federal benefits and protections.
- 2 = allow same-sex marriage nationwide while protecting some organizations' right to decline participation.
- 3 = let each state decide its own same-sex marriage laws without federal interference.
- 4 = recognize civil unions for same-sex couples but reserve marriage for opposite-sex couples.
- 5 = make same-sex marriage illegal and define marriage as only between one man and one woman.

---

### school-vouchers
**Title:** School Vouchers
**Question:** What role should vouchers and school choice play in the public education system?
**Chairs (verbatim):**
- 1 = Fully funding public schools and eliminating voucher programs that divert taxpayer money to private institutions
- 2 = Prioritizing public school funding while restricting vouchers to low-income families who lack adequate local options
- 3 = Funding public schools at current levels while allowing means-tested voucher programs with accountability requirements for participating private schools
- 4 = Expanding voucher eligibility to most families so parents can choose the school that best fits their child, while maintaining baseline public school funding
- 5 = Providing universal vouchers so that education funding follows the student to any school — public, private, or religious — chosen by the family

---

### social-security
**Title:** Social Security
**Question:** How should Social Security be funded and structured for the future?
**Chairs (verbatim):**
- 1 = expand Social Security benefits significantly and remove the income cap on payroll taxes to fund it.
- 2 = increase Social Security benefits modestly while raising taxes on higher earners to strengthen the program.
- 3 = make small adjustments to both benefits and taxes to keep Social Security stable for future generations.
- 4 = gradually raise the retirement age and reduce benefits for higher earners to save Social Security.
- 5 = transition Social Security to private investment accounts that individuals control themselves.

---

### tariffs
**Title:** Tariffs
**Question:** How should trade policy balance domestic industry with global commerce?
**Chairs (verbatim):**
- 1 = eliminate all tariffs and pursue completely free trade with every country.
- 2 = reduce most tariffs while keeping some on products that harm the environment.
- 3 = use tariffs selectively to protect key American industries and jobs.
- 4 = increase tariffs on countries that don't trade fairly with America.
- 5 = impose high tariffs on all imports to bring manufacturing back to America.

---

### taxes
**Title:** Taxes
**Question:** How should government balance what it collects in taxes against what it spends on public services?
**Chairs (verbatim):**
- 1 = Significantly raise taxes on wealthy people and large companies to fund more public services
- 2 = Moderately raise taxes on wealthy people and large companies to fund existing services
- 3 = Keep the current tax system mostly as-is with small adjustments to close unfair loopholes
- 4 = Cut taxes for everyone and scale back public services to match
- 5 = Drastically cut taxes and shrink government so people and businesses keep more of their money

---

### trans-athletes
**Title:** Trans Athletes
**Question:** How should sports leagues determine eligibility for transgender athletes?
**Chairs (verbatim):**
- 1 = allow all transgender athletes to compete on teams matching their gender identity without any restrictions or requirements.
- 2 = should allow transgender athletes to compete on teams matching their gender identity after completing basic documentation of their transition.
- 3 = create separate transgender divisions or allow case-by-case decisions based on individual circumstances and sport requirements.
- 4 = require transgender athletes to compete only on teams matching their biological sex assigned at birth.
- 5 = completely ban all transgender athletes from competing in any organized sports competitions.

---

### transportation-priorities
**Title:** Transportation Priorities
**Question:** Where should government focus its transportation investment?
**Chairs (verbatim):**
- 1 = Prioritize pedestrian infrastructure, cycling networks, and public transit; reduce parking requirements communitywide
- 2 = Invest equally in roads and multimodal options; require bike lanes and sidewalks on all new road projects
- 3 = Maintain roads while selectively adding transit connections and pedestrian improvements where density supports it
- 4 = Focus on road capacity and traffic flow; transportation investment should serve the majority who drive
- 5 = Prioritize highway access and abundant free parking as the foundation of local transportation policy

---

### ukraine-support
**Title:** Ukraine Support
**Question:** What level of military and financial support should be provided to Ukraine?
**Chairs (verbatim):**
- 1 = significantly increase military aid to Ukraine and commit to supporting them until complete victory over Russia
- 2 = continue providing current levels of military and economic aid to help Ukraine defend itself.
- 3 = provide limited humanitarian aid to Ukraine while encouraging diplomatic negotiations to end the war.
- 4 = reduce aid to Ukraine and focus American resources on domestic priorities instead.
- 5 = end all aid to Ukraine immediately and stay completely out of the conflict.

---

### voting-rights
**Title:** Voting Rights
**Question:** How should voter access be balanced with election security?
**Chairs (verbatim):**
- 1 = automatically register all eligible citizens to vote and allow online voting
- 2 = expand early voting periods and make mail-in voting available to all voters without requiring an excuse
- 3 = standardize voter ID requirements while ensuring free IDs are available to all eligible citizens
- 4 = require photo ID for voting and regularly update voter rolls to remove inactive registrations
- 5 = mandate in-person voting with strict photo ID and eliminate mail-in voting except for military overseas

---
