-- 1728_pr_municipios_mayors.sql
--
-- Puerto Rico's 78 municipios and their alcaldes — the island's entire layer of local
-- government, none of which was in the database. Migration 1720 seated the Governor and the
-- legislature; this is the part a resident actually deals with. PR has no counties and no
-- separate cities: the municipio IS the unit of local government, and its executive is the
-- alcalde.
--
-- ROSTER SOURCE — the blocker recorded in the 1720 todo turned out to be false. That note said
-- no non-partisan roster existed and the only lists were the two PARTISAN mayors' associations.
-- The CEE (Comisión Estatal de Elecciones) publishes the certified count as machine-readable
-- XML behind its results portal:
--   https://elecciones2024.ceepur.org/Escrutinio_General_123/data/ALCALDES_Municipios.xml
--   (ISO-8859-1, one <group> per municipio, certified 2025-02-11)
-- Every one of the 78 was then cross-checked against the independently-maintained
-- es.wikipedia per-municipio result tables: 78/78 agreed on winner AND party, party totals
-- match at PPD 41 / PNP 37, and no race was closer than 50 votes. Only rows where both
-- sources agreed are written here.
--
-- 🔴 GEO_ID COLLISION, BY DESIGN — do not "fix" it. Municipio FIPS (72001..72153) share the
-- five-digit space with PR's senatorial (G5210, 72001..72008) and representative (G5220,
-- 72001..72040) districts: 72001 is simultaneously Adjuntas, Senate District 1 and House
-- District 1. Resolution is by MTFCC, never by geo_id alone. These districts are LOCAL_EXEC
-- and their polygons carry G4020; MTFCC_DISTRICT_TYPE_GUARD gained a PR-scoped clause in this
-- change so G4020 resolves to LOCAL_EXEC for PR and nothing else. 72xxx is state-FIPS-prefixed,
-- so the scope is airtight — the same argument the existing DC ward clause makes.
--
-- WHY LOCAL_EXEC AND NOT COUNTY: TIGER files municipios in the county-equivalent layer because
-- that is what they are statistically, but civically they are municipalities with a mayor.
-- Typing them COUNTY would make PR the only place in the database where a Mayor hangs off a
-- COUNTY district, so every "find the mayors" query would silently miss all 78.
--
-- ocd_id is NULL, deliberately. The Open Civic Data identifier set has NO Puerto Rico
-- divisions at all (zero lines matching state:pr in country-us.csv), so any value here would
-- be a synthesized slug — and synthesized slugs are sticky. Every other PR district in this
-- database already carries NULL for the same reason. ocd_id gates only the admin coverage
-- dashboard, never address search, which resolves on geo_id.
--
-- TERM START is statutory, not a press date. Código Municipal de Puerto Rico (Ley 107-2020):
-- the alcalde holds office for four years "contados a partir del segundo lunes del mes de
-- enero del año siguiente a la elección general". The second Monday of January 2025 is
-- 2025-01-13. (Contemporary coverage that calls 8 January "the second Monday" is simply
-- wrong — 1 January 2025 was a Wednesday.) No term_end is written: these run to the second
-- Monday of January 2029, but the house rule is to re-seat after the election rather than
-- pre-date a term nobody has served.
--
-- Polygons were loaded separately by scripts/load-pr-municipio-boundaries.mjs, which verifies
-- that the 78 TILE the territory (union area equals the PR polygon, zero uncovered area, no
-- overlap) and that eight known coordinates — including Vieques, Culebra and the two
-- name-collision municipios — each fall in exactly one municipio.
--
-- Idempotent: re-running inserts nothing and re-seats nobody.

BEGIN;

