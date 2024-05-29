# GUI

une console escamotable en bas de l'écran de droite
un bouton en haut à gauche pour faire apparaître une fenêtre modale qui permet de faire différentes choses en pas à pas (cf Working Copy)

# Mapping table for network interface names

# Data model

- Node name: mDNS host name or DNS name or unnamed
- "mac-de-alexandre-2.local" (from: mDNS)
  - list of mDNS TCP service names
  - list of mDNS UDP service names
  - list of IPv4
  - IPv4: "10.69.184.197" (from: mDNS)
    - list of TCP services (port + name from port + name from mDNS)
    - list of UDP services (port + name from port + name from mDNS)
  - list of IPv6
  - IPv6: "fe80::4fa:96b3:7066:bbbf", interface "en0"/WiFi, MAC address
  - list of TCP services (port + name from port + name from mDNS)
  - list of UDP services (port + name from port + name from mDNS)

Mac-de-Alexandre% dig @224.0.0.251 -4 -p 5353 F.B.B.B.6.6.0.7.3.B.6.9.A.F.4.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.E.F.ip6.arpa. ptr
F.B.B.B.6.6.0.7.3.B.6.9.A.F.4.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.E.F.ip6.arpa. 10 IN    PTR Mac-de-Alexandre-2.local.

sh-3.2# dig @224.0.0.251 -4 -p 5353 195.184.69.10.in-addr.arpa. ptr +short
Mac-de-Alexandre.local.

mDNS : taille max des infos, protocole, etc. : http://grouper.ieee.org/groups/1722/contributions/2009/Bonjour%20Device%20Discovery.pdf

utiliser requêtes PTR en mDNS pour les reverse IPv4 et IPv6 !

iOS device running the app:
- interface
  - interface name
  - interface type (derived from name)
  - interface address
  - interface netmask

cf. UIDevice.current
cf. NetTools.c :
- getifaddrs: local interfaces
- getaddrinfo: hostname to IP via DNS
- getnameinfo: IP to hostname via DNS

faire requête DNS inverse et directe : OK
idem pour mDNS : 
requête mDNS pour tous les services ?

mDNS : wireshark sur le wifi et lancer une des apps de recherche d'hôtes sur le lan

net_test():
lo0: AF_LINK 
lo0: AF_INET 127.0.0.1 255.0.0.0 
lo0: AF_INET6 ::1 ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff scope:0 
lo0: AF_INET6 fe80::1 ffff:ffff:ffff:ffff:: scope:0 
gif0: AF_LINK 
stf0: AF_LINK 
XHC0: AF_LINK 
en0: AF_LINK 
en0: AF_INET6 fe80::146d:6335:18ad:a939 ffff:ffff:ffff:ffff:: scope:0 
en0: AF_INET 10.69.184.195 255.255.255.192 
utun0: AF_LINK 
utun0: AF_INET6 fe80::97e6:f41a:32d5:5de8 ffff:ffff:ffff:ffff:: scope:0 
www.fenyo.net AF_INET 88.170.235.198 0 
www.fenyo.net AF_INET 88.170.235.198 0 

requête d'un iOS en IPv4 et IPv6 :
66  11.364183 10.69.184.195 → 224.0.0.251  MDNS 340 Standard query 0x0000 PTR _sleep-proxy._udp.local, "QM" question PTR _airport._tcp.local, "QM" question PTR _airplay._tcp.local, "QM" question PTR _raop._tcp.local, "QM" question PTR _uscans._tcp.local, "QM" question PTR _uscan._tcp.local, "QM" question PTR _ippusb._tcp.local, "QM" question PTR _ipp._tcp.local, "QM" question PTR _scanner._tcp.local, "QM" question PTR _ipps._tcp.local, "QM" question PTR _printer._tcp.local, "QM" question PTR _pdl-datastream._tcp.local, "QM" question PTR _ptp._tcp.local, "QM" question PTR _apple-mobdev2._tcp.local, "QM" question PTR _apple-mobdev._tcp.local, "QM" question PTR 8d1a07c0._sub._apple-mobdev2._tcp.local, "QM" question PTR _apple-pairable._tcp.local, "QM" question
67  11.364225 fe80::146d:6335:18ad:a939 → ff02::fb     MDNS 360 Standard query 0x0000 PTR _sleep-proxy._udp.local, "QM" question PTR _airport._tcp.local, "QM" question PTR _airplay._tcp.local, "QM" question PTR _raop._tcp.local, "QM" question PTR _uscans._tcp.local, "QM" question PTR _uscan._tcp.local, "QM" question PTR _ippusb._tcp.local, "QM" question PTR _ipp._tcp.local, "QM" question PTR _scanner._tcp.local, "QM" question PTR _ipps._tcp.local, "QM" question PTR _printer._tcp.local, "QM" question PTR _pdl-datastream._tcp.local, "QM" question PTR _ptp._tcp.local, "QM" question PTR _apple-mobdev2._tcp.local, "QM" question PTR _apple-mobdev._tcp.local, "QM" question PTR 8d1a07c0._sub._apple-mobdev2._tcp.local, "QM" question PTR _apple-pairable._tcp.local, "QM" question

# 3D GUI
