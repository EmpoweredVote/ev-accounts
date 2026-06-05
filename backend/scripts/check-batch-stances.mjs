import { pool } from '../src/lib/db.js';
const ids = [
  { name: 'Robert Rivas (AD-29)', id: '5a75d4fb-e4fe-441a-8658-e6eb57574fd4' },
  { name: 'Dawn Addis (AD-30)', id: '2ba6e476-1d62-4ac5-a70d-f4bcbe704f39' },
  { name: 'Dr. Joaquin Arambula (AD-31)', id: '9edab965-ac61-4227-a8d6-601c07821f53' },
  { name: 'Stan Ellis (AD-32)', id: 'fcdd3836-bb89-44ec-920a-75a21c9d726f' },
  { name: 'Greg Wallis (AD-47)', id: 'c6c04131-96f3-40d8-b881-e6c57f986d38' },
  { name: 'Leticia Castillo (AD-58)', id: '30fee995-e2e3-42d6-9993-d000fd73b919' },
  { name: 'Natasha Johnson (AD-63)', id: '3f200d93-74aa-4191-a275-77b64ff5b219' },
  { name: 'Avelino Valencia (AD-68)', id: 'a1467b58-9cc8-4611-a03e-07defc1679bf' },
  { name: 'Tri Ta (AD-70)', id: 'c2975ee6-7770-4c5f-809c-4e1245f2ab64' },
  { name: 'Kate Sanchez (AD-71)', id: '62dfefeb-9979-445a-aee6-06cf7c03a8c0' },
  { name: 'Diane B. Dixon (AD-72)', id: '9aa10096-180d-424b-8fc8-cca5796704a6' },
  { name: 'Cottie Petrie-Norris (AD-73)', id: '065c6e87-8778-43ee-ab44-b9982a677aa7' },
  { name: 'Laurie Davies (AD-74)', id: '7778111f-551f-407f-87c7-e30268ea5e0a' },
  { name: 'Carl DeMaio (AD-75)', id: 'a6d96375-a61c-4a13-9afa-99914456e8c2' },
  { name: 'Dr. Darshana R. Patel (AD-76)', id: '9a927fae-60bf-41f9-8ec0-433cc98997fa' },
  { name: 'Tasha Boerner (AD-77)', id: '0a9171c6-0676-4704-b825-a7e16c66f1c2' },
  { name: 'Christopher M. Ward (AD-78)', id: '1ee95c1d-6127-494b-9f68-e8b3c975adee' },
  { name: 'Dr. LaShae Sharp-Collins (AD-79)', id: 'cb2ae7a3-3b6a-462b-8fe8-47f3ce4cb7a2' },
  { name: 'David A. Alvarez (AD-80)', id: 'e0451383-4594-4247-8297-acc388a7e0c3' },
];
for (const p of ids) {
  const { rows } = await pool.query(
    `SELECT COUNT(*) as cnt FROM inform.politician_answers WHERE politician_id = $1`,
    [p.id]
  );
  console.log(`${rows[0].cnt.toString().padStart(3)} stances — ${p.name}`);
}
await pool.end();
