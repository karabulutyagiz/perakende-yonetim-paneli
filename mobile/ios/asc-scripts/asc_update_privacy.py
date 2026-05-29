#!/usr/bin/env python3
"""Update Privacy Policy URL on App Info level."""
import json, os, time
from pathlib import Path
import jwt, requests

KEY_ID = os.environ.get("ASC_KEY_ID", "K3YS3S4G5T")
ISSUER_ID = os.environ.get("ASC_ISSUER_ID", "a9daba92-43c7-4471-b81c-689e1f17357e")
KEY_PATH = Path(os.environ.get(
    "ASC_KEY_PATH",
    str(Path.home() / ".appstoreconnect/private_keys" / f"AuthKey_{KEY_ID}.p8"),
)).expanduser()
BUNDLE_ID = "com.parasende.app"
BASE = "https://api.appstoreconnect.apple.com/v1"

PRIVACY_URL_FOR = {
    "tr": "https://toptanperakende.online/privacy",
    "tr-TR": "https://toptanperakende.online/privacy",
    "en-US": "https://toptanperakende.online/legal/en/privacy.html",
    "en-GB": "https://toptanperakende.online/legal/en/privacy.html",
}
DEFAULT_PRIVACY = "https://toptanperakende.online/privacy"


def tok():
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 900,
         "aud": "appstoreconnect-v1"},
        KEY_PATH.read_text(),
        algorithm="ES256",
        headers={"kid": KEY_ID, "typ": "JWT"},
    )

def http(method, path, t, *, params=None, body=None):
    url = path if path.startswith("http") else BASE + path
    h = {"Authorization": f"Bearer {t}"}
    if body is not None:
        h["Content-Type"] = "application/json"
    r = requests.request(method, url, headers=h, params=params,
                         data=json.dumps(body) if body else None)
    if not r.ok:
        print(f"\n!! HTTP {r.status_code} on {method} {url}\n{r.text}")
        r.raise_for_status()
    return r.json() if r.status_code != 204 else None

import sys
mode = sys.argv[1] if len(sys.argv) > 1 else "inspect"
t = tok()
app = http("GET", "/apps", t, params={"filter[bundleId]": BUNDLE_ID})["data"][0]
print(f"App {app['id']} {app['attributes'].get('name')!r}")

# Get appInfos for the app
infos = http("GET", f"/apps/{app['id']}/appInfos", t)["data"]
print(f"\nAppInfos ({len(infos)}):")
for info in infos:
    a = info["attributes"]
    print(f"  · id={info['id']} state={a.get('state')} "
          f"appStoreState={a.get('appStoreState')}")

# Pick the editable one (state PREPARE_FOR_SUBMISSION or similar)
editable = next(
    (i for i in infos
     if i["attributes"].get("state") in ("PREPARE_FOR_SUBMISSION",)
     or i["attributes"].get("appStoreState") in ("PREPARE_FOR_SUBMISSION",
                                                 "REJECTED", "METADATA_REJECTED")),
    infos[0],
)
print(f"\n→ editing appInfo {editable['id']}")

locs = http("GET", f"/appInfos/{editable['id']}/appInfoLocalizations", t)["data"]
print(f"\nLocalizations ({len(locs)}):")
for loc in locs:
    a = loc["attributes"]
    print(f"  · {a.get('locale')} (id={loc['id']}) "
          f"privacyPolicyUrl={a.get('privacyPolicyUrl')!r}")

if mode == "inspect":
    raise SystemExit(0)

print("\n== Updating Privacy Policy URLs ==")
for loc in locs:
    locale = loc["attributes"].get("locale", "")
    url = PRIVACY_URL_FOR.get(locale, DEFAULT_PRIVACY)
    body = {"data": {
        "type": "appInfoLocalizations",
        "id": loc["id"],
        "attributes": {"privacyPolicyUrl": url},
    }}
    print(f"  · {locale}: → {url}")
    http("PATCH", f"/appInfoLocalizations/{loc['id']}", t, body=body)

print("\n== Verify ==")
for loc in http("GET", f"/appInfos/{editable['id']}/appInfoLocalizations", t)["data"]:
    a = loc["attributes"]
    print(f"  · {a.get('locale')}: privacy={a.get('privacyPolicyUrl')}")
