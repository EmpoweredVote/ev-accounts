import pg from 'pg';
const { Pool } = pg;
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

const SQL = `
  SELECT p.full_name, o.state_abbr, o.party, COUNT(pa.topic_id)::int as stances
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id
  LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
  WHERE o.chamber_id = '7cbe07bc-84b8-433b-952b-540e7de18a92'
  GROUP BY p.id, p.full_name, o.state_abbr, o.party
  ORDER BY o.state_abbr, p.full_name
`;

pool.query(SQL).then(({ rows }) => {
  const byState = {};
  rows.forEach(r => {
    const st = r.state_abbr || '??';
    if (!byState[st]) byState[st] = [];
    byState[st].push(r);
  });

  console.log('=== States with != 2 senators ===');
  Object.entries(byState).sort().forEach(([st, ss]) => {
    if (ss.length !== 2) {
      console.log(st + ': ' + ss.length + ' senator(s)');
      ss.forEach(s => console.log('  ' + s.full_name + ' (' + (s.party||'?') + ') stances=' + s.stances));
    }
  });

  console.log('\n=== 0-stance senators ===');
  rows.filter(r => r.stances === 0).forEach(r => console.log(r.state_abbr + ': ' + r.full_name));

  console.log('\nTotal: ' + rows.length);
  pool.end();
}).catch(e => { console.error(e.message); pool.end(); process.exit(1); });
