"""Plant one deliberate defect per MN-3 gate, into copies of the dry run.

Every control ASSERTS what it planted before writing the file. A control that quietly plants
something other than what it claims proves nothing about the gate it then appears to trip --
which happened twice while these were being written, and is why the assertions are here.
"""
import re

src = open('_dryrun-mn3.sql', encoding='utf-8').read()

BOUNDARY_RE = r"INSERT INTO essentials\.geofence_boundaries[\s\S]*?ON CONFLICT \(geo_id, mtfcc\) DO NOTHING;"

# 1. No boundaries at all -- today's production state.
c1 = re.sub(BOUNDARY_RE, "", src)
assert 'geofence_boundaries' not in c1.split('-- ══════')[0], 'control 1 left a boundary insert behind'
open('_c1.sql', 'w', encoding='utf-8').write(c1)

# 2. Duluth boundaries stamped with the SUPERSEDED 2012 service.
c2 = src.replace('VotingDistricts/MapServer/16 "Districts and City Councilors"',
                 'GeneralUse/Precincts_Council_Boundaries_Duluth/MapServer/1')
assert c2 != src, 'control 2 changed nothing'
open('_c2.sql', 'w', encoding='utf-8').write(c2)

# 3. Exactly ONE Duluth council district missing.
# ⚠ A greedy regex here deleted THREE inserts and the gate then reported 2, not 4. The gate was
# right; the CONTROL was lying about what it had planted.
stmts = re.findall(BOUNDARY_RE, src)
assert len(stmts) == 12, f'expected 12 boundary inserts, found {len(stmts)}'
victim = [s for s in stmts if "'duluth-mn-council-district-3'" in s]
assert len(victim) == 1, f'expected exactly 1 statement for Duluth district 3, found {len(victim)}'
c3 = src.replace(victim[0], '')
assert len(re.findall(BOUNDARY_RE, c3)) == 11, 'control 3 removed the wrong number of statements'
open('_c3.sql', 'w', encoding='utf-8').write(c3)

# 4. Duluth's four at-large offices given the SAME internal ordinal.
c4, n4 = re.subn(r"Internal ordinal \d of 4\.", "Internal ordinal 1 of 4.", src)
assert n4 >= 4, f'control 4 rewrote {n4} ordinals, expected at least 4'
open('_c4.sql', 'w', encoding='utf-8').write(c4)

# 5. Saint Paul given an at-large council seat its charter does not create.
c5 = src.replace("'Councilmember, Ward 7', NULL, 'Saint Paul')",
                 "'Councilmember, At Large', NULL, 'Saint Paul')", 1)
assert c5 != src, 'control 5 changed nothing'
open('_c5.sql', 'w', encoding='utf-8').write(c5)

# 6. A term written with no start date -- what MN-2 did everywhere and MN-3 must not.
c6, n6 = re.subn(r"'\d{4}-\d{2}-\d{2}'::date, '(?:day|month|year)'", "NULL::date, 'unknown'", src, count=1)
assert n6 == 1, 'control 6 blanked no date'
open('_c6.sql', 'w', encoding='utf-8').write(c6)

# 7. A term given a term_end, which silently self-vacates the seat.
c7 = src.replace("SELECT o.id, p.id, t.term_start, NULL, t.start_precision",
                 "SELECT o.id, p.id, t.term_start, DATE '2028-01-03', t.start_precision", 1)
assert c7 != src, 'control 7 changed nothing'
open('_c7.sql', 'w', encoding='utf-8').write(c7)

# 8. Two at-large seats given the SAME person.
# ⚠ The first attempt duplicated a PERSON row and the unique index on external_id fired before
# the gate did. A control that aborts for the wrong reason proves nothing, so the defect is
# planted in the TERM rows instead: two at-large terms pointing at one external_id.
lines = src.split('\n')
al = [i for i, l in enumerate(lines) if "'Councilor, At Large'" in l and '::date' in l]
assert len(al) == 4, f'expected 4 at-large term rows, found {len(al)}'
first_id = re.search(r'(-2734\d{3}), ', lines[al[0]]).group(1)
before = lines[al[1]]
lines[al[1]] = re.sub(r'-2734\d{3}, ', first_id + ', ', before, count=1)
assert lines[al[1]] != before, 'control 8 changed no external_id'
assert lines[al[1]].count(first_id) >= 1, 'control 8 did not duplicate the id'
open('_c8.sql', 'w', encoding='utf-8').write('\n'.join(lines))

print('  planted 8 control(s), each asserted')
