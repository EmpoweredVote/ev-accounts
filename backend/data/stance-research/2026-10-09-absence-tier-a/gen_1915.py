"""Generate migration 1915 from the LEDGER decision table.

⚠ Generated, never hand-written. The decisions are parsed back out of LEDGER.md so the file that
gets applied is derived from the written record, not retyped from it.

🔴 Do NOT %-format the SQL: PL/pgSQL's RAISE uses % as a placeholder and LIKE uses % as a wildcard.
Substitution is @TOKEN@ via str.replace, as mig 1914 did.
🔴 A trailing `-- comment` on a VALUES row eats the comma that joins it to the next row. Every
comment goes on its OWN line, BEFORE the row.
"""
import io, json, re, csv

OUT = 'C:/EV-Accounts-absence/backend/migrations/1915_blank_absence_seated_stance_rows.sql'
SEASON2 = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'

TOPICS = {
 'abortion':('af2fdfd6-02c4-49df-b09c-cf8536f4773f','dab46e5c-628a-4360-ad1d-3aaba61768f0'),
 'ai-regulation':('666bf03d-81fc-4138-ab15-69ae734c9023','c594dc06-0c70-4707-8ae0-d4bc760172db'),
 'campaign-finance':('92730f69-ae57-401c-8ad1-2d07834a895d','ae53ba29-79eb-420f-aac6-ec99f8031ec6'),
 'childcare':('c1ac1330-47f7-44ec-baf3-c913d926b97c','0e9fe0f2-cfab-4553-99cd-c3195d08e236'),
 'city-sanitation':('7687de4f-4d0b-462a-b803-bdfb23b16b42','af3c2445-97e5-46a7-b33d-6915c13eab5c'),
 'civil-rights':('0bc588c6-39e1-4084-b5de-cac909b8b762','2010cab0-1968-4f24-b74d-ca47c2f90165'),
 'climate-change':('f1e44d66-5d27-4b51-b54f-b7ace86f6a3c','5f1403f3-90b6-491f-ba54-3c8e46a5ae26'),
 'data-centers':('4559b513-0fd8-4ed1-babd-f3b554162f40','c48a03d6-b972-4f27-9a8a-d41b07f4a929'),
 'deportation':('44905f3b-e105-4f6c-afc7-5d223813dbac','55c3167e-3ad8-425d-a699-b2e91552d912'),
 'economic-development':('eb3d1247-0de1-4b7f-baec-7259861efd53','af855dba-96f3-4fa0-beb7-43c5edb3f499'),
 'fossil-fuels':('a22215c3-6693-4bc2-b248-01aebba14570','c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'),
 'growth-and-development':('fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4','65e8ffd5-5aac-4d40-8862-a321949eafa4'),
 'healthcare':('e8dad4a8-eb93-4931-91f5-d8fb5d7dd529','afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'),
 'homelessness':('4938766b-b45a-46e3-93bd-b8b30651271a','6958fa99-e317-45d7-8076-d11a0a78c897'),
 'homelessness-response':('6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f','0e47ec98-46af-4e77-ae81-04d1311b4543'),
 'housing':('669cac97-66a6-4087-b036-936fbe62efb3','598c879d-f387-461c-9120-fbbbf6314bbc'),
 'jail-capacity':('c267e137-0ff9-4e7d-9d13-e3cea1756cd0','f63a4e70-055e-4115-a5e0-3deeb5748816'),
 'judicial-interpretation':('448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee','e9bd9e3b-5ced-439e-b989-b98643d053f2'),
 'local-environment':('1935979c-b290-42e4-baa5-8cb0138b4ffa','d67eabf7-8da0-4ca7-b2af-74745b3bfd47'),
 'local-immigration':('b9ccee94-ad96-4f10-b655-889d8e5abe92','d497a221-1616-4ebf-8405-f9c851083e2c'),
 'medicare/aid':('cab61e8a-64fe-4bbd-bc08-fe9914d0091b','38bab357-9790-4cb3-a6d2-c43cbdca615b'),
 'misinformation':('ddd65d64-9dc7-4208-a30f-59f4b9c0653d','bd313c07-02a5-4344-8cc3-0e4b4c3b78a1'),
 'public-safety-approach':('e9ebefcd-c496-45e8-b816-a79f8442ba85','b9c1c07f-f80e-493a-9bb0-015e46c9bc71'),
 'redistricting':('48cc9585-ec22-4f53-8d42-6839828dd36f','c7f973fc-33f5-4570-bfe2-bff4ac6141cc'),
 'religious-freedom':('6b9ba6d9-1001-43f5-b073-4d37130696fd','dfbd847a-294c-49d2-9ac3-69270ea03054'),
 'rent-regulation':('c308e8e8-caac-44f5-ab04-dbfecf40bbe2','6fa44a68-8006-48e9-b562-6b5e61d58693'),
 'residential-zoning':('d4f18138-a2e0-4110-b925-7387d9d0d16d','ef2a5e59-525a-41fa-94de-ce771df7c927'),
 'same-sex-marriage':('c5ab4eab-702f-49b8-9277-8ea53f3835c6','8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'),
 'school-vouchers':('00b95a6a-75db-4521-b523-3326bba938de','88858826-90c0-41c9-a3a4-1d9f5b8c5307'),
 'social-security':('87d20824-a6e9-407b-983c-65440084a0ab','8defc029-0b7e-426f-b838-a2e170f566c9'),
 'tariffs':('683c8084-2281-4920-a07c-18439b2dd413','9f094155-f604-47e8-93db-54a3142420ca'),
 'taxes':('f7e5678d-dadd-4556-a2fc-446e24642ceb','87f8c011-5c70-4f39-a1ea-5cc53c010c60'),
 'trans-athletes':('d1618b9c-0b9e-45af-b986-bb33d270b8e4','af2c6427-daf8-4819-93ba-42db212bae68'),
 'transportation-priorities':('ba59337e-30e2-4aba-a39a-426b3366eb27','c48782d5-e905-408d-8532-2a5fd5bb6efa'),
 'ukraine-support':('24e9212c-b011-422a-865c-093e35050901','107d180d-a949-4a42-a250-54f0a7683be0'),
 'voting-rights':('d1792200-1d3b-4955-a0b7-0e6980d7a7b2','2a18c152-67a0-4380-a381-cb8795110a7c'),
}

