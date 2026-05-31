---
name: scale-direction-anchors
description: "Per-topic scale direction anchors — which end is 1 and which end is 5, with a self-check rule to prevent inversion errors"
metadata:
  type: feedback
---

# Scale Direction Anchors

**Scale:** 1 = strongly OPPOSE the topic as labeled. 5 = strongly SUPPORT the topic as labeled.

The label on the topic IS the thing being supported or opposed. Do not apply external political mapping.

## Self-check rule (run before returning any JSON)

For every stance, ask: "If someone read this value cold, would they correctly understand this politician's position?" A politician who actively pushes for aggressive climate policy gets `climate-change=5`. A politician who opposes fossil fuel industry expansion gets `fossil-fuels=1` or `2`. A politician who fully supports same-sex marriage gets `same-sex-marriage=5`.

## Per-topic anchors

| topic_key | value=1 means... | value=5 means... |
|---|---|---|
| abortion | opposes abortion access / favors restrictions | strongly supports abortion access |
| ai-regulation | opposes AI regulation | strongly supports AI regulation |
| campaign-finance | opposes campaign finance limits/disclosure | strongly supports campaign finance reform |
| childcare | opposes public childcare investment | strongly supports universal/subsidized childcare |
| city-sanitation | opposes increased sanitation services | strongly supports investment in sanitation |
| civil-rights | opposes civil rights protections/enforcement | strongly supports civil rights protections |
| climate-change | denies or opposes climate action policy | strongly supports aggressive climate action |
| data-centers | opposes data center development | strongly supports data center development |
| deportation | opposes deportation of immigrants | strongly supports deportation enforcement |
| economic-development | opposes economic development incentives | strongly supports economic development incentives |
| fossil-fuels | opposes fossil fuel industry / favors phase-out | strongly supports fossil fuel industry / expansion |
| growth-and-development | opposes development/permitting | strongly supports streamlined growth and development |
| healthcare | opposes expanded healthcare coverage | strongly supports expanded/universal healthcare |
| homelessness | opposes addressing homelessness / dismisses | strongly supports intervention and services for homeless |
| homelessness-response | favors services-only / opposes any enforcement | favors enforcement-first / criminalization approach |
| housing | opposes housing expansion or tenant rights | strongly supports housing expansion and tenant rights |
| immigration | favors restrictions / enforcement-first | strongly supports expanded immigration / protections |
| jail-capacity | opposes expanding jail capacity | strongly supports expanding jail capacity |
| judicial-access-to-justice | opposes expanding access to courts | strongly supports access to justice reforms |
| judicial-bail-pretrial | opposes bail reform / favors cash bail | strongly supports bail reform / pretrial release |
| judicial-criminal-justice | opposes criminal justice reform | strongly supports criminal justice reform |
| judicial-government-deference | courts should actively check government power | courts should defer broadly to government |
| judicial-interpretation | favors broad/living interpretation | favors strict/originalist interpretation |
| judicial-police-accountability | opposes police oversight | strongly supports police accountability |
| judicial-prosecution-priorities | favors diversion / non-prosecution of low-level crimes | favors aggressive prosecution across all offense levels |
| judicial-transparency | opposes transparency in institutions | strongly supports institutional transparency |
| local-environment | opposes local environmental protections | strongly supports local environmental protections |
| local-immigration | refuses all ICE cooperation / sanctuary | full cooperation with federal immigration enforcement |
| medicare/aid | opposes Medicaid/Medicare expansion | strongly supports Medicaid/Medicare expansion |
| misinformation | opposes regulating misinformation | strongly supports regulating misinformation |
| public-safety-approach | favors community-led/alternative safety models | favors law enforcement capacity / tough on crime |
| redistricting | opposes independent/fair redistricting | strongly supports independent/fair redistricting |
| religious-freedom | opposes religious exemptions in law | strongly supports religious exemptions in law |
| rent-regulation | opposes rent control/stabilization | strongly supports rent control/stabilization |
| residential-zoning | opposes upzoning/density | strongly supports upzoning and density |
| same-sex-marriage | opposes same-sex marriage | strongly supports same-sex marriage |
| school-vouchers | opposes school vouchers | strongly supports school vouchers |
| social-security | opposes maintaining/expanding Social Security | strongly supports maintaining/expanding Social Security |
| tariffs | opposes tariffs / favors free trade | strongly supports tariffs |
| taxes | opposes taxes / favors cuts | strongly supports higher taxes on wealthy/corporations |
| trans-athletes | supports trans athlete inclusion | opposes trans athlete inclusion / favors sport bans |
| transportation-priorities | opposes public transit / favors car-centric | strongly supports public transit / multimodal |
| ukraine-support | opposes Ukraine aid / favors diplomacy/Russia | strongly supports Ukraine military and financial aid |
| unions | opposes unions / favors employer rights | strongly supports unions and collective bargaining |
| vaccines | opposes vaccine requirements | strongly supports vaccine requirements |
| veterans | opposes veteran benefits | strongly supports veteran benefits |
| voting-rights | opposes voting access expansion | strongly supports voting access expansion |

## Common inversion traps

- **fossil-fuels**: A politician who OPPOSES fossil fuel expansion gets a LOW score (1-2). Do NOT give them a high score because "they have strong views."
- **local-immigration**: 1 = sanctuary / refuse ICE. 5 = full ICE cooperation. Most city politicians in blue cities score 1-2.
- **trans-athletes**: 1 = supports trans inclusion in sports. 5 = opposes trans athletes / supports bans. This is inverted from many other civil rights topics.
- **homelessness-response**: 1 = services-only approach. 5 = enforcement/criminalization approach. Authoring a camping ban → HIGH score.
- **judicial-interpretation**: 1 = living constitution / broad interpretation. 5 = originalism / strict construction.
- **judicial-government-deference**: 1 = courts should check government. 5 = courts should defer to government. A politician who files lawsuits against federal overreach → LOW score.
- **religious-freedom**: 1 = opposes religious exemptions. 5 = strongly supports religious exemptions from civil law.
