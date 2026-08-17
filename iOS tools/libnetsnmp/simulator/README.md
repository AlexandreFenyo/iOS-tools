# libnetsnmp.a — tranche simulateur

Bibliothèque net-snmp 5.9.4 **patchée** pour le simulateur iOS (arm64), sélectionnée par le
réglage `LIBRARY_SEARCH_PATHS[sdk=iphonesimulator*]` du projet. Les builds appareil
continuent d'utiliser `../libnetsnmp.a` (arm64/arm64e iphoneos), qui reste la référence.

## Provenance

Construite intégralement depuis les sources patchées de
<https://github.com/AlexandreFenyo/net-snmp> (commit `0281b6f`), qui contiennent
`snmplib/alex_walk.c`, `snmplib/alex_translate.c` et les ajouts `alex_setsnmpmibdir` /
`alex_setsnmpconfpath` dans `mib.c` / `read_config.c`.

Attention : `mib.c` contient des octets ISO-8859 — `grep` le traite comme binaire et ne
montre les patchs qu'avec l'option `-a`.

## Reconstruire

Répliquer `build-nodebugging.sh` du dépôt net-snmp avec la section simulateur :

```sh
cp -a ~/git/net-snmp/net-snmp-5.9.4 ~/git/net-snmp/mycpp <répertoire-de-travail>/
cd <répertoire-de-travail>/net-snmp-5.9.4
SDK=iphonesimulator
export CC=$(xcrun --find --sdk $SDK clang) CXX=$(xcrun --find --sdk $SDK clang++)
export CPP=../mycpp
export CFLAGS="-arch arm64 -mios-simulator-version-min=16.6 -isysroot $(xcrun --sdk $SDK --show-sdk-path) -O3 -g3"
export CXXFLAGS="$CFLAGS" LDFLAGS="-arch arm64 -mios-simulator-version-min=16.6 -isysroot $(xcrun --sdk $SDK --show-sdk-path)"
./configure --host=arm-apple-darwin --prefix=$PWD/../_build \
    --exec-prefix=$PWD/../_build/platforms/arm64-sim \
    --enable-static --disable-agent --enable-reentrant --disable-shared
make -j8 && make install    # l'échec final sur les pages man (maninstall) est sans importance
cp ../_build/platforms/arm64-sim/lib/libnetsnmp.a <ce dossier>/
```

## Test de bout en bout

Agent SNMP de test : `flood.eowyn.eu.org`, communauté `public`, v2c.
