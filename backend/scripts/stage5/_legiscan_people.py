"""Match LegiScan people to roster politician ids, shared by the bill-round tools.

The LegiScan person id is the key: `idmap.tsv` (`<legiscan people_id>\t<politician_id>`) is read first, and a match
made by name is reported so it can be saved there once (review 2026-11-12, change 7: a new nickname per state cost
hand work in IN, NC, WI and GA). A name match needs the first three letters of the first name (or of the nickname
LegiScan prints, or of a quoted nickname in the roster name) and the whole last name, and it must be unique.
"""
import csv, glob, json, os, re, unicodedata

SUFFIX = {'jr', 'sr', 'ii', 'iii', 'iv'}


def norm(s):
    return re.sub(r'[^a-z]', '', unicodedata.normalize('NFD', s or '').encode('ascii', 'ignore').decode().lower())


def read_roster(paths):
    """Roster rows by politician id (first file wins), from one or more roster TSVs."""
    out = {}
    for p in paths:
        for r in csv.DictReader(open(p), delimiter='\t'):
            out.setdefault(r['politician_id'], r)
    return out


def read_idmap(path):
    out = {}
    if path and os.path.exists(path):
        for line in open(path):
            parts = line.rstrip('\n').split('\t')
            if len(parts) >= 2 and parts[0].strip().isdigit(): out[int(parts[0])] = parts[1]
    return out


def read_people(ds_root, state):
    """LegiScan people of one state's datasets (`<ds_root>/<ST>-<sid>/<...>/people/*.json`), by people_id."""
    out = {}
    for f in glob.glob(os.path.join(ds_root, f'{state}-*', '*', '*', 'people', '*.json')):
        p = json.load(open(f))['person']
        out[p['people_id']] = p
    return out


class Matcher:
    def __init__(self, roster, idmap, people):
        self.idmap, self.people, self.by_name = idmap, people, {}
        self.ids = set(roster)
        for pid, r in roster.items():
            name = r.get('full_name') or r.get('name') or ''
            words = [w for w in re.sub(r'"[^"]*"', ' ', name).replace(',', ' ').split() if norm(w) not in SUFFIX and not re.match(r'^[A-Z]\.$', w)]
            if not words: continue
            firsts = [words[0]] + re.findall(r'"([^"]+)"', name)
            for f in firsts: self.by_name.setdefault((norm(f)[:3], norm(words[-1])), set()).add(pid)
        self.by_name_used = {}

    def match(self, ls_id):
        """Politician id for a LegiScan person, or None. Name matches are remembered in `by_name_used`."""
        if ls_id in self.idmap:
            x = self.idmap[ls_id]
            return x if x in self.ids else None
        p = self.people.get(ls_id)
        if not p: return None
        hits = set()
        for f in (p.get('first_name'), p.get('nickname')):
            if f: hits |= self.by_name.get((norm(f)[:3], norm(p.get('last_name'))), set())
        if len(hits) == 1:
            x = hits.pop()
            self.by_name_used[ls_id] = (x, p.get('name') or f"{p.get('first_name')} {p.get('last_name')}")
            return x
        return None
