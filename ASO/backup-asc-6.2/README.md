# Sauvegarde App Store Connect avant la 6.3 (23/09/2026)

Le 23/09/2026, la version 6.2 (jamais soumise) a été renommée en 6.3 et son contenu
remplacé par celui de la 6.1 (textes, captures, nom, sous-titre, 3 langues), à la demande
du propriétaire : la 6.3 est un correctif du lancement sous iOS 27 et ne reprend pas le
travail ASO de la 6.2.

Ce dossier conserve l'état ASC d'avant l'opération, pour pouvoir reprendre ce travail :

- `versions-6.1-6.2.json` — localisations des versions 6.1 et 6.2 (textes complets) et
  liste des captures par langue et par format (les URL d'images peuvent expirer ; les
  captures de la 6.2 se régénèrent avec `scripts/screenshots.sh`).
- `appinfos.json` — nom, sous-titre, URL de confidentialité : fiche en vente et fiche
  éditable de la 6.2 (7 langues, nom « WiFi Heat Map & Analyzer »).

Les textes maîtres de la 6.2 restent aussi dans `ASO/metadata/<locale>/`.
