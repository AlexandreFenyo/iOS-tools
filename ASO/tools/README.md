# Outillage API App Store Connect

Client minimal pour lire/écrire les métadonnées de la fiche (app id 1662393654).

- `asc_jwt.rb` — signe un JWT ES256 avec la clé `~/.appstoreconnect/AuthKey_8534RFTT7P.p8`
  (rôle App Manager ; révocable dans App Store Connect → Utilisateurs et accès → Intégrations).
- `asc.sh` — enveloppe curl : `ASC_ISSUER_ID=<issuer> ./asc.sh GET|POST|PATCH "/v1/..." [payload.json]`

L'Issuer ID se lit dans App Store Connect → Utilisateurs et accès → Intégrations.
La clé privée ne doit jamais entrer dans le dépôt.

La clé est cherchée dans `~/.appstoreconnect/` puis `~/.appstore/` (ou via `ASC_KEY_PATH`).

Identifiants utiles :
- appStoreVersion 6.3 : ec7c637d-919d-4ae4-a12d-c6fea96fd17b (créée en 6.2 le 16/08/2026,
  renommée 6.3 et soumise le 23/09/2026 avec la fiche de la 6.1)
- appStoreVersion 6.1 : 85bf9c2c-cfad-4f9f-ae35-97ddbb503bdc (en vente)
- appInfo en vente    : cfefcdb7-a2ff-445a-8ed8-240943e1420d
- appInfo éditable    : 2b4c5325-7066-449b-9db4-99341283f2c6

Scripts :
- `prepare-6.3.py` — recopie une fiche (textes, nom/sous-titre, captures) d'une version à
  l'autre ; modèle pour remettre la fiche ASO depuis `../backup-asc-6.2/`.

Soumission par API : `POST /v1/reviewSubmissions` (platform IOS), `POST /v1/reviewSubmissionItems`
(appStoreVersion), puis `PATCH` avec `submitted: true`. Le contact App Review
(`appStoreReviewDetails` : prénom, nom, e-mail, téléphone au format +33…) est obligatoire.
