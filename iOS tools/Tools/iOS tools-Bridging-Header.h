//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

int localChargenClientOpen();
int localChargenClientClose();
int localChargenClientStop();
int localChargenClientGetLastErrorNo();
long localChargenClientGetNRead();

// Trick to avoid this warning at localChargenClientLoop(), localDiscardClientLoop(), localPingClientLoop() and localFloodClientLoop() function definitions: "declaration of 'struct sockaddr' will not be visible outside of this function"
typedef struct foo_struct foo_type;

// int localChargenClientLoop(const struct sockaddr *saddr);
int localChargenClientLoop(foo_type *);

int localDiscardClientOpen();
int localDiscardClientClose();
int localDiscardClientStop();
int localDiscardClientGetLastErrorNo();
long localDiscardClientGetNWrite();
//int localDiscardClientLoop(const struct sockaddr *saddr);
int localDiscardClientLoop(foo_type *);

int localPingClientOpen();
int localPingClientClose();
int localPingClientStop();
int localPingClientGetLastErrorNo();
long localPingClientGetRTT();
// int localPingClientLoop(const struct sockaddr *saddr, const int);
int localPingClientLoop(foo_type *, const int);

int localFloodClientOpen();
int localFloodClientClose();
int localFloodClientStop();
int localFloodClientGetLastErrorNo();
long localFloodClientGetNWrite();
// int localFloodClientLoop(const struct sockaddr *saddr);
int localFloodClientLoop(foo_type *);

int c_test();

void net_test();

#include <sys/select.h>
fd_set getfds(int fd);

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
