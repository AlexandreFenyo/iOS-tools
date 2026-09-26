# Améliorations à prévoir

## SNMP — anneau de résultats de `alex_walk` sans synchronisation

Fork net-snmp (github.com/AlexandreFenyo/net-snmp), `net-snmp-5.9.4/snmplib/alex_walk.c` :
l'anneau `alex_rollingbuf` (1024 entrées) qui transmet les résultats du walk (thread C
producteur, `alex_walk`) au thread Swift consommateur (`SNMPManager.walk`) n'a ni verrou
ni barrière mémoire. Les index `alex_rollingbuf_write_idx` / `alex_rollingbuf_read_idx`
sont des `int` simples, partagés entre les deux threads.

Risque : sur ARM64 (modèle mémoire faible), le consommateur pourrait en théorie voir
`write_idx` incrémenté avant que l'écriture du pointeur `malloc` de l'entrée soit visible.
C'est rare, mais possible.

Correction proposée : déclarer les deux index `_Atomic int` et utiliser un ordre
release/acquire — le producteur publie `write_idx` en release après avoir écrit l'entrée,
le consommateur le lit en acquire avant de lire l'entrée (symétriquement pour `read_idx`,
publié par le consommateur après le `free`/la copie). Les fonctions concernées :
`alex_rollingbuf_push`, `_pop`, `_poplength`, `_isempty`, `_isfull`, `_incr_*_idx`, `_init`.
Côté Swift, `SNMPManager.getState()` lit aussi `alex_rollingbuf_isempty()` depuis un autre
thread : il bénéficierait de la même lecture acquire.

Après modification : recompiler les trois tranches de `libnetsnmp.a` (appareil, simulateur,
Mac Catalyst), cf. `iOS tools/libnetsnmp/simulator/README.md`.

## SNMP — `numprinted` jamais remis à zéro (code mort, sans effet aujourd'hui)

`alex_walk.c` : le global `numprinted` n'est initialisé qu'à sa déclaration (l. 160) et
jamais remis à zéro dans `alex_main`. Après le premier walk qui renvoie quelque chose, le
repli en GET de fin de walk (l. 531-538 : « walk vide sur une instance feuille comme
`sysDescr.0` → tenter un GET ») n'est donc plus jamais tenté.

Aucun effet visible aujourd'hui : l'app ne fait de walk que sur des sous-arbres (mib-2,
system, ifTable, `.1.3.6.1.2.1.1.1`), jamais sur une instance feuille, et l'utilisateur ne
peut pas saisir d'OID. De plus, `snmp_get_and_print` écrit sur stdout (`print_variable`)
et non dans l'anneau : son résultat n'arriverait de toute façon pas à l'app.

À corriger si un jour l'app parcourt un OID choisi par l'utilisateur : remettre
`numprinted = 0` au début de `alex_main`, et faire passer le résultat de
`snmp_get_and_print` par `alex_rollingbuf_push` (comme la boucle principale).

## SNMP — `alex_setsnmpconfpath` sans effet

- `SNMPManager.pushArray` appelle `alex_setsnmpconfpath(pointer)` pour chaque argument
  (reste de copier-coller probable) : le chemin est écrasé par "snmpwalk", "-r3", … puis
  par la chaîne de l'agent.
- C'est sans conséquence, car dans le fork `alex_setsnmpconfpath` (`read_config.c:1383`)
  remplit une variable `static char snmpconfpath[4096]` qui n'est lue nulle part : même
  l'appel de `initLibSNMP` (qui y met `$HOME/Documents/snmp`) ne sert à rien.
- À faire : retirer l'appel de `pushArray`, et soit brancher réellement `snmpconfpath`
  dans `read_config_files_of_type`, soit supprimer la fonction. Vérifier au passage si le
  fichier `Documents/snmp/snmp.conf` écrit par `initLibSNMP` (directive `mibdirs`) est lu
  par un autre chemin ; les MIB, elles, viennent de `alex_setsnmpmibdir` (`mib.c:2626`),
  qui fonctionne.

## SNMP — le « full scan » ne parcourt que mib-2

Sans OID en argument, `alex_main` part de `objid_mib = {1,3,6,1,2,1}` (l. 159, 340) :
le full scan couvre mib-2 mais jamais la branche enterprises (`1.3.6.1.4.1`), ni les MIB
privées des équipements (ex. LanManager `1.3.6.1.4.1.77` sur un agent Windows). Pour tout
parcourir, passer `.1` comme racine dans le bouton full scan (`SNMPView.swift`, ~l. 617) ;
prévoir que le parcours sera nettement plus long sur certains agents.
