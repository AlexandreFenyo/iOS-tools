#!/usr/bin/env python3
"""Publie la version 6.4 sur App Store Connect : 50 langues, frises, soumission.

La 6.4 remet la fiche de référencement préparée pour la 6.2 (nom « WiFi Heat Map &
Analyzer », textes de ASO/metadata/<locale>/) et l'étend aux 50 langues de la fiche
de Captured ; ses notes de version annoncent l'app en 44 langues. Captures : les frises
de ASO/screenshots/<locale>/{iphone69,ipad13-landscape}-frise/ (scripts/screenshots.sh).

Étapes (idempotentes, à lancer dans l'ordre) :
  version      crée la version 6.4 (ou la retrouve), publication automatique à l'approbation
  texts        nom, sous-titre, URL de confidentialité (appInfo) ; description, mots-clés,
               texte promotionnel, notes de version, URL (version), pour chaque langue
  screenshots  remplace toutes les captures par les frises iPhone 6,9" et iPad 13" ;
               supprime les jeux d'anciens formats (Apple les déduit des plus grands)
  build        rattache le build 29 une fois traité par Apple
  submit       recopie le contact App Review de la 6.3 et soumet la version à la revue

Usage : ASC_ISSUER_ID=<issuer> python3 ASO/tools/publish-6.4.py <étape> [locales]
"""
import hashlib
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
META = os.path.join(ROOT, "ASO", "metadata")
SHOTS = os.path.join(ROOT, "ASO", "screenshots")
APP = "1662393654"
VERSION, BUILD = "6.4", "29"
V63 = "ec7c637d-919d-4ae4-a12d-c6fea96fd17b"
SUPPORT = "https://fenyo.net/network3dwifitools/support.html"
MARKETING = "https://fenyo.net/network3dwifitools"
PRIVACY = "https://fenyo.net/network3dwifitools/support.html"
# Jeux de captures publiés : format App Store Connect -> dossier des frises
DISPLAY = {"APP_IPHONE_67": "iphone69-frise", "APP_IPAD_PRO_3GEN_129": "ipad13-landscape-frise"}


def call(method, path, body=None):
    args = [os.path.join(HERE, "asc.sh"), method, path]
    tmp = None
    if body is not None:
        tmp = os.path.join(HERE, f".body-{os.getpid()}.json")
        with open(tmp, "w") as f:
            json.dump(body, f)
        args.append(tmp)
    try:
        out = subprocess.run(args, capture_output=True, text=True, check=True).stdout
    finally:
        if tmp and os.path.exists(tmp):
            os.remove(tmp)
    txt, _, code = out.rpartition("__HTTP_")
    code = int(code.strip("_\n"))
    data = json.loads(txt) if txt.strip() else None
    if code >= 300:
        raise RuntimeError(f"{method} {path} -> {code}: {json.dumps(data)[:800]}")
    return data


def get_all(path):
    out, url = [], path
    while url:
        d = call("GET", url)
        out += d["data"]
        nxt = d.get("links", {}).get("next")
        url = nxt.replace("https://api.appstoreconnect.apple.com", "") if nxt else None
    return out


def read(locale, name):
    with open(os.path.join(META, locale, name), encoding="utf-8") as f:
        return f.read().strip()


def locales():
    return sorted(d for d in os.listdir(META) if os.path.isdir(os.path.join(META, d)))


def find_version():
    for v in get_all(f"/v1/apps/{APP}/appStoreVersions?limit=50"):
        a = v["attributes"]
        if a["platform"] == "IOS" and a["versionString"] == VERSION:
            return v["id"], a["appStoreState"]
    return None, None


def step_version():
    vid, state = find_version()
    if not vid:
        vid = call("POST", "/v1/appStoreVersions", {"data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": VERSION, "releaseType": "AFTER_APPROVAL"},
            "relationships": {"app": {"data": {"type": "apps", "id": APP}}}}})["data"]["id"]
        state = "créée"
    else:
        call("PATCH", f"/v1/appStoreVersions/{vid}", {"data": {
            "type": "appStoreVersions", "id": vid, "attributes": {"releaseType": "AFTER_APPROVAL"}}})
    print(f"version {VERSION} : {vid} ({state})")
    return vid


def editable_appinfo():
    for i in get_all(f"/v1/apps/{APP}/appInfos"):
        if (i["attributes"].get("state") or i["attributes"].get("appStoreState")) not in (
                "READY_FOR_DISTRIBUTION", "READY_FOR_SALE"):
            return i["id"]
    sys.exit("pas d'appInfo modifiable : lancer d'abord l'étape « version »")


