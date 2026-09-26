# libnetsnmp.a — tranche simulateur

Bibliothèque net-snmp 5.9.4 **patchée** pour le simulateur iOS (arm64), sélectionnée par le
réglage `LIBRARY_SEARCH_PATHS[sdk=iphonesimulator*]` du projet. Les builds appareil
continuent d'utiliser `../libnetsnmp.a` (arm64/arm64e iphoneos), qui reste la référence.

## Provenance

Les trois tranches (`../libnetsnmp.a` appareil arm64/arm64e, `libnetsnmp.a` ici simulateur
arm64, `../maccatalyst/libnetsnmp.a` Catalyst arm64+x86_64) sont construites depuis les sources
patchées de <https://github.com/AlexandreFenyo/net-snmp>, qui contiennent
`snmplib/alex_walk.c`, `snmplib/alex_translate.c` et les ajouts `alex_setsnmpmibdir` /
`alex_setsnmpconfpath` dans `mib.c` / `read_config.c`. Dernière reconstruction : 27 sept. 2026, commit `cab2cb6`
(anneau à index atomiques, arrêt de walk `alex_walk_stop`, fuite mémoire de
`alex_rollingbuf_pop` corrigée), iOS 16.6 minimum.

Attention : `mib.c` contient des octets ISO-8859 — `grep` le traite comme binaire et ne
montre les patchs qu'avec l'option `-a`.

## Reconstruire

Script du dépôt net-snmp (il documente aussi les pièges : configure interactif, objets
compilés présents dans le dépôt, pcap indisponible sous Catalyst, assembleur x86) :

```sh
~/git3/net-snmp/build-ios-tools.sh <répertoire-de-travail> "<dépôt iOS-tools>/iOS tools/libnetsnmp"
```

Les en-têtes C exposés à Swift sont déclarés dans `iOS tools/Tools/iOS tools-Bridging-Header.h`.

## Test de bout en bout

Agent SNMP de test : `flood.eowyn.eu.org`, communauté `public`, v2c.
