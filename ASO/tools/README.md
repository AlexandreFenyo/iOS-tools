# Outillage API App Store Connect

Client minimal pour lire/écrire les métadonnées de la fiche (app id 1662393654).

- `asc_jwt.rb` — signe un JWT ES256 avec la clé `~/.appstoreconnect/AuthKey_8534RFTT7P.p8`
  (rôle App Manager ; révocable dans App Store Connect → Utilisateurs et accès → Intégrations).
- `asc.sh` — enveloppe curl : `ASC_ISSUER_ID=<issuer> ./asc.sh GET|POST|PATCH "/v1/..." [payload.json]`

L'Issuer ID se lit dans App Store Connect → Utilisateurs et accès → Intégrations.
La clé privée ne doit jamais entrer dans le dépôt.

Identifiants utiles (version 6.2 créée le 16/08/2026) :
- appStoreVersion 6.2 : ec7c637d-919d-4ae4-a12d-c6fea96fd17b
- appInfo éditable   : 2b4c5325-7066-449b-9db4-99341283f2c6
