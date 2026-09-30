import importlib.util, sys, json
spec = importlib.util.spec_from_file_location("j","join2.py")
# re-import just the matcher by exec'ing the top of join2
src = open("join2.py").read().split("VACANT = re.compile")[0]
ns = {}; exec(src, ns)
same = ns["same"]

cases = [
 # (a, b, expected_same, why)
 ("Mazzie Christensen","Mazzie Boyd", False, "TAMPER: surname change must NOT auto-match"),
 ("Mark Sharp","Greg Sharpe",        False, "one letter apart, two real people"),
 ("Richard Brown","Donnie Brown",    False, "Brown 27 vs Brown 149"),
 ("Kem Smith","Cody Smith",          False, "two real Smiths"),
 ("John Simmons","Kyle Marquart",    False, "the HD-109 gap"),
 ("Ken Jamison","Kenneth Jamison",   True,  "nickname, same person"),
 ("Dean Van Schoiack","Dean VanSchoiack", True, "spacing, same person"),
 ("Marty Joe Murray","Marty (Joe) Murray", True, "parenthetical, same person"),
 ("Dirk E. Deaton","Dirk Deaton",    True,  "middle initial, same person"),
]
bad = 0
for a,b,exp,why in cases:
    got = same(a,b)
    ok = "ok  " if got==exp else "FAIL"
    if got!=exp: bad += 1
    print(f"  {ok} same({a!r:22},{b!r:22}) = {got!s:5} expected {exp!s:5}  # {why}")
print(f"\n{'ALL CONTROLS PASS' if bad==0 else str(bad)+' CONTROL(S) FAILED'}")
