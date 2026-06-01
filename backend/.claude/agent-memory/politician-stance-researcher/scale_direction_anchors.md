---
name: scale-direction-anchors
description: "Per-topic scale direction anchors — what value=1 and value=5 actually mean for each topic, derived from the written stance texts in the database"
metadata:
  type: feedback
---

# Scale Direction Anchors

**How the scale works:** Each value (1–5) corresponds to a specific pre-written stance text stored in `inform.compass_stances`. Value=1 is one end of the spectrum, value=5 is the other. **There is no universal rule like "1=oppose, 5=support" or "1=liberal, 5=conservative."** The direction is different for different topics — always consult the table below.

## Self-check rule (run before returning any value)

Before assigning a value, ask: does this politician's documented position match the written description at that value? Do not use generic political alignment as a shortcut.

Examples of correct application:
- A politician who **supports same-sex marriage** gets `same-sex-marriage=1` (stance 1 = require all states to recognize SSM with full federal benefits).
- A politician who **strongly supports abortion access** gets `abortion=1` (stance 1 = ensure abortion is legal, accessible, and publicly funded at all stages).
- A politician who **opposes abortion access** gets `abortion=4` or `5` (stance 5 = complete ban with criminal penalties).
- A politician who **opposes fossil fuel expansion** gets `fossil-fuels=1` or `2` (stance 1 = ban all new drilling).
- A politician who **favors maximizing fossil fuel extraction** gets `fossil-fuels=5`.
- A politician who **supports school vouchers** gets `school-vouchers=4` or `5` (stance 5 = universal vouchers). A politician who **opposes vouchers** gets `school-vouchers=1`.
- A politician who **supports independent redistricting** gets `redistricting=1` (stance 1 = independent citizens' commission).

## Per-topic anchors

| topic_key | value=1 means... | value=5 means... |
|---|---|---|
| abortion | ensures abortion is legal, accessible, and publicly funded at all stages | bans abortion completely with no exceptions; criminal penalties for providers and patients |
| ai-regulation | no government interference — AI companies develop and deploy freely | strict government approval requirements; bans AI systems that could cause serious harm |
| campaign-finance | bans all private money in politics; publicly funds all campaigns | eliminates all campaign finance laws and limits |
| childcare | publicly funded universal childcare so all families have access regardless of income | no government subsidies or mandates; leave childcare entirely to private market and families |
| city-sanitation | significantly expands sanitation staffing, cleaning frequency, and free community disposal | privatizes sanitation; residents and businesses contract for cleanup directly |
| civil-rights | mandates racial equity requirements in all institutions; provides reparations | eliminates affirmative action and all race-based government programs |
| climate-change | declares climate emergency; bans all activities that increase carbon emissions | rejects climate change policies entirely; focuses on economic growth instead |
| data-centers | moratorium on new data center construction until energy infrastructure can support demand without raising residential costs | welcomes data center investment with minimal regulatory barriers and competitive incentives |
| deportation | stops deportations entirely; protects undocumented residents from removal | deports all undocumented people quickly regardless of length of residence or family ties |
| economic-development | no corporate tax incentives; invest in public services and infrastructure to attract business organically | offers maximum incentives to attract any large employer; economic growth is top priority |
| fossil-fuels | immediately bans all new fossil fuel drilling and extraction | removes environmental restrictions; maximizes fossil fuel extraction |
| growth-and-development | imposes growth limits; requires voter approval for major annexations or large-scale developments | removes all regulatory barriers to development; lets market demand determine growth pace |
| healthcare | makes healthcare free and available to everyone, paid for and run by the public sector | stays out of healthcare entirely; private markets handle all coverage decisions |
| homelessness | protects right to sleep in public spaces; redirects enforcement budgets toward housing and mental health services | bans public camping with criminal penalties to maintain public safety and order |
| homelessness-response | housing-first: permanent supportive housing with no preconditions; avoids criminalization entirely | prioritizes strict enforcement of trespassing and camping bans; minimizes city spending on homeless services |
| housing | directly builds and operates public housing so anyone who needs a home can get one | stays out of housing entirely; market determines prices and supply |
| immigration | makes legal immigration easier; all immigrants including undocumented can fully use public services | stops most legal immigration; blocks public services for anyone without legal status |
| jail-capacity | redirects incarceration funding into community mental health, addiction, housing, and restorative justice programs | expands jail capacity and enforcement as the primary response to crime |
| judicial-access-to-justice | courts should be easy to access for everyone; low barriers mean more access to justice | most disputes should be settled privately; courts should be a last resort |
| judicial-bail-pretrial | judges should closely watch prosecutorial power and ensure it is used fairly | trust prosecutors; judges should not second-guess their judgment on cases already screened |
| judicial-criminal-justice | criminal justice should focus on helping the person change their life (rehabilitation) | criminal justice should focus on punishment — society needs to know breaking the law has consequences |
| judicial-government-deference | courts should actively protect citizens from government power; level the playing field | courts should broadly defer to government officials unless they have obviously overreached |
| judicial-interpretation | courts should reconsider old rulings when society has changed (living constitutionalism) | judges should apply the law as written, not rewrite it; leave changes to elected legislators (originalism) |
| judicial-police-accountability | accountability office works for the public; investigates independently | office defends the city government and its employees aggressively |
| judicial-prosecution-priorities | prosecution is a last resort; connect people to treatment, housing, and job programs | if a case is prosecutable, prosecute it; courts figure out the rest |
| judicial-transparency | everything possible should be public — hearings, evidence, rulings, and reasoning behind them | courts should have broad discretion to limit public access to protect integrity of proceedings |
| local-environment | requires significant green space, tree preservation, and environmental review before any development | removes local environmental restrictions beyond what state and federal law requires |
| local-immigration | refuses all ICE detainers; prohibits city employees from sharing immigration status with federal agencies | directs city police to actively assist with immigration enforcement and federal detention operations |
| medicare/aid | expands Medicare to cover everyone regardless of age | phases out both Medicare and Medicaid; private insurance only |
| misinformation | requires platforms to remove all false information and regulate algorithms | bans any government involvement in content moderation decisions |
| public-safety-approach | redirects significant police budget to social services, mental health, and community programs | makes expanding police budget the top city spending priority over other municipal services |
| redistricting | independent citizens' commission with no elected officials involved at any level | the party that controls the state legislature draws the maps without outside interference |
| religious-freedom | strictly separates religion from all public institutions; prohibits religious exemptions from civil rights laws | strongly protects religious freedom; allows religious organizations complete autonomy in operations and hiring |
| rent-regulation | expands rent control to all rental units with strong tenant protections and just-cause eviction requirements | opposes rent control entirely; rents set by the market without government intervention |
| residential-zoning | protects existing neighborhood character strictly; requires community votes before any rezoning | eliminates single-family-only zoning; allows any housing type on any lot citywide |
| same-sex-marriage | requires all states to recognize same-sex marriages and provide full federal benefits and protections | makes same-sex marriage illegal and defines marriage as only between one man and one woman |
| school-vouchers | fully funds public schools and eliminates voucher programs that divert taxpayer money to private institutions | provides universal vouchers so education funding follows the student to any school chosen by the family |
| social-security | expands Social Security benefits significantly; removes income cap on payroll taxes to fund it | transitions Social Security to private investment accounts that individuals control themselves |
| tariffs | eliminates all tariffs; pursues completely free trade with every country | imposes high tariffs on all imports to bring manufacturing back to America |
| taxes | significantly raises taxes on wealthy people and large companies to fund more public services | drastically cuts taxes and shrinks government so people and businesses keep more money |
| trans-athletes | allows all transgender athletes to compete on teams matching their gender identity without restrictions | completely bans all transgender athletes from competing in any organized sports competitions |
| transportation-priorities | prioritizes pedestrian infrastructure, cycling networks, and public transit; reduces parking requirements citywide | prioritizes highway access and abundant free parking as the foundation of local transportation policy |
| ukraine-support | significantly increases military aid to Ukraine; committed to supporting until complete victory over Russia | ends all aid to Ukraine immediately; stays completely out of the conflict |
| unions | [verify from compass_stances — not yet confirmed] | [verify from compass_stances — not yet confirmed] |
| vaccines | [verify from compass_stances — not yet confirmed] | [verify from compass_stances — not yet confirmed] |
| veterans | [verify from compass_stances — not yet confirmed] | [verify from compass_stances — not yet confirmed] |
| voting-rights | automatically registers all eligible citizens to vote; allows online voting | mandates in-person voting with strict photo ID; eliminates mail-in voting except for military overseas |

## Common traps (topics where direction is non-obvious)

- **abortion**: value=1 is PRO-choice (legal, accessible, publicly funded). value=5 is the most restrictive (complete ban + criminal penalties). A Democrat who strongly supports abortion access gets a LOW score (1–2).
- **same-sex-marriage**: value=1 = SUPPORTS SSM (require all states to recognize). value=5 = OPPOSES SSM (make it illegal). The low end is the pro-SSM position.
- **redistricting**: value=1 = SUPPORTS independent redistricting (citizens' commission). value=5 = OPPOSES reform (party draws the maps). The low end is the reform position.
- **civil-rights**: value=1 = most progressive (mandate equity/reparations). value=5 = most conservative (eliminate affirmative action). A civil rights champion gets a LOW score.
- **taxes**: value=1 = RAISE taxes on wealthy (liberal). value=5 = CUT taxes/shrink government (conservative). A tax-the-rich advocate gets a LOW score.
- **climate-change**: value=1 = declare emergency/ban all carbon activities. value=5 = reject climate policies entirely. An aggressive climate policy champion gets a LOW score.
- **ai-regulation**: value=1 = NO government interference (libertarian). value=5 = STRICT requirements and bans (interventionist). This is the opposite of most "regulation" topics — Democrats who favor AI oversight score HIGHER than Republicans.
- **misinformation**: value=1 = require platforms to remove false info (interventionist). value=5 = ban government from content moderation (hands-off). Intervening on misinformation is the LOW end.
- **fossil-fuels**: A politician who OPPOSES fossil fuel expansion gets a LOW score (1–2). Do not give them a high score because "they have strong views on energy."
- **local-immigration**: value=1 = sanctuary / refuse ICE. value=5 = full ICE cooperation. Most blue-city politicians score 1–2.
- **trans-athletes**: value=1 = supports trans inclusion (most liberal). value=5 = complete ban (most conservative). A Republican opposing trans athletes in sports gets a HIGH score.
- **homelessness-response**: value=1 = housing-first/no criminalization. value=5 = enforcement-first/camping bans. Authoring a camping ban ordinance → HIGH score.
- **judicial-interpretation**: value=1 = living constitutionalism. value=5 = originalism/strict construction. Conservative judges get HIGH scores.
- **judicial-government-deference**: value=1 = courts check government. value=5 = courts defer to government. A politician who files lawsuits against federal overreach → LOW score.
- **school-vouchers**: value=1 = OPPOSES vouchers / fully funds public schools. value=5 = SUPPORTS universal vouchers. A pro-voucher Republican gets a HIGH score; a public-schools Democrat gets a LOW score.
- **redistricting**: value=1 = SUPPORTS independent redistricting reform. value=5 = party controls the maps. A good-government reformer gets a LOW score.
