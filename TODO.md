# Améliorations à prévoir

## SNMP — `alex_setsnmpconfpath` sans effet

- `SNMPManager.pushArray` appelle `alex_setsnmpconfpath(pointer)` pour chaque argument
  (reste de copier-coller probable) : le chemin est écrasé par "snmpwalk", "-r3", … puis
  par la chaîne de l'agent.
- C'est sans conséquence, car dans le fork `alex_setsnmpconfpath` (`read_config.c:1383`)
  remplit une variable `static char snmpconfpath[4096]` qui n'est lue nulle part : même
  l'appel de `initLibSNMP` (qui y met `$HOME/Documents/snmp`) ne sert à rien.
- Fait (27 sept. 2026) : l'appel de `pushArray` est retiré.
- Reste à faire : soit brancher réellement `snmpconfpath`
  dans `read_config_files_of_type`, soit supprimer la fonction. Vérifier au passage si le
  fichier `Documents/snmp/snmp.conf` écrit par `initLibSNMP` (directive `mibdirs`) est lu
  par un autre chemin ; les MIB, elles, viennent de `alex_setsnmpmibdir` (`mib.c:2626`),
  qui fonctionne.

## SNMP — bouton d'arrêt d'un walk

`SNMPManager.stopWalk()` (appel C `alex_walk_stop()`) arrête un walk en cours : sortie par le
chemin normal de `alex_main` (session fermée, walk suivant sain), résultats partiels transmis
à `onEnd` avec le message « Walk interrupted ». Délai : entre deux requêtes, donc au plus ~4 s
en UDP (`-r3 -t1`) si l'agent ne répond plus, et pas avant la fin d'un `connect()` TCP (~75 s).
Reste à ajouter le déclencheur dans l'interface (onglet SNMP), en arrêtant aussi la boucle du
scan des interfaces (`interface_loop`). Pour un arrêt immédiat, il faudrait remplacer
`snmp_synch_response` par un envoi asynchrone et une boucle d'attente vérifiant l'indicateur.

## SNMP — tranche Catalyst x86_64 non testée à l'exécution

Compilée avec `-DOPENSSL_NO_INLINE_ASM` (MD5/SHA en C portable). Rosetta n'est pas installé
sur le Mac de développement : à tester sur un Mac Intel ou sous Rosetta (walk v2c et v3
authPriv), avant la prochaine publication Mac.

## SNMP — agent de test flood.eowyn.eu.org

- La dernière requête d'un walk (celle qui dépasse la fin de la vue) n'obtient pas de réponse
  depuis Internet : walk terminé par « Timeout: No Response » après ~5,4 s, y compris avec le
  `snmpwalk` standard du Mac et avec l'ancienne racine mib-2 (en local sur le serveur, la
  réponse « end of MIB view » est immédiate). À étudier côté serveur.
- L'utilisateur SNMPv3 `authPrivUser` déclaré dans `snmpd.conf` n'existe pas (« Unknown user
  name ») : le créer (`net-snmp-create-v3-user`) pour pouvoir tester v3 et le chiffrement.

