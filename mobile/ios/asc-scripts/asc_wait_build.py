#!/usr/bin/env python3
"""Poll App Store Connect until a given build number is VALID (processed)."""
import json, os, sys, time
from pathlib import Path
import jwt, requests

KEY_ID = "K3YS3S4G5T"
ISSUER_ID = "a9daba92-43c7-4471-b81c-689e1f17357e"
KEY_PATH = Path.home() / ".appstoreconnect/private_keys" / f"AuthKey_{KEY_ID}.p8"
BUNDLE_ID = "com.parasende.app"
BASE = "https://api.appstoreconnect.apple.com/v1"

TARGET_BUILD = sys.argv[1] if len(sys.argv) > 1 else "10"
TIMEOUT_SEC = int(sys.argv[2]) if len(sys.argv) > 2 else 1200  # 20 min
POLL_INTERVAL = 30


def tok():
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now+900, "aud":"appstoreconnect-v1"},
        KEY_PATH.read_text(), algorithm="ES256",
        headers={"kid": KEY_ID, "typ":"JWT"})

def get(path, params=None):
    r = requests.get(BASE+path,
        headers={"Authorization": f"Bearer {tok()}"}, params=params)
    r.raise_for_status()
    return r.json()

app = get("/apps", {"filter[bundleId]": BUNDLE_ID})["data"][0]
app_id = app["id"]
deadline = time.time() + TIMEOUT_SEC

print(f"Waiting for build {TARGET_BUILD} to be VALID (timeout {TIMEOUT_SEC}s)...")
while True:
    builds = get(f"/apps/{app_id}/builds", {"limit": 25})["data"]
    target = next((b for b in builds if b["attributes"].get("version") == TARGET_BUILD), None)
    elapsed = int(time.time() - (deadline - TIMEOUT_SEC))
    if target:
        state = target["attributes"].get("processingState")
        print(f"  [{elapsed:4d}s] build {TARGET_BUILD} state={state}", flush=True)
        if state == "VALID":
            print(f"\n✅ build {TARGET_BUILD} is VALID (id={target['id']})")
            sys.exit(0)
        if state in ("FAILED", "INVALID"):
            print(f"\n❌ build failed: {state}")
            sys.exit(2)
    else:
        print(f"  [{elapsed:4d}s] build {TARGET_BUILD} not yet visible in App Store Connect", flush=True)
    if time.time() > deadline:
        print(f"\n⏱  timed out after {TIMEOUT_SEC}s")
        sys.exit(3)
    time.sleep(POLL_INTERVAL)
