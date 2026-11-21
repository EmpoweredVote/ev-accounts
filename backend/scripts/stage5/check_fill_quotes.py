"""Check that each quote a bill-text fill gives is in the saved bill text (9 states each kept their own copy of this).

usage: python3 -I scripts/stage5/check_fill_quotes.py --fills <dir> --texts <dir> --state xx [--flag <key>] [--skip <id>]...
                                                      [--worktree <dir>]

--fills  the folder of fill files, one <ID>.json per bill, each with `id` and `operative_text` (one quote per line).
         Only this state's files are read (<XX>-*.json).
--texts  the saved texts, <ID>.<version>.txt, with added words saved as {+ +} and struck words as [- -].
--flag   check only fills where this key is true (the fill brief's on-topic flag). Without it every fill is checked.
--skip   a bill to leave out (for example one whose stored text was kept as it was).

A quote passes when its letters are in the text as printed, or in the text as it reads once struck words are removed.
Section labels at the start of a line are removed first: the common ones ("Sec. 3:", "SECTION 2 (…):", "(a)", "[…]"),
then the legislature's own, from its profile (`fill_quotes.label_strips` in backend/data/legislatures/<xx>.json). A
long quote may break across lines of the text, so it is compared in windows of 8 words and passes when at most a
quarter of the windows miss. Parts of a quote on either side of "..." are checked apart; a part under 6 words is not.

Then every token of the quote, words and numbers, must be in the text in order (2026-11-21). The windows above read
letters only and forgive a quarter of a long quote, so "21" changed to "25" passed, and so did "shall not" changed to
"may" (Nevada; over 3,848 real quote parts of eight states the windows caught 0 of 996 planted number changes and 424
of 1,422 planted word changes, this rule 898 and 1,357, and it fails 32 honest parts, nearly all a label the fill
added in front). The text may hold more than the quote (a line number, a page header: up to 6 tokens between two
neighbours), a quote may carry on from another place when at least 4 tokens in a row are there, and a label of the
quote's own (a number, a letter, "Sec", "new law"; or its first words up to a colon) is passed over. A word or a
number the text does not have at that place is a miss: `MISS ... | exact: <why> at "<words>"`.
Prints each miss and exits 1 when there is one. 🔴 Run it once on a planted wrong quote before trusting a clean result,
and plant a hard one: change one number in a real quote.
"""
import bisect, collections, glob, json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt, opts
import legislature

USAGE = 'check_fill_quotes.py --fills <dir> --texts <dir> --state xx [--flag <key>] [--skip <id>]... [--worktree <dir>]'
SEC = r'(Sec(tion)?\.?|SECTION|SEC\.)'
def norm(s): return re.sub(r'[^a-z]+', ' ', s.lower()).strip()

GAP = 6          # text tokens that may sit between two neighbours of a quote (a line number, a page header)
RUN = 4          # a quote that jumps to another place must land on at least this many tokens in a row
LABELS = {'sec', 'section', 'new', 'law', 'subsection', 'sub'}
def toks(s): return re.findall(r'[a-z]+|\d+', s.lower())
def label(t): return t.isdigit() or len(t) == 1 or t in LABELS
def index(T):
    d = collections.defaultdict(list)
    for i, t in enumerate(T): d[t].append(i)
    return d
def _next(tok, cur, T, idx):
    """the text position of `tok` within GAP after `cur`; a word the text breaks in two ("pro- cess") counts"""
    ps = idx.get(tok)
    if ps:
        j = bisect.bisect_right(ps, cur)
        if j < len(ps) and ps[j] - cur - 1 <= GAP: return ps[j]
    for a in range(cur + 1, min(cur + 2 + GAP, len(T) - 1)):
        if T[a] + T[a + 1] == tok: return a + 1
    return None
def _run(q, k, T, idx, after=None):
    """where q[k:k+n] sits in the text in a row; `after`: only starting within GAP after that position"""
    n = min(RUN, len(q) - k)
    for s in idx.get(q[k], ()):
        if after is not None and not (after < s <= after + 1 + GAP): continue
        cur, m = s, 1
        while m < n:
            p = _next(q[k + m], cur, T, idx)
            if p is None: break
            cur, m = p, m + 1
        if m == n: return s, cur
    return None
