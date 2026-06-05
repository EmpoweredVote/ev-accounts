# generate_md_house.ps1
# Generates migration 274: Maryland House of Delegates (141 delegates)
# 140 active + 1 vacant (District 42A -- verified vacant at 2026-06-05 on mgaleg.maryland.gov).
#
# Three district categories:
#   Whole districts (29 districts x 3 = 87 entries):
#     geo_id = '24' + dist.PadLeft(3,'0')  e.g. dist=3 -> '24003'
#     3 separate CTE blocks per district (same geo_id, different ext_id + politician)
#   A/B/C subdistricts (6 parents x 3 = 18 entries):
#     geo_id = '24' + dist.PadLeft(2,'0') + sub  e.g. dist=1, sub='A' -> '2401A'
#     1 block per subdistrict row
#   A/B subdistricts (12 parents, 36 total entries summing to 3 per parent):
#     geo_id = '24' + dist.PadLeft(2,'0') + sub  e.g. dist=2, sub='A' -> '2402A'
#     1-2 blocks per subdistrict row (2+1 or 1+2 split per parent)
#
# CRITICAL: NOT EXISTS guard uses (district_id, politician_id) NOT (district_id, chamber_id).
#           Using chamber_id blocks the 2nd and 3rd office inserts for whole districts.
# CRITICAL: d.state = 'md' (lowercase) -- TIGER loader casing for STATE_LOWER
# CRITICAL: district_type = 'STATE_LOWER' required -- geo_ids 24001-24047 overlap with STATE_UPPER
# CRITICAL: external_id range -2420001 (HD-1A Hinebaugh) through -2420141 (HD-47B Taveras)
# CRITICAL: Whole districts emit 3 CTE blocks per geo_id with different politicians/ext_ids
#
# Non-ASCII names:
#   Joseline Pena-Melnyk (HD-21): n-with-tilde = [char]0x00F1
#   No other accented characters found in 2026RS roster.
#
# Roster verification: 141 entries confirmed from mgaleg.maryland.gov/mgawebsite/Members/Index/house
#   on 2026-06-05: 87 whole + 54 subdistrict. District 42A confirmed vacant.

param(
    [string]$Out = "C:/EV-Accounts/backend/migrations/274_md_delegates.sql"
)

function EscSql([string]$s) { $s.Replace("'", "''") }

function DelegateBlock($r) {
    $f   = EscSql $r.full
    $fn  = EscSql $r.first
    $ln  = EscSql $r.last
    $pa  = EscSql $r.party
    $gid = $r.geo_id
    $isVacant = $r.is_vacant
    $isActive = if ($isVacant) { 'false' } else { 'true' }
    $isIncumbent = if ($isVacant) { 'false' } else { 'true' }
@"
-- ===== $($r.label) ($gid): $($r.full) ($($r.party)) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), '$f', '$fn', '$ln', '$pa',
          $isActive, false, $($isVacant.ToString().ToLower()), $isIncumbent, $($r.ext_id))
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Maryland House of Delegates'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Maryland' AND state = 'MD')),
       p.id,
       'Delegate', 'MD', false, $($isVacant.ToString().ToLower())
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '$gid' AND d.district_type = 'STATE_LOWER' AND d.state = 'md'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

"@
}

