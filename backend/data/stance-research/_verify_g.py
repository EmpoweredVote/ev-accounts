import ast
src = open(r'C:/EV-Accounts/backend/data/stance-research/gen_migration.py', encoding='utf-8').read()
ast.parse(src)
assert 'MD_DELEGATES_G_CANDIDATES' in src
assert 'migration_num=292' in src
names = ['Samuel I. Rosenberg','Malcolm P. Ruff','Sean A. Stinnett','Michele Guyton',
         'Joshua J. Stonko','Regina T. Boyce','Elizabeth Embry','Catherine M. Forbes',
         'Eric Ebersole','Aletheia McCaskill','Sheila Ruth','Jackie Addison',
         'Stephanie Smith','Caylin Young','Luke Clippinger','Mark Edelson',
         'Robbyn Lewis','Diana M. Fennell','Julian Ivey','Deni Taveras']
missing = [n for n in names if n not in src]
assert not missing, f'missing: {missing}'
assert '67acad60-5839-4a8a-95ac-c881c3ca39a9' in src, 'Vacant UUID missing'
for prev in ['MD_DELEGATES_A_CANDIDATES','MD_DELEGATES_B_CANDIDATES','MD_DELEGATES_C_CANDIDATES',
             'MD_DELEGATES_D_CANDIDATES','MD_DELEGATES_E_CANDIDATES','MD_DELEGATES_F_CANDIDATES',
             'MD_EXEC_CANDIDATES','MD_SENATORS_A_CANDIDATES','MD_SENATORS_B_CANDIDATES','MD_SENATORS_C_CANDIDATES']:
    assert prev in src, f'prior section removed: {prev}'
# Check MD_DELEGATES_G_CSVS has 20 entries (not 21 — no vacant CSV)
import re
g_csvs_match = re.search(r'MD_DELEGATES_G_CSVS\s*=\s*\[(.*?)\]', src, re.DOTALL)
assert g_csvs_match, 'MD_DELEGATES_G_CSVS not found'
csvs_block = g_csvs_match.group(1)
csv_entries = [l.strip() for l in csvs_block.strip().splitlines() if l.strip() and not l.strip().startswith('#')]
print(f'CSV entries count: {len(csv_entries)}')
assert len(csv_entries) == 20, f'Expected 20 CSV paths, got {len(csv_entries)}'
print('OK', len(names), '+ Vacant placeholder; CSV count=20: PASS')