def step_texts(only):
    vid, _ = find_version()
    info = editable_appinfo()
    infolocs = {l["attributes"]["locale"]: l["id"] for l in get_all(f"/v1/appInfos/{info}/appInfoLocalizations")}
    for loc in only:
        attrs = {"name": read(loc, "name.txt"), "subtitle": read(loc, "subtitle.txt"), "privacyPolicyUrl": PRIVACY}
        if loc in infolocs:
            call("PATCH", f"/v1/appInfoLocalizations/{infolocs[loc]}", {"data": {
                "type": "appInfoLocalizations", "id": infolocs[loc], "attributes": attrs}})
        else:
            # Crée aussi la localisation de version correspondante (on la complète ensuite)
            call("POST", "/v1/appInfoLocalizations", {"data": {
                "type": "appInfoLocalizations", "attributes": {"locale": loc, **attrs},
                "relationships": {"appInfo": {"data": {"type": "appInfos", "id": info}}}}})
    vlocs = {l["attributes"]["locale"]: l["id"] for l in get_all(f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations?limit=50")}
    for loc in only:
        attrs = {"description": read(loc, "description.txt"), "keywords": read(loc, "keywords.txt"),
                 "promotionalText": read(loc, "promotional_text.txt"), "whatsNew": read(loc, "release_notes.txt"),
                 "supportUrl": SUPPORT, "marketingUrl": MARKETING}
        if loc in vlocs:
            call("PATCH", f"/v1/appStoreVersionLocalizations/{vlocs[loc]}", {"data": {
                "type": "appStoreVersionLocalizations", "id": vlocs[loc], "attributes": attrs}})
        else:
            call("POST", "/v1/appStoreVersionLocalizations", {"data": {
                "type": "appStoreVersionLocalizations", "attributes": {"locale": loc, **attrs},
                "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})
        print(f"{loc} : textes posés")


def upload_screenshot(set_id, path):
    data = open(path, "rb").read()
    shot = call("POST", "/v1/appScreenshots", {"data": {
        "type": "appScreenshots",
        "attributes": {"fileName": os.path.basename(path), "fileSize": len(data)},
        "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})["data"]
    for op in shot["attributes"]["uploadOperations"]:
        chunk = data[op["offset"]:op["offset"] + op["length"]]
        cmd = ["curl", "-sSf", "--max-time", "300", "-X", op["method"], "--data-binary", "@-", op["url"]]
        for h in op.get("requestHeaders", []):
            cmd[1:1] = ["-H", f"{h['name']}: {h['value']}"]
        subprocess.run(cmd, input=chunk, capture_output=True, check=True)
    call("PATCH", f"/v1/appScreenshots/{shot['id']}", {"data": {
        "type": "appScreenshots", "id": shot["id"],
        "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})


def step_screenshots(only):
    vid, _ = find_version()
    vlocs = {l["attributes"]["locale"]: l["id"] for l in get_all(f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations?limit=50")}
    for loc in only:
        lid = vlocs[loc]
        sets = {s["attributes"]["screenshotDisplayType"]: s["id"] for s in
                get_all(f"/v1/appStoreVersionLocalizations/{lid}/appScreenshotSets?limit=50")}
        # Anciens formats : supprimés, Apple réduit les frises 6,9" et 13" pour les autres tailles
        for dt, sid in sets.items():
            if dt not in DISPLAY:
                call("DELETE", f"/v1/appScreenshotSets/{sid}")
        for dt, folder in DISPLAY.items():
            files = sorted(f for f in os.listdir(os.path.join(SHOTS, loc, folder)) if f[0].isdigit())
            if dt in sets:
                for shot in get_all(f"/v1/appScreenshotSets/{sets[dt]}/appScreenshots?limit=50"):
                    call("DELETE", f"/v1/appScreenshots/{shot['id']}")
                sid = sets[dt]
            else:
                sid = call("POST", "/v1/appScreenshotSets", {"data": {
                    "type": "appScreenshotSets", "attributes": {"screenshotDisplayType": dt},
                    "relationships": {"appStoreVersionLocalization": {
                        "data": {"type": "appStoreVersionLocalizations", "id": lid}}}}})["data"]["id"]
            for f in files:
                upload_screenshot(sid, os.path.join(SHOTS, loc, folder, f))
            print(f"{loc} : {len(files)} captures {dt}")


def step_build():
    vid, _ = find_version()
    builds = get_all(f"/v1/builds?filter[app]={APP}&filter[version]={BUILD}&filter[preReleaseVersion.version]={VERSION}")
    if not builds:
        sys.exit(f"build {BUILD} pas encore visible sur App Store Connect")
    b = builds[0]
    state = b["attributes"]["processingState"]
    if state != "VALID":
        sys.exit(f"build {BUILD} en cours de traitement ({state})")
    call("PATCH", f"/v1/appStoreVersions/{vid}/relationships/build", {"data": {"type": "builds", "id": b["id"]}})
    print(f"build {BUILD} rattaché ({b['id']})")


def step_submit():
    vid, state = find_version()
    src = call("GET", f"/v1/appStoreVersions/{V63}/appStoreReviewDetail")["data"]["attributes"]
    keep = {k: src[k] for k in ("contactFirstName", "contactLastName", "contactEmail", "contactPhone",
                                "demoAccountRequired")}
    try:
        cur = call("GET", f"/v1/appStoreVersions/{vid}/appStoreReviewDetail")["data"]
    except RuntimeError:
        cur = None
    if cur:
        call("PATCH", f"/v1/appStoreReviewDetails/{cur['id']}", {"data": {
            "type": "appStoreReviewDetails", "id": cur["id"], "attributes": keep}})
    else:
        call("POST", "/v1/appStoreReviewDetails", {"data": {
            "type": "appStoreReviewDetails", "attributes": keep,
            "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})
    sub = call("POST", "/v1/reviewSubmissions", {"data": {
        "type": "reviewSubmissions", "attributes": {"platform": "IOS"},
        "relationships": {"app": {"data": {"type": "apps", "id": APP}}}}})["data"]["id"]
    call("POST", "/v1/reviewSubmissionItems", {"data": {
        "type": "reviewSubmissionItems",
        "relationships": {"reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub}},
                          "appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})
    call("PATCH", f"/v1/reviewSubmissions/{sub}", {"data": {
        "type": "reviewSubmissions", "id": sub, "attributes": {"submitted": True}}})
    print(f"version {VERSION} soumise à la revue (soumission {sub})")


if __name__ == "__main__":
    step = sys.argv[1] if len(sys.argv) > 1 else ""
    only = sys.argv[2].split(",") if len(sys.argv) > 2 else locales()
    {"version": lambda: step_version(), "texts": lambda: step_texts(only),
     "screenshots": lambda: step_screenshots(only), "build": step_build, "submit": step_submit
     }.get(step, lambda: sys.exit(__doc__))()
