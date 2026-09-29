"""Apply essentials.politician_name_duplicate_guard()'s EXACT rule to every person this wave
would insert: an ACTIVE row whose lower(btrim(first_name)) and lower(btrim(last_name)) both match.

A full_name sweep is NOT the same test and missed David Tyson Smith vs Florida's David Smith.
"""
import json, html, os

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
rows = json.load(open(os.path.join(HERE, "mo-occupancy-2026-09-28.json"), encoding="utf-8"))
seated = [r for r in rows if not r["is_vacant"]]

def q(s):
    return s.replace("'", "''")

vals = []
for r in seated:
    n = html.unescape(r["holder"]).strip()
    t = n.split()
    vals.append("  ('%s','%s','%s','%s',%d)" % (q(n), q(t[0]), q(t[-1]), r["chamber"], r["district"]))

sql = """WITH mo(full_name, first_name, last_name, chamber, district) AS (VALUES
%s
)
SELECT mo.chamber, mo.district, mo.full_name AS ours,
       p.full_name AS theirs, p.external_id, p.is_incumbent,
       coalesce(c.name, '-') AS their_chamber,
       coalesce(d.label, '-') AS their_seat,
       coalesce(d.state, '-') AS their_state,
       (SELECT count(*) FROM inform.politician_answers pa WHERE pa.politician_id = p.id) AS stances,
       (SELECT count(*) FROM essentials.quotes qq WHERE qq.politician_id = p.id) AS quotes,
       (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.politician_id = p.id) AS races
FROM mo
JOIN essentials.politicians p
  ON p.is_active
 AND lower(btrim(p.first_name)) = lower(btrim(mo.first_name))
 AND lower(btrim(p.last_name))  = lower(btrim(mo.last_name))
LEFT JOIN essentials.office_current_holder och ON och.politician_id = p.id
LEFT JOIN essentials.offices o ON o.id = och.office_id
LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
LEFT JOIN essentials.districts d ON d.id = o.district_id
ORDER BY mo.chamber, mo.district;""" % ",\n".join(vals)

out = os.path.join(HERE, "_guardcheck.sql")
open(out, "w", encoding="utf-8", newline="\n").write(sql)
print("wrote", out, len(sql), "chars,", len(vals), "people tested")
