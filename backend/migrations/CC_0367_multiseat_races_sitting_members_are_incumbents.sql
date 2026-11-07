-- CC_0367 — in a race that fills MORE THAN ONE SEAT, a candidate who sits on that same body on election
--           day is an incumbent. 128 race_candidates rows said otherwise.
--
-- Slot CC_0367 reserved via `npm run steward --prefix backend -- slot CC` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand (pure DML). No DELETE.
-- ✅ APPLIED to prod 2026-11-07 by Chris Andrews: dry run (ROLLBACK) then apply, both gates green each time. Re-read after:
--   check:incumbency 0 drift (control passed) and check:duplicate-people OK.
--
-- WHY. race_candidates.is_incumbent was ruled on 2026-11-04 to mean "incumbent OF THE SEAT THIS RACE IS FOR"
--   (CC_0343). A race row points at ONE office, and a multi-seat race (a council electing three, a state
--   board electing two) hangs off one of its body's offices. So the seat-only rule called every OTHER
--   sitting member defending a seat in that race a challenger. CC_0364 marked four such board members
--   (Galuteria, Waihee IV, Tilley, Tebay) correctly as incumbents, check:incumbency reported them as drift,
--   and master CI went red on 2026-11-07.
-- RULED 2026-11-07 (Chris Andrews): in a race with seats > 1, a candidate holding ANY office of the race
--   office's chamber on the race's election date is an incumbent. Single-seat races are unchanged.
--   scripts/reconcile-incumbency.mjs carries the same predicate (same PR), so the daily check and this
--   file agree; run read-only before this file, it reported exactly these 128 rows plus Garcia Richard
--   (CC_0365).
--
-- THE 128 (84 races, 2026-05-02 .. 2026-11-03), measured 2026-11-07. Each holds a current term on an office
--   of the race office's chamber on election day and does NOT hold the race's own office. Reviewed by
--   shape: city councils (several "Mayor" holders are council members in a rotating-mayor city), water,
--   library and services district boards, school boards, and the Arizona Corporation Commission (Kevin
--   Thompson and Nick Myers, both elected 2022 to four-year terms, so both were defending their seats).
--
-- WHAT CHANGES: race_candidates.is_incumbent false -> true on the 128 listed ids. Nothing else.
-- ROLLBACK: set is_incumbent = false on the same 128 ids.
-- IDEMPOTENT: guarded on the pre-image; a re-run changes nothing and both gates still pass.

BEGIN;

