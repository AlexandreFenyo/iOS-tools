//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

extern void alex_walk(void);

extern void init_snmp(const char *);
extern int add_mibdir(const char *); // TODO: voir s'il faut mettre des const ci-dessous
extern int alex_debug(char *);
extern int alex_chdir(char *);
extern void alex_list_dir(void);
extern void alex_getcwd(void);
extern void alex_setsnmpconfpath(char *);
extern void alex_setsnmpmibdir(char *);

extern void alex_rollingbuf_init(void);
extern void alex_rollingbuf_close(void);
extern int alex_rollingbuf_poplength(void);
extern int alex_rollingbuf_pop(char *target);
extern int alex_rollingbuf_isempty(void);
extern void alex_set_av(int, char *);
extern void alex_set_av_count(int);
extern void alex_translate(char *);
extern void alex_get_translation(char *);
extern void alex_errbuf_clear(void);
extern void alex_errbuf_get(char *target);

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
long localPingClientIsInsideLoop();
long localPingClientGetRTT();

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

#include <unistd.h>
int localPingClientSetDelay(useconds_t);
int localPingClientLoop(foo_type *, const int, useconds_t);