def exact(q, T, idx):
    """None when every token of the quote is in the text, in order; else the token index where it stops and why."""
    k, cur = 0, None
    while k < len(q):
        if cur is not None:
            p = _next(q[k], cur, T, idx)
            if p is not None: cur, k = p, k + 1; continue
        r = _run(q, k, T, idx)                     # the quote carries on from another place
        if r: cur, k = r[1], k + min(RUN, len(q) - k); continue
        sk = 0
        while k + sk < len(q) and sk < 3 and label(q[k + sk]): 
            sk += 1
            if k + sk == len(q): return None       # the quote ends on a label of its own
            if cur is not None:
                adj = _run(q, k + sk, T, idx, after=cur)
                if adj:
                    if adj[0] == cur + 1 and not any(t.isdigit() for t in q[k:k + sk]): break   # a label the quote added
                    return k, 'the text has other words here'
            if _run(q, k + sk, T, idx): break
        else:
            return k, 'not in the text'
        r = _run(q, k + sk, T, idx, after=cur) if cur is not None else None
        r = r if (r and r[0] == cur + 1) else _run(q, k + sk, T, idx)
        if not r: return k, 'not in the text'
        cur, k = r[1], k + sk + min(RUN, len(q) - k - sk)
    return None


def main():
    fills, texts = opt('--fills', required=True, usage=USAGE), opt('--texts', required=True, usage=USAGE)
    xx = opt('--state', required=True, usage=USAGE).lower(); flag, skip = opt('--flag'), set(opts('--skip'))
    leg = legislature.load(xx, opt('--worktree')) or {}
    strips = [re.compile(rx, re.I) for rx in (leg.get('fill_quotes') or {}).get('label_strips') or []]
    files = sorted(glob.glob(os.path.join(fills, f'{xx.upper()}-*.json')))
    if not files: raise SystemExit(f'no {xx.upper()}-*.json in {fills}')
    tot = bad = bills = notext = 0
    for f in files:
        x = json.load(open(f)); iid = x['id']
        if iid in skip or (flag and not x.get(flag)): continue
        raws = [open(p).read() for p in glob.glob(os.path.join(texts, f'{iid}.*.txt'))]
        if not raws: notext += 1; print('NO TEXT', iid); continue
        bills += 1
        plain = lambda r: r.replace('{+', '').replace('+}', '')
        if (leg.get('fill_quotes') or {}).get('brackets_delete'):
            # The text prints words deleted from existing law in plain [brackets] (Maryland): a quote of the law after
            # the bill leaves them out, so compare with a copy that leaves them out too.
            raws = raws + [re.sub(r'\[(?![-+])[^\[\]]*?\]', '', r, flags=re.S) for r in raws]
        variants = [v for r in raws for v in (plain(r).replace('[-', '').replace('-]', ''), plain(re.sub(r'\[-.*?-\]', '', r, flags=re.S)))]
        TT = [(T, index(T)) for T in map(toks, variants)]
        t = ' || '.join(norm(plain(r).replace('[-', '').replace('-]', '')) + ' || ' + norm(plain(re.sub(r'\[-.*?-\]', '', r, flags=re.S))) for r in raws)
        for line in (x.get('operative_text') or '').split('\n'):
            for rx in strips: line = rx.sub(' ', line, count=1)
            m = re.match(r'^\s*' + SEC + r'\s*[\w.\-]+\s*\(.{0,160}?\)\s*:\s*', line, flags=re.I) or re.match(r'^\s*' + SEC + r'\s*[\w.\-]+\s*:\s*', line, flags=re.I)
            q = line[m.end():] if m else line
            if re.match(r'^\s*(Sec|SEC)', q): q = re.sub(r'^\s*' + SEC + r'\s*[\w.\-]+[^:]{0,160}:\s*', '', q, flags=re.I)
            q = re.sub(r'^\s*\[[^\]]*\]\s*', '', q)
            q = re.sub(r'^\s*(\([a-zA-Z0-9]{1,4}\)\s*)+', '', q)
            for part in re.split(r'\s*(?:\.\.\.|…)\s*', q):
                n = norm(part)
                if len(n.split()) < 6: continue
                tot += 1
                if n not in t:
                    w = n.split(); idx = range(0, max(1, len(w) - 7), 4); miss = [i for i in idx if ' '.join(w[i:i + 8]) not in t]
                    if len(miss) > len(idx) * 0.25: bad += 1; print('MISS', iid, len(miss), '/', len(idx), '|', part[:120]); continue
                # a label of the fill's own in front of the quote ("New Sec. 4 (new law): ...") is not the bill's words
                qs = [toks(part)] + ([toks(part.split(':', 1)[1])] if ':' in part[:60] else [])
                res = [exact(q, T, ix) for q in qs if q for T, ix in TT]
                if all(res):
                    k, why = max(res); q = qs[0]; bad += 1
                    print('MISS', iid, '| exact:', why, 'at "' + ' '.join(q[max(0, k - 4):k]) + ' >>' + ' '.join(q[k:k + 4]) + '<<" |', part[:120])
    print(f'{bills} bill(s), checked {tot} quote parts; misses {bad}' + (f'; {notext} bill(s) with no saved text' if notext else ''))
    return 1 if bad or notext else 0


if __name__ == '__main__':
    sys.exit(main())
