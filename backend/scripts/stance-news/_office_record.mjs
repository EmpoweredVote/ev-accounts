// Print a Legistar person's office records, so a term start is read from the body's own roster.
// Usage: node _office_record.mjs <client> <Surname>
const client = process.argv[2];
const surname = process.argv[3];
const get = async (u) => { const r = await fetch(u); if (!r.ok) throw new Error(r.status + ' ' + u); return r.json(); };
const people = await get(`https://webapi.legistar.com/v1/${client}/persons`);
const hits = people.filter((p) => (p.PersonLastName || '').toLowerCase() === surname.toLowerCase()
  || (p.PersonFullName || '').toLowerCase().includes(surname.toLowerCase()));
if (!hits.length) { console.log('no person named ' + surname); process.exit(0); }
for (const p of hits) {
  console.log(`PersonId ${p.PersonId} | ${p.PersonFullName} | active=${p.PersonActiveFlag}`);
  let recs = [];
  try { recs = await get(`https://webapi.legistar.com/v1/${client}/persons/${p.PersonId}/officerecords`); } catch (e) { console.log('  officerecords: ' + e.message); }
  for (const o of recs) {
    console.log(`   ${String(o.OfficeRecordTitle).padEnd(22)} ${(o.OfficeRecordStartDate || '').slice(0, 10)} -> ${(o.OfficeRecordEndDate || '').slice(0, 10)}   ${o.OfficeRecordBodyName}`);
  }
}
