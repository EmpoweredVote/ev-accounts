# Politician Stance Researcher — Memory Index

Compacted index — one line per entry group; full detail lives in each topic file.

- [scale_direction_anchors.md](scale_direction_anchors.md) — READ FIRST: per-topic scale anchors + inversion traps
- [stance_joe_roybal_epc_sheriff.md](stance_joe_roybal_epc_sheriff.md) — EPC CO Sheriff Roybal, LOCAL 22-topic scale, 2/22 (local-immigration=4, public-safety-approach=4); epcsheriffsoffice.com has a real WordPress search, own-voice goldmine; Teller Co. Sheriff Mikesell's "no roundups of families" quote is NOT Roybal's — don't misattribute
- [stance_scott_bottoms_co_hd15.md](stance_scott_bottoms_co_hd15.md) — CO HD-15 Bottoms, state-scale (28 topics) 3/28; worked sponsorship-trap example (categorical bill vs. licensing bill vs. narrow-crime penalty bill); ballotpedia returns EMPTY body (not 403) for CO legislators; gazette.com/denvergazette.com same WAF; completecolorado.com + coloradopolitics.com live and good (he's also a 2026 CO gov candidate — campaign-trail quotes separate from HD-15 record); caucus-site "In the News" hrefs missing from harvested markdown — re-fetch profile page asking for the specific `<a>` href
- [stance_rebecca_keltie_co_hd16.md](stance_rebecca_keltie_co_hd16.md) — CO HD-16 Keltie (not seeking reelection), 1/28; 2024 candidate-questionnaire voter guide on coloradopolitics.com is a goldmine; worked example of enforcement-cooperation≠deportation-chair and abortion-nudge-bill≠abortion-chair applied to a candidate's own words, not just bills
- [stance_marc_snyder_co_sd12.md](stance_marc_snyder_co_sd12.md) — CO SD-12 Snyder, 5/28; `snyderforcolorado.com/issues/` live goldmine but 🔴🔴 WebFetch re-summarizes even through r.jina.ai — a quote is only trustworthy if it reproduces byte-identical across 2+ independent section-targeted fetches; `r.jina.ai/<gazette-url>` bypasses the gazette WAF; `r.jina.ai/https://html.duckduckgo.com/html/?q=...` is a reliable DDG proxy (direct DDG CAPTCHAs)
- [ref_oregon_olis_odata.md](ref_oregon_olis_odata.md) — **OR: use the OLIS OData API** for individual votes + sponsorships (no rate limit); TRAP: "motion to withdraw" Nay votes are procedural, not stances
- [stance_jason_kropf_or_hd54.md](stance_jason_kropf_or_hd54.md) — OR HD-54 Kropf 14/25 (remediation of 6 fabricated rows); ex-Deschutes DA, criminal-justice topics best-evidenced
- [stance_emerson_levy_or_hd53.md](stance_emerson_levy_or_hd53.md) — OR HD-53 Levy 14/25 (remediation of 6 fabricated rows); `Rep Levy E` vs Bobby Levy `Rep Levy B` wrong-person trap; 2023R1 HB 2001 ≠ 2019 HB 2001
- [stance_broadman_summers_or_sd27_hd53.md](stance_broadman_summers_or_sd27_hd53.md) — OR SD-27 Broadman 14/25 (remediation; Wikipedia infobox Jan-2021 term = Bend CITY COUNCIL not Senate) + HD-53 challenger Summers 4/25 (`electsummers.com` live, other domains dead)
- [ref_bend_oregon_sources.md](ref_bend_oregon_sources.md) — Bend/Deschutes fetch routes: bendbulletin needs plain curl NOT jina; county voters'-pamphlet PDF at `/assets/displaypdf/<node>`; attribute by "(This information furnished by X.)"
- [stance_phil_chang_deschutes.md](stance_phil_chang_deschutes.md) — Deschutes Co OR Commissioner Chang, 5/14 city topics; bendbulletin.com/?s= site-search best tool for this jurisdiction; ktvz/bendsource/centraloregondaily/opb/DDG all dead ends
- [Vibert White FL-10](stance_vibert_white_fl10.md) — 0/24 skip; AI-content-farm aggregator sites (decodethevote/electionsfla/civoren) never citable
- [Walls-Windhauser FL-10](stance_angela_walls_windhauser_fl10.md) — 0/24 ghost/multi-office filer
- [VA HD-23 Franklin](stance_margaret_angela_franklin_va_hd23.md) — 7/44; swearing-in-date check caught hallucinated vote table; wrong-person trap vs Lily Franklin HD-41; LIS is a pure SPA, skip it
- [VA HD-40/42 McNamara+Ballard](stance_mcnamara_ballard_va_hd40_hd42.md) — 4/44; HJ4 redistricting read corrected to =2 (see HD-43-46 file)
- [VA HD-43-46 Morefield+O'Quinn+Kilgore+Cornett](stance_va_hd43_44_45_46_morefield_oquinn_kilgore_cornett.md) — 7/7/5/3-of-44; HJ4=GA mid-decade grant vs existing commission→No vote=redistricting-2; named-crossover vote inference OK if cross-checked vs 1 VPAP-confirmed vote
- [TN Senate indep. batch1](stance_tn_senate_2026_independents_batch1.md) — Gerena/Whitson/Sutman 0/24 all three; jina-proxied DDG-html technique
- [Travis Stevens DE Senate](stance_travis_stevens_de_senate.md) — 2/24, GoFundMe only real source
- [ref_indiana_sources.md](ref_indiana_sources.md), [ref_la_county_supervisors.md](ref_la_county_supervisors.md), [ref_la_city_council_d11_faizah_malik.md](ref_la_city_council_d11_faizah_malik.md)-no-data, [ref_la_mayor_2026_lesser_candidates.md](ref_la_mayor_2026_lesser_candidates.md)-14-cand-list
- [stance_applegate_nelson_epc_d4_d5.md](stance_applegate_nelson_epc_d4_d5.md) — EPC Commissioners Applegate(D4)-2/22, Nelson(D5)-4/22; 🔴 county commissioner vacancies go through the PARTY vacancy committee, not a BOCC vote — no AgendaSuite application packet exists for that office type (unlike a city council seat); Nelson's real campaign-site content hides behind decorative nav at `/blank` and `/blank-2`; both commissioners' transportation quotes are pure roads-only silence-on-transit, read as chair 4 not chair 3
- [IA/IL Senate gen-mixed-2](stance_ia_il_senate_2026_gen_mixed2.md) — Turek-11/24, Laehn-6/24, Harrington-3/24(party-label mismatch)

**LA (Louisiana) US House 2026:** [LA-1](stance_la1_arrington_long_2026.md) 0/24 vs Scalise. [LA-2](stance_renada_collins_la02.md) 0/24 vs Carter. [LA-3](stance_la3_2026_house_day_lebrun_walker.md) vs Higgins: Day-7,LeBrun-8,Walker-skip. [LA-4](stance_la4_2026_house_morott_nichols_cable_gromlich.md) vs Speaker Johnson: Morott-13,Nichols-2,Cable-5,Gromlich-6. [LA-5](stance_la5_2026_house_batchb.md) open: Firment-3,Fleenor-7,Foy-7,Garcia-6,McKay-2,Nyman-7 (bayouprogressive.com goldmine). [LA-6](stance_la6_2026_chris_johnson.md) vs Fields: "Chris Johnson"(R)-1,Davis-7,Williams-skip. Pattern: Ballotpedia dead, DDG-via-jina best.

**MD US House** (`stance_<name>.md`): Harris-MD01-17/24, Olszewski-MD02-16/24, Wallace-MD02-3/24, Landman-MD06-11/24, Jordan-MD05-3/24, Ivey-MD04-16/24. jina fixes 403s; Wikipedia needs (politician) suffix.

**IN-8:** Allen-D-7/24, Messmer-R-10/24(re-verify multi-amendment votes). **ID-1:** Peterson-D-12/24(needs Playwright not WebFetch).

**MN US Senate pri (open, Aug-11):** [carney-gail-kalberer](stance_mn_senate_2026_carney_gail_kalberer.md) Carney-1,Gail-3,Kalberer-skip. [pri1](stance_mn_senate_2026_pri1.md) Schwarze-5,Hassan-2(jina-only),Nord-3,Munro-7,Murgic-skip,Weiler-2. Ballotpedia returns EMPTY not 403 — jina fixes; DDG-html-via-jina reliable fallback.

**MN-5** (vs Omar unless noted, `stance_<name>_mn05.md`): Nagel-2,Schluter-2,AlAqidi-6(isidewith-trap),McKenzie-skip,Le-4,Jackson-I-skip(wrong-person),Windhauser-2,Reeves-11,Zieska-skip.

**MI-13** (vs Thanedar): Nykoriak-2,McKinney-12,Waters-4. **MI-7/11:** Prieditis-4,Rais-skip,Torres-13+,Farooqi-rich,Baker-disqualified.

**2026 federal candidates/freshmen** (`stance_<name>.md`): Harding-VA07-R, Macy-VA06-D, Vindman-VA07-D, McGuire-VA05-R, Tracinski-VA05-D, Bankhead-MT-Sen-D, Meuser-PA09-R, Jackson-MI12-D, McGuire-NJ03-R-skip.

**UT House/Senate cands:** Wiley/Paden+Catten/Anderson+Hunsaker/Fiefia/Stephenson/Vindas+McConnehey/Jemison+Jackson/Davis — `stance_<name>_ut_*.md`.
**UT statewide incumbents:** Moore/Maloy/Adams/Escamilla/Pitcher/Brammer/Millner/Cannon/Brown/Owens/Kennedy/Curtis/Lee/Johnson — `stance_<name>.md`.
**SLC/SLCo local:** Mendenhall-Mayor + Council/SLCo-primary/Sheriff/D5/AtLarge/DA batches — `stance_<name>*.md`.

**MO 2026 House:** Bush-MO1-20/24, Wellman-MO2, MO5/MO7(Craig-use-http)/MO8-BatchB files.

**MN-1:** Goetzman-2,Eaton-3,Johnson-8,Morlan-5(try /home). **MN-6:** Corey-1-thin. **MN-2:** Pratt-2,McTavish-5,Little-9. (`stance_<name>_mn0*.md`)

**IN-4:** Cox-D-10/24(drewcox.org sitemap). **IN-04 incumbent:** Baird-R-15/24. **IN-7:** Carson-D-18/24(govtrack ID mismatch risk). **IN-6/1:** Young, Pierce, Sceniak-20/24.

**FL/NJ/PA/CA reps & execs:** Steube-FL17, Rutherford-FL05, Castor-FL14, Hilton-CAGov, Becerra-CAGov, Mackenzie-PA07, Dean-PA04, OchoaBogh-CA-SD19 — `stance_<name>.md`.

**Berkeley CA City Council:** Humbert/OKeefe/Taplin/Bartlett/Blackaby/Lunaparra — `stance_<name>_berkeley_d*.md`.

**US Senate (R) roster (~30):** Daines/Blackburn/Hawley/Rounds/Thune/Hoeven/McCormick/Lummis/Moreno/Husted/Wicker/Kennedy-LA/Grassley/Murkowski/Justice-WV/Cotton/Sullivan/Moody/Scott-FL/Crapo/Risch/Moran/Young-IN/HydeSmith/Barrasso/Fischer/Lankford/Graham/Cramer/RJohnson-WI.
**US Senate mixed:** Collins-ME/Ricketts-NE/Tillis-NC/Sheehy-MT/Budd-NC/Ernst-IA/McConnell-KY/Marshall-KS/Banks-IN/Paul-KY/Hagerty-TN/Schmitt-MO/Warren-MA/Markey-MA/Vance-VP/Padilla-CA. (`stance_<name>.md`)

**TX House batches (5/each):** [b1](stance_tx_house_batch1.md)–[b16](stance_tx_house_batch16.md), [b21](politician_tx_house_batch21.md), [b24](stance_tx_house_batch24.md)–[b32](politician_tx_house_batch32.md).
**TX House named:** Tepper/Fairly/HarrisDavila/Isaac/GarciaHernandez/Bryant/Flores/DeAyala/LaHood/Dorazio — `politician_<name>.md`.
**TX Senate batches:** [b1](stance_tx_senate_batch1.md)–[b6](stance_tx_senate_batch6.md).

**MA House batches (8/each):** [b1](stance_ma_house_batch1.md)–[b11](stance_ma_house_batch11.md).
**MA Senate (~35, 3 groups):** Tarr/Fattman-R + Brownsberger/Eldridge/JLewis/Comerford/Gomez/DiDomenico/Jehlen/Spilka/Edwards; Rausch/Creem/Howard/Miranda/NCollins/Cyr/Barrett/PMark/RKennedy/Fernandes/Lovely/Crighton; Finegold/Friedman/Oliveira/Velis/Keenan/Cronin/Montigny/MBrady/Rush/Rodrigues/MMoore/Feeney/Payano/WDriscoll+Dooner/OConnor/Durant-R. (`stance_<name>.md`)
**MA statewide/US House:** Healey/KDriscoll/Campbell/DiZoglio/Galvin/Goldberg + McGovern-MA02/Clark-MA05/Pressley-MA07/Trahan-MA03/Auchincloss-MA04/Moulton-MA06/Lynch-MA08/Neal-MA01/Keating-MA09/Decker+Connolly.
**Cambridge MA Council:** Siddiqui/Azeem/Simmons/SobrinhoWheeler/MMcGovern/Nolan/Flaherty/AlZubi/Zusy.

**CA Assembly batches:** [b1](stance_ca_assembly_batch1.md) [b2](stance_ca_assembly_batch2.md).

**LA (Los Angeles) City/County:** Bonta-AG, Horvath-D3, Raman-CD4, SotoMartinez-CD13, Hernandez-CD1, Park-CD11, Nazarian-CD2, Blumenfield-Mayor-cand, Price-CD9, Hutt-CD10, Padilla-CD6, Lee-CD12, Yaroslavsky-CD5, HarrisDawson-CD8-Pres, Rodriguez-CD7-thin, McOsker-CD15, Jurado-CD14-DSA, Bass-Mayor, Lopez/Kim-Mayor-cand, FeldsteinSoto/Roy-CityAtty, Mejia-Controller, Solis-D1, Hahn-D4, Alnajjar-Mayor-cand, Mazariegos-CD9-cand, Barger-D5-Gov-cand, Mitchell-D2, Torres-CA35, Waters-CA43, Garcia-CA42, Tran-CA45.

**WI-4** (vs Moore): Rogers-R-2/24(FEC-api disambig). **WI-7 open Dem pri:** Murray-4/24(gingerforus.com).

**AL-2 special GOP pri (Aug-11):** [6 cands](stance_al2_2026_special_gop_primary.md) Marques-6,McKee-6,Harris-3,Richardson-3,Matthews-2,Horn-1. algop.org good roster source.

**CO 2026 US House new cands:** [9-cand-50-rows](stance_co_2026_house_163_10.md) Rutinel/Kiros/Peterson/Dennison/Romero/Laubacher/Killin/Clark/Bennett. Schema: politician_context(politician_id,topic_id,sources[]) not pc.answer_id. BallotReady Timothy Bennett wrong-person trap.

**MT-02:** Miller-D-6/24(dailymontanan.com richest).

**ID US Senate general** (vs Risch): [file](stance_id_senate_2026_loesby_fleming_achilles.md) Loesby-L-8,Fleming-I-5,Achilles-I-10(legislature.idaho.gov vote source, caught H93 NAY). Ballotpedia fully dead this session.

**AK US Senate jungle pri** (vs Sullivan): [pri2](stance_ak_senate_2026_pri2.md) Darden-2,Southworth-skip,Grauberger-skip. [pri3](stance_ak_senate_2026_pri3.md) Heikes-4,McElwain-skip,Roberts-8(lessawfulguy.com). [pri4](stance_ak_senate_2026_pri4.md) Mayers-R-0(nazi-troll persona, deliberate skip),Grayson-Green-4(2004 diary, dated+caveated; predictionedge.com unreliable),Kohlhaas-L-5(scott4ak.org). [pri5](stance_ak_senate_2026_pri2.md) Saucerman-1,Sid-Hill-skip. elections.alaska.gov needs jina; alaskabeacon.com needs jina.

**KS US Senate pri** (Aug-4): [file](stance_ks_senate_2026_primary_anderson_murray_hart.md) Anderson-5,Murray-5,Hart-7,Schmidt-D-7(kslegislature.gov),Naramore-3,SpidelNeumann-6. Ballotpedia dead; OnTheIssues bullets are paraphrase not verbatim.

**FL US Senate GOP pri** (vs Moody, Aug-18): [pri1](stance_fl_senate_2026_gop_primary_pri1.md) Gleason-12,Rivera-14(richest),Perry-2(stance-shift, unscored).

**WY US Senate GOP pri** (Aug-18): [pri2](stance_wy_senate_2026_pri2_holtz_mead.md) Holtz-3(skipped abortion-ambiguous),Mead-5(own statements only). oilcity/capcity/county17.com shared-publisher network, jina fixes 429s.

**NH US Senate GOP pri** (open, Sep-8): [pri3](stance_nh_senate_2026_pri3_mcmenamon_smith_brown.md) McMenamon-0(ghost),Sabrina-Smith-0(ghost),Scott-Brown-11(Citizens Count useless for current stance; concordmonitor.com+thedartmouth.com+scottbrown.com/news/ gold; homepage Issues section has placeholder-text bug). DDG CAPTCHAs after ~6-8 queries/session.

**RI US Senate GOP pri** (sole cand, vs Reed): [file](stance_raymond_mckay_ri_senate.md) McKay-5/24. Site moved domains; real platform at `/right-direction/` not `/issues/`. Ballotpedia 403'd even via jina (rare).

**DE US Senate pri** (vs Coons, Sep-15): [file](stance_de_senate_2026_pri1.md) Beardsley-D-10(WITHDREW from US Senate, now DE State Senate, scored+flagged),Katz-R-10(drmikekatz.com, real party-shift D→I→R),Shulli-R-13(shulli.org/platform/ not shulliforsenate.com-dead). FEC UI ignores query params — use API directly.

**2026 Senate gen minor-party trio** (MN/MS/MT): [file](stance_senate_2026_gen_mixed4.md) Whiting-3,Pinkins-9(richest, D→I switch, site typinkins.com),Austin-4(MTLP disavowed him, skipped). Ballotpedia EMPTY body for MN/MT.

**KY/MA/MN Senate gen-mixed-3:** [file](stance_senate_2026_gen_mixed3.md) Campbell-KY-2(correct-person trap avoided vs Cooperrider4KY),Bech-MA-6(PARTY FLAG: switched to Independent by mid-2026),Simonetti-MN-3.

**TN US Senate general** (3 indep vs Hagerty): [file](stance_tn_senate_2026_gen_independents.md) Robert-Jones-5(robertfortn.com, use sitemap.xml),James-Macon-III-0(real cand, zero content),Jeremy-Dean-Hearn-0(site exists but incoherent, correctly skipped). marginalia-search.com surfaced thegreenpapers.com/G26/TN roster. FEC DEMO_KEY rate-limited ~17hr — use fec.gov/data/candidate/ID/ directly.

**NC US Senate general** (open, Tillis retiring): [file](stance_michael_dublin_nc_senate.md) Dublin-Green-11(dublinforcongress.com/platform verbatim goldmine, re-fetch explicitly or WebFetch over-summarizes).

**NM US Senate general** (vs Luján): [file](stance_larry_marker_nm_senate.md) Marker-R-3(abortion=5 from his own pro-se lawsuits; election-integrity lawsuits don't map to voting-rights, correctly skipped).

**FL-10** (vs Frost): [Stuart Ross Farber](stance_stuart_farber_fl10.md)-R-0, ghost (FEC H6FL10177); don't confuse w/ separate filer "Stuart Dr Farber" NPA/FL-09.

**gen-mixed-8 (SD+TX Senate):** [file](stance_senate_2026_gen_mixed8.md) Bengs-I-SD-9(D→I switch, bengsforsouthdakota.substack.com),Beaudion-D-SD-3(headings only, no body text),Ted-Brown-L-TX-8(TX seat OPEN: Paxton vs Talarico vs Brown; tedbrown.org jina-only).