CREATE TEMP TABLE _pr_muni (
  fips       text PRIMARY KEY,
  label      text NOT NULL,
  muni       text NOT NULL
) ON COMMIT DROP;
INSERT INTO _pr_muni (fips, label, muni) VALUES

  ('72001', 'Adjuntas Mayor', 'Adjuntas'),
  ('72003', 'Aguada Mayor', 'Aguada'),
  ('72005', 'Aguadilla Mayor', 'Aguadilla'),
  ('72007', 'Aguas Buenas Mayor', 'Aguas Buenas'),
  ('72009', 'Aibonito Mayor', 'Aibonito'),
  ('72011', 'Añasco Mayor', 'Añasco'),
  ('72013', 'Arecibo Mayor', 'Arecibo'),
  ('72015', 'Arroyo Mayor', 'Arroyo'),
  ('72017', 'Barceloneta Mayor', 'Barceloneta'),
  ('72019', 'Barranquitas Mayor', 'Barranquitas'),
  ('72021', 'Bayamón Mayor', 'Bayamón'),
  ('72023', 'Cabo Rojo Mayor', 'Cabo Rojo'),
  ('72025', 'Caguas Mayor', 'Caguas'),
  ('72027', 'Camuy Mayor', 'Camuy'),
  ('72029', 'Canóvanas Mayor', 'Canóvanas'),
  ('72031', 'Carolina Mayor', 'Carolina'),
  ('72033', 'Cataño Mayor', 'Cataño'),
  ('72035', 'Cayey Mayor', 'Cayey'),
  ('72037', 'Ceiba Mayor', 'Ceiba'),
  ('72039', 'Ciales Mayor', 'Ciales'),
  ('72041', 'Cidra Mayor', 'Cidra'),
  ('72043', 'Coamo Mayor', 'Coamo'),
  ('72045', 'Comerío Mayor', 'Comerío'),
  ('72047', 'Corozal Mayor', 'Corozal'),
  ('72049', 'Culebra Mayor', 'Culebra'),
  ('72051', 'Dorado Mayor', 'Dorado'),
  ('72053', 'Fajardo Mayor', 'Fajardo'),
  ('72054', 'Florida Mayor', 'Florida'),
  ('72055', 'Guánica Mayor', 'Guánica'),
  ('72057', 'Guayama Mayor', 'Guayama'),
  ('72059', 'Guayanilla Mayor', 'Guayanilla'),
  ('72061', 'Guaynabo Mayor', 'Guaynabo'),
  ('72063', 'Gurabo Mayor', 'Gurabo'),
  ('72065', 'Hatillo Mayor', 'Hatillo'),
  ('72067', 'Hormigueros Mayor', 'Hormigueros'),
  ('72069', 'Humacao Mayor', 'Humacao'),
  ('72071', 'Isabela Mayor', 'Isabela'),
  ('72073', 'Jayuya Mayor', 'Jayuya'),
  ('72075', 'Juana Díaz Mayor', 'Juana Díaz'),
  ('72077', 'Juncos Mayor', 'Juncos'),
  ('72079', 'Lajas Mayor', 'Lajas'),
  ('72081', 'Lares Mayor', 'Lares'),
  ('72083', 'Las Marías Mayor', 'Las Marías'),
  ('72085', 'Las Piedras Mayor', 'Las Piedras'),
  ('72087', 'Loíza Mayor', 'Loíza'),
  ('72089', 'Luquillo Mayor', 'Luquillo'),
  ('72091', 'Manatí Mayor', 'Manatí'),
  ('72093', 'Maricao Mayor', 'Maricao'),
  ('72095', 'Maunabo Mayor', 'Maunabo'),
  ('72097', 'Mayagüez Mayor', 'Mayagüez'),
  ('72099', 'Moca Mayor', 'Moca'),
  ('72101', 'Morovis Mayor', 'Morovis'),
  ('72103', 'Naguabo Mayor', 'Naguabo'),
  ('72105', 'Naranjito Mayor', 'Naranjito'),
  ('72107', 'Orocovis Mayor', 'Orocovis'),
  ('72109', 'Patillas Mayor', 'Patillas'),
  ('72111', 'Peñuelas Mayor', 'Peñuelas'),
  ('72113', 'Ponce Mayor', 'Ponce'),
  ('72115', 'Quebradillas Mayor', 'Quebradillas'),
  ('72117', 'Rincón Mayor', 'Rincón'),
  ('72119', 'Río Grande Mayor', 'Río Grande'),
  ('72121', 'Sabana Grande Mayor', 'Sabana Grande'),
  ('72123', 'Salinas Mayor', 'Salinas'),
  ('72125', 'San Germán Mayor', 'San Germán'),
  ('72127', 'San Juan Mayor', 'San Juan'),
  ('72129', 'San Lorenzo Mayor', 'San Lorenzo'),
  ('72131', 'San Sebastián Mayor', 'San Sebastián'),
  ('72133', 'Santa Isabel Mayor', 'Santa Isabel'),
  ('72135', 'Toa Alta Mayor', 'Toa Alta'),
  ('72137', 'Toa Baja Mayor', 'Toa Baja'),
  ('72139', 'Trujillo Alto Mayor', 'Trujillo Alto'),
  ('72141', 'Utuado Mayor', 'Utuado'),
  ('72143', 'Vega Alta Mayor', 'Vega Alta'),
  ('72145', 'Vega Baja Mayor', 'Vega Baja'),
  ('72147', 'Vieques Mayor', 'Vieques'),
  ('72149', 'Villalba Mayor', 'Villalba'),
  ('72151', 'Yabucoa Mayor', 'Yabucoa'),
  ('72153', 'Yauco Mayor', 'Yauco');

