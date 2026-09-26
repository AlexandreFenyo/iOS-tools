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
