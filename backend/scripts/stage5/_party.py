"""The shared party-label test for the Python batch tools: asks party-check.ts (namesParty + roll-call letters),
so build_evidence.py, add_fallback.py and party-sweep.ts can never disagree on what names a party.
One long-lived child process per run; answers are cached. Needs backend/node_modules (npm ci)."""
import json, os, subprocess

_HERE = os.path.dirname(os.path.abspath(__file__))
_BACKEND = os.path.dirname(os.path.dirname(_HERE))
_proc, _cache = None, {}


def names_party(text):
    """True when text a reader would see carries a party label."""
    global _proc
    if text in _cache: return _cache[text]
    if _proc is None:
        tsx = os.path.join(_BACKEND, 'node_modules', '.bin', 'tsx')
        if not os.path.exists(tsx): raise SystemExit(f'party check needs {tsx}: run npm ci in {_BACKEND}')
        _proc = subprocess.Popen([tsx, os.path.join(_HERE, 'party-check.ts')], cwd=_BACKEND,
                                 stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, bufsize=1)
    _proc.stdin.write(json.dumps(text) + '\n'); _proc.stdin.flush()
    a = _proc.stdout.readline().strip()
    if a not in ('0', '1'): raise SystemExit(f'party check answered {a!r} for {text[:80]!r}')
    _cache[text] = a == '1'
    return _cache[text]
