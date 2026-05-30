# generate_me_house.ps1
# Generates migration 173: Maine House of Representatives (151 districts, 132nd Legislature)
# 150 named reps + 1 vacant office (District 29 Javner deceased)
# NOTE: District 94 (Cloutier resigned) was filled by Scott Harriman (D) via special election 2026.
#
# Data-quality corrections applied (verified from legislature.maine.gov 2026-05-19):
#   D32: Research listed "Walter Runte" -> actual: Steven Foster (Republican)
#   D34: Research listed "Eleanor Sato" -> actual: Abigail Griffin (Republican)
#   D40: Research listed "D. Ray"       -> actual: D. Michael Ray (Democrat)
#   D58: Research listed "Michael Soboleski" -> actual: Sharon Frost (Unenrolled)
#   D73: Michael Soboleski (Republican) -> confirmed correct
#   D94: Research listed VACANT (Cloutier resigned) -> Scott Harriman (Democrat) won special election 2026
#   D109: Eleanor Sato (Democrat)       -> confirmed correct (Sato is D109 only)
#   D112: Research listed "W. Crockett" -> actual: W. Edward Crockett (Unenrolled)
#   D143: Research listed "Tiffany Roberts" -> actual: Ann Fredericks (Republican)
#   D146: Walter Runte (Democrat)       -> confirmed correct (Runte is D146 only)
#   D149: Tiffany Roberts (Democrat)    -> confirmed correct (Roberts is D149 only)
#   D29: Kathy Javner (R) deceased      -> confirmed still vacant (no special election)

param(
    [string]$Out = "C:/EV-Accounts/backend/migrations/173_me_state_house_officials.sql"
)

$CH = 'Maine House of Representatives'

function EscSql([string]$s) { $s.Replace("'", "''") }

function RepBlock($r) {
    $f   = EscSql $r.full
    $fn  = EscSql $r.first
    $ln  = EscSql $r.last
    $pa  = EscSql $r.party
    $gid = '23' + ([int]$r.dist).ToString().PadLeft(3, '0')
@"
-- ===== District $($r.dist) ($gid): $($r.full) ($($r.party)) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), '$f', '$fn', '$ln', '$pa',
          true, false, false, true, $($r.ext_id))
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = '$CH'),
       p.id,
       'Representative', 'ME', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '$gid' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = '$CH')
  );

"@
}

function VacantBlock($r) {
    $gid = '23' + ([int]$r.dist).ToString().PadLeft(3, '0')
@"
-- ===== District $($r.dist) ($gid): VACANT ($($r.reason)) =====
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = '$CH'),
       NULL,
       'Representative', 'ME', false, true
FROM essentials.districts d
WHERE d.geo_id = '$gid' AND d.district_type = 'STATE_LOWER' AND d.state = 'me'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = '$CH')
  );

"@
}

