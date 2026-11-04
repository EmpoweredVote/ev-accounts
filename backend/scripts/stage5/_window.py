"""The shared blank-passage finder for the Python batch tools: asks window-check.ts (verifiableWindow in lib.ts,
the verifier's own snippet, span and name-proximity checks plus the party test), so a passage add_fallback.py or
build_evidence.py cites for a blank is one the verifier verifies. One long-lived child process per run.
Needs backend/node_modules (npm ci)."""
import json, os, subprocess

_HERE = os.path.dirname(os.path.abspath(__file__))
_BACKEND = os.path.dirname(os.path.dirname(_HERE))
_proc = None


def verifiable_window(page_path, full_name, aliases=(), text=None):
    """A 25+ word party-free passage of the saved page (or of text) the verifier ties to full_name, or None."""
    global _proc
    if _proc is None:
        tsx = os.path.join(_BACKEND, 'node_modules', '.bin', 'tsx')
        if not os.path.exists(tsx): raise SystemExit(f'window check needs {tsx}: run npm ci in {_BACKEND}')
        _proc = subprocess.Popen([tsx, os.path.join(_HERE, 'window-check.ts')], cwd=_BACKEND,
                                 stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, bufsize=1)
    q = {'full_name': full_name, 'aliases': list(aliases)}
    if text is not None: q['text'] = text
    else: q['page'] = os.path.abspath(page_path)
    _proc.stdin.write(json.dumps(q) + '\n'); _proc.stdin.flush()
    a = json.loads(_proc.stdout.readline())
    if a == 'E': raise SystemExit(f'window check failed on {page_path!r} for {full_name!r}')
    return a
