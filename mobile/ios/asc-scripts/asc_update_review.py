#!/usr/bin/env python3
"""
App Store Connect — sync App Review Information across versions.

Modes:
  inspect              read-only; show app + versions + review detail
  apply                ensure PREPARE_FOR_SUBMISSION version has full review
                       detail (creates if missing, patches if present) with
                       new notes + demo credentials + contact info.

Env:
  ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH
  BUNDLE_ID            default com.parasende.app
  NOTES_PATH           path to the new review notes (UTF-8 text)
  DEMO_USER, DEMO_PASSWORD
  CONTACT_FIRST_NAME, CONTACT_LAST_NAME, CONTACT_EMAIL, CONTACT_PHONE
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
BUNDLE_ID = os.environ.get("BUNDLE_ID", "com.parasende.app")
NOTES_PATH = Path(os.environ.get("NOTES_PATH", ""))
DEMO_USER = os.environ.get("DEMO_USER", "playreview@toptanpanel.com")
DEMO_PASSWORD = os.environ.get("DEMO_PASSWORD", "pZ4S7MikKv81soRO")

CONTACT_FIRST_NAME = os.environ.get("CONTACT_FIRST_NAME", "Yağız")
CONTACT_LAST_NAME = os.environ.get("CONTACT_LAST_NAME", "Karabulut")
CONTACT_EMAIL = os.environ.get("CONTACT_EMAIL", "yigit@karabulut.work")
CONTACT_PHONE = os.environ.get("CONTACT_PHONE", "+905394812767")

BASE = "https://api.appstoreconnect.apple.com/v1"


def make_token() -> str:
    now = int(time.time())
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": now + 60 * 15,
        "aud": "appstoreconnect-v1",
    }
    return jwt.encode(
        payload,
        KEY_PATH.read_text(),
        algorithm="ES256",
        headers={"kid": KEY_ID, "typ": "JWT"},
    )


def http(method: str, path: str, token: str, *, params=None, body=None):
    url = path if path.startswith("http") else BASE + path
    headers = {"Authorization": f"Bearer {token}"}
    if body is not None:
        headers["Content-Type"] = "application/json"
    r = requests.request(method, url, headers=headers, params=params,
                         data=json.dumps(body) if body else None)
    if not r.ok:
        print(f"\n!! HTTP {r.status_code} on {method} {url}")
        print(r.text)
        r.raise_for_status()
    if r.status_code == 204:
        return None
    return r.json()


def discover_app(token: str) -> dict:
    res = http("GET", "/apps", token, params={"filter[bundleId]": BUNDLE_ID})
    apps = res.get("data", [])
    if not apps:
        raise SystemExit(f"No app for bundleId={BUNDLE_ID}")
    return apps[0]


def all_versions(token: str, app_id: str) -> list:
    res = http("GET", f"/apps/{app_id}/appStoreVersions", token, params={"limit": 25})
    versions = res.get("data", [])
    versions.sort(key=lambda v: v["attributes"].get("createdDate", ""), reverse=True)
    return versions


def review_detail(token: str, version_id: str):
    try:
        res = http("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail", token)
    except requests.HTTPError:
        return None
    return res.get("data") if res else None


def print_detail(d):
    if not d:
        print("    (no review detail)")
        return
    a = d.get("attributes", {})
    for k in ["contactFirstName", "contactLastName", "contactEmail", "contactPhone",
              "demoAccountName", "demoAccountPassword", "demoAccountRequired"]:
        print(f"    {k:24s} = {a.get(k)!r}")
    notes = a.get("notes") or ""
    head = notes[:140].replace("\n", " ")
    print(f"    notes ({len(notes)} chars) head: {head!r}")


def create_review_detail(token, version_id, notes, demo_user, demo_pass):
    body = {
        "data": {
            "type": "appStoreReviewDetails",
            "attributes": {
                "contactFirstName": CONTACT_FIRST_NAME,
                "contactLastName": CONTACT_LAST_NAME,
                "contactEmail": CONTACT_EMAIL,
                "contactPhone": CONTACT_PHONE,
                "demoAccountName": demo_user,
                "demoAccountPassword": demo_pass,
                "demoAccountRequired": True,
                "notes": notes,
            },
            "relationships": {
                "appStoreVersion": {
                    "data": {"type": "appStoreVersions", "id": version_id},
                },
            },
        }
    }
    return http("POST", "/appStoreReviewDetails", token, body=body)


def patch_review_detail(token, detail_id, notes, demo_user, demo_pass):
    body = {
        "data": {
            "type": "appStoreReviewDetails",
            "id": detail_id,
            "attributes": {
                "contactFirstName": CONTACT_FIRST_NAME,
                "contactLastName": CONTACT_LAST_NAME,
                "contactEmail": CONTACT_EMAIL,
                "contactPhone": CONTACT_PHONE,
                "demoAccountName": demo_user,
                "demoAccountPassword": demo_pass,
                "demoAccountRequired": True,
                "notes": notes,
            },
        }
    }
    return http("PATCH", f"/appStoreReviewDetails/{detail_id}", token, body=body)


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "inspect"
    token = make_token()

    print("\n== App ==")
    app = discover_app(token)
    print(f"  id={app['id']} name={app['attributes'].get('name')!r}")

    print("\n== Versions (newest first) ==")
    versions = all_versions(token, app["id"])
    for v in versions:
        a = v["attributes"]
        print(f"\n  · {a.get('versionString')} state={a.get('appStoreState')} "
              f"created={a.get('createdDate')} id={v['id']}")
        d = review_detail(token, v["id"])
        print_detail(d)

    target = next(
        (v for v in versions
         if v["attributes"].get("appStoreState") in (
             "PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED",
             "DEVELOPER_REMOVED_FROM_SALE", "REJECTED", "METADATA_REJECTED",
             "INVALID_BINARY", "WAITING_FOR_REVIEW", "IN_REVIEW")),
        None,
    )
    if not target:
        raise SystemExit("No editable version found.")
    print(f"\n→ Target version for edits: id={target['id']} "
          f"({target['attributes']['versionString']}, "
          f"state={target['attributes']['appStoreState']})")

    if mode == "inspect":
        print("\nDone (read-only).")
        return

    if mode != "apply":
        raise SystemExit(f"unknown mode: {mode}")

    if not NOTES_PATH or not NOTES_PATH.exists():
        raise SystemExit(f"NOTES_PATH missing: {NOTES_PATH}")
    new_notes = NOTES_PATH.read_text()
    if len(new_notes) > 4000:
        raise SystemExit(f"notes too long ({len(new_notes)} > 4000)")

    print(f"\n== Applying changes (notes {len(new_notes)} chars) ==")
    existing = review_detail(token, target["id"])
    if existing:
        print(f"  PATCH /appStoreReviewDetails/{existing['id']}")
        patch_review_detail(token, existing["id"], new_notes, DEMO_USER, DEMO_PASSWORD)
    else:
        print(f"  POST  /appStoreReviewDetails (new for version {target['id']})")
        res = create_review_detail(token, target["id"], new_notes,
                                   DEMO_USER, DEMO_PASSWORD)
        print(f"  created id={res['data']['id']}")

    print("\n== Re-fetch to verify ==")
    print_detail(review_detail(token, target["id"]))


if __name__ == "__main__":
    main()
