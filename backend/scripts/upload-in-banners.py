"""
upload-in-banners.py -- upload the two certified Indiana city banners to Supabase Storage.

🔴 BOTH HEADERS, OR IT FAILS AS A 400. Since the legacy anon/service_role keys were disabled,
SUPABASE_SERVICE_ROLE_KEY is not a JWT. `Authorization: Bearer <key>` alone returns HTTP 400
{"statusCode":"403","error":"Unauthorized","message":"Invalid Compact JWS"}. Send Authorization
AND apikey, both set to the key.

🔴 VERIFY BY sha256 ON BOTH THE PLAIN AND A CACHE-BUSTED URL, never by HTTP 200. Overwriting an
object does NOT reliably purge the CDN -- measured on cities/bend.jpg and again on states/TX.jpg,
where the plain URL served the OLD bytes seconds after a successful upload. These are NEW keys, so
no -v2 is needed, but the check is run anyway: that is how the stale-CDN behaviour was found.
"""
import hashlib, os, sys
import requests
from dotenv import load_dotenv

load_dotenv()
URL = os.environ["SUPABASE_URL"].rstrip("/")
KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
BUCKET = "politician_photos"
H = {"Authorization": f"Bearer {KEY}", "apikey": KEY}

FILES = [("cities/fort-wayne.jpg", "data/_banners/fort-wayne.jpg"),
         ("cities/gary.jpg", "data/_banners/gary.jpg")]

fail = False
for path, local in FILES:
    raw = open(local, "rb").read()
    local_sha = hashlib.sha256(raw).hexdigest()
    pub = f"{URL}/storage/v1/object/public/{BUCKET}/{path}"

    # Refuse to clobber: these are meant to be new keys.
    head = requests.get(pub, timeout=60)
    if head.status_code == 200:
        print(f"  !! {path} ALREADY EXISTS ({len(head.content)} bytes). Not overwriting -- an "
              f"overwrite needs a versioned filename, not a silent replace.")
        fail = True
        continue

    r = requests.post(f"{URL}/storage/v1/object/{BUCKET}/{path}", headers=H,
                      data=raw, timeout=180,
                      params={"cacheControl": "3600"})
    print(f"  upload {path}: HTTP {r.status_code} {r.text[:120] if r.status_code >= 300 else ''}")
    if r.status_code >= 300:
        fail = True
        continue

    import time
    time.sleep(1)
    plain = requests.get(pub, timeout=60)
    busted = requests.get(pub + f"?v={int(time.time())}", timeout=60)
    ps = hashlib.sha256(plain.content).hexdigest()
    bs = hashlib.sha256(busted.content).hexdigest()
    ok = (ps == local_sha == bs)
    print(f"     local  sha256 {local_sha[:16]}  {len(raw)} bytes")
    print(f"     plain  sha256 {ps[:16]}  HTTP {plain.status_code}")
    print(f"     busted sha256 {bs[:16]}  HTTP {busted.status_code}")
    print(f"     -> {'MATCH on both URLs' if ok else 'MISMATCH -- do not register this URL'}")
    print(f"     {pub}")
    if not ok:
        fail = True

sys.exit(1 if fail else 0)