# 141-entry roster (verified from mgaleg.maryland.gov 2026-06-05)
# Order: district number asc, then subdistrict letter asc, then alphabetical within whole districts
# ext_id: -2420001 (first entry) through -2420141 (last entry)
$roster = @(
    # ===== District 1 (A/B/C subdistricts -- 1 delegate each) =====
    @{ dist=1;  sub='A'; geo_id='2401A'; label='HD-1A';           ext_id=-2420001; full='Jim Hinebaugh, Jr.';          first='Jim';          last='Hinebaugh, Jr.';          party='Republican'; is_vacant=$false }
    @{ dist=1;  sub='B'; geo_id='2401B'; label='HD-1B';           ext_id=-2420002; full='Jason C. Buckel';             first='Jason';        last='Buckel';                  party='Republican'; is_vacant=$false }
    @{ dist=1;  sub='C'; geo_id='2401C'; label='HD-1C';           ext_id=-2420003; full='Terry L. Baker';              first='Terry';        last='Baker';                   party='Republican'; is_vacant=$false }

    # ===== District 2 (A/B split: 2A=2 delegates, 2B=1 delegate) =====
    @{ dist=2;  sub='A'; geo_id='2402A'; label='HD-2A (1/2)';     ext_id=-2420004; full='William Valentine';          first='William';      last='Valentine';               party='Republican'; is_vacant=$false }
    @{ dist=2;  sub='A'; geo_id='2402A'; label='HD-2A (2/2)';     ext_id=-2420005; full='William J. Wivell';          first='William';      last='Wivell';                  party='Republican'; is_vacant=$false }
    @{ dist=2;  sub='B'; geo_id='2402B'; label='HD-2B';           ext_id=-2420006; full='Matthew J. Schindler';       first='Matthew';      last='Schindler';               party='Democrat';   is_vacant=$false }

    # ===== District 3 (whole -- 3 delegates) =====
    @{ dist=3;  sub=$null; geo_id='24003'; label='HD-3 (1/3)';    ext_id=-2420007; full='Kris Fair';                  first='Kris';         last='Fair';                    party='Democrat';   is_vacant=$false }
    @{ dist=3;  sub=$null; geo_id='24003'; label='HD-3 (2/3)';    ext_id=-2420008; full='Kenneth Kerr';               first='Kenneth';      last='Kerr';                    party='Democrat';   is_vacant=$false }
    @{ dist=3;  sub=$null; geo_id='24003'; label='HD-3 (3/3)';    ext_id=-2420009; full='Karen Simpson';              first='Karen';        last='Simpson';                 party='Democrat';   is_vacant=$false }

    # ===== District 4 (whole -- 3 delegates) =====
    @{ dist=4;  sub=$null; geo_id='24004'; label='HD-4 (1/3)';    ext_id=-2420010; full='Barrie S. Ciliberti';        first='Barrie';       last='Ciliberti';               party='Republican'; is_vacant=$false }
    @{ dist=4;  sub=$null; geo_id='24004'; label='HD-4 (2/3)';    ext_id=-2420011; full='April Miller';               first='April';        last='Miller';                  party='Republican'; is_vacant=$false }
    @{ dist=4;  sub=$null; geo_id='24004'; label='HD-4 (3/3)';    ext_id=-2420012; full='Jesse T. Pippy';             first='Jesse';        last='Pippy';                   party='Republican'; is_vacant=$false }

    # ===== District 5 (whole -- 3 delegates) =====
    @{ dist=5;  sub=$null; geo_id='24005'; label='HD-5 (1/3)';    ext_id=-2420013; full='Christopher Eric Bouchat';  first='Christopher';  last='Bouchat';                 party='Republican'; is_vacant=$false }
    @{ dist=5;  sub=$null; geo_id='24005'; label='HD-5 (2/3)';    ext_id=-2420014; full='April Rose';                first='April';        last='Rose';                    party='Republican'; is_vacant=$false }
    @{ dist=5;  sub=$null; geo_id='24005'; label='HD-5 (3/3)';    ext_id=-2420015; full='Chris Tomlinson';           first='Chris';        last='Tomlinson';               party='Republican'; is_vacant=$false }

    # ===== District 6 (whole -- 3 delegates) =====
    @{ dist=6;  sub=$null; geo_id='24006'; label='HD-6 (1/3)';    ext_id=-2420016; full='Robin L. Grammer, Jr.';     first='Robin';        last='Grammer, Jr.';            party='Republican'; is_vacant=$false }
    @{ dist=6;  sub=$null; geo_id='24006'; label='HD-6 (2/3)';    ext_id=-2420017; full='Robert B. Long';            first='Robert';       last='Long';                    party='Republican'; is_vacant=$false }
    @{ dist=6;  sub=$null; geo_id='24006'; label='HD-6 (3/3)';    ext_id=-2420018; full='Ric Metzgar';               first='Ric';          last='Metzgar';                 party='Republican'; is_vacant=$false }

    # ===== District 7 (A/B split: 7A=2 delegates, 7B=1 delegate) =====
    @{ dist=7;  sub='A'; geo_id='2407A'; label='HD-7A (1/2)';     ext_id=-2420019; full='Ryan Nawrocki';             first='Ryan';         last='Nawrocki';                party='Republican'; is_vacant=$false }
    @{ dist=7;  sub='A'; geo_id='2407A'; label='HD-7A (2/2)';     ext_id=-2420020; full='Kathy Szeliga';             first='Kathy';        last='Szeliga';                 party='Republican'; is_vacant=$false }
    @{ dist=7;  sub='B'; geo_id='2407B'; label='HD-7B';           ext_id=-2420021; full='Lauren Arikan';             first='Lauren';       last='Arikan';                  party='Republican'; is_vacant=$false }

    # ===== District 8 (whole -- 3 delegates) =====
    @{ dist=8;  sub=$null; geo_id='24008'; label='HD-8 (1/3)';    ext_id=-2420022; full='Nick Allen';                first='Nick';         last='Allen';                   party='Democrat';   is_vacant=$false }
    @{ dist=8;  sub=$null; geo_id='24008'; label='HD-8 (2/3)';    ext_id=-2420023; full='Harry Bhandari';            first='Harry';        last='Bhandari';                party='Democrat';   is_vacant=$false }
    @{ dist=8;  sub=$null; geo_id='24008'; label='HD-8 (3/3)';    ext_id=-2420024; full='Kim Ross';                  first='Kim';          last='Ross';                    party='Democrat';   is_vacant=$false }

    # ===== District 9 (A/B split: 9A=2 delegates, 9B=1 delegate) =====
    @{ dist=9;  sub='A'; geo_id='2409A'; label='HD-9A (1/2)';     ext_id=-2420025; full='Chao Wu';                   first='Chao';         last='Wu';                      party='Democrat';   is_vacant=$false }
    @{ dist=9;  sub='A'; geo_id='2409A'; label='HD-9A (2/2)';     ext_id=-2420026; full='Natalie Ziegler';           first='Natalie';      last='Ziegler';                 party='Democrat';   is_vacant=$false }
    @{ dist=9;  sub='B'; geo_id='2409B'; label='HD-9B';           ext_id=-2420027; full='Courtney Watson';           first='Courtney';     last='Watson';                  party='Democrat';   is_vacant=$false }

    # ===== District 10 (whole -- 3 delegates) =====
    @{ dist=10; sub=$null; geo_id='24010'; label='HD-10 (1/3)';   ext_id=-2420028; full='Adrienne A. Jones';         first='Adrienne';     last='Jones';                   party='Democrat';   is_vacant=$false }
    @{ dist=10; sub=$null; geo_id='24010'; label='HD-10 (2/3)';   ext_id=-2420029; full='N. Scott Phillips';         first='N. Scott';     last='Phillips';                party='Democrat';   is_vacant=$false }
    @{ dist=10; sub=$null; geo_id='24010'; label='HD-10 (3/3)';   ext_id=-2420030; full='Jennifer White Holland';    first='Jennifer';     last='White Holland';           party='Democrat';   is_vacant=$false }

    # ===== District 11 (A/B split: 11A=1 delegate, 11B=2 delegates) =====
    @{ dist=11; sub='A'; geo_id='2411A'; label='HD-11A';          ext_id=-2420031; full='Cheryl E. Pasteur';         first='Cheryl';       last='Pasteur';                 party='Democrat';   is_vacant=$false }
    @{ dist=11; sub='B'; geo_id='2411B'; label='HD-11B (1/2)';    ext_id=-2420032; full='Jon S. Cardin';             first='Jon';          last='Cardin';                  party='Democrat';   is_vacant=$false }
    @{ dist=11; sub='B'; geo_id='2411B'; label='HD-11B (2/2)';    ext_id=-2420033; full='Dana Stein';                first='Dana';         last='Stein';                   party='Democrat';   is_vacant=$false }

    # ===== District 12 (A/B split: 12A=2 delegates, 12B=1 delegate) =====
    @{ dist=12; sub='A'; geo_id='2412A'; label='HD-12A (1/2)';    ext_id=-2420034; full='Jessica Feldmark';          first='Jessica';      last='Feldmark';                party='Democrat';   is_vacant=$false }
    @{ dist=12; sub='A'; geo_id='2412A'; label='HD-12A (2/2)';    ext_id=-2420035; full='Terri L. Hill';             first='Terri';        last='Hill';                    party='Democrat';   is_vacant=$false }
    @{ dist=12; sub='B'; geo_id='2412B'; label='HD-12B';          ext_id=-2420036; full='Gary Simmons';              first='Gary';         last='Simmons';                 party='Democrat';   is_vacant=$false }

    # ===== District 13 (whole -- 3 delegates) =====
    @{ dist=13; sub=$null; geo_id='24013'; label='HD-13 (1/3)';   ext_id=-2420037; full='Pam Lanman Guzzone';        first='Pam';          last='Guzzone';                 party='Democrat';   is_vacant=$false }
    @{ dist=13; sub=$null; geo_id='24013'; label='HD-13 (2/3)';   ext_id=-2420038; full='Gabriel M. Moreno';         first='Gabriel';      last='Moreno';                  party='Democrat';   is_vacant=$false }
    @{ dist=13; sub=$null; geo_id='24013'; label='HD-13 (3/3)';   ext_id=-2420039; full='Jen Terrasa';               first='Jen';          last='Terrasa';                 party='Democrat';   is_vacant=$false }

    # ===== District 14 (whole -- 3 delegates) =====
    @{ dist=14; sub=$null; geo_id='24014'; label='HD-14 (1/3)';   ext_id=-2420040; full='Anne R. Kaiser';            first='Anne';         last='Kaiser';                  party='Democrat';   is_vacant=$false }
    @{ dist=14; sub=$null; geo_id='24014'; label='HD-14 (2/3)';   ext_id=-2420041; full='Bernice Mireku-North';      first='Bernice';      last='Mireku-North';            party='Democrat';   is_vacant=$false }
    @{ dist=14; sub=$null; geo_id='24014'; label='HD-14 (3/3)';   ext_id=-2420042; full='Pam Queen';                 first='Pam';          last='Queen';                   party='Democrat';   is_vacant=$false }

    # ===== District 15 (whole -- 3 delegates) =====
    @{ dist=15; sub=$null; geo_id='24015'; label='HD-15 (1/3)';   ext_id=-2420043; full='Linda Foley';               first='Linda';        last='Foley';                   party='Democrat';   is_vacant=$false }
    @{ dist=15; sub=$null; geo_id='24015'; label='HD-15 (2/3)';   ext_id=-2420044; full='David Fraser-Hidalgo';      first='David';        last='Fraser-Hidalgo';          party='Democrat';   is_vacant=$false }
    @{ dist=15; sub=$null; geo_id='24015'; label='HD-15 (3/3)';   ext_id=-2420045; full='Lily Qi';                   first='Lily';         last='Qi';                      party='Democrat';   is_vacant=$false }

    # ===== District 16 (whole -- 3 delegates) =====
    @{ dist=16; sub=$null; geo_id='24016'; label='HD-16 (1/3)';   ext_id=-2420046; full='Marc Korman';               first='Marc';         last='Korman';                  party='Democrat';   is_vacant=$false }
    @{ dist=16; sub=$null; geo_id='24016'; label='HD-16 (2/3)';   ext_id=-2420047; full='Sarah Wolek';               first='Sarah';        last='Wolek';                   party='Democrat';   is_vacant=$false }
    @{ dist=16; sub=$null; geo_id='24016'; label='HD-16 (3/3)';   ext_id=-2420048; full='Teresa Woorman';            first='Teresa';       last='Woorman';                 party='Democrat';   is_vacant=$false }

    # ===== District 17 (whole -- 3 delegates) =====
    @{ dist=17; sub=$null; geo_id='24017'; label='HD-17 (1/3)';   ext_id=-2420049; full='Julie Palakovich Carr';     first='Julie';        last='Palakovich Carr';         party='Democrat';   is_vacant=$false }
    @{ dist=17; sub=$null; geo_id='24017'; label='HD-17 (2/3)';   ext_id=-2420050; full='Ryan Spiegel';              first='Ryan';         last='Spiegel';                 party='Democrat';   is_vacant=$false }
    @{ dist=17; sub=$null; geo_id='24017'; label='HD-17 (3/3)';   ext_id=-2420051; full='Joe Vogel';                 first='Joe';          last='Vogel';                   party='Democrat';   is_vacant=$false }

    # ===== District 18 (whole -- 3 delegates) =====
    @{ dist=18; sub=$null; geo_id='24018'; label='HD-18 (1/3)';   ext_id=-2420052; full='Aaron M. Kaufman';          first='Aaron';        last='Kaufman';                 party='Democrat';   is_vacant=$false }
    @{ dist=18; sub=$null; geo_id='24018'; label='HD-18 (2/3)';   ext_id=-2420053; full='Emily Shetty';              first='Emily';        last='Shetty';                  party='Democrat';   is_vacant=$false }
    @{ dist=18; sub=$null; geo_id='24018'; label='HD-18 (3/3)';   ext_id=-2420054; full='Jared Solomon';             first='Jared';        last='Solomon';                 party='Democrat';   is_vacant=$false }

    # ===== District 19 (whole -- 3 delegates) =====
    @{ dist=19; sub=$null; geo_id='24019'; label='HD-19 (1/3)';   ext_id=-2420055; full='Charlotte Crutchfield';     first='Charlotte';    last='Crutchfield';             party='Democrat';   is_vacant=$false }
    @{ dist=19; sub=$null; geo_id='24019'; label='HD-19 (2/3)';   ext_id=-2420056; full='Bonnie Cullison';           first='Bonnie';       last='Cullison';                party='Democrat';   is_vacant=$false }
    @{ dist=19; sub=$null; geo_id='24019'; label='HD-19 (3/3)';   ext_id=-2420057; full='Vaughn Stewart';            first='Vaughn';       last='Stewart';                 party='Democrat';   is_vacant=$false }

    # ===== District 20 (whole -- 3 delegates) =====
    @{ dist=20; sub=$null; geo_id='24020'; label='HD-20 (1/3)';   ext_id=-2420058; full='Lorig Charkoudian';         first='Lorig';        last='Charkoudian';             party='Democrat';   is_vacant=$false }
    @{ dist=20; sub=$null; geo_id='24020'; label='HD-20 (2/3)';   ext_id=-2420059; full='David Moon';                first='David';        last='Moon';                    party='Democrat';   is_vacant=$false }
    @{ dist=20; sub=$null; geo_id='24020'; label='HD-20 (3/3)';   ext_id=-2420060; full='Jheanelle K. Wilkins';      first='Jheanelle';    last='Wilkins';                 party='Democrat';   is_vacant=$false }

    # ===== District 21 (whole -- 3 delegates) -- NOTE: Pena-Melnyk has n-tilde [char]0x00F1 =====
    @{ dist=21; sub=$null; geo_id='24021'; label='HD-21 (1/3)';   ext_id=-2420061; full='Ben Barnes';                first='Ben';          last='Barnes';                  party='Democrat';   is_vacant=$false }
    @{ dist=21; sub=$null; geo_id='24021'; label='HD-21 (2/3)';   ext_id=-2420062; full='Mary A. Lehman';            first='Mary';         last='Lehman';                  party='Democrat';   is_vacant=$false }
    @{ dist=21; sub=$null; geo_id='24021'; label='HD-21 (3/3)';   ext_id=-2420063; full="Joseline Pe$([char]0x00F1)a-Melnyk"; first='Joseline'; last="Pe$([char]0x00F1)a-Melnyk"; party='Democrat'; is_vacant=$false }

    # ===== District 22 (whole -- 3 delegates) =====
    @{ dist=22; sub=$null; geo_id='24022'; label='HD-22 (1/3)';   ext_id=-2420064; full='Anne Healey';               first='Anne';         last='Healey';                  party='Democrat';   is_vacant=$false }
    @{ dist=22; sub=$null; geo_id='24022'; label='HD-22 (2/3)';   ext_id=-2420065; full='Ashanti Martinez';          first='Ashanti';      last='Martinez';                party='Democrat';   is_vacant=$false }
    @{ dist=22; sub=$null; geo_id='24022'; label='HD-22 (3/3)';   ext_id=-2420066; full='Nicole A. Williams';        first='Nicole';       last='Williams';                party='Democrat';   is_vacant=$false }

    # ===== District 23 (whole -- 3 delegates) =====
    @{ dist=23; sub=$null; geo_id='24023'; label='HD-23 (1/3)';   ext_id=-2420067; full='Adrian Boafo';              first='Adrian';       last='Boafo';                   party='Democrat';   is_vacant=$false }
    @{ dist=23; sub=$null; geo_id='24023'; label='HD-23 (2/3)';   ext_id=-2420068; full='Marvin E. Holmes, Jr.';     first='Marvin';       last='Holmes, Jr.';             party='Democrat';   is_vacant=$false }
    @{ dist=23; sub=$null; geo_id='24023'; label='HD-23 (3/3)';   ext_id=-2420069; full='Kym Taylor';                first='Kym';          last='Taylor';                  party='Democrat';   is_vacant=$false }

    # ===== District 24 (whole -- 3 delegates) =====
    @{ dist=24; sub=$null; geo_id='24024'; label='HD-24 (1/3)';   ext_id=-2420070; full='Tiffany T. Alston';         first='Tiffany';      last='Alston';                  party='Democrat';   is_vacant=$false }
    @{ dist=24; sub=$null; geo_id='24024'; label='HD-24 (2/3)';   ext_id=-2420071; full='Derrick Coley';             first='Derrick';      last='Coley';                   party='Democrat';   is_vacant=$false }
    @{ dist=24; sub=$null; geo_id='24024'; label='HD-24 (3/3)';   ext_id=-2420072; full='Andrea Fletcher Harrison';  first='Andrea';       last='Harrison';                party='Democrat';   is_vacant=$false }

    # ===== District 25 (whole -- 3 delegates) =====
    @{ dist=25; sub=$null; geo_id='24025'; label='HD-25 (1/3)';   ext_id=-2420073; full='Kent Roberson';             first='Kent';         last='Roberson';                party='Democrat';   is_vacant=$false }
    @{ dist=25; sub=$null; geo_id='24025'; label='HD-25 (2/3)';   ext_id=-2420074; full='Denise Roberts';            first='Denise';       last='Roberts';                 party='Democrat';   is_vacant=$false }
    @{ dist=25; sub=$null; geo_id='24025'; label='HD-25 (3/3)';   ext_id=-2420075; full='Karen Toles';               first='Karen';        last='Toles';                   party='Democrat';   is_vacant=$false }

    # ===== District 26 (whole -- 3 delegates) =====
    @{ dist=26; sub=$null; geo_id='24026'; label='HD-26 (1/3)';   ext_id=-2420076; full='Veronica Turner';           first='Veronica';     last='Turner';                  party='Democrat';   is_vacant=$false }
    @{ dist=26; sub=$null; geo_id='24026'; label='HD-26 (2/3)';   ext_id=-2420077; full='Kriselda Valderrama';       first='Kriselda';     last='Valderrama';              party='Democrat';   is_vacant=$false }
    @{ dist=26; sub=$null; geo_id='24026'; label='HD-26 (3/3)';   ext_id=-2420078; full='Jamila J. Woods';           first='Jamila';       last='Woods';                   party='Democrat';   is_vacant=$false }

    # ===== District 27 (A/B/C subdistricts -- 1 delegate each) =====
    @{ dist=27; sub='A'; geo_id='2427A'; label='HD-27A';          ext_id=-2420079; full='Darrell Odom';              first='Darrell';      last='Odom';                    party='Democrat';   is_vacant=$false }
    @{ dist=27; sub='B'; geo_id='2427B'; label='HD-27B';          ext_id=-2420080; full='Jeffrie E. Long, Jr.';      first='Jeffrie';      last='Long, Jr.';               party='Democrat';   is_vacant=$false }
    @{ dist=27; sub='C'; geo_id='2427C'; label='HD-27C';          ext_id=-2420081; full='Mark N. Fisher';            first='Mark';         last='Fisher';                  party='Republican'; is_vacant=$false }

    # ===== District 28 (whole -- 3 delegates) =====
    @{ dist=28; sub=$null; geo_id='24028'; label='HD-28 (1/3)';   ext_id=-2420082; full='Debra Davis';               first='Debra';        last='Davis';                   party='Democrat';   is_vacant=$false }
    @{ dist=28; sub=$null; geo_id='24028'; label='HD-28 (2/3)';   ext_id=-2420083; full='Edith J. Patterson';        first='Edith';        last='Patterson';               party='Democrat';   is_vacant=$false }
    @{ dist=28; sub=$null; geo_id='24028'; label='HD-28 (3/3)';   ext_id=-2420084; full='C. T. Wilson';              first='C. T.';        last='Wilson';                  party='Democrat';   is_vacant=$false }

    # ===== District 29 (A/B/C subdistricts -- 1 delegate each) =====
    @{ dist=29; sub='A'; geo_id='2429A'; label='HD-29A';          ext_id=-2420085; full='Matthew Morgan';            first='Matthew';      last='Morgan';                  party='Republican'; is_vacant=$false }
    @{ dist=29; sub='B'; geo_id='2429B'; label='HD-29B';          ext_id=-2420086; full='Brian M. Crosby';           first='Brian';        last='Crosby';                  party='Democrat';   is_vacant=$false }
    @{ dist=29; sub='C'; geo_id='2429C'; label='HD-29C';          ext_id=-2420087; full='Todd B. Morgan';            first='Todd';         last='Morgan';                  party='Republican'; is_vacant=$false }

    # ===== District 30 (A/B split: 30A=2 delegates, 30B=1 delegate) =====
    @{ dist=30; sub='A'; geo_id='2430A'; label='HD-30A (1/2)';    ext_id=-2420088; full='Dylan Behler';              first='Dylan';        last='Behler';                  party='Democrat';   is_vacant=$false }
    @{ dist=30; sub='A'; geo_id='2430A'; label='HD-30A (2/2)';    ext_id=-2420089; full='Dana Jones';                first='Dana';         last='Jones';                   party='Democrat';   is_vacant=$false }
    @{ dist=30; sub='B'; geo_id='2430B'; label='HD-30B';          ext_id=-2420090; full='Seth A. Howard';            first='Seth';         last='Howard';                  party='Republican'; is_vacant=$false }

    # ===== District 31 (whole -- 3 delegates) =====
    @{ dist=31; sub=$null; geo_id='24031'; label='HD-31 (1/3)';   ext_id=-2420091; full='Brian Chisholm';            first='Brian';        last='Chisholm';                party='Republican'; is_vacant=$false }
    @{ dist=31; sub=$null; geo_id='24031'; label='HD-31 (2/3)';   ext_id=-2420092; full='Nicholaus R. Kipke';        first='Nicholaus';    last='Kipke';                   party='Republican'; is_vacant=$false }
    @{ dist=31; sub=$null; geo_id='24031'; label='HD-31 (3/3)';   ext_id=-2420093; full='LaToya Nkongolo';           first='LaToya';       last='Nkongolo';                party='Republican'; is_vacant=$false }

    # ===== District 32 (whole -- 3 delegates) =====
    @{ dist=32; sub=$null; geo_id='24032'; label='HD-32 (1/3)';   ext_id=-2420094; full='J. Sandy Bartlett';         first='J. Sandy';     last='Bartlett';                party='Democrat';   is_vacant=$false }
    @{ dist=32; sub=$null; geo_id='24032'; label='HD-32 (2/3)';   ext_id=-2420095; full='Mark S. Chang';             first='Mark';         last='Chang';                   party='Democrat';   is_vacant=$false }
    @{ dist=32; sub=$null; geo_id='24032'; label='HD-32 (3/3)';   ext_id=-2420096; full='Mike Rogers';               first='Mike';         last='Rogers';                  party='Democrat';   is_vacant=$false }

    # ===== District 33 (A/B/C subdistricts -- 1 delegate each) =====
    @{ dist=33; sub='A'; geo_id='2433A'; label='HD-33A';          ext_id=-2420097; full='Andrew C. Pruski';          first='Andrew';       last='Pruski';                  party='Democrat';   is_vacant=$false }
    @{ dist=33; sub='B'; geo_id='2433B'; label='HD-33B';          ext_id=-2420098; full='Stuart Michael Schmidt, Jr.'; first='Stuart';     last='Schmidt, Jr.';            party='Republican'; is_vacant=$false }
    @{ dist=33; sub='C'; geo_id='2433C'; label='HD-33C';          ext_id=-2420099; full='Heather Bagnall';           first='Heather';      last='Bagnall';                 party='Democrat';   is_vacant=$false }

    # ===== District 34 (A/B split: 34A=2 delegates, 34B=1 delegate) =====
    @{ dist=34; sub='A'; geo_id='2434A'; label='HD-34A (1/2)';    ext_id=-2420100; full='Andre V. Johnson, Jr.';     first='Andre';        last='Johnson, Jr.';            party='Democrat';   is_vacant=$false }
    @{ dist=34; sub='A'; geo_id='2434A'; label='HD-34A (2/2)';    ext_id=-2420101; full='Steve Johnson';             first='Steve';        last='Johnson';                 party='Democrat';   is_vacant=$false }
    @{ dist=34; sub='B'; geo_id='2434B'; label='HD-34B';          ext_id=-2420102; full='Susan K. McComas';          first='Susan';        last='McComas';                 party='Republican'; is_vacant=$false }

    # ===== District 35 (A/B split: 35A=2 delegates, 35B=1 delegate) =====
    @{ dist=35; sub='A'; geo_id='2435A'; label='HD-35A (1/2)';    ext_id=-2420103; full='Mike Griffith';             first='Mike';         last='Griffith';                party='Republican'; is_vacant=$false }
    @{ dist=35; sub='A'; geo_id='2435A'; label='HD-35A (2/2)';    ext_id=-2420104; full='Teresa E. Reilly';          first='Teresa';       last='Reilly';                  party='Republican'; is_vacant=$false }
    @{ dist=35; sub='B'; geo_id='2435B'; label='HD-35B';          ext_id=-2420105; full='Kevin B. Hornberger';       first='Kevin';        last='Hornberger';              party='Republican'; is_vacant=$false }

    # ===== District 36 (whole -- 3 delegates) =====
    @{ dist=36; sub=$null; geo_id='24036'; label='HD-36 (1/3)';   ext_id=-2420106; full='Steven J. Arentz';          first='Steven';       last='Arentz';                  party='Republican'; is_vacant=$false }
    @{ dist=36; sub=$null; geo_id='24036'; label='HD-36 (2/3)';   ext_id=-2420107; full='Jefferson L. Ghrist';       first='Jefferson';    last='Ghrist';                  party='Republican'; is_vacant=$false }
    @{ dist=36; sub=$null; geo_id='24036'; label='HD-36 (3/3)';   ext_id=-2420108; full='Jay A. Jacobs';             first='Jay';          last='Jacobs';                  party='Republican'; is_vacant=$false }

    # ===== District 37 (A/B split: 37A=1 delegate, 37B=2 delegates) =====
    @{ dist=37; sub='A'; geo_id='2437A'; label='HD-37A';          ext_id=-2420109; full='Sheree Sample-Hughes';      first='Sheree';       last='Sample-Hughes';           party='Democrat';   is_vacant=$false }
    @{ dist=37; sub='B'; geo_id='2437B'; label='HD-37B (1/2)';    ext_id=-2420110; full='Christopher T. Adams';      first='Christopher';  last='Adams';                   party='Republican'; is_vacant=$false }
    @{ dist=37; sub='B'; geo_id='2437B'; label='HD-37B (2/2)';    ext_id=-2420111; full='Thomas S. Hutchinson';      first='Thomas';       last='Hutchinson';              party='Republican'; is_vacant=$false }

    # ===== District 38 (A/B/C subdistricts -- 1 delegate each) =====
    @{ dist=38; sub='A'; geo_id='2438A'; label='HD-38A';          ext_id=-2420112; full='H. Kevin Anderson';         first='H. Kevin';     last='Anderson';                party='Republican'; is_vacant=$false }
    @{ dist=38; sub='B'; geo_id='2438B'; label='HD-38B';          ext_id=-2420113; full='Barry Beauchamp';           first='Barry';        last='Beauchamp';               party='Republican'; is_vacant=$false }
    @{ dist=38; sub='C'; geo_id='2438C'; label='HD-38C';          ext_id=-2420114; full='Wayne A. Hartman';          first='Wayne';        last='Hartman';                 party='Republican'; is_vacant=$false }

    # ===== District 39 (whole -- 3 delegates) =====
    @{ dist=39; sub=$null; geo_id='24039'; label='HD-39 (1/3)';   ext_id=-2420115; full='Gabriel Acevero';           first='Gabriel';      last='Acevero';                 party='Democrat';   is_vacant=$false }
    @{ dist=39; sub=$null; geo_id='24039'; label='HD-39 (2/3)';   ext_id=-2420116; full='Lesley J. Lopez';           first='Lesley';       last='Lopez';                   party='Democrat';   is_vacant=$false }
    @{ dist=39; sub=$null; geo_id='24039'; label='HD-39 (3/3)';   ext_id=-2420117; full='Greg Wims';                 first='Greg';         last='Wims';                    party='Democrat';   is_vacant=$false }

    # ===== District 40 (whole -- 3 delegates) =====
    @{ dist=40; sub=$null; geo_id='24040'; label='HD-40 (1/3)';   ext_id=-2420118; full='Marlon Amprey';             first='Marlon';       last='Amprey';                  party='Democrat';   is_vacant=$false }
    @{ dist=40; sub=$null; geo_id='24040'; label='HD-40 (2/3)';   ext_id=-2420119; full='Frank M. Conaway, Jr.';     first='Frank';        last='Conaway, Jr.';            party='Democrat';   is_vacant=$false }
    @{ dist=40; sub=$null; geo_id='24040'; label='HD-40 (3/3)';   ext_id=-2420120; full='Melissa Wells';             first='Melissa';      last='Wells';                   party='Democrat';   is_vacant=$false }

    # ===== District 41 (whole -- 3 delegates) =====
    @{ dist=41; sub=$null; geo_id='24041'; label='HD-41 (1/3)';   ext_id=-2420121; full='Samuel I. Rosenberg';       first='Samuel';       last='Rosenberg';               party='Democrat';   is_vacant=$false }
    @{ dist=41; sub=$null; geo_id='24041'; label='HD-41 (2/3)';   ext_id=-2420122; full='Malcolm P. Ruff';           first='Malcolm';      last='Ruff';                    party='Democrat';   is_vacant=$false }
    @{ dist=41; sub=$null; geo_id='24041'; label='HD-41 (3/3)';   ext_id=-2420123; full='Sean A. Stinnett';          first='Sean';         last='Stinnett';                party='Democrat';   is_vacant=$false }

    # ===== District 42 (A/B/C subdistricts -- 42A is VACANT) =====
    @{ dist=42; sub='A'; geo_id='2442A'; label='HD-42A (VACANT)'; ext_id=-2420124; full='Vacant';                    first='';             last='Vacant';                  party='';           is_vacant=$true  }
    @{ dist=42; sub='B'; geo_id='2442B'; label='HD-42B';          ext_id=-2420125; full='Michele Guyton';            first='Michele';      last='Guyton';                  party='Democrat';   is_vacant=$false }
    @{ dist=42; sub='C'; geo_id='2442C'; label='HD-42C';          ext_id=-2420126; full='Joshua J. Stonko';          first='Joshua';       last='Stonko';                  party='Republican'; is_vacant=$false }

    # ===== District 43 (A/B split: 43A=2 delegates, 43B=1 delegate) =====
    @{ dist=43; sub='A'; geo_id='2443A'; label='HD-43A (1/2)';    ext_id=-2420127; full='Regina T. Boyce';           first='Regina';       last='Boyce';                   party='Democrat';   is_vacant=$false }
    @{ dist=43; sub='A'; geo_id='2443A'; label='HD-43A (2/2)';    ext_id=-2420128; full='Elizabeth Embry';           first='Elizabeth';    last='Embry';                   party='Democrat';   is_vacant=$false }
    @{ dist=43; sub='B'; geo_id='2443B'; label='HD-43B';          ext_id=-2420129; full='Catherine M. Forbes';       first='Catherine';    last='Forbes';                  party='Democrat';   is_vacant=$false }

    # ===== District 44 (A/B split: 44A=1 delegate, 44B=2 delegates) =====
    @{ dist=44; sub='A'; geo_id='2444A'; label='HD-44A';          ext_id=-2420130; full='Eric Ebersole';             first='Eric';         last='Ebersole';                party='Democrat';   is_vacant=$false }
    @{ dist=44; sub='B'; geo_id='2444B'; label='HD-44B (1/2)';    ext_id=-2420131; full='Aletheia McCaskill';        first='Aletheia';     last='McCaskill';               party='Democrat';   is_vacant=$false }
    @{ dist=44; sub='B'; geo_id='2444B'; label='HD-44B (2/2)';    ext_id=-2420132; full='Sheila Ruth';               first='Sheila';       last='Ruth';                    party='Democrat';   is_vacant=$false }

    # ===== District 45 (whole -- 3 delegates) =====
    @{ dist=45; sub=$null; geo_id='24045'; label='HD-45 (1/3)';   ext_id=-2420133; full='Jackie Addison';            first='Jackie';       last='Addison';                 party='Democrat';   is_vacant=$false }
    @{ dist=45; sub=$null; geo_id='24045'; label='HD-45 (2/3)';   ext_id=-2420134; full='Stephanie Smith';           first='Stephanie';    last='Smith';                   party='Democrat';   is_vacant=$false }
    @{ dist=45; sub=$null; geo_id='24045'; label='HD-45 (3/3)';   ext_id=-2420135; full='Caylin Young';              first='Caylin';       last='Young';                   party='Democrat';   is_vacant=$false }

    # ===== District 46 (whole -- 3 delegates) =====
    @{ dist=46; sub=$null; geo_id='24046'; label='HD-46 (1/3)';   ext_id=-2420136; full='Luke Clippinger';           first='Luke';         last='Clippinger';              party='Democrat';   is_vacant=$false }
    @{ dist=46; sub=$null; geo_id='24046'; label='HD-46 (2/3)';   ext_id=-2420137; full='Mark Edelson';              first='Mark';         last='Edelson';                 party='Democrat';   is_vacant=$false }
    @{ dist=46; sub=$null; geo_id='24046'; label='HD-46 (3/3)';   ext_id=-2420138; full='Robbyn Lewis';              first='Robbyn';       last='Lewis';                   party='Democrat';   is_vacant=$false }

    # ===== District 47 (A/B split: 47A=2 delegates, 47B=1 delegate) =====
    @{ dist=47; sub='A'; geo_id='2447A'; label='HD-47A (1/2)';    ext_id=-2420139; full='Diana M. Fennell';          first='Diana';        last='Fennell';                 party='Democrat';   is_vacant=$false }
    @{ dist=47; sub='A'; geo_id='2447A'; label='HD-47A (2/2)';    ext_id=-2420140; full='Julian Ivey';               first='Julian';       last='Ivey';                    party='Democrat';   is_vacant=$false }
    @{ dist=47; sub='B'; geo_id='2447B'; label='HD-47B';          ext_id=-2420141; full='Deni Taveras';              first='Deni';         last='Taveras';                 party='Democrat';   is_vacant=$false }
)