CREATE TEMP TABLE _pr_mayor (
  external_id bigint PRIMARY KEY,
  full_name   text NOT NULL,
  first_name  text NOT NULL,
  last_name   text NOT NULL,
  party       text NOT NULL,
  fips        text NOT NULL REFERENCES _pr_muni(fips)
) ON COMMIT DROP;
INSERT INTO _pr_mayor (external_id, full_name, first_name, last_name, party, fips) VALUES

  (-7230001, 'José Hiram Soto Rivera', 'José Hiram', 'Soto Rivera', 'Partido Popular Democrático', '72001'),
  (-7230002, 'Christian Cortés', 'Christian', 'Cortés', 'Partido Popular Democrático', '72003'),
  (-7230003, 'Julio Roldán Concepción', 'Julio', 'Roldán Concepción', 'Partido Popular Democrático', '72005'),
  (-7230004, 'Karina Nieves Serrano', 'Karina', 'Nieves Serrano', 'Partido Nuevo Progresista', '72007'),
  (-7230005, 'Willie Alicea Pérez', 'Willie', 'Alicea Pérez', 'Partido Nuevo Progresista', '72009'),
  (-7230006, 'Kabir Solares García', 'Kabir', 'Solares García', 'Partido Nuevo Progresista', '72011'),
  (-7230007, 'Carlos Rubén (Tito) Ramírez Irizarry', 'Carlos Rubén', 'Ramírez Irizarry', 'Partido Popular Democrático', '72013'),
  (-7230008, 'Eric Enrique Bachier Román', 'Eric Enrique', 'Bachier Román', 'Partido Popular Democrático', '72015'),
  (-7230009, 'Wanda (Tata) Soler', 'Wanda', 'Soler', 'Partido Popular Democrático', '72017'),
  (-7230010, 'Elliot Colón Blanco', 'Elliot', 'Colón Blanco', 'Partido Nuevo Progresista', '72019'),
  (-7230011, 'Ramón Luis Rivera Cruz', 'Ramón Luis', 'Rivera Cruz', 'Partido Nuevo Progresista', '72021'),
  (-7230012, 'Jorge Morales Wiscovitch (Jorgito)', 'Jorge', 'Morales Wiscovitch', 'Partido Nuevo Progresista', '72023'),
  (-7230013, 'William Miranda Torres', 'William', 'Miranda Torres', 'Partido Popular Democrático', '72025'),
  (-7230014, 'Gabriel (Gaby) Hernández', 'Gabriel', 'Hernández', 'Partido Nuevo Progresista', '72027'),
  (-7230015, 'Lornna Soto', 'Lornna', 'Soto', 'Partido Nuevo Progresista', '72029'),
  (-7230016, 'José Carlos Aponte Dalmau', 'José Carlos', 'Aponte Dalmau', 'Partido Popular Democrático', '72031'),
  (-7230017, 'Julio Alicea Vasallo', 'Julio', 'Alicea Vasallo', 'Partido Nuevo Progresista', '72033'),
  (-7230018, 'Rolando Ortiz', 'Rolando', 'Ortiz', 'Partido Popular Democrático', '72035'),
  (-7230019, 'Samuel Rivera Báez', 'Samuel', 'Rivera Báez', 'Partido Nuevo Progresista', '72037'),
  (-7230020, 'Jesús Resto', 'Jesús', 'Resto', 'Partido Popular Democrático', '72039'),
  (-7230021, 'Delvis Pagán Clavijo', 'Delvis', 'Pagán Clavijo', 'Partido Nuevo Progresista', '72041'),
  (-7230022, 'Juan Carlos García Padilla', 'Juan Carlos', 'García Padilla', 'Partido Popular Democrático', '72043'),
  (-7230023, 'Irvin Rivera', 'Irvin', 'Rivera', 'Partido Popular Democrático', '72045'),
  (-7230024, 'Luis A. (Luiggi) García Rolón', 'Luis A.', 'García Rolón', 'Partido Nuevo Progresista', '72047'),
  (-7230025, 'Edilberto Romero Llovet', 'Edilberto', 'Romero Llovet', 'Partido Nuevo Progresista', '72049'),
  (-7230026, 'Carlos A. López Rivera', 'Carlos A.', 'López Rivera', 'Partido Popular Democrático', '72051'),
  (-7230027, 'José Aníbal (Joey) Meléndez Méndez', 'José Aníbal', 'Meléndez Méndez', 'Partido Nuevo Progresista', '72053'),
  (-7230028, 'José E. Gerena Polanco', 'José E.', 'Gerena Polanco', 'Partido Nuevo Progresista', '72054'),
  (-7230029, 'Ismael (Titi) Rodríguez Ramos', 'Ismael', 'Rodríguez Ramos', 'Partido Popular Democrático', '72055'),
  (-7230030, 'O''brain Vázquez Molina', 'O''brain', 'Vázquez Molina', 'Partido Popular Democrático', '72057'),
  (-7230031, 'Raúl Rivera Rodríguez', 'Raúl', 'Rivera Rodríguez', 'Partido Nuevo Progresista', '72059'),
  (-7230032, 'Edward Alexis O''neill Rosa', 'Edward Alexis', 'O''neill Rosa', 'Partido Nuevo Progresista', '72061'),
  (-7230033, 'Rosachely Rivera Santana', 'Rosachely', 'Rivera Santana', 'Partido Nuevo Progresista', '72063'),
  (-7230034, 'Carlos E. Román Román', 'Carlos E.', 'Román Román', 'Partido Popular Democrático', '72065'),
  (-7230035, 'Pedro García', 'Pedro', 'García', 'Partido Popular Democrático', '72067'),
  (-7230036, 'Rosamar Trujillo Plumey', 'Rosamar', 'Trujillo Plumey', 'Partido Popular Democrático', '72069'),
  (-7230037, 'Miguel (Ricky) Méndez Pérez', 'Miguel', 'Méndez Pérez', 'Partido Popular Democrático', '72071'),
  (-7230038, 'Jorge (Georgie) González', 'Jorge', 'González', 'Partido Popular Democrático', '72073'),
  (-7230039, 'Ramón (Ramoncito) Hernández', 'Ramón', 'Hernández', 'Partido Popular Democrático', '72075'),
  (-7230040, 'Alfredo (Papo) Alejandro Carrión', 'Alfredo', 'Alejandro Carrión', 'Partido Popular Democrático', '72077'),
  (-7230041, 'Jayson (Jay) Martínez', 'Jayson', 'Martínez', 'Partido Nuevo Progresista', '72079'),
  (-7230042, 'Fabián (Faby) Arroyo Rodríguez', 'Fabián', 'Arroyo Rodríguez', 'Partido Popular Democrático', '72081'),
  (-7230043, 'Edwin Soto Santiago', 'Edwin', 'Soto Santiago', 'Partido Nuevo Progresista', '72083'),
  (-7230044, 'Miguel (Micky) López', 'Miguel', 'López', 'Partido Nuevo Progresista', '72085'),
  (-7230045, 'Julia M. Nazario Fuentes', 'Julia M.', 'Nazario Fuentes', 'Partido Popular Democrático', '72087'),
  (-7230046, 'Jesús (Jerry) Márquez Rodríguez', 'Jesús', 'Márquez Rodríguez', 'Partido Popular Democrático', '72089'),
  (-7230047, 'José A. Sánchez González', 'José A.', 'Sánchez González', 'Partido Nuevo Progresista', '72091'),
  (-7230048, 'Wilfredo (Juny) Ruiz', 'Wilfredo', 'Ruiz', 'Partido Popular Democrático', '72093'),
  (-7230049, 'Ángel Omar Lafuente Amaro', 'Ángel Omar', 'Lafuente Amaro', 'Partido Nuevo Progresista', '72095'),
  (-7230050, 'Jorge Luis Ramos Ruiz', 'Jorge Luis', 'Ramos Ruiz', 'Partido Popular Democrático', '72097'),
  (-7230051, 'Efraín (Franco) Barreto', 'Efraín', 'Barreto', 'Partido Popular Democrático', '72099'),
  (-7230052, 'Carmen Irene Maldonado González', 'Carmen Irene', 'Maldonado González', 'Partido Popular Democrático', '72101'),
  (-7230053, 'Miraidaliz Rosario Pagán', 'Miraidaliz', 'Rosario Pagán', 'Partido Popular Democrático', '72103'),
  (-7230054, 'Orlando Ortiz Chevres', 'Orlando', 'Ortiz Chevres', 'Partido Nuevo Progresista', '72105'),
  (-7230055, 'Jesús E. Colón Berlingeri', 'Jesús E.', 'Colón Berlingeri', 'Partido Nuevo Progresista', '72107'),
  (-7230056, 'Maritza Sánchez Neris', 'Maritza', 'Sánchez Neris', 'Partido Nuevo Progresista', '72109'),
  (-7230057, 'Josean González Febres', 'Josean', 'González Febres', 'Partido Nuevo Progresista', '72111'),
  (-7230058, 'Marlese Sifre', 'Marlese', 'Sifre', 'Partido Popular Democrático', '72113'),
  (-7230059, 'Heriberto Vélez Vélez', 'Heriberto', 'Vélez Vélez', 'Partido Popular Democrático', '72115'),
  (-7230060, 'Carlos (Carlitos) López Bonilla', 'Carlos', 'López Bonilla', 'Partido Popular Democrático', '72117'),
  (-7230061, 'Ángel (Bori) González Damutd', 'Ángel', 'González Damutd', 'Partido Popular Democrático', '72119'),
  (-7230062, 'Marcos (Marquitos) Valentín Flores', 'Marcos', 'Valentín Flores', 'Partido Popular Democrático', '72121'),
  (-7230063, 'Karilyn Bonilla Colón', 'Karilyn', 'Bonilla Colón', 'Partido Popular Democrático', '72123'),
  (-7230064, 'Virgilio Olivera Olivera', 'Virgilio', 'Olivera Olivera', 'Partido Nuevo Progresista', '72125'),
  (-7230065, 'Miguel Romero', 'Miguel', 'Romero', 'Partido Nuevo Progresista', '72127'),
  (-7230066, 'Jaime Alverio Ramos', 'Jaime', 'Alverio Ramos', 'Partido Nuevo Progresista', '72129'),
  (-7230067, 'Eladio (Layito) Cardona Quiles', 'Eladio', 'Cardona Quiles', 'Partido Popular Democrático', '72131'),
  (-7230068, 'Meldwin Rivera Rodríguez', 'Meldwin', 'Rivera Rodríguez', 'Partido Nuevo Progresista', '72133'),
  (-7230069, 'Clemente (Chito) Agosto', 'Clemente', 'Agosto', 'Partido Popular Democrático', '72135'),
  (-7230070, 'Bernardo (Betito) Márquez García', 'Bernardo', 'Márquez García', 'Partido Nuevo Progresista', '72137'),
  (-7230071, 'Pedro (Pedrito) Rodríguez González', 'Pedro', 'Rodríguez González', 'Partido Popular Democrático', '72139'),
  (-7230072, 'Jorge (Jorgito) Pérez', 'Jorge', 'Pérez', 'Partido Nuevo Progresista', '72141'),
  (-7230073, 'María Vega', 'María', 'Vega', 'Partido Nuevo Progresista', '72143'),
  (-7230074, 'Marcos Cruz Molina', 'Marcos', 'Cruz Molina', 'Partido Popular Democrático', '72145'),
  (-7230075, 'José Junito Corcino Acevedo', 'José Junito', 'Corcino Acevedo', 'Partido Nuevo Progresista', '72147'),
  (-7230076, 'Danny (Dan) Santiago', 'Danny', 'Santiago', 'Partido Nuevo Progresista', '72149'),
  (-7230077, 'Rafael Surillo Ruiz', 'Rafael', 'Surillo Ruiz', 'Partido Popular Democrático', '72151'),
  (-7230078, 'Angel (Luigi) Torres Ortiz', 'Angel', 'Torres Ortiz', 'Partido Nuevo Progresista', '72153');