CREATE TEMP TABLE _rc (id uuid PRIMARY KEY, full_name text NOT NULL, race text NOT NULL) ON COMMIT DROP;
INSERT INTO _rc VALUES
  ('e4b506cc-9c06-48e7-b3ba-9b0cdb14fa08'::uuid, 'Kevin Thompson', 'Arizona Corporation Commission'),
  ('2db1547a-59ed-477e-b38e-8077b53da2dd'::uuid, 'Nick Myers', 'Arizona Corporation Commission'),
  ('f354a410-4e57-4d3a-9f95-7a5732aa06be'::uuid, 'Melissa Ramoso', 'Artesia City Council'),
  ('8d899442-7676-4e78-a528-2dcf1520510d'::uuid, 'Rene J. Trevino', 'Artesia City Council'),
  ('0d00ee04-3825-422c-9c46-6b4020b4e7e6'::uuid, 'Alejandra Avila', 'Baldwin Park City Council'),
  ('d77398ce-e7b7-4c9b-9ea2-d460700b2ad7'::uuid, 'Jean M. Ayala', 'Baldwin Park City Council'),
  ('cc3056a4-3193-4645-b3a4-ca247ded936a'::uuid, 'John B. De Leon', 'Baldwin Park Unified School Board'),
  ('3acbd303-c58f-499f-9d54-166f6e0ee470'::uuid, 'Aaron Simental', 'Bassett Unified School Board'),
  ('9c23555f-fd3b-436b-a9ac-ac55408e05cd'::uuid, 'Patrice Stanzione', 'Bassett Unified School Board'),
  ('a8a05ce4-550d-4311-8a51-109c8ba7ee3f'::uuid, 'Francis De Leon Sanchez', 'Bell Gardens City Council'),
  ('ad751e96-125d-4597-aeec-5af1399ce754'::uuid, 'Marco Barcena', 'Bell Gardens City Council'),
  ('529370ab-1e08-4f76-a0e1-4e03f8c4932d'::uuid, 'Miguel De La Rosa', 'Bell Gardens City Council'),
  ('c681cd55-3d94-4d8a-90c3-f72042d12aa9'::uuid, 'Judith Manouchehri', 'Beverly Hills Unified School Board'),
  ('9f07ae34-f5d4-4d2e-8fca-21cfbf72a12a'::uuid, 'Nikki Perez', 'Burbank City Council'),
  ('4e11238e-e200-4346-b5d0-a3aa3fd4d85a'::uuid, 'Tamala Takahashi', 'Burbank City Council'),
  ('59821dfb-00db-41f3-835b-be0f355cc296'::uuid, 'Mireya Garcia', 'Commerce City Council'),
  ('569c56a0-fe68-47ab-a9cb-d91ca29212b8'::uuid, 'Jeffery W. Johnson', 'Crescenta Valley Water District Board'),
  ('a518bf4b-a889-4873-b322-1abb56c1a8c0'::uuid, 'Martin U. Fuentes', 'Cudahy City Council'),
  ('6551697a-7efb-4b38-83b6-26b52bbb51f5'::uuid, 'Freddy Puza', 'Culver City City Council'),
  ('0f221378-b043-49bd-9769-655842b23962'::uuid, 'Brian Guerrero', 'Culver City Unified School Board'),
  ('50ec9c2a-8058-4442-a82f-597b70764cca'::uuid, 'Stephanie Loredo', 'Culver City Unified School Board'),
  ('5a84b690-be4a-4fe3-8e15-a515e8f7dd5b'::uuid, 'Cesar Peralta', 'El Monte City School Board'),
  ('f03d9da0-d8fb-4ffb-a1ab-d766f058f876'::uuid, 'Elizabeth "Beth" Rivas', 'El Monte City School Board'),
  ('119fe4f2-6ced-4948-a1f0-da7728818275'::uuid, 'Esther Mejia', 'El Rancho Unified School Board'),
  ('9989a055-83d4-4621-aa22-547b964488b0'::uuid, 'Hector Lafarga Jr.', 'El Rancho Unified School Board'),
  ('64f691bd-35b7-4f82-b6fd-dc08d6b587ac'::uuid, 'Ryan W. Baldino', 'El Segundo City Council'),
  ('48b2f458-838f-4bf3-b755-f2a2859e931b'::uuid, 'Frank Christopher Glynn', 'El Segundo Unified School Board'),
  ('de3ae7b8-d68e-4346-ac57-d57f1b11cae5'::uuid, 'Tracey I. Miller-Zarneke', 'El Segundo Unified School Board'),
  ('7234d555-d0cf-4f12-98d2-f55adfb00ece'::uuid, 'Alek Bartrosouf', 'Glendale City Council'),
  ('6f4994bf-4f97-4ef2-b68f-b8618f522d40'::uuid, 'Dan Brotman', 'Glendale City Council'),
  ('d4e41b93-4179-44df-9d4d-4c2f0397aa1a'::uuid, 'Dandy De Paula', 'Hawaiian Gardens City Council'),
  ('893c99f3-fbb4-490b-aaac-83d373255d44'::uuid, 'Luis Roa', 'Hawaiian Gardens City Council'),
  ('16e61305-55ee-40fe-9ff5-b2c19479d173'::uuid, 'Maria Teresa Del Rio', 'Hawaiian Gardens City Council'),
  ('369bf570-caa8-437c-8203-13ac935e7cd7'::uuid, 'Alexandre ''Alex'' Monteiro', 'Hawthorne City Council'),
  ('e6054c3d-b0fe-4f2a-b431-e204e969286e'::uuid, 'Eugene Krank', 'Hawthorne School Board'),
  ('70a81201-3f9b-449d-8882-4bbe02cd21a3'::uuid, 'Luciano Aguilar', 'Hawthorne School Board'),
  ('e577b45f-8fd0-4873-a0b6-7e2819ccf5df'::uuid, 'Jen Cole', 'Hermosa Beach City School Board'),
  ('f8223760-ac84-4275-86be-f2c59674bc3a'::uuid, 'Hector "Manuel" Ortiz', 'Irwindale City Council'),
  ('a8a1af85-e78a-4f4d-b749-9a8d798b8215'::uuid, 'Joe Radabaugh', 'La Cañada Unified School Board'),
  ('a92b8dcb-372b-4213-bc87-170be33f8875'::uuid, 'Octavia Thuss', 'La Cañada Unified School Board'),
  ('ea62e2fb-492c-470d-8c99-64c3f7bfcc59'::uuid, 'Henry P. Hernandez', 'La Puente Valley County Water District Board'),
  ('e3b17d51-7a38-463c-97d6-5ce8aed96ece'::uuid, 'John P. Escalera', 'La Puente Valley County Water District Board'),
  ('adf66625-684f-496f-9551-cf9548e53446'::uuid, 'Dallas Lawrence', 'Las Virgenes Unified School Board'),
  ('461a1014-2d9a-4bee-a8e1-23c4d27e8981'::uuid, 'Bernadette Lourdes Suarez', 'Lawndale City Council'),
  ('7b9d2d6e-9d4a-4f47-85d1-71dbb986678d'::uuid, 'Karina Cordero', 'Lennox School Board'),
  ('92e12961-f0bc-4c1b-bb47-0e9e2440bf29'::uuid, 'Gabriela Camacho', 'Lynwood City Council'),
  ('7ea74797-8f07-47c2-b08a-81c66e8affce'::uuid, 'Juan Muñoz-Guevara', 'Lynwood City Council'),
  ('ceb1f135-adfa-4a08-97e4-07ebc18f25f2'::uuid, 'Julian Del Real-Calleros', 'Lynwood Unified School Board'),
  ('52fff4cf-f4c2-499e-95e5-6fff9e4f2301'::uuid, 'Doug Stewart', 'Malibu City Council'),
  ('8e979c21-3313-4d06-986a-95872b90912a'::uuid, 'Marianne Riggins', 'Malibu City Council'),
  ('2adbe68c-0f6c-4ed2-ad99-23b165258529'::uuid, 'Amy Howorth', 'Manhattan Beach City Council'),
  ('20886a6b-e7c6-4424-9be7-a707f74e8fc4'::uuid, 'Christina "Tina" Shivpuri', 'Manhattan Beach Unified School Board'),
  ('3c865c21-c31c-488a-bb48-4bab6f869819'::uuid, 'Kristen "Wysh" Weinstein', 'Manhattan Beach Unified School Board'),
  ('38427ffb-dce9-435e-a66c-9c6887cd4b87'::uuid, 'Eduardo Eddie De La Riva', 'Maywood City Council'),
  ('25c5e02b-6cbe-41cd-9a0e-6fcb183e77d4'::uuid, 'Mayra Aguiluz', 'Maywood City Council'),
  ('e4ed5da8-aed5-4d5e-82a9-7f8b5052847b'::uuid, 'Larry J. Spicer', 'Monrovia City Council'),
  ('b6afebd1-fc50-4504-ab33-efceed50b5d9'::uuid, 'Adam C. Carranza', 'Mountain View School Board'),
  ('7d956514-75ce-44fa-b0da-e04c3b5aeae7'::uuid, 'Cindy Wu', 'Mountain View School Board'),
  ('cf1cdb45-b098-40e1-a14c-2c3f0a499460'::uuid, 'Veronica B. Sifuentes', 'Mountain View School Board'),
  ('af0a69d1-8cdc-40fe-b0c4-bc2cfcacd8da'::uuid, 'Tony Ayala', 'Norwalk City Council'),
  ('1ee38e04-f80d-4bbc-a131-c70c99de62cd'::uuid, 'Michael Kemps', 'Palos Verdes Estates City Council'),
  ('87aae6c0-9ddd-4caa-b4fa-95c6e523d315'::uuid, 'Victoria Lozzi', 'Palos Verdes Estates City Council'),
  ('1d3d48e9-7733-4f9a-b001-69daa4c8947e'::uuid, 'Beth K. Whittenbury', 'Palos Verdes Library District Board'),
  ('168002da-7c38-4d42-b9ea-65e5f4a06c0c'::uuid, 'Billy Barron', 'Parker Councilmember At-Large'),
  ('5c9eae2c-6b9a-469c-bbbb-7cc6c6955506'::uuid, 'Buddy Pilgrim', 'Parker Councilmember At-Large'),
  ('c7e9cde7-7f85-4553-bb4b-a1f7e218fcb0'::uuid, 'Gustavo V. Camacho', 'Pico Rivera City Council'),
  ('8aa76b14-1198-4ba9-9497-2e72e88e13c0'::uuid, 'John R. Garcia', 'Pico Rivera City Council'),
  ('204683dd-b4d9-42db-980f-2347626b83f2'::uuid, 'James Black, M.D.', 'Rolling Hills City Council'),
  ('2e900c4e-6a8a-4d71-a61e-9685d0ea1b24'::uuid, 'Leah Mirsch', 'Rolling Hills City Council'),
  ('960a7f41-33be-4b26-b63d-2b5b9539daee'::uuid, 'Sandra Armenta', 'Rosemead City Council'),
  ('7196821b-91d3-4cf9-989f-0975b15fe393'::uuid, 'Steven Ly', 'Rosemead City Council'),
  ('598e5388-5cb0-4f3f-80a8-18d6031a3970'::uuid, 'Diane Benitez', 'Rosemead School Board'),
  ('f2d77148-97ee-44c7-bf00-b3b4f66e01a9'::uuid, 'John Quintanilla', 'Rosemead School Board'),
  ('7e0c8a4b-a1c8-4ecd-9587-063f6c276d7c'::uuid, 'Denise Menchaca', 'San Gabriel City Council'),
  ('ef8b9b8e-19e0-4180-b10e-3ccd17404f8c'::uuid, 'John Wu', 'San Gabriel City Council'),
  ('4c4c6bd9-029d-4201-a53d-4349c550bf2b'::uuid, 'Gary Thomas Scott', 'San Gabriel Unified School Board'),
  ('2812b8a9-df2d-4c0b-a8eb-11256b29cbff'::uuid, 'Rochelle Kate Ongsiako Haas', 'San Gabriel Unified School Board'),
  ('8dabad7a-603b-4bff-a86e-9a22e936ba14'::uuid, 'Calvin Lo', 'San Marino City Council'),
  ('d7687169-c225-44b8-bb0f-c31d86a9d2dd'::uuid, 'Shelley Carolyn Ryan', 'San Marino Unified School Board'),
  ('d93f44eb-0389-4833-ab51-f4a92e2b8778'::uuid, 'Kenneth "Ken" Petersen', 'Santa Clarita Valley Water Agency Board - Division 3'),
  ('ac0cdc15-ec0c-4d67-aa2c-dd44d3ce4b8f'::uuid, 'Bill "William" Rounds', 'Santa Fe Springs City Council'),
  ('3e4b9445-95d2-4135-bc81-f1034724873e'::uuid, 'Juanita Martin', 'Santa Fe Springs City Council'),
  ('749ef9c2-8c9e-44c2-80d9-253e71c20e5d'::uuid, 'Caroline Torosis', 'Santa Monica City Council'),
  ('51c3f89a-fb6c-4bcd-a6b4-cf633e0063ad'::uuid, 'Lana Negrete', 'Santa Monica City Council'),
  ('2b1d86ee-6208-471a-be0d-29e43ce2398f'::uuid, 'Luis Barrera Castañón', 'Santa Monica Community College Board'),
  ('58da4b18-a601-4ac7-a91c-8653d7242838'::uuid, 'Sion Roy', 'Santa Monica Community College Board'),
  ('a304f248-df3b-414c-ae72-6bd931a444e0'::uuid, 'Tom Peters', 'Santa Monica Community College Board'),
  ('4509b08d-b78b-490f-9904-e925375dfb53'::uuid, 'Alicia Mignano', 'Santa Monica-Malibu Unified School Board'),
  ('25bc5bb1-0385-429d-beac-ab05199b7944'::uuid, 'Laurie Lieberman', 'Santa Monica-Malibu Unified School Board'),
  ('2b9537d4-6779-4acb-8c48-3fec8baf0d25'::uuid, 'Stacy Rouse', 'Santa Monica-Malibu Unified School Board'),
  ('43642d5f-15c7-4220-9396-0bbfdab7af81'::uuid, 'Manuel "Manny" Acosta', 'South El Monte City Council'),
  ('bb571e6c-4a3d-4eeb-81b2-1d1632d0f8cf'::uuid, 'Rudy Bojorquez', 'South El Monte City Council'),
  ('37cd8fe3-f939-49bf-808a-554998280112'::uuid, 'Joshua Barron', 'South Gate City Council'),
  ('7313d707-47be-4970-9ad4-1d292e592e99'::uuid, 'Selina Bliss', 'State House District 1'),
  ('d63c3daf-24b9-4a22-aedf-6694acc5da15'::uuid, 'Justin Olson', 'State House District 10'),
  ('bc7f05ec-f776-4bc7-aaad-be5d1e0b5baa'::uuid, 'Oscar De Los Santos', 'State House District 11'),
  ('bf0cfbcb-77f5-40de-a8a1-ea0f16b924cb'::uuid, 'Stacey Travers', 'State House District 12'),
  ('9aae028c-a0df-4670-a739-4c07a0725c9c'::uuid, 'Laurin Hendrix', 'State House District 14'),
  ('f797f71b-4b9c-42fe-80be-45e8768d4829'::uuid, 'Michael Way', 'State House District 15'),
  ('905c424f-9289-45b7-a2ab-918ae84832a8'::uuid, 'Teresa Martinez', 'State House District 16'),
  ('98bcb59c-979f-4a09-af3e-b78c19ce6596'::uuid, 'Rachel Keshel', 'State House District 17'),
  ('120adad9-0bae-4f60-91ae-348236986392'::uuid, 'Nancy Gutierrez', 'State House District 18'),
  ('8716e59b-a9a4-4223-bb8a-9f120e0629f9'::uuid, 'Justin Wilmeth', 'State House District 2'),
  ('4547f7dc-9375-4157-bcb3-170f78f54fd9'::uuid, 'Mariana Sandoval', 'State House District 23'),
  ('bbc00082-80dd-4845-93ca-4d75ccda8cea'::uuid, 'Michael Carbone', 'State House District 25'),
  ('fc99a9c4-11d2-43bc-88bc-2c52efce5872'::uuid, 'Cesar Aguilar', 'State House District 26'),
  ('71a9d517-7fcc-4373-9a11-2ced57a23c14'::uuid, 'Tony Rivero', 'State House District 27'),
  ('6eeb81aa-9427-4730-ab46-d1007591cfa9'::uuid, 'David Livingston', 'State House District 28'),
  ('ed0e370a-ece8-4c3a-b36d-12c3a2a8c39c'::uuid, 'James Taylor', 'State House District 29'),
  ('9d61f494-fa61-43d4-8f2f-c070312086b7'::uuid, 'Pamela Carter', 'State House District 4'),
  ('c21b3484-7ddb-43d8-9ec6-dcb82e9b85d1'::uuid, 'Aaron Márquez', 'State House District 5'),
  ('a15805f5-8c63-4cf1-b943-51999021f648'::uuid, 'Janeen Connolly', 'State House District 8'),
  ('29fa0018-4385-4b06-96c4-298dd0e20694'::uuid, 'Lorena Austin', 'State House District 9'),
  ('a88f6414-f5a5-4a09-a749-8512dc6a8905'::uuid, 'Jacqueline J. Rubio', 'Valle Lindo School Board'),
  ('3a69c6e8-819d-47d5-91bb-e30679c2444f'::uuid, 'Rudy T. Martinez', 'Valle Lindo School Board'),
  ('7932e285-fded-4376-ba44-2c6a0ed7213d'::uuid, 'Jazmin Leos', 'Valley County Water District Board'),
  ('7bcc654d-d205-479e-a5a8-8d69b86cea94'::uuid, 'Lenet Pacheco', 'Valley County Water District Board'),
  ('b0e6507a-a9f4-4bef-b476-6eb02208b3c4'::uuid, 'Allen Wu', 'Walnut City Council'),
  ('ea269aca-51fd-4618-8ba6-06e9aa59bb60'::uuid, 'Cindy M. Ruiz', 'Walnut Valley Unified School Board'),
  ('77d7444d-6a81-4448-baf9-af63aaa7ba91'::uuid, 'Yi Tony Torng', 'Walnut Valley Unified School Board'),
  ('20f00e4d-6630-4cf9-8276-70cf0112bbbe'::uuid, 'Eileen Miranda Jimenez', 'West Covina Unified School Board'),
  ('8386ac19-464e-4eb1-8bcc-d500be3d912e'::uuid, 'Chelsea Byers', 'West Hollywood City Council'),
  ('63d8d49b-fdb4-4e5a-a8cb-f1a9cdb7ec46'::uuid, 'Jennifer Navarro', 'Westside Union School Board'),
  ('46ec2772-73ab-4392-ab4a-afff7fbf19a7'::uuid, 'John Curiel', 'Westside Union School Board'),
  ('ea91c17b-6066-4b17-94d0-ddb30cb6a177'::uuid, 'Nelson E. Martinez', 'Wiseburn Unified School Board'),
  ('5dab4351-4c76-48c3-8ca9-61da303bfd37'::uuid, 'Rebecca Hamburg Cappy', 'Wiseburn Unified School Board'),
  ('23a6d5a6-dbe2-4c71-8dbd-1ac09d0ab3ac'::uuid, 'David E. Schoenwetter', 'Wrightwood Community Services District Board'),
  ('54733b5c-96dd-4755-8d7b-d20676f891ff'::uuid, 'Erin C. DeGroot', 'Wrightwood Community Services District Board');