# 151-entry roster (verified from legislature.maine.gov 2026-05-19).
# All Task 1 Step 1 corrections applied.
# Named rep: @{ dist=N; ext_id=-(232000+N); full='...'; first='...'; last='...'; party='...' }
# Vacant:    @{ dist=N; vacant=$true; reason='...' }
$roster = @(
    @{ dist=1;   ext_id=-232001; full='Lucien Daigle';              first='Lucien';      last='Daigle';              party='Republican'  }
    @{ dist=2;   ext_id=-232002; full='Roger Albert';               first='Roger';       last='Albert';              party='Republican'  }
    @{ dist=3;   ext_id=-232003; full='Mark Babin';                 first='Mark';        last='Babin';               party='Republican'  }
    @{ dist=4;   ext_id=-232004; full='Timothy Guerrette';          first='Timothy';     last='Guerrette';           party='Republican'  }
    @{ dist=5;   ext_id=-232005; full='Joseph Underwood';           first='Joseph';      last='Underwood';           party='Republican'  }
    @{ dist=6;   ext_id=-232006; full='Donald Ardell';              first='Donald';      last='Ardell';              party='Republican'  }
    @{ dist=7;   ext_id=-232007; full='Gregory Swallow';            first='Gregory';     last='Swallow';             party='Republican'  }
    @{ dist=8;   ext_id=-232008; full='Tracy Quint';                first='Tracy';       last='Quint';               party='Republican'  }
    @{ dist=9;   ext_id=-232009; full='Arthur Mingo';               first='Arthur';      last='Mingo';               party='Republican'  }
    @{ dist=10;  ext_id=-232010; full='William Tuell';              first='William';     last='Tuell';               party='Republican'  }
    @{ dist=11;  ext_id=-232011; full='Tiffany Strout';             first='Tiffany';     last='Strout';              party='Republican'  }
    @{ dist=12;  ext_id=-232012; full='Billy Bob Faulkingham';      first='Billy Bob';   last='Faulkingham';         party='Republican'  }
    @{ dist=13;  ext_id=-232013; full='Russell White';              first='Russell';     last='White';               party='Republican'  }
    @{ dist=14;  ext_id=-232014; full='Gary Friedmann';             first='Gary';        last='Friedmann';           party='Democrat'    }
    @{ dist=15;  ext_id=-232015; full='Holly Eaton';                first='Holly';       last='Eaton';               party='Democrat'    }
    @{ dist=16;  ext_id=-232016; full='Nina Milliken';              first='Nina';        last='Milliken';            party='Democrat'    }
    @{ dist=17;  ext_id=-232017; full='Steven Bishop';              first='Steven';      last='Bishop';              party='Republican'  }
    @{ dist=18;  ext_id=-232018; full='Mathew McIntyre';            first='Mathew';      last='McIntyre';            party='Republican'  }
    @{ dist=19;  ext_id=-232019; full='Richard Campbell';           first='Richard';     last='Campbell';            party='Republican'  }
    @{ dist=20;  ext_id=-232020; full='Dani O''Halloran';           first='Dani';        last="O'Halloran";          party='Democrat'    }
    @{ dist=21;  ext_id=-232021; full='Ambureen Rana';              first='Ambureen';    last='Rana';                party='Democrat'    }
    @{ dist=22;  ext_id=-232022; full='Laura Supica';               first='Laura';       last='Supica';              party='Democrat'    }
    @{ dist=23;  ext_id=-232023; full='Amy Roeder';                 first='Amy';         last='Roeder';              party='Democrat'    }
    @{ dist=24;  ext_id=-232024; full='Sean Faircloth';             first='Sean';        last='Faircloth';           party='Democrat'    }
    @{ dist=25;  ext_id=-232025; full='Laurie Osher';               first='Laurie';      last='Osher';               party='Democrat'    }
    @{ dist=26;  ext_id=-232026; full='James Dill';                 first='James';       last='Dill';                party='Democrat'    }
    @{ dist=27;  ext_id=-232027; full='Gary Drinkwater';            first='Gary';        last='Drinkwater';          party='Republican'  }
    @{ dist=28;  ext_id=-232028; full='Irene Gifford';              first='Irene';       last='Gifford';             party='Republican'  }
    @{ dist=29;  vacant=$true;   reason='Kathy Javner (R) deceased, no special election as of 2026-05-19' }
    @{ dist=30;  ext_id=-232030; full='James White';                first='James';       last='White';               party='Republican'  }
    @{ dist=31;  ext_id=-232031; full='Chad Perkins';               first='Chad';        last='Perkins';             party='Republican'  }
    @{ dist=32;  ext_id=-232032; full='Steven Foster';              first='Steven';      last='Foster';              party='Republican'  }
    @{ dist=33;  ext_id=-232033; full='Kenneth Fredette';           first='Kenneth';     last='Fredette';            party='Republican'  }
    @{ dist=34;  ext_id=-232034; full='Abigail Griffin';            first='Abigail';     last='Griffin';             party='Republican'  }
    @{ dist=35;  ext_id=-232035; full='James Thorne';               first='James';       last='Thorne';              party='Republican'  }
    @{ dist=36;  ext_id=-232036; full='Kimberly Haggan';            first='Kimberly';    last='Haggan';              party='Republican'  }
    @{ dist=37;  ext_id=-232037; full='Reagan Paul';                first='Reagan';      last='Paul';                party='Republican'  }
    @{ dist=38;  ext_id=-232038; full='Benjamin Hymes';             first='Benjamin';    last='Hymes';               party='Republican'  }
    @{ dist=39;  ext_id=-232039; full='Janice Dodge';               first='Janice';      last='Dodge';               party='Democrat'    }
    @{ dist=40;  ext_id=-232040; full='D. Michael Ray';             first='D. Michael';  last='Ray';                 party='Democrat'    }
    @{ dist=41;  ext_id=-232041; full='Victoria Doudera';           first='Victoria';    last='Doudera';             party='Democrat'    }
    @{ dist=42;  ext_id=-232042; full='Valli Geiger';               first='Valli';       last='Geiger';              party='Democrat'    }
    @{ dist=43;  ext_id=-232043; full='Ann Matlack';                first='Ann';         last='Matlack';             party='Democrat'    }
    @{ dist=44;  ext_id=-232044; full='William Pluecker';           first='William';     last='Pluecker';            party='Independent' }
    @{ dist=45;  ext_id=-232045; full='Abden Simmons';              first='Abden';       last='Simmons';             party='Republican'  }
    @{ dist=46;  ext_id=-232046; full='Lydia Crafts';               first='Lydia';       last='Crafts';              party='Democrat'    }
    @{ dist=47;  ext_id=-232047; full='Wayne Farrin';               first='Wayne';       last='Farrin';              party='Democrat'    }
    @{ dist=48;  ext_id=-232048; full='Holly Stover';               first='Holly';       last='Stover';              party='Democrat'    }
    @{ dist=49;  ext_id=-232049; full='Allison Hepler';             first='Allison';     last='Hepler';              party='Democrat'    }
    @{ dist=50;  ext_id=-232050; full='David Sinclair';             first='David';       last='Sinclair';            party='Democrat'    }
    @{ dist=51;  ext_id=-232051; full='Rafael Macias';              first='Rafael';      last='Macias';              party='Democrat'    }
    @{ dist=52;  ext_id=-232052; full='Sally Cluchey';              first='Sally';       last='Cluchey';             party='Democrat'    }
    @{ dist=53;  ext_id=-232053; full='Michael Lemelin';            first='Michael';     last='Lemelin';             party='Republican'  }
    @{ dist=54;  ext_id=-232054; full='Karen Montell';              first='Karen';       last='Montell';             party='Democrat'    }
    @{ dist=55;  ext_id=-232055; full='Daniel Shagoury';            first='Daniel';      last='Shagoury';            party='Democrat'    }
    @{ dist=56;  ext_id=-232056; full='Randall Greenwood';          first='Randall';     last='Greenwood';           party='Republican'  }
    @{ dist=57;  ext_id=-232057; full='Tavis Hasenfus';             first='Tavis';       last='Hasenfus';            party='Democrat'    }
    @{ dist=58;  ext_id=-232058; full='Sharon Frost';               first='Sharon';      last='Frost';               party='Unenrolled'  }
    @{ dist=59;  ext_id=-232059; full='David Rollins';              first='David';       last='Rollins';             party='Democrat'    }
    @{ dist=60;  ext_id=-232060; full='William Bridgeo';            first='William';     last='Bridgeo';             party='Democrat'    }
    @{ dist=61;  ext_id=-232061; full='Alicia Collins';             first='Alicia';      last='Collins';             party='Republican'  }
    @{ dist=62;  ext_id=-232062; full='Katrina Smith';              first='Katrina';     last='Smith';               party='Republican'  }
    @{ dist=63;  ext_id=-232063; full='Paul Flynn';                 first='Paul';        last='Flynn';               party='Republican'  }
    @{ dist=64;  ext_id=-232064; full='Flavia DeBrito';             first='Flavia';      last='DeBrito';             party='Democrat'    }
    @{ dist=65;  ext_id=-232065; full='Cassie Julia';               first='Cassie';      last='Julia';               party='Democrat'    }
    @{ dist=66;  ext_id=-232066; full='Robert Nutting';             first='Robert';      last='Nutting';             party='Republican'  }
    @{ dist=67;  ext_id=-232067; full='Shelley Rudnicki';           first='Shelley';     last='Rudnicki';            party='Republican'  }
    @{ dist=68;  ext_id=-232068; full='Amanda Collamore';           first='Amanda';      last='Collamore';           party='Republican'  }
    @{ dist=69;  ext_id=-232069; full='Dean Cray';                  first='Dean';        last='Cray';                party='Republican'  }
    @{ dist=70;  ext_id=-232070; full='Jennifer Poirier';           first='Jennifer';    last='Poirier';             party='Republican'  }
    @{ dist=71;  ext_id=-232071; full='John Ducharme';              first='John';        last='Ducharme';            party='Republican'  }
    @{ dist=72;  ext_id=-232072; full='Elizabeth Caruso';           first='Elizabeth';   last='Caruso';              party='Republican'  }
    @{ dist=73;  ext_id=-232073; full='Michael Soboleski';          first='Michael';     last='Soboleski';           party='Republican'  }
    @{ dist=74;  ext_id=-232074; full='Randall Hall';               first='Randall';     last='Hall';                party='Republican'  }
    @{ dist=75;  ext_id=-232075; full='Stephan Bunker';             first='Stephan';     last='Bunker';              party='Democrat'    }
    @{ dist=76;  ext_id=-232076; full='Sheila Lyman';               first='Sheila';      last='Lyman';               party='Republican'  }
    @{ dist=77;  ext_id=-232077; full='Tammy Schmersal-Burgess';    first='Tammy';       last='Schmersal-Burgess';   party='Republican'  }
    @{ dist=78;  ext_id=-232078; full='Rachel Henderson';           first='Rachel';      last='Henderson';           party='Republican'  }
    @{ dist=79;  ext_id=-232079; full='Michael Lance';              first='Michael';     last='Lance';               party='Republican'  }
    @{ dist=80;  ext_id=-232080; full='Caldwell Jackson';           first='Caldwell';    last='Jackson';             party='Republican'  }
    @{ dist=81;  ext_id=-232081; full='Peter Wood';                 first='Peter';       last='Wood';                party='Republican'  }
    @{ dist=82;  ext_id=-232082; full='Nathan Wadsworth';           first='Nathan';      last='Wadsworth';           party='Republican'  }
    @{ dist=83;  ext_id=-232083; full='Marygrace Cimino';           first='Marygrace';   last='Cimino';              party='Republican'  }
    @{ dist=84;  ext_id=-232084; full='Mark Walker';                first='Mark';        last='Walker';              party='Republican'  }
    @{ dist=85;  ext_id=-232085; full='Kimberly Pomerleau';         first='Kimberly';    last='Pomerleau';           party='Republican'  }
    @{ dist=86;  ext_id=-232086; full='Rolf Olsen';                 first='Rolf';        last='Olsen';               party='Republican'  }
    @{ dist=87;  ext_id=-232087; full='David Boyer';                first='David';       last='Boyer';               party='Republican'  }
    @{ dist=88;  ext_id=-232088; full='Quentin Chapman';            first='Quentin';     last='Chapman';             party='Republican'  }
    @{ dist=89;  ext_id=-232089; full='Adam Lee';                   first='Adam';        last='Lee';                 party='Democrat'    }
    @{ dist=90;  ext_id=-232090; full='Laurel Libby';               first='Laurel';      last='Libby';               party='Republican'  }
    @{ dist=91;  ext_id=-232091; full='Joshua Morris';              first='Joshua';      last='Morris';              party='Republican'  }
    @{ dist=92;  ext_id=-232092; full='Stephen Wood';               first='Stephen';     last='Wood';                party='Republican'  }
    @{ dist=93;  ext_id=-232093; full='Julia McCabe';               first='Julia';       last='McCabe';              party='Democrat'    }
    @{ dist=94;  ext_id=-232094; full='Scott Harriman';             first='Scott';       last='Harriman';            party='Democrat'    }
    @{ dist=95;  ext_id=-232095; full='Mana Abdi';                  first='Mana';        last='Abdi';                party='Democrat'    }
    @{ dist=96;  ext_id=-232096; full='Michel Lajoie';              first='Michel';      last='Lajoie';              party='Democrat'    }
    @{ dist=97;  ext_id=-232097; full='Richard Mason';              first='Richard';     last='Mason';               party='Republican'  }
    @{ dist=98;  ext_id=-232098; full='Kilton Webb';                first='Kilton';      last='Webb';                party='Democrat'    }
    @{ dist=99;  ext_id=-232099; full='Cheryl Golek';               first='Cheryl';      last='Golek';               party='Democrat'    }
    @{ dist=100; ext_id=-232100; full='Daniel Ankeles';             first='Daniel';      last='Ankeles';             party='Democrat'    }
    @{ dist=101; ext_id=-232101; full='Poppy Arford';               first='Poppy';       last='Arford';              party='Democrat'    }
    @{ dist=102; ext_id=-232102; full='Melanie Sachs';              first='Melanie';     last='Sachs';               party='Democrat'    }
    @{ dist=103; ext_id=-232103; full='Arthur Bell';                first='Arthur';      last='Bell';                party='Democrat'    }
    @{ dist=104; ext_id=-232104; full='Amy Arata';                  first='Amy';         last='Arata';               party='Republican'  }
    @{ dist=105; ext_id=-232105; full='Anne Graham';                first='Anne';        last='Graham';              party='Democrat'    }
    @{ dist=106; ext_id=-232106; full='Barbara Bagshaw';            first='Barbara';     last='Bagshaw';             party='Republican'  }
    @{ dist=107; ext_id=-232107; full='Mark Cooper';                first='Mark';        last='Cooper';              party='Republican'  }
    @{ dist=108; ext_id=-232108; full='Parnell Terry';              first='Parnell';     last='Terry';               party='Democrat'    }
    @{ dist=109; ext_id=-232109; full='Eleanor Sato';               first='Eleanor';     last='Sato';                party='Democrat'    }
    @{ dist=110; ext_id=-232110; full='Christina Mitchell';         first='Christina';   last='Mitchell';            party='Democrat'    }
    @{ dist=111; ext_id=-232111; full='Amy Kuhn';                   first='Amy';         last='Kuhn';                party='Democrat'    }
    @{ dist=112; ext_id=-232112; full='W. Edward Crockett';         first='W. Edward';   last='Crockett';            party='Unenrolled'  }
    @{ dist=113; ext_id=-232113; full='Grayson Lookner';            first='Grayson';     last='Lookner';             party='Democrat'    }
    @{ dist=114; ext_id=-232114; full='Dylan Pugh';                 first='Dylan';       last='Pugh';                party='Democrat'    }
    @{ dist=115; ext_id=-232115; full='Michael Brennan';            first='Michael';     last='Brennan';             party='Democrat'    }
    @{ dist=116; ext_id=-232116; full='Samuel Zager';               first='Samuel';      last='Zager';               party='Democrat'    }
    @{ dist=117; ext_id=-232117; full='Matt Moonen';                first='Matt';        last='Moonen';              party='Democrat'    }
    @{ dist=118; ext_id=-232118; full='Yusuf Yusuf';                first='Yusuf';       last='Yusuf';               party='Democrat'    }
    @{ dist=119; ext_id=-232119; full='Charles Skold';              first='Charles';     last='Skold';               party='Democrat'    }
    @{ dist=120; ext_id=-232120; full='Deqa Dhalac';                first='Deqa';        last='Dhalac';              party='Democrat'    }
    @{ dist=121; ext_id=-232121; full='Christopher Kessler';        first='Christopher'; last='Kessler';             party='Democrat'    }
    @{ dist=122; ext_id=-232122; full='Matthew Beck';               first='Matthew';     last='Beck';                party='Democrat'    }
    @{ dist=123; ext_id=-232123; full='Michelle Boyer';             first='Michelle';    last='Boyer';               party='Democrat'    }
    @{ dist=124; ext_id=-232124; full='Sophia Warren';              first='Sophia';      last='Warren';              party='Democrat'    }
    @{ dist=125; ext_id=-232125; full='Kelly Murphy';               first='Kelly';       last='Murphy';              party='Democrat'    }
    @{ dist=126; ext_id=-232126; full='Drew Gattine';               first='Drew';        last='Gattine';             party='Democrat'    }
    @{ dist=127; ext_id=-232127; full='Morgan Rielly';              first='Morgan';      last='Rielly';              party='Democrat'    }
    @{ dist=128; ext_id=-232128; full='Suzanne Salisbury';          first='Suzanne';     last='Salisbury';           party='Democrat'    }
    @{ dist=129; ext_id=-232129; full='Marshall Archer';            first='Marshall';    last='Archer';              party='Democrat'    }
    @{ dist=130; ext_id=-232130; full='Lynn Copeland';              first='Lynn';        last='Copeland';            party='Democrat'    }
    @{ dist=131; ext_id=-232131; full='Lori Gramlich';              first='Lori';        last='Gramlich';            party='Democrat'    }
    @{ dist=132; ext_id=-232132; full='Ryan Fecteau';               first='Ryan';        last='Fecteau';             party='Democrat'    }
    @{ dist=133; ext_id=-232133; full='Marc Malon';                 first='Marc';        last='Malon';               party='Democrat'    }
    @{ dist=134; ext_id=-232134; full='Traci Gere';                 first='Traci';       last='Gere';                party='Democrat'    }
    @{ dist=135; ext_id=-232135; full='Daniel Sayre';               first='Daniel';      last='Sayre';               party='Democrat'    }
    @{ dist=136; ext_id=-232136; full='John Eder';                  first='John';        last='Eder';                party='Republican'  }
    @{ dist=137; ext_id=-232137; full='Nathan Carlow';              first='Nathan';      last='Carlow';              party='Republican'  }
    @{ dist=138; ext_id=-232138; full='Mark Blier';                 first='Mark';        last='Blier';               party='Republican'  }
    @{ dist=139; ext_id=-232139; full='David Woodsome';             first='David';       last='Woodsome';            party='Republican'  }
    @{ dist=140; ext_id=-232140; full='Wayne Parry';                first='Wayne';       last='Parry';               party='Republican'  }
    @{ dist=141; ext_id=-232141; full='Lucas Lanigan';              first='Lucas';       last='Lanigan';             party='Republican'  }
    @{ dist=142; ext_id=-232142; full='Anne-Marie Mastraccio';      first='Anne-Marie';  last='Mastraccio';          party='Democrat'    }
    @{ dist=143; ext_id=-232143; full='Ann Fredericks';             first='Ann';         last='Fredericks';          party='Republican'  }
    @{ dist=144; ext_id=-232144; full='Jeffrey Adams';              first='Jeffrey';     last='Adams';               party='Republican'  }
    @{ dist=145; ext_id=-232145; full='Robert Foley';               first='Robert';      last='Foley';               party='Republican'  }
    @{ dist=146; ext_id=-232146; full='Walter Runte';               first='Walter';      last='Runte';               party='Democrat'    }
    @{ dist=147; ext_id=-232147; full='Holly Sargent';              first='Holly';       last='Sargent';             party='Democrat'    }
    @{ dist=148; ext_id=-232148; full='Thomas Lavigne';             first='Thomas';      last='Lavigne';             party='Republican'  }
    @{ dist=149; ext_id=-232149; full='Tiffany Roberts';            first='Tiffany';     last='Roberts';             party='Democrat'    }
    @{ dist=150; ext_id=-232150; full='Michele Meyer';              first='Michele';     last='Meyer';               party='Democrat'    }
    @{ dist=151; ext_id=-232151; full='Kristi Mathieson';           first='Kristi';      last='Mathieson';           party='Democrat'    }
)