-- Pre-flight. Refuse rather than build half an island.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM _pr_muni;
  IF n <> 78 THEN RAISE EXCEPTION 'expected 78 municipios, have %', n; END IF;

  SELECT count(*) INTO n FROM _pr_mayor;
  IF n <> 78 THEN RAISE EXCEPTION 'expected 78 mayors, have %', n; END IF;

  -- every municipio must already have its polygon, or the seat is unreachable by address
  SELECT count(*) INTO n
  FROM _pr_muni m
  LEFT JOIN essentials.geofence_boundaries b
         ON b.geo_id = m.fips AND b.mtfcc = 'G4020' AND b.state = '72'
  WHERE b.geo_id IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'aborting: % municipio(s) have no G4020 polygon — run scripts/load-pr-municipio-boundaries.mjs first', n;
  END IF;

  -- the external_id band must be free (or already ours)
  SELECT count(*) INTO n
  FROM essentials.politicians p
  WHERE p.external_id BETWEEN -7239999 AND -7230001
    AND p.external_id NOT IN (SELECT external_id FROM _pr_mayor);
  IF n <> 0 THEN
    RAISE EXCEPTION 'aborting: % politician(s) already occupy the -723xxxx band', n;
  END IF;
END $$;

-- 1. districts
INSERT INTO essentials.districts
  (district_type, label, state, geo_id, mtfcc, num_officials, representation_basis)
