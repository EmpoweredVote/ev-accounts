import csv,re,html,json,subprocess,sys,unicodedata,os,time
D=sys.argv[1]
r=list(csv.DictReader(open(f'{D}/roster.csv'))); h={x['pid'] for x in r if x['kind']=='holder'}
ch={}
for x in r:
    if x['kind']=='candidate' and x['pid'] not in h: ch.setdefault(x['pid'],x)
def slug(s): s=unicodedata.normalize('NFKD',s).encode('ascii','ignore').decode().lower(); return re.sub(r'[^a-z0-9]+','-',s).strip('-')
def variants(n):
    p=n.replace('.','').split(); v=[slug(n)]
    if len(p)>2: v.append(slug(p[0]+' '+p[-1]))
    q=[w for w in p if not re.fullmatch(r'(jr|sr|ii|iii|iv),?',w.lower())]
    if q!=p: v.append(slug(' '.join(q))); v.append(slug(q[0]+' '+q[-1]))
    return list(dict.fromkeys(v))
def text(t):
    t=re.sub(r'<script.*?</script>|<style.*?</style>','',t,flags=re.S); return re.sub(r'\s+',' ',html.unescape(re.sub(r'<[^>]+>',' ',t)))
out=[]
for pid,x in ch.items():
    rec={'pid':pid,'name':x['full_name'],'county':x['county'],'level':x['district_type'],'race':x['race'] or x['title'],'tries':[]}
    for v in variants(x['full_name']):
        u=f'https://www.ballotready.org/people/{v}'
        f=f'{D}/pages/{v}.html'; os.makedirs(f'{D}/pages',exist_ok=True)
        code=subprocess.run(['curl','-sL','-A','Mozilla/5.0 (Macintosh) Chrome/128','-o',f,'-w','%{http_code}',u],capture_output=True,text=True).stdout
        rec['tries'].append([v,code]); time.sleep(1)
        if code=='200':
            t=text(open(f).read()); m=re.search(r'Candidate Profile .*? ((?:Candidate for|Running for|Former candidate for|.{0,40}?) .{0,160}?)\. Share',t)
            rec.update(url=u,slug=v,headline=(m.group(1) if m else t[t.find('Candidate Profile'):][:200]))
            i=t.find('Issue Stances'); rec['has_stances']=i>=0
            rec['stances']=t[i:t.find('Endorsements',i) if t.find('Endorsements',i)>0 else i+6000][:6000] if i>=0 else ''
            break
    out.append(rec); print(rec['name'],'|',rec.get('slug'),'|',rec.get('headline','')[:110],'|stances' if rec.get('has_stances') else '',flush=True)
json.dump(out,open(f'{D}/br_challengers.json','w'),indent=1)
