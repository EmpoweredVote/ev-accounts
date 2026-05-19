---
name: stance_alex_padilla
description: Verified stances for Alex Padilla, US Senator California (appointed 2021, re-elected 2022); top-off research 2026-05-16 covering 10 additional local/judicial topics
metadata:
  type: project
---

# Alex Padilla — Stance Research Notes

**Role:** US Senator, California (D). Appointed Jan 2021 to replace Kamala Harris, re-elected Nov 2022. Previously: CA Secretary of State (2015–2021), CA State Senate (2006–2014), LA City Council (2003–2006). First Latino California senator.

**Politician ID:** `2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f`

## Research Status

### Already Scored (pre-existing):
abortion=1, ai-regulation=4, campaign-finance=2, childcare=2, civil-rights=2, climate-change=2, data-centers=2, deportation=2, fossil-fuels=2, healthcare=1, homelessness=2, housing=2, immigration=2, medicare/aid=1, misinformation=2, redistricting=1, religious-freedom=2, same-sex-marriage=1, school-vouchers=2, social-security=2, tariffs=2, taxes=2, trans-athletes=2, ukraine-support=2, voting-rights=1

### New Top-Off Scores (2026-05-16):
- **local-immigration = 1** — Refused to accept ICE enforcement at schools; called for cutting ICE detention budget >$1B in FY22; introduced Dignity for Detained Immigrants Act; bodily removed from DHS press conference opposing LA ICE raids (Jun 2025); praised local officials requiring warrants before admitting ICE agents to schools
- **public-safety-approach = 2** — Cosponsored George Floyd Justice in Policing Act; introduced Accountability for Federal Law Enforcement Act (civil suit rights against federal officers); not a defund advocate
- **judicial-police-accountability = 2** — Same bills as above; limits qualified immunity; bans chokeholds; ends racial profiling; no abolition stance
- **judicial-criminal-justice = 2** — George Floyd Act; LA County probation accountability; condemns systemic racial bias in policing; reform-oriented not punitive
- **transportation-priorities = 2** — All Aboard Act ($200B rail); ~$2B CA transit funding; RAISE grants with protected bikeways + pedestrian + multimodal; not purely highway-focused
- **homelessness-response = 2** — Housing for All Act; Fighting Homelessness Through Services and Housing Act; Continuum of Care; permanent supportive housing; HUD-VASH; no anti-camping enforcement support
- **economic-development = 2** — EDA bills focused on underserved/Tribal communities with community benefit requirements; targeted equity-focused approach
- **jail-capacity = 2** — Opposed using BOP prisons for immigrant detention ("unconstitutional, inhumane"); opposed expanding ICE detention capacity; supports diversion over expansion
- **rent-regulation = 2** — Co-led Keeping Renters Safe Act 2021 (permanent HHS eviction moratorium authority); pushed Treasury for emergency rental assistance deployment; consistent tenant protection advocate
- **local-environment = 2** — Protects California public lands; Reconnecting Communities grants with environmental review; climate-resilient transportation standards; Fix Our Forests Act; POWER On Act

### Skipped (no sufficient evidence):
- **city-sanitation** — US Senator; no relevant federal record
- **growth-and-development** — US Senator; no relevant federal record
- **residential-zoning** — US Senator; housing record focused on supply/affordability funding, not zoning authority
- **judicial-interpretation** — Did not explicitly articulate originalism vs. living constitution; focused on outcomes not methodology in KBJ confirmation
- **judicial-government-deference** — No explicit doctrine statements
- **judicial-bail-pretrial** — Cash bail is state-level; no direct federal Senate votes
- **judicial-prosecution-priorities** — No direct evidence
- **judicial-transparency** — Clarence Thomas recusal demand noted but insufficient for scoring
- **judicial-access-to-justice** — Mentioned Legal Services Corporation but no scored evidence

## Key Sources
- `padilla.senate.gov/newsroom/press-releases/` — Direct press releases; use slug patterns
- `padilla.senate.gov/press_releases-sitemap.xml` and `press_releases-sitemap2.xml` — Full URL index; use to find topic-specific URLs
- `padilla.senate.gov/issues/` — Issue pages exist but often return JPEG (image) not text
- `padilla.senate.gov/about/` — Biographical overview with broad issue statements

## Research Notes
- congress.gov returns 403 Forbidden for all bill-specific URLs — cannot use for Padilla
- padilla.senate.gov issue pages (e.g., /issues/immigration/) return binary JPEG files — cannot parse
- Press release sitemaps (sitemap.xml and sitemap2.xml) are the most reliable discovery mechanism
- Press release search queries (e.g., ?q=ICE) do NOT filter — always return latest 6 press releases regardless
- Best approach: query sitemaps first to get real URL slugs, then fetch those directly
- Progressive Punch score: 97.57% lifetime (rank #14 among Senate Democrats)
