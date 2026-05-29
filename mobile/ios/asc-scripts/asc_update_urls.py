#!/usr/bin/env python3
"""
Update App Store version-level localization URLs:
  - supportUrl
  - marketingUrl
  - whatsNew (release notes, optional)

For PREPARE_FOR_SUBMISSION version of ParaSende.
"""
import json
import os
import sys
import time
from pathlib import Path

import jwt
import requests

KEY_ID = os.environ.get("ASC_KEY_ID", "K3YS3S4G5T")
ISSUER_ID = os.environ.get("ASC_ISSUER_ID", "a9daba92-43c7-4471-b81c-689e1f17357e")
KEY_PATH = Path(os.environ.get(
    "ASC_KEY_PATH",
    str(Path.home() / ".appstoreconnect/private_keys" / f"AuthKey_{KEY_ID}.p8"),
)).expanduser()
BUNDLE_ID = "com.parasende.app"
BASE = "https://api.appstoreconnect.apple.com/v1"


def token() -> str:
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
    if r.status_code == 204:
        return None
    return r.json()


URL_FOR_LOCALE = {
    "tr": {
        "marketingUrl": "https://toptanperakende.online/",
        "supportUrl": "https://toptanperakende.online/destek/",
        "promotionalText": None,  # leave alone
    },
    "tr-TR": {
        "marketingUrl": "https://toptanperakende.online/",
        "supportUrl": "https://toptanperakende.online/destek/",
    },
    "en-US": {
        "marketingUrl": "https://toptanperakende.online/en/",
        "supportUrl": "https://toptanperakende.online/en/support/",
    },
    "en-GB": {
        "marketingUrl": "https://toptanperakende.online/en/",
        "supportUrl": "https://toptanperakende.online/en/support/",
    },
}
DEFAULT_URLS = {
    "marketingUrl": "https://toptanperakende.online/",
    "supportUrl": "https://toptanperakende.online/support",
}


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "inspect"
    t = token()
    apps = http("GET", "/apps", t, params={"filter[bundleId]": BUNDLE_ID})["data"]
    app_id = apps[0]["id"]
    versions = http("GET", f"/apps/{app_id}/appStoreVersions", t,
                    params={"limit": 25})["data"]
    versions.sort(key=lambda v: v["attributes"].get("createdDate", ""), reverse=True)
    target = next(
        (v for v in versions
         if v["attributes"].get("appStoreState") in (
             "PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED",
             "REJECTED", "METADATA_REJECTED")),
        versions[0],
    )
    print(f"Target version: {target['attributes']['versionString']} "
          f"({target['attributes']['appStoreState']}) id={target['id']}")

    locs = http("GET", f"/appStoreVersions/{target['id']}/appStoreVersionLocalizations",
                t)["data"]
    print(f"\nLocalizations ({len(locs)}):")
    for loc in locs:
        a = loc["attributes"]
        print(f"  · {a.get('locale')} (id={loc['id']})")
        for k in ["supportUrl", "marketingUrl", "promotionalText"]:
            v = a.get(k)
            if v:
                v = v[:80] + ("…" if len(v) > 80 else "")
            print(f"      {k:18s} = {v!r}")

    if mode == "inspect":
        return

    if mode != "apply":
        raise SystemExit(f"unknown mode: {mode}")

    print(f"\n== Updating URLs for each locale ==")
    for loc in locs:
        locale = loc["attributes"].get("locale", "")
        urls = URL_FOR_LOCALE.get(locale, DEFAULT_URLS)
        attrs = {}
        if "marketingUrl" in urls and urls["marketingUrl"]:
            attrs["marketingUrl"] = urls["marketingUrl"]
        if "supportUrl" in urls and urls["supportUrl"]:
            attrs["supportUrl"] = urls["supportUrl"]
        if not attrs:
            print(f"  · {locale}: nothing to change")
            continue
        body = {"data": {
            "type": "appStoreVersionLocalizations",
            "id": loc["id"],
            "attributes": attrs,
        }}
        print(f"  · {locale}: PATCH {attrs}")
        http("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", t, body=body)

    print("\n== Verify ==")
    locs = http("GET", f"/appStoreVersions/{target['id']}/appStoreVersionLocalizations",
                t)["data"]
    for loc in locs:
        a = loc["attributes"]
        print(f"  · {a.get('locale')}: "
              f"support={a.get('supportUrl')} "
              f"marketing={a.get('marketingUrl')}")


if __name__ == "__main__":
    main()