# Build output
$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine("-- Migration 173: Maine House of Representatives (132nd Legislature)")
$null = $sb.AppendLine("-- 150 named representatives + 1 vacant office (District 29 Javner deceased)")
$null = $sb.AppendLine("-- NOTE: District 94 (Cloutier resigned) was filled by Scott Harriman (D) via special election 2026.")
$null = $sb.AppendLine("--")
$null = $sb.AppendLine("-- Uses existing Maine House of Representatives chamber from Phase 50 migration 168 (no chamber INSERT).")
$null = $sb.AppendLine("-- Uses existing STATE_LOWER districts from Phase 49 TIGER load (no district INSERT).")
$null = $sb.AppendLine("-- Tribal representatives (Aaron Dana, Brian Reynolds) NOT seeded -- no STATE_LOWER district geofence.")
$null = $sb.AppendLine("-- Idempotent: ON CONFLICT (external_id) DO NOTHING on politicians; WHERE NOT EXISTS on offices.")
$null = $sb.AppendLine("--")
$null = $sb.AppendLine("BEGIN;")
$null = $sb.AppendLine("")

foreach ($r in $roster) {
    if ($r.vacant) {
        $null = $sb.AppendLine((VacantBlock $r))
    } else {
        $null = $sb.AppendLine((RepBlock $r))
    }
}

# office_id back-fill
$null = $sb.AppendLine("-- ===== office_id back-fill =====")
$null = $sb.AppendLine("UPDATE essentials.politicians p")
$null = $sb.AppendLine("SET office_id = o.id")
$null = $sb.AppendLine("FROM essentials.offices o")
$null = $sb.AppendLine("WHERE o.politician_id = p.id")
$null = $sb.AppendLine("  AND p.external_id BETWEEN -232151 AND -232001")
$null = $sb.AppendLine("  AND p.office_id IS NULL;")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("COMMIT;")

# UTF-8 without BOM (required for psql)
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($Out, $sb.ToString(), $utf8NoBom)
Write-Host "Written: $Out"

# Verify counts
$content = Get-Content $Out -Raw
$cteCount = ([regex]::Matches($content, 'WITH ins_p AS')).Count
$vacCount = ([regex]::Matches($content, '-- ===== District \d+ \(\d+\): VACANT')).Count
Write-Host "CTE blocks (named reps): $cteCount  (expected 150)"
Write-Host "Vacant blocks:           $vacCount  (expected 1)"
Write-Host "Total district blocks:   $($cteCount + $vacCount)  (expected 151)"