SELECT 'LOCAL_EXEC', m.label, 'pr', m.fips, 'G4020', 1, 'residency'
FROM _pr_muni m
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = m.fips AND d.district_type = 'LOCAL_EXEC'
);

-- 2. offices (one Mayor per municipio). voting_powers stays 'full' and
--    representation_basis is 'residency', so representation_note is correctly NULL.
INSERT INTO essentials.offices
  (district_id, title, representing_state, representing_city, seats,
   normalized_position_name, is_vacant, voting_powers)
SELECT d.id, 'Mayor', 'PR', m.muni, 1, 'Mayor', false, 'full'
FROM _pr_muni m
JOIN essentials.districts d ON d.geo_id = m.fips AND d.district_type = 'LOCAL_EXEC'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.title = 'Mayor'
);

-- 3. the alcaldes themselves
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, party, is_active, is_vacant, source)
SELECT x.external_id, x.full_name, x.first_name, x.last_name, x.party, true, false,
       'CEE Escrutinio General 2024 (ALCALDES_Municipios.xml, certified 2025-02-11) cross-checked against es.wikipedia per-municipio results; Census TIGERweb county-equivalent polygons (migration 1728)'
FROM _pr_mayor x
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politicians p WHERE p.external_id = x.external_id
);

-- 4. occupancy. An office with no office_terms row is INVISIBLE and nothing errors, so this
--    goes through the helper rather than a hand-rolled two-step.
DO $$
DECLARE r record; n_seated int := 0;
BEGIN
  FOR r IN
    SELECT o.id AS office_id, p.id AS politician_id
    FROM _pr_mayor x
    JOIN essentials.politicians p ON p.external_id = x.external_id
    JOIN essentials.districts d ON d.geo_id = x.fips AND d.district_type = 'LOCAL_EXEC'
    JOIN essentials.offices   o ON o.district_id = d.id AND o.title = 'Mayor'
    WHERE NOT EXISTS (
      SELECT 1 FROM essentials.office_terms t
      WHERE t.office_id = o.id AND t.politician_id = p.id AND t.term_end IS NULL
    )
  LOOP
    PERFORM essentials.seat_officeholder(
      r.office_id, r.politician_id, DATE '2025-01-13',
      'CEE Escrutinio General 2024 (ALCALDES_Municipios.xml, certified 2025-02-11) cross-checked against es.wikipedia per-municipio results; Census TIGERweb county-equivalent polygons (migration 1728)', 'elected', 'day');
    n_seated := n_seated + 1;
  END LOOP;
  RAISE NOTICE 'seated % alcalde(s)', n_seated;
