const fs=require('fs');require(process.argv[2]+'/node_modules/dotenv').config({path:process.argv[2]+'/.env'});
const {Client}=require(process.argv[2]+'/node_modules/pg');
(async()=>{const c=new Client({connectionString:process.env.DATABASE_URL,ssl:{rejectUnauthorized:false}});await c.connect();
await c.query("SET default_transaction_read_only = on");
const sql=fs.readFileSync(process.argv[3],'utf8');const r=await c.query(sql);const res=Array.isArray(r)?r[r.length-1]:r;
const cols=res.fields.map(f=>f.name);const esc=v=>v==null?'':/[",\n]/.test(v)?'"'+String(v).replace(/"/g,'""')+'"':v;
fs.writeFileSync(process.argv[4],[cols.join(','),...res.rows.map(x=>cols.map(k=>esc(x[k])).join(','))].join('\n')+'\n');
console.log(res.rows.length);await c.end();})().catch(e=>{console.error(e.message);process.exit(1)});
