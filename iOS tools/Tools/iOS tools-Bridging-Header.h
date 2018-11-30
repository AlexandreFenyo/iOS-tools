//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

int localChargenClientOpen();
int localChargenClientClose();
int localChargenClientStop();
int localChargenClientGetLastErrorNo();
long localChargenClientGetNRead();
int localChargenClientLoop(const struct sockaddr *saddr);

int localDiscardClientOpen();
int localDiscardClientClose();
int localDiscardClientStop();
int localDiscardClientGetLastErrorNo();
long localDiscardClientGetNWrite();
int localDiscardClientLoop(const struct sockaddr *saddr);

int localPingClientOpen();
int localPingClientClose();
int localPingClientStop();
int localPingClientGetLastErrorNo();
long localPingClientGetRTT();
int localPingClientLoop(const struct sockaddr *saddr);

int localFloodClientOpen();
int localFloodClientClose();
int localFloodClientStop();
int localFloodClientGetLastErrorNo();
long localFloodClientGetNWrite();
int localFloodClientLoop(const struct sockaddr *saddr);

int c_test();

void net_test();

// needed to access to struct icmp from Swift
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/ip_icmp.h>
#include <netinet/icmp6.h>

__uint16_t _htons(__uint16_t x);
__uint16_t _ntohs(__uint16_t x);

int getlocaladdr(int ifindex, struct sockaddr *sa, socklen_t salen);
int getlocalgatewayipv4(int ifindex, struct sockaddr *sa, socklen_t salen);
int getlocalgatewayipv6(int ifindex, struct sockaddr *sa, socklen_t salen);
int multicasticmp6();