END $$;

-- Post-verify.
DO $$
DECLARE n_d int; n_o int; n_p int; n_h int; n_ppd int; n_pnp int; n_reach int; n_note int;
BEGIN
  SELECT count(*) INTO n_d FROM essentials.districts d
   JOIN _pr_muni m ON m.fips = d.geo_id AND d.district_type='LOCAL_EXEC';
  IF n_d <> 78 THEN RAISE EXCEPTION 'expected 78 municipio districts, found %', n_d; END IF;

  SELECT count(*) INTO n_o
  FROM _pr_muni m
  JOIN essentials.districts d ON d.geo_id=m.fips AND d.district_type='LOCAL_EXEC'
  JOIN essentials.offices o ON o.district_id=d.id AND o.title='Mayor';
  IF n_o <> 78 THEN RAISE EXCEPTION 'expected 78 mayor offices, found %', n_o; END IF;

  SELECT count(*) INTO n_p FROM essentials.politicians p
   JOIN _pr_mayor x ON x.external_id = p.external_id;
  IF n_p <> 78 THEN RAISE EXCEPTION 'expected 78 alcaldes, found %', n_p; END IF;

  -- office_current_holder LEFT JOINs from offices, so a vacancy is a NULL politician_id and a
  -- bare count(*) would pass vacuously. Count seated holders explicitly.
  SELECT count(*) INTO n_h
  FROM _pr_muni m
  JOIN essentials.districts d ON d.geo_id=m.fips AND d.district_type='LOCAL_EXEC'
  JOIN essentials.offices o ON o.district_id=d.id AND o.title='Mayor'
  JOIN essentials.office_current_holder och ON och.office_id=o.id
  WHERE och.politician_id IS NOT NULL;
  IF n_h <> 78 THEN RAISE EXCEPTION 'expected 78 seated alcaldes, found %', n_h; END IF;

  SELECT count(*) FILTER (WHERE p.party='Partido Popular Democrático'),
         count(*) FILTER (WHERE p.party='Partido Nuevo Progresista')
    INTO n_ppd, n_pnp
  FROM essentials.politicians p JOIN _pr_mayor x ON x.external_id=p.external_id;
  IF (n_ppd, n_pnp) <> (41, 37) THEN
    RAISE EXCEPTION 'party split is PPD %, PNP % — expected 41/37 per the CEE certified count',
      n_ppd, n_pnp;
  END IF;

  -- migration 1720's rule: PR parties are Spanish and never map onto the US two-party split
  SELECT count(*) INTO n_note FROM essentials.politicians p
   JOIN _pr_mayor x ON x.external_id=p.external_id
   WHERE p.party IN ('Democrat','Republican','Democratic','Democratic Party','Republican Party');
  IF n_note <> 0 THEN RAISE EXCEPTION '% alcalde(s) carry a mainland party label', n_note; END IF;

  -- the whole point: every municipio must be resolvable from its own polygon, and the
  -- MTFCC pairing must pick the LOCAL_EXEC seat rather than the same-geo_id legislative ones.
  SELECT count(*) INTO n_reach
  FROM essentials.geofence_boundaries b
  JOIN essentials.districts d
    ON d.geo_id = b.geo_id
   AND b.mtfcc = 'G4020' AND d.district_type = 'LOCAL_EXEC'
  JOIN essentials.offices o ON o.district_id = d.id AND o.title='Mayor'
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE b.state = '72' AND och.politician_id IS NOT NULL;
  IF n_reach <> 78 THEN
    RAISE EXCEPTION 'only % of 78 municipios resolve polygon -> LOCAL_EXEC -> seated mayor', n_reach;
  END IF;

  RAISE NOTICE 'ok: 78 municipios, 78 mayor offices, % seated (PPD %, PNP %), % reachable',
    n_h, n_ppd, n_pnp, n_reach;
END $$;

COMMIT;
