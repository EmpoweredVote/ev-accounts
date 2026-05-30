# generate_ma_house.ps1
# Generates migration 152: Massachusetts House of Representatives
# 158 named representatives + 2 vacant offices (25042, 25075)

param(
    [string]$Out = "C:/EV-Accounts/backend/migrations/152_ma_state_house_officials.sql"
)

$CH = 'Massachusetts House of Representatives'

function EscSql([string]$s) { $s.Replace("'", "''") }

function RepBlock($r) {
    $f   = EscSql $r.full
    $fn  = EscSql $r.first
    $ln  = EscSql $r.last
    $pa  = EscSql $r.party
    $lb  = EscSql $r.label
    $pc  = @{ Democrat='D'; Republican='R'; Unenrolled='U' }[$r.party]
    $emailCol = if ($r.email) { ",`n     email_addresses" } else { "" }
    $emailVal = if ($r.email) { ",`n          ARRAY['$($r.email)']" } else { "" }
@"
-- ===== $($r.geo_id): $($r.full) ($pc) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, urls$emailCol)
  VALUES (gen_random_uuid(), '$f', '$fn', '$ln', '$pa',
          true, false, false, true, $($r.ext_id),
          ARRAY['https://malegislature.gov/Legislators/Profile/$($r.code)']$emailVal)
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
       'Representative, $lb', 'MA', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '$($r.geo_id)' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = '$CH')
  );
"@
}

function VacantBlock($r) {
    $lb = EscSql $r.label
@"
-- ===== $($r.geo_id): VACANT =====
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name = '$CH'),
       NULL,
       'Representative, $lb', 'MA', false, true
FROM essentials.districts d
WHERE d.geo_id = '$($r.geo_id)' AND d.district_type = 'STATE_LOWER' AND d.state = 'ma'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers WHERE name = '$CH')
  );
"@
}