-- the rule, evaluated per row: multi-seat race, holds an office of the race office's chamber on election
-- day, does not hold the race's own office (those were already right)
CREATE TEMP TABLE _eligible ON COMMIT DROP AS
SELECT rc.id
  FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  JOIN essentials.offices ro ON ro.id = r.office_id
  JOIN essentials.elections e ON e.id = r.election_id
 WHERE r.seats > 1 AND ro.chamber_id IS NOT NULL AND rc.politician_id IS NOT NULL
   AND EXISTS (SELECT 1 FROM essentials.office_terms t JOIN essentials.offices o2 ON o2.id = t.office_id
                WHERE t.politician_id = rc.politician_id AND o2.chamber_id = ro.chamber_id
                  AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                  AND (t.term_end   IS NULL OR t.term_end   >= e.election_date))
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                    WHERE t.politician_id = rc.politician_id AND t.office_id = r.office_id
                      AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                      AND (t.term_end   IS NULL OR t.term_end   >= e.election_date));

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- every listed row exists, under its reviewed name, and is still eligible by the rule
  SELECT count(*) INTO v_n FROM _rc x
    JOIN essentials.race_candidates rc ON rc.id = x.id AND rc.full_name = x.full_name
    JOIN _eligible el ON el.id = x.id;
  IF v_n <> 128 THEN RAISE EXCEPTION 'PRE: % of 128 listed rows exist under their name and meet the rule', v_n; END IF;

  -- the only eligible rows NOT listed are the four CC_0364 already marked true
  SELECT count(*) INTO v_n FROM _eligible el JOIN essentials.race_candidates rc ON rc.id = el.id
   WHERE el.id NOT IN (SELECT id FROM _rc) AND NOT rc.is_incumbent;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % eligible row(s) marked false that this file does not list; re-measure', v_n; END IF;

  -- first run: all false; re-run: all true
  SELECT count(DISTINCT rc.is_incumbent) INTO v_n FROM _rc x JOIN essentials.race_candidates rc ON rc.id = x.id;
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: the 128 rows are partly applied; investigate before running'; END IF;

  RAISE NOTICE 'CC_0367 pre-flight OK';
END $$;

UPDATE essentials.race_candidates rc SET is_incumbent = true, updated_at = now()
  FROM _rc x WHERE rc.id = x.id AND NOT rc.is_incumbent;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _rc x JOIN essentials.race_candidates rc ON rc.id = x.id WHERE rc.is_incumbent;
  IF v_n <> 128 THEN RAISE EXCEPTION 'POST: % of 128 rows are incumbents', v_n; END IF;

  SELECT count(*) INTO v_n FROM _eligible el JOIN essentials.race_candidates rc ON rc.id = el.id WHERE NOT rc.is_incumbent;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % eligible row(s) still false', v_n; END IF;

  RAISE NOTICE 'CC_0367 post-verify OK';
END $$;

COMMIT;
