#!/bin/zsh
# Client minimal pour l'API App Store Connect.
#   ./asc.sh GET  "/v1/apps?filter[bundleId]=..."
#   ./asc.sh PATCH "/v1/appStoreVersionLocalizations/ID" payload.json
# La clé privée n'est jamais affichée ni transmise ailleurs qu'à la signature locale.

set -euo pipefail

HERE="${0:A:h}"
KEY="$HOME/.appstoreconnect/AuthKey_8534RFTT7P.p8"
KEY_ID="8534RFTT7P"
ISSUER_ID="${ASC_ISSUER_ID:?ASC_ISSUER_ID non defini}"

METHOD="${1:?methode manquante}"
ENDPOINT="${2:?endpoint manquant}"
BODY="${3:-}"

JWT="$(ruby "$HERE/asc_jwt.rb" "$KEY" "$KEY_ID" "$ISSUER_ID")"

args=(-sS -X "$METHOD" -H "Authorization: Bearer $JWT" -w '\n__HTTP_%{http_code}__')
if [[ -n "$BODY" ]]; then
  args+=(-H 'Content-Type: application/json' --data-binary "@$BODY")
fi

curl "${args[@]}" "https://api.appstoreconnect.apple.com${ENDPOINT}"
