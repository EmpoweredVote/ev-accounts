import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def load(path, key_candidates):
    g = json.load(open(path, encoding='utf-8'))
    out = []
    for f in g['features']:
        p = f['properties']
        k = None
        for c in key_candidates:
            if c in p and p[c] not in (None, ''):
                k = str(p[c]).strip(); break
        rings = []
        geom = f['geometry']
        polys = geom['coordinates'] if geom['type'] == 'MultiPolygon' else [geom['coordinates']]
        for poly in polys:
            rings.append([[(x, y) for x, y in r] for r in poly])
        out.append((k, rings, p))
    return out

def pip(x, y, rings):
    """rings = list of polygons, each a list of rings (outer first)"""
    inside = False
    for poly in rings:
        c = False
        for ri, ring in enumerate(poly):
            w = False
            n = len(ring)
            for i in range(n):
                x1, y1 = ring[i]; x2, y2 = ring[(i+1) % n]
                if ((y1 > y) != (y2 > y)) and (x < (x2-x1)*(y-y1)/((y2-y1) or 1e-15) + x1):
                    w = not w
            if ri == 0: c = w
            elif w: c = False          # hole
        if c: inside = True
    return inside

def assign(x, y, layer):
    for k, rings, _ in layer:
        if pip(x, y, rings): return k
    return None

A = load('geo-Council_District_Plan_2022.json', ['DISTRICT','SHORTNAME','LONGNAME'])
B = load('geo-Council_Districts_WFL1.json',     ['DISTRICT','SHORTNAME','LONGNAME'])
C = load('geo-County_Council_Districts_2019.json', ['COUNTY_COU','NAME'])

for nm, L in (('Plan_2022', A), ('WFL1/2023', B), ('2019 (control)', C)):
    print(f'{nm:18s} features={len(L):2d} keys={sorted(k for k,_,_ in L)}')

# bbox from A
xs = [x for _, rings, _ in A for poly in rings for ring in poly for x, y in ring]
ys = [y for _, rings, _ in A for poly in rings for ring in poly for x, y in ring]
x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
print(f'bbox {x0:.4f},{y0:.4f} .. {x1:.4f},{y1:.4f}')

N = 160
pts = []
for i in range(N):
    for j in range(N):
        pts.append((x0 + (x1-x0)*(i+0.5)/N, y0 + (y1-y0)*(j+0.5)/N))

def compare(L1, L2, n1, n2):
    same = diff = only1 = only2 = neither = 0
    examples = []
    for x, y in pts:
        a = assign(x, y, L1); b = assign(x, y, L2)
        if a is None and b is None: neither += 1
        elif a is None: only2 += 1
        elif b is None: only1 += 1
        elif a == b: same += 1
        else:
            diff += 1
            if len(examples) < 5: examples.append((round(x,5), round(y,5), a, b))
    inside = same + diff + only1 + only2
    print(f'\n{n1} vs {n2}: {inside} pts inside either')
    print(f'   same district : {same:6d}  ({100*same/(inside or 1):.2f}%)')
    print(f'   DIFFERENT     : {diff:6d}  ({100*diff/(inside or 1):.2f}%)   e.g. {examples}')
    print(f'   only {n1:12s}: {only1}')
    print(f'   only {n2:12s}: {only2}')
    return diff, inside

compare(A, B, 'Plan_2022', 'WFL1/2023')
compare(A, C, 'Plan_2022', '2019ctl')