# Verify roster count
if ($roster.Count -ne 141) {
    Write-Error "ROSTER COUNT ERROR: expected 141, got $($roster.Count). Fix before proceeding."
    exit 1
}

# Build output
$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine("-- Migration 274: Maryland House of Delegates Officials")
$null = $sb.AppendLine("-- 141 delegate offices (140 active + 1 vacant, District 42A).")
$null = $sb.AppendLine("--")
$null = $sb.AppendLine("-- Uses existing Maryland House of Delegates chamber from Phase 93 migration 272.")
$null = $sb.AppendLine("-- Uses existing STATE_LOWER districts from Phase 91 TIGER load.")
$null = $sb.AppendLine("-- Idempotent: ON CONFLICT (external_id) DO NOTHING; WHERE NOT EXISTS (district_id, politician_id).")
$null = $sb.AppendLine("--")
$null = $sb.AppendLine("-- external_id range: -2420001 (HD-1A Hinebaugh) through -2420141 (HD-47B Taveras)")
$null = $sb.AppendLine("-- CRITICAL: NOT EXISTS guard = (district_id, politician_id) NOT (district_id, chamber_id)")
$null = $sb.AppendLine("--           Multi-member whole districts require 3 offices per district_id row.")
$null = $sb.AppendLine("--           (district_id, chamber_id) guard blocks 2nd/3rd office inserts -- DO NOT use.")
$null = $sb.AppendLine("-- CRITICAL: d.state = 'md' (lowercase) -- TIGER loader casing for STATE_LOWER")
$null = $sb.AppendLine("-- CRITICAL: district_type = 'STATE_LOWER' required")
$null = $sb.AppendLine("--           geo_ids 24001-24047 exist in BOTH STATE_UPPER and STATE_LOWER")
$null = $sb.AppendLine("-- CRITICAL: whole districts emit 3 CTE blocks with SAME geo_id but DIFFERENT ext_id + politician")
$null = $sb.AppendLine("--")
$null = $sb.AppendLine("BEGIN;")
$null = $sb.AppendLine("")

foreach ($r in $roster) {
    $null = $sb.AppendLine((DelegateBlock $r))
}

$null = $sb.AppendLine("-- ===== office_id back-fill =====")
$null = $sb.AppendLine("UPDATE essentials.politicians p")
$null = $sb.AppendLine("SET office_id = o.id")
$null = $sb.AppendLine("FROM essentials.offices o")
$null = $sb.AppendLine("WHERE o.politician_id = p.id")
$null = $sb.AppendLine("  AND p.external_id BETWEEN -2420141 AND -2420001")
$null = $sb.AppendLine("  AND p.office_id IS NULL;")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("COMMIT;")

# Write UTF-8 without BOM (required for psql; needed for non-ASCII names like Pena-Melnyk)
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($Out, $sb.ToString(), $utf8NoBom)
Write-Host "Written: $Out"

# Verify counts
$content = Get-Content $Out -Raw -Encoding UTF8
$cteCount = ([regex]::Matches($content, 'WITH ins_p AS')).Count
Write-Host "CTE blocks (delegates): $cteCount  (expected 141)"
if ($cteCount -ne 141) {
    Write-Error "CTE COUNT MISMATCH: expected 141, got $cteCount. Do not apply this migration."
    exit 1
}