$roster = @(
    # --- Barnstable ---
    @{ geo_id='25001'; ext_id=-210041; full='Christopher R. Flanagan'; first='Christopher'; last='Flanagan'; party='Democrat'; code='CRF1'; label='1st Barnstable District' }
    @{ geo_id='25002'; ext_id=-210042; full='Kip A. Diggs'; first='Kip'; last='Diggs'; party='Democrat'; code='KAD1'; label='2nd Barnstable District' }
    @{ geo_id='25003'; ext_id=-210043; full='David T. Vieira'; first='David'; last='Vieira'; party='Republican'; code='DTV1'; label='3rd Barnstable District' }
    @{ geo_id='25004'; ext_id=-210044; full='Hadley Luddy'; first='Hadley'; last='Luddy'; party='Democrat'; code='H_L1'; label='4th Barnstable District' }
    @{ geo_id='25005'; ext_id=-210045; full='Steven G. Xiarhos'; first='Steven'; last='Xiarhos'; party='Republican'; code='SGX1'; label='5th Barnstable District' }
    @{ geo_id='25006'; ext_id=-210046; full='Thomas W. Moakley'; first='Thomas'; last='Moakley'; party='Democrat'; code='TWM1'; label='Barnstable-Dukes-Nantucket District' }
    # --- Berkshire ---
    @{ geo_id='25007'; ext_id=-210047; full='John Barrett'; first='John'; last='Barrett'; party='Democrat'; code='J_B1'; label='1st Berkshire District' }
    @{ geo_id='25008'; ext_id=-210048; full='Tricia Farley-Bouvier'; first='Tricia'; last='Farley-Bouvier'; party='Democrat'; code='TFB1'; label='2nd Berkshire District' }
    @{ geo_id='25009'; ext_id=-210049; full='Leigh S. Davis'; first='Leigh'; last='Davis'; party='Democrat'; code='LSD1'; label='3rd Berkshire District' }
    # --- Bristol ---
    @{ geo_id='25010'; ext_id=-210050; full='Michael S. Chaisson'; first='Michael'; last='Chaisson'; party='Republican'; code='MSC1'; label='1st Bristol District' }
    @{ geo_id='25011'; ext_id=-210051; full='James K. Hawkins'; first='James'; last='Hawkins'; party='Democrat'; code='JKH1'; label='2nd Bristol District' }
    @{ geo_id='25012'; ext_id=-210052; full='Lisa M. Field'; first='Lisa'; last='Field'; party='Democrat'; code='LMF1'; label='3rd Bristol District' }
    @{ geo_id='25013'; ext_id=-210053; full='Steven S. Howitt'; first='Steven'; last='Howitt'; party='Republican'; code='SSH1'; label='4th Bristol District' }
    @{ geo_id='25014'; ext_id=-210054; full='Justin Thurber'; first='Justin'; last='Thurber'; party='Republican'; code='J_T2'; label='5th Bristol District' }
    @{ geo_id='25015'; ext_id=-210055; full='Carole A. Fiola'; first='Carole'; last='Fiola'; party='Democrat'; code='CAF1'; label='6th Bristol District' }
    @{ geo_id='25016'; ext_id=-210056; full='Alan Silvia'; first='Alan'; last='Silvia'; party='Democrat'; code='A_S1'; label='7th Bristol District' }
    @{ geo_id='25017'; ext_id=-210057; full='Steven J. Ouellette'; first='Steven'; last='Ouellette'; party='Democrat'; code='SJO1'; label='8th Bristol District' }
    @{ geo_id='25018'; ext_id=-210058; full='Christopher M. Markey'; first='Christopher'; last='Markey'; party='Democrat'; code='CMM1'; label='9th Bristol District' }
    @{ geo_id='25019'; ext_id=-210059; full='Mark D. Sylvia'; first='Mark'; last='Sylvia'; party='Democrat'; code='MDS1'; label='10th Bristol District' }
    @{ geo_id='25020'; ext_id=-210060; full='Christopher Hendricks'; first='Christopher'; last='Hendricks'; party='Democrat'; code='C_H1'; label='11th Bristol District' }
    @{ geo_id='25021'; ext_id=-210061; full='Norman J. Orrall'; first='Norman'; last='Orrall'; party='Republican'; code='NJO1'; label='12th Bristol District' }
    @{ geo_id='25022'; ext_id=-210062; full='Antonio F. Cabral'; first='Antonio'; last='Cabral'; party='Democrat'; code='AFC1'; label='13th Bristol District' }
    @{ geo_id='25023'; ext_id=-210063; full='Adam J. Scanlon'; first='Adam'; last='Scanlon'; party='Democrat'; code='AJS1'; label='14th Bristol District' }
    # --- Essex ---
    @{ geo_id='25024'; ext_id=-210064; full='Dawne Shand'; first='Dawne'; last='Shand'; party='Democrat'; code='D_S1'; label='1st Essex District' }
    @{ geo_id='25025'; ext_id=-210065; full='Kristin Kassner'; first='Kristin'; last='Kassner'; party='Democrat'; code='K_K2'; label='2nd Essex District' }
    @{ geo_id='25026'; ext_id=-210066; full='Andres X. Vargas'; first='Andres'; last='Vargas'; party='Democrat'; code='AXV1'; label='3rd Essex District' }
    @{ geo_id='25027'; ext_id=-210067; full='Estela A. Reyes'; first='Estela'; last='Reyes'; party='Democrat'; code='EAR1'; label='4th Essex District' }
    @{ geo_id='25028'; ext_id=-210068; full='Andrew F. Tarr'; first='Andrew'; last='Tarr'; party='Democrat'; code='AFT1'; label='5th Essex District' }
    @{ geo_id='25029'; ext_id=-210069; full='Hannah L. Bowen'; first='Hannah'; last='Bowen'; party='Democrat'; code='HLB1'; label='6th Essex District' }
    @{ geo_id='25030'; ext_id=-210070; full='Manny Cruz'; first='Manny'; last='Cruz'; party='Democrat'; code='M_C3'; label='7th Essex District' }
    @{ geo_id='25031'; ext_id=-210071; full='Jennifer Balinsky Armini'; first='Jennifer'; last='Armini'; party='Democrat'; code='JBA1'; label='8th Essex District' }
    @{ geo_id='25032'; ext_id=-210072; full='Donald H. Wong'; first='Donald'; last='Wong'; party='Republican'; code='DHW1'; label='9th Essex District' }
    @{ geo_id='25033'; ext_id=-210073; full='Daniel F. Cahill'; first='Daniel'; last='Cahill'; party='Democrat'; code='DFC1'; label='10th Essex District' }
    @{ geo_id='25034'; ext_id=-210074; full='Sean Reid'; first='Sean'; last='Reid'; party='Democrat'; code='S_R1'; label='11th Essex District' }
    @{ geo_id='25035'; ext_id=-210075; full='Thomas J. Walsh'; first='Thomas'; last='Walsh'; party='Democrat'; code='TJW1'; label='12th Essex District' }
    @{ geo_id='25036'; ext_id=-210076; full='Sally P. Kerans'; first='Sally'; last='Kerans'; party='Democrat'; code='SPK1'; label='13th Essex District' }
    @{ geo_id='25037'; ext_id=-210077; full='Adrianne P. Ramos'; first='Adrianne'; last='Ramos'; party='Democrat'; code='APR1'; label='14th Essex District' }
    @{ geo_id='25038'; ext_id=-210078; full='Ryan M. Hamilton'; first='Ryan'; last='Hamilton'; party='Democrat'; code='RMH2'; label='15th Essex District' }
    @{ geo_id='25039'; ext_id=-210079; full='Francisco E. Paulino'; first='Francisco'; last='Paulino'; party='Democrat'; code='FEP1'; label='16th Essex District' }
    @{ geo_id='25040'; ext_id=-210080; full='Frank A. Moran'; first='Frank'; last='Moran'; party='Democrat'; code='FAM1'; label='17th Essex District' }
    @{ geo_id='25041'; ext_id=-210081; full='Tram T. Nguyen'; first='Tram'; last='Nguyen'; party='Democrat'; code='TTN1'; label='18th Essex District' }
    # --- Franklin ---
    @{ geo_id='25042'; label='1st Franklin District'; vacant=$true }
    @{ geo_id='25043'; ext_id=-210082; full='Susannah L. Whipps'; first='Susannah'; last='Whipps'; party='Unenrolled'; code='SLG1'; label='2nd Franklin District' }
    # --- Hampden ---
    @{ geo_id='25044'; ext_id=-210083; full='Todd M. Smola'; first='Todd'; last='Smola'; party='Republican'; code='TMS2'; label='1st Hampden District' }
    @{ geo_id='25045'; ext_id=-210084; full='Brian M. Ashe'; first='Brian'; last='Ashe'; party='Democrat'; code='BMA1'; label='2nd Hampden District' }
    @{ geo_id='25046'; ext_id=-210085; full='Nicholas A. Boldyga'; first='Nicholas'; last='Boldyga'; party='Republican'; code='NAG1'; label='3rd Hampden District' }
    @{ geo_id='25047'; ext_id=-210086; full='Kelly W. Pease'; first='Kelly'; last='Pease'; party='Republican'; code='KWP1'; label='4th Hampden District' }
    @{ geo_id='25048'; ext_id=-210087; full='Patricia A. Duffy'; first='Patricia'; last='Duffy'; party='Democrat'; code='PAD1'; label='5th Hampden District' }
    @{ geo_id='25049'; ext_id=-210088; full='Michael J. Finn'; first='Michael'; last='Finn'; party='Democrat'; code='MJF1'; label='6th Hampden District' }
    @{ geo_id='25050'; ext_id=-210089; full='Aaron L. Saunders'; first='Aaron'; last='Saunders'; party='Democrat'; code='ALS1'; label='7th Hampden District' }
    @{ geo_id='25051'; ext_id=-210090; full='Shirley A. Arriaga'; first='Shirley'; last='Arriaga'; party='Democrat'; code='SBA1'; label='8th Hampden District' }
    @{ geo_id='25052'; ext_id=-210091; full='Orlando Ramos'; first='Orlando'; last='Ramos'; party='Democrat'; code='O_R1'; label='9th Hampden District' }
    @{ geo_id='25053'; ext_id=-210092; full='Carlos González'; first='Carlos'; last='González'; party='Democrat'; code='C_G1'; label='10th Hampden District' }
    @{ geo_id='25054'; ext_id=-210093; full='Bud L. Williams'; first='Bud'; last='Williams'; party='Democrat'; code='BLW1'; label='11th Hampden District' }
    @{ geo_id='25055'; ext_id=-210094; full='Angelo J. Puppolo'; first='Angelo'; last='Puppolo'; party='Democrat'; code='AJP1'; label='12th Hampden District' }
    # --- Hampshire ---
    @{ geo_id='25056'; ext_id=-210095; full='Lindsay Sabadosa'; first='Lindsay'; last='Sabadosa'; party='Democrat'; code='L_S1'; label='1st Hampshire District' }
    @{ geo_id='25057'; ext_id=-210096; full='Homar Gómez'; first='Homar'; last='Gómez'; party='Democrat'; code='H_G1'; label='2nd Hampshire District' }
    @{ geo_id='25058'; ext_id=-210097; full='Mindy Domb'; first='Mindy'; last='Domb'; party='Democrat'; code='M_D2'; label='3rd Hampshire District' }
    # --- Middlesex ---
    @{ geo_id='25059'; ext_id=-210098; full='Margaret R. Scarsdale'; first='Margaret'; last='Scarsdale'; party='Democrat'; code='MRS1'; label='1st Middlesex District' }
    @{ geo_id='25060'; ext_id=-210099; full='James Arciero'; first='James'; last='Arciero'; party='Democrat'; code='J_A1'; label='2nd Middlesex District' }
    @{ geo_id='25061'; ext_id=-210100; full='Kate Hogan'; first='Kate'; last='Hogan'; party='Democrat'; code='K_H1'; label='3rd Middlesex District' }
    @{ geo_id='25062'; ext_id=-210101; full='Danielle W. Gregoire'; first='Danielle'; last='Gregoire'; party='Democrat'; code='DWG1'; label='4th Middlesex District' }
    @{ geo_id='25063'; ext_id=-210102; full='David P. Linsky'; first='David'; last='Linsky'; party='Democrat'; code='DPL1'; label='5th Middlesex District' }
    @{ geo_id='25064'; ext_id=-210103; full='Priscila S. Sousa'; first='Priscila'; last='Sousa'; party='Democrat'; code='PSS1'; label='6th Middlesex District' }
    @{ geo_id='25065'; ext_id=-210104; full='Jack P. Lewis'; first='Jack'; last='Lewis'; party='Democrat'; code='JPL1'; label='7th Middlesex District' }
    @{ geo_id='25066'; ext_id=-210105; full='James Arena-DeRosa'; first='James'; last='Arena-DeRosa'; party='Democrat'; code='JCD1'; label='8th Middlesex District' }
    @{ geo_id='25067'; ext_id=-210106; full='Thomas M. Stanley'; first='Thomas'; last='Stanley'; party='Democrat'; code='TMS1'; label='9th Middlesex District' }
    @{ geo_id='25068'; ext_id=-210107; full='John J. Lawn'; first='John'; last='Lawn'; party='Democrat'; code='JJL2'; label='10th Middlesex District' }
    @{ geo_id='25069'; ext_id=-210108; full='Amy M. Sangiolo'; first='Amy'; last='Sangiolo'; party='Democrat'; code='AMS3'; label='11th Middlesex District' }
    @{ geo_id='25070'; ext_id=-210109; full='Greg Schwartz'; first='Greg'; last='Schwartz'; party='Democrat'; code='G_S1'; label='12th Middlesex District' }
    @{ geo_id='25071'; ext_id=-210110; full='Carmine L. Gentile'; first='Carmine'; last='Gentile'; party='Democrat'; code='CLG1'; label='13th Middlesex District' }
    @{ geo_id='25072'; ext_id=-210111; full='Simon Cataldo'; first='Simon'; last='Cataldo'; party='Democrat'; code='S_C1'; label='14th Middlesex District' }
    @{ geo_id='25073'; ext_id=-210112; full='Michelle Ciccolo'; first='Michelle'; last='Ciccolo'; party='Democrat'; code='M_C2'; label='15th Middlesex District' }
    @{ geo_id='25074'; ext_id=-210113; full='Rodney M. Elliott'; first='Rodney'; last='Elliott'; party='Democrat'; code='RME1'; label='16th Middlesex District' }
    @{ geo_id='25075'; label='17th Middlesex District'; vacant=$true }
    @{ geo_id='25076'; ext_id=-210114; full='Tara T. Hong'; first='Tara'; last='Hong'; party='Democrat'; code='TTH1'; label='18th Middlesex District' }
    @{ geo_id='25077'; ext_id=-210115; full='David Robertson'; first='David'; last='Robertson'; party='Democrat'; code='D_R1'; label='19th Middlesex District' }
    @{ geo_id='25078'; ext_id=-210116; full='Bradley H. Jones'; first='Bradley'; last='Jones'; party='Republican'; code='BHJ1'; label='20th Middlesex District' }
    @{ geo_id='25079'; ext_id=-210117; full='Kenneth I. Gordon'; first='Kenneth'; last='Gordon'; party='Democrat'; code='KIG1'; label='21st Middlesex District' }
    @{ geo_id='25080'; ext_id=-210118; full='Marc T. Lombardo'; first='Marc'; last='Lombardo'; party='Republican'; code='MTL1'; label='22nd Middlesex District' }
    @{ geo_id='25081'; ext_id=-210119; full='Sean Garballey'; first='Sean'; last='Garballey'; party='Democrat'; code='S_G1'; label='23rd Middlesex District' }
    @{ geo_id='25082'; ext_id=-210120; full='David M. Rogers'; first='David'; last='Rogers'; party='Democrat'; code='DMR1'; label='24th Middlesex District'; email='Dave.Rogers@mahouse.gov' }
    @{ geo_id='25083'; ext_id=-210121; full='Marjorie C. Decker'; first='Marjorie'; last='Decker'; party='Democrat'; code='MCD1'; label='25th Middlesex District'; email='Marjorie.Decker@mahouse.gov' }
    @{ geo_id='25084'; ext_id=-210122; full='Mike Connolly'; first='Mike'; last='Connolly'; party='Democrat'; code='M_C1'; label='26th Middlesex District'; email='Mike.Connolly@mahouse.gov' }
    @{ geo_id='25085'; ext_id=-210123; full='Erika Uyterhoeven'; first='Erika'; last='Uyterhoeven'; party='Democrat'; code='E_U1'; label='27th Middlesex District' }
    @{ geo_id='25086'; ext_id=-210124; full='Joseph W. McGonagle'; first='Joseph'; last='McGonagle'; party='Democrat'; code='jwm1'; label='28th Middlesex District' }
    @{ geo_id='25087'; ext_id=-210125; full='Steven C. Owens'; first='Steven'; last='Owens'; party='Democrat'; code='SCO1'; label='29th Middlesex District' }
    @{ geo_id='25088'; ext_id=-210126; full='Richard M. Haggerty'; first='Richard'; last='Haggerty'; party='Democrat'; code='RMH1'; label='30th Middlesex District' }
    @{ geo_id='25089'; ext_id=-210127; full='Michael S. Day'; first='Michael'; last='Day'; party='Democrat'; code='MSD1'; label='31st Middlesex District' }
    @{ geo_id='25090'; ext_id=-210128; full='Kate Lipper-Garabedian'; first='Kate'; last='Lipper-Garabedian'; party='Democrat'; code='KLG1'; label='32nd Middlesex District' }
    @{ geo_id='25091'; ext_id=-210129; full='Steven Ultrino'; first='Steven'; last='Ultrino'; party='Democrat'; code='S_G2'; label='33rd Middlesex District' }
    @{ geo_id='25092'; ext_id=-210130; full='Christine P. Barber'; first='Christine'; last='Barber'; party='Democrat'; code='CPB2'; label='34th Middlesex District' }
    @{ geo_id='25093'; ext_id=-210131; full='Paul J. Donato'; first='Paul'; last='Donato'; party='Democrat'; code='PJD1'; label='35th Middlesex District' }
    @{ geo_id='25094'; ext_id=-210132; full='Colleen M. Garry'; first='Colleen'; last='Garry'; party='Democrat'; code='CMG1'; label='36th Middlesex District' }
    @{ geo_id='25095'; ext_id=-210133; full='Danillo Sena'; first='Danillo'; last='Sena'; party='Democrat'; code='DAS1'; label='37th Middlesex District' }
    # --- Norfolk ---
    @{ geo_id='25096'; ext_id=-210134; full='Bruce J. Ayers'; first='Bruce'; last='Ayers'; party='Democrat'; code='BJA1'; label='1st Norfolk District' }
    @{ geo_id='25097'; ext_id=-210135; full='Tackey Chan'; first='Tackey'; last='Chan'; party='Democrat'; code='T_C1'; label='2nd Norfolk District' }
    @{ geo_id='25098'; ext_id=-210136; full='Ronald Mariano'; first='Ronald'; last='Mariano'; party='Democrat'; code='R_M1'; label='3rd Norfolk District' }
    @{ geo_id='25099'; ext_id=-210137; full='James M. Murphy'; first='James'; last='Murphy'; party='Democrat'; code='JMM1'; label='4th Norfolk District' }
    @{ geo_id='25100'; ext_id=-210138; full='Mark J. Cusack'; first='Mark'; last='Cusack'; party='Democrat'; code='MJC1'; label='5th Norfolk District' }
    @{ geo_id='25101'; ext_id=-210139; full='William C. Galvin'; first='William'; last='Galvin'; party='Democrat'; code='WCG1'; label='6th Norfolk District' }
    @{ geo_id='25102'; ext_id=-210140; full='Richard G. Wells'; first='Richard'; last='Wells'; party='Democrat'; code='RGW1'; label='7th Norfolk District' }
    @{ geo_id='25103'; ext_id=-210141; full='Edward R. Philips'; first='Edward'; last='Philips'; party='Democrat'; code='ERP1'; label='8th Norfolk District' }
    @{ geo_id='25104'; ext_id=-210142; full='Marcus S. Vaughn'; first='Marcus'; last='Vaughn'; party='Republican'; code='MSV1'; label='9th Norfolk District' }
    @{ geo_id='25105'; ext_id=-210143; full='Jeffrey N. Roy'; first='Jeffrey'; last='Roy'; party='Democrat'; code='JNR1'; label='10th Norfolk District' }
    @{ geo_id='25106'; ext_id=-210144; full='Paul McMurtry'; first='Paul'; last='McMurtry'; party='Democrat'; code='P_M1'; label='11th Norfolk District' }
    @{ geo_id='25107'; ext_id=-210145; full='John H. Rogers'; first='John'; last='Rogers'; party='Democrat'; code='JHR1'; label='12th Norfolk District' }
    @{ geo_id='25108'; ext_id=-210146; full='Joshua Tarsky'; first='Joshua'; last='Tarsky'; party='Democrat'; code='J_T1'; label='13th Norfolk District' }
    @{ geo_id='25109'; ext_id=-210147; full='Alice H. Peisch'; first='Alice'; last='Peisch'; party='Democrat'; code='AHP1'; label='14th Norfolk District' }
    @{ geo_id='25110'; ext_id=-210148; full='Tommy Vitolo'; first='Tommy'; last='Vitolo'; party='Democrat'; code='T_V1'; label='15th Norfolk District' }
    # --- Plymouth ---
    @{ geo_id='25111'; ext_id=-210149; full='Michelle L. Badger'; first='Michelle'; last='Badger'; party='Democrat'; code='MLB1'; label='1st Plymouth District' }
    @{ geo_id='25112'; ext_id=-210150; full='John R. Gaskey'; first='John'; last='Gaskey'; party='Republican'; code='JRG2'; label='2nd Plymouth District' }
    @{ geo_id='25113'; ext_id=-210151; full='Joan Meschino'; first='Joan'; last='Meschino'; party='Democrat'; code='J_M1'; label='3rd Plymouth District' }
    @{ geo_id='25114'; ext_id=-210152; full='Patrick J. Kearney'; first='Patrick'; last='Kearney'; party='Democrat'; code='PJK1'; label='4th Plymouth District' }
    @{ geo_id='25115'; ext_id=-210153; full='David F. DeCoste'; first='David'; last='DeCoste'; party='Republican'; code='DFD1'; label='5th Plymouth District' }
    @{ geo_id='25116'; ext_id=-210154; full='Kenneth P. Sweezey'; first='Kenneth'; last='Sweezey'; party='Republican'; code='KPS1'; label='6th Plymouth District' }
    @{ geo_id='25117'; ext_id=-210155; full='Alyson Sullivan-Almeida'; first='Alyson'; last='Sullivan-Almeida'; party='Republican'; code='AMS2'; label='7th Plymouth District' }
    @{ geo_id='25118'; ext_id=-210156; full='Dennis C. Gallagher'; first='Dennis'; last='Gallagher'; party='Democrat'; code='DCG2'; label='8th Plymouth District' }
    @{ geo_id='25119'; ext_id=-210157; full='Bridget M. Plouffe'; first='Bridget'; last='Plouffe'; party='Democrat'; code='BMP1'; label='9th Plymouth District' }
    @{ geo_id='25120'; ext_id=-210158; full='Michelle M. DuBois'; first='Michelle'; last='DuBois'; party='Democrat'; code='MMD1'; label='10th Plymouth District' }
    @{ geo_id='25121'; ext_id=-210159; full='Rita A. Mendes'; first='Rita'; last='Mendes'; party='Democrat'; code='RAM1'; label='11th Plymouth District' }
    @{ geo_id='25122'; ext_id=-210160; full='Kathleen P. LaNatra'; first='Kathleen'; last='LaNatra'; party='Democrat'; code='KPL1'; label='12th Plymouth District' }
    # --- Suffolk ---
    @{ geo_id='25123'; ext_id=-210161; full='Adrian C. Madaro'; first='Adrian'; last='Madaro'; party='Democrat'; code='ACM1'; label='1st Suffolk District' }
    @{ geo_id='25124'; ext_id=-210162; full='Daniel J. Ryan'; first='Daniel'; last='Ryan'; party='Democrat'; code='djr1'; label='2nd Suffolk District' }
    @{ geo_id='25125'; ext_id=-210163; full='Aaron Michlewitz'; first='Aaron'; last='Michlewitz'; party='Democrat'; code='AMM1'; label='3rd Suffolk District' }
    @{ geo_id='25126'; ext_id=-210164; full='David Biele'; first='David'; last='Biele'; party='Democrat'; code='D_B1'; label='4th Suffolk District' }
    @{ geo_id='25127'; ext_id=-210165; full='Christopher J. Worrell'; first='Christopher'; last='Worrell'; party='Democrat'; code='CJW1'; label='5th Suffolk District' }
    @{ geo_id='25128'; ext_id=-210166; full='Russell E. Holmes'; first='Russell'; last='Holmes'; party='Democrat'; code='REH1'; label='6th Suffolk District' }
    @{ geo_id='25129'; ext_id=-210167; full='Chynah Tyler'; first='Chynah'; last='Tyler'; party='Democrat'; code='C_T1'; label='7th Suffolk District' }
    @{ geo_id='25130'; ext_id=-210168; full='Jay Livingstone'; first='Jay'; last='Livingstone'; party='Democrat'; code='J_L1'; label='8th Suffolk District' }
    @{ geo_id='25131'; ext_id=-210169; full='John F. Moran'; first='John'; last='Moran'; party='Democrat'; code='JFM1'; label='9th Suffolk District' }
    @{ geo_id='25132'; ext_id=-210170; full='William F. MacGregor'; first='William'; last='MacGregor'; party='Democrat'; code='WFM1'; label='10th Suffolk District' }
    @{ geo_id='25133'; ext_id=-210171; full='Judith A. Garcia'; first='Judith'; last='Garcia'; party='Democrat'; code='JAG2'; label='11th Suffolk District' }
    @{ geo_id='25134'; ext_id=-210172; full='Brandy Fluker-Reid'; first='Brandy'; last='Fluker-Reid'; party='Democrat'; code='BFR1'; label='12th Suffolk District' }
    @{ geo_id='25135'; ext_id=-210173; full='Daniel J. Hunt'; first='Daniel'; last='Hunt'; party='Democrat'; code='djh1'; label='13th Suffolk District' }
    @{ geo_id='25136'; ext_id=-210174; full='Rob Consalvo'; first='Rob'; last='Consalvo'; party='Democrat'; code='R_C1'; label='14th Suffolk District' }
    @{ geo_id='25137'; ext_id=-210175; full='Samantha Montaño'; first='Samantha'; last='Montaño'; party='Democrat'; code='S_M1'; label='15th Suffolk District' }
    @{ geo_id='25138'; ext_id=-210176; full='Jessica A. Giannino'; first='Jessica'; last='Giannino'; party='Democrat'; code='JAG1'; label='16th Suffolk District' }
    @{ geo_id='25139'; ext_id=-210177; full='Kevin G. Honan'; first='Kevin'; last='Honan'; party='Democrat'; code='KGH1'; label='17th Suffolk District' }
    @{ geo_id='25140'; ext_id=-210178; full='Michael J. Moran'; first='Michael'; last='Moran'; party='Democrat'; code='MJM1'; label='18th Suffolk District' }
    @{ geo_id='25141'; ext_id=-210179; full='Jeffrey R. Turco'; first='Jeffrey'; last='Turco'; party='Democrat'; code='JRT1'; label='19th Suffolk District' }
    # --- Worcester ---
    @{ geo_id='25142'; ext_id=-210180; full='Kimberly N. Ferguson'; first='Kimberly'; last='Ferguson'; party='Republican'; code='KNF1'; label='1st Worcester District' }
    @{ geo_id='25143'; ext_id=-210181; full='Jonathan D. Zlotnik'; first='Jonathan'; last='Zlotnik'; party='Democrat'; code='JDZ1'; label='2nd Worcester District' }
    @{ geo_id='25144'; ext_id=-210182; full='Michael P. Kushmerek'; first='Michael'; last='Kushmerek'; party='Democrat'; code='MPK1'; label='3rd Worcester District' }
    @{ geo_id='25145'; ext_id=-210183; full='Natalie Higgins'; first='Natalie'; last='Higgins'; party='Democrat'; code='N_H1'; label='4th Worcester District' }
    @{ geo_id='25146'; ext_id=-210184; full='Donald R. Berthiaume'; first='Donald'; last='Berthiaume'; party='Republican'; code='DRB1'; label='5th Worcester District' }
    @{ geo_id='25147'; ext_id=-210185; full='John J. Marsi'; first='John'; last='Marsi'; party='Republican'; code='JJM1'; label='6th Worcester District' }
    @{ geo_id='25148'; ext_id=-210186; full='Paul K. Frost'; first='Paul'; last='Frost'; party='Republican'; code='PKF1'; label='7th Worcester District' }
    @{ geo_id='25149'; ext_id=-210187; full='Michael J. Soter'; first='Michael'; last='Soter'; party='Republican'; code='MJS3'; label='8th Worcester District' }
    @{ geo_id='25150'; ext_id=-210188; full='David K. Muradian'; first='David'; last='Muradian'; party='Republican'; code='DKM1'; label='9th Worcester District' }
    @{ geo_id='25151'; ext_id=-210189; full='Brian W. Murray'; first='Brian'; last='Murray'; party='Democrat'; code='BWM1'; label='10th Worcester District' }
    @{ geo_id='25152'; ext_id=-210190; full='Hannah E. Kane'; first='Hannah'; last='Kane'; party='Republican'; code='HEK1'; label='11th Worcester District' }
    @{ geo_id='25153'; ext_id=-210191; full='Meghan Kilcoyne'; first='Meghan'; last='Kilcoyne'; party='Democrat'; code='M_K1'; label='12th Worcester District' }
    @{ geo_id='25154'; ext_id=-210192; full='John J. Mahoney'; first='John'; last='Mahoney'; party='Democrat'; code='JJM2'; label='13th Worcester District' }
    @{ geo_id='25155'; ext_id=-210193; full="James J. O'Day"; first='James'; last="O'Day"; party='Democrat'; code='JJO1'; label='14th Worcester District' }
    @{ geo_id='25156'; ext_id=-210194; full='Mary S. Keefe'; first='Mary'; last='Keefe'; party='Democrat'; code='MSK1'; label='15th Worcester District' }
    @{ geo_id='25157'; ext_id=-210195; full='Daniel M. Donahue'; first='Daniel'; last='Donahue'; party='Democrat'; code='DMD1'; label='16th Worcester District' }
    @{ geo_id='25158'; ext_id=-210196; full='David A. LeBoeuf'; first='David'; last='LeBoeuf'; party='Democrat'; code='DAL1'; label='17th Worcester District' }
    @{ geo_id='25159'; ext_id=-210197; full='Joseph D. McKenna'; first='Joseph'; last='McKenna'; party='Republican'; code='JDM1'; label='18th Worcester District' }
    @{ geo_id='25160'; ext_id=-210198; full='Kate Donaghue'; first='Kate'; last='Donaghue'; party='Democrat'; code='K_D1'; label='19th Worcester District' }
)

# Build output
$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine("-- Migration 152: Massachusetts House of Representatives")
$null = $sb.AppendLine("-- 158 named representatives + 2 vacant offices (25042, 25075)")
$null = $sb.AppendLine("")

foreach ($r in $roster) {
    if ($r.vacant) {
        $null = $sb.AppendLine((VacantBlock $r))
    } else {
        $null = $sb.AppendLine((RepBlock $r))
    }
}

# Write UTF-8 without BOM (required for psql)
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($Out, $sb.ToString(), $utf8NoBom)
Write-Host "Written: $Out"

# Verify counts
$content = Get-Content $Out -Raw
$cteCount  = ([regex]::Matches($content, 'WITH ins_p AS')).Count
$vacCount  = ([regex]::Matches($content, '-- ===== \d+: VACANT')).Count
Write-Host "CTE blocks (named reps): $cteCount  (expected 158)"
Write-Host "Vacant blocks:           $vacCount  (expected 2)"
