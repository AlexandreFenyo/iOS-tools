#!/usr/bin/env python3
"""Prépare la version 6.3 sur App Store Connect avec le contenu de la 6.1.

La 6.3 est l'ancienne fiche 6.2 renommée (déjà fait : numéro 6.3, publication
AFTER_APPROVAL). Ce script, idempotent, termine l'opération :

  1. supprime les langues ajoutées par la 6.2 (en-GB, nl-NL, it ; de-DE est déjà supprimée) ;
  2. remet pour en-US, fr-FR, es-ES les textes de la 6.1 (description, mots-clés, texte
     promotionnel, URL) et pose le « What's New » de la 6.3 ;
  3. remet le nom et le sous-titre de la fiche en vente (l'URL de confidentialité corrigée
     de la 6.2 est conservée : l'ancienne, wifimapexplorer.com, ne répond plus) ;
  4. remplace les captures de la 6.2 par celles de la 6.1, format par format.

L'état d'avant opération est dans ASO/backup-asc-6.2/.

Usage : ASC_ISSUER_ID=<issuer> python3 ASO/tools/prepare-6.3.py
"""
import hashlib
import json
import os
import subprocess
import sys
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
BACKUP = os.path.join(HERE, "..", "backup-asc-6.2")
V63 = "ec7c637d-919d-4ae4-a12d-c6fea96fd17b"
LIVE_INFO = "cfefcdb7-a2ff-445a-8ed8-240943e1420d"
EDIT_INFO = "2b4c5325-7066-449b-9db4-99341283f2c6"
LOCALES = ("en-US", "fr-FR", "es-ES")
EXTRA_LOCALES = ("de-DE", "en-GB", "nl-NL", "it")
WHATS_NEW = {
    "en-US": "This version fixes a bug that prevented the app from launching on the latest version of iOS.",
    "fr-FR": "Cette version corrige un bug qui empêchait l'app de se lancer sur la dernière version d'iOS.",
    "es-ES": "Esta versión corrige un error que impedía que la app se abriera en la última versión de iOS.",
}


def call(method, path, body=None):
    args = [os.path.join(HERE, "asc.sh"), method, path]
    tmp = None
    if body is not None:
        tmp = os.path.join(HERE, ".body.json")
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


def delete_if_exists(path):
    try:
        call("DELETE", path)
        return "supprimé"
    except RuntimeError as e:
        if "-> 404" in str(e):
            return "déjà absent"
        raise


def download(template_url, w, h):
    url = template_url.replace("{w}", str(w)).replace("{h}", str(h)).replace("{f}", "png")
    with urllib.request.urlopen(url, timeout=60) as r:
        return r.read()


def upload_screenshot(set_id, file_name, data):
    res = call("POST", "/v1/appScreenshots", {"data": {
        "type": "appScreenshots",
        "attributes": {"fileName": file_name, "fileSize": len(data)},
        "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})
    shot = res["data"]
    for op in shot["attributes"]["uploadOperations"]:
        chunk = data[op["offset"]:op["offset"] + op["length"]]
        req = urllib.request.Request(op["url"], data=chunk, method=op["method"])
        for h in op.get("requestHeaders", []):
            req.add_header(h["name"], h["value"])
        urllib.request.urlopen(req, timeout=120).read()
    call("PATCH", f"/v1/appScreenshots/{shot['id']}", {"data": {
        "type": "appScreenshots", "id": shot["id"],
        "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})


def main():
    snap = json.load(open(os.path.join(BACKUP, "versions-6.1-6.2.json")))
    infos = json.load(open(os.path.join(BACKUP, "appinfos.json")))

    v = call("GET", f"/v1/appStoreVersions/{V63}")["data"]["attributes"]
    if v["versionString"] != "6.3" or v["appStoreState"] != "PREPARE_FOR_SUBMISSION":
        sys.exit(f"Version inattendue : {v['versionString']} {v['appStoreState']}")

    # 1. Langues de la 6.2 absentes de la 6.1
    for loc in EXTRA_LOCALES:
        a = delete_if_exists(f"/v1/appStoreVersionLocalizations/{snap['6.2'][loc]['id']}")
        b = delete_if_exists(f"/v1/appInfoLocalizations/{infos[EDIT_INFO]['locs'][loc]['id']}")
        print(f"{loc}: version {a}, fiche {b}")

    current = {l["attributes"]["locale"]: l["id"] for l in
               call("GET", f"/v1/appStoreVersions/{V63}/appStoreVersionLocalizations?limit=50")["data"]}

    for loc in LOCALES:
        lid = current[loc]
        # 2. Textes de la 6.1 + What's New
        src = snap["6.1"][loc]["attrs"]
        attrs = {k: src.get(k) for k in ("description", "keywords", "promotionalText", "supportUrl", "marketingUrl")}
        attrs["whatsNew"] = WHATS_NEW[loc]
        call("PATCH", f"/v1/appStoreVersionLocalizations/{lid}",
             {"data": {"type": "appStoreVersionLocalizations", "id": lid, "attributes": attrs}})
        # 3. Nom et sous-titre en vente
        live = infos[LIVE_INFO]["locs"][loc]
        eid = infos[EDIT_INFO]["locs"][loc]["id"]
        call("PATCH", f"/v1/appInfoLocalizations/{eid}", {"data": {
            "type": "appInfoLocalizations", "id": eid,
            "attributes": {"name": live["name"], "subtitle": live["subtitle"]}}})
        print(f"{loc}: textes, nom et sous-titre de la 6.1 appliqués")

        # 4. Captures : on vide tous les jeux existants puis on recopie ceux de la 6.1
        sets = {s["attributes"]["screenshotDisplayType"]: s["id"] for s in
                call("GET", f"/v1/appStoreVersionLocalizations/{lid}/appScreenshotSets?limit=50")["data"]}
        for set_id in sets.values():
            for shot in call("GET", f"/v1/appScreenshotSets/{set_id}/appScreenshots?limit=50")["data"]:
                call("DELETE", f"/v1/appScreenshots/{shot['id']}")
        for display_type, shots in snap["6.1"][loc]["screenshots"].items():
            if display_type not in sets:
                sets[display_type] = call("POST", "/v1/appScreenshotSets", {"data": {
                    "type": "appScreenshotSets",
                    "attributes": {"screenshotDisplayType": display_type},
                    "relationships": {"appStoreVersionLocalization": {
                        "data": {"type": "appStoreVersionLocalizations", "id": lid}}}}})["data"]["id"]
            for i, s in enumerate(shots, 1):
                data = download(s["url"], s["w"], s["h"])
                upload_screenshot(sets[display_type], s.get("fileName") or f"{loc}-{display_type}-{i}.png", data)
            print(f"{loc}: {len(shots)} captures {display_type} recopiées")

    print("Terminé : fiche 6.3 alignée sur la 6.1.")


if __name__ == "__main__":
    main()