q = lambda s: "'" + str(s).replace("'", "''") + "'"


def clean(w):
    """Ledger prose -> plain text. Strips markdown emphasis, code ticks and the leading emoji."""
    w = w.replace('**', '').replace('`', '')
    w = re.sub(r'^[^A-Za-z0-9"\u201c(]+', '', w).strip()
    w = re.sub(r'\s+', ' ', w)
    return w


blanks = json.load(io.open('C:/ev-stance-work/absence/decisions_blank.json', encoding='utf-8'))
wl = json.load(io.open('C:/ev-stance-work/absence/worklist.json', encoding='utf-8'))
src = {(p['politician_id'], r['topic']): r.get('sources', '') for p in wl for r in p['rows']}

values, missing = [], []
for n, pid, name, topic, v1, why in blanks:
    if topic not in TOPICS:
        missing.append(topic); continue
    tid, rev = TOPICS[topic]
    reasoning = (
        'INTERNAL RECORD - blanked: the chair rested on an absence of evidence rather than on '
        'evidence of a position. ' + clean(why) + ' Writing this pair blank in Season 2 withdraws '
        'the Season 1 answer from view; it does not assert that the person holds no view, only '
        'that none was shown. Absence tier-A queue, migration 1915, ledger row ' + str(n) + '.')
    raw = [s for s in re.split(r'\s+', src.get((pid, topic), '') or '') if s.startswith('http')]
    arr = 'ARRAY[' + ','.join(q(s) for s in raw) + ']::text[]' if raw else "'{}'::text[]"
    # The comment sits on its OWN line, before the row -- a trailing one eats the comma.
    values.append('-- #%d  %s / %s  (was %s)\n(%s,%s,%s,%s,%s,%d)'
                  % (n, name.replace('\n', ' '), topic, v1, q(pid), q(tid), q(rev), q(reasoning), arr, n))

assert not missing, 'topics with no Season 2 mapping: %s' % set(missing)

tpl = io.open('C:/ev-stance-work/absence/1915.sql.tpl', encoding='utf-8').read()
sql = (tpl.replace('@SEASON2@', SEASON2)
          .replace('@N@', str(len(values)))
          .replace('@VALUES@', ',\n'.join(values)))
io.open(OUT, 'w', encoding='utf-8', newline='\n').write(sql)
print('wrote %s  (%d rows, %d people)' % (OUT, len(values), len({b[1] for b in blanks})))
