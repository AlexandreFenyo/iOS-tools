//
//  NetTools.c
//  iOS tools
//
//  Created by Alexandre Fenyo on 15/06/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

#include "NetTools.h"

__uint16_t _htons(__uint16_t x) {
    return htons(x);
}

static int nextValidAddr(struct ifaddrs **paddress) {
    while ((*paddress)->ifa_addr == NULL || ((*paddress)->ifa_addr->sa_family != AF_INET && (*paddress)->ifa_addr->sa_family != AF_INET6)) {
        *paddress = (*paddress)->ifa_next;
        if ((*paddress) == NULL) return -1;
    }
    return 0;
}

static int countBits(void *buf, int count) {
    int nbits = 0;
    for (int i = 0; i < count; i++) {
        unsigned char c = ((unsigned char *) buf)[i];
        while (c) {
            if (c & 1) nbits++;
            c >>= 1;
        }
    }
    return nbits;
}

int getlocaladdr(int ifindex, struct sockaddr *sa, socklen_t salen) {
    struct ifaddrs *addresses, *address;
    int mask_len;

    if (getifaddrs(&addresses) != 0) {
        perror("getifaddrs");
        return -1;
    }
    if (addresses == NULL) return -2;

    address = addresses;
    if (nextValidAddr(&address) == -1) return -3;
    while (--ifindex >= 0) {
        address = address->ifa_next;
        if (address == NULL) return -4;
        if (nextValidAddr(&address) == -1) return -3;
    }

    if (address->ifa_addr->sa_family == AF_INET) {
        struct sockaddr_in *s_in = (struct sockaddr_in *) address->ifa_addr;
        if (salen < sizeof(struct sockaddr_in)) return -5;
        memcpy(sa, s_in, sizeof(struct sockaddr_in));

        struct sockaddr_in *netmask = (struct sockaddr_in *) address->ifa_netmask;
        mask_len = countBits(&netmask->sin_addr, sizeof netmask->sin_addr);
    } else {
        struct sockaddr_in6 *s_in6 = (struct sockaddr_in6 *) address->ifa_addr;
        if (salen < sizeof(struct sockaddr_in6)) return -6;
        memcpy(sa, s_in6, sizeof(struct sockaddr_in6));
        
        struct sockaddr_in6 *netmask = (struct sockaddr_in6 *) address->ifa_netmask;
        mask_len = countBits(&netmask->sin6_addr, sizeof netmask->sin6_addr);
    }
    
    freeifaddrs(addresses);
    return mask_len;
}
// From OSX net/route.h:
struct rt_metrics {
    u_int32_t       rmx_locks;      /* Kernel leaves these values alone */
    u_int32_t       rmx_mtu;        /* MTU for this path */
    u_int32_t       rmx_hopcount;   /* max hops expected */
    int32_t         rmx_expire;     /* lifetime for route, e.g. redirect */
    u_int32_t       rmx_recvpipe;   /* inbound delay-bandwidth product */
    u_int32_t       rmx_sendpipe;   /* outbound delay-bandwidth product */
    u_int32_t       rmx_ssthresh;   /* outbound gateway buffer limit */
    u_int32_t       rmx_rtt;        /* estimated round trip time */
    u_int32_t       rmx_rttvar;     /* estimated rtt variance */
    u_int32_t       rmx_pksent;     /* packets sent using this route */
    u_int32_t       rmx_state;      /* route state */
    u_int32_t       rmx_filler[3];  /* will be used for T/TCP later */
};

// From OSX net/route.h:
struct rt_msghdr {
    u_short rtm_msglen;     /* to skip over non-understood messages */
    u_char  rtm_version;    /* future binary compatibility */
    u_char  rtm_type;       /* message type */
    u_short rtm_index;      /* index for associated ifp */
    int     rtm_flags;      /* flags, incl. kern & message, e.g. DONE */
    int     rtm_addrs;      /* bitmask identifying sockaddrs in msg */
    pid_t   rtm_pid;        /* identify sender */
    int     rtm_seq;        /* for sender to identify action */
    int     rtm_errno;      /* why failed */
    int     rtm_use;        /* from rtentry */
    u_int32_t rtm_inits;    /* which metrics we are initializing */
    struct rt_metrics rtm_rmx; /* metrics themselves */
};

// FAIRE PASSER UN TABLEAU DE STRUCTURES VERS SWIFT
void net_ipv4_gateway() {
    int mib[6];
    mib[0] = CTL_NET;
    mib[1] = PF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_INET;
    mib[4] = NET_RT_FLAGS;
    // see RTF_* in /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/net/route.h
    mib[5] = 2 | 1 | 0x10000000;
    size_t needed = 0;
    int res = sysctl(mib, 6, NULL, &needed, NULL, 0);
    if (res < 0) {
        perror("sysctl");
        return;
    }
    void *msg;
    printf("needed: %d\n", needed);
    msg = malloc(needed);
    if (!msg) {
        perror("malloc");
        return;
    }
    res = sysctl(mib, 6, msg, &needed, NULL, 0);
    if (res < 0) {
        perror("sysctl");
        return;
    }
    void *lim = msg + needed;
    void *next;
    for (next = msg; next < lim; next += ((struct rt_msghdr *) next)->rtm_msglen) {
        if (((struct rt_msghdr *) next)->rtm_addrs != 7) continue;
        
        struct sockaddr_in *sin = next + sizeof(struct rt_msghdr);
        if (sin->sin_addr.s_addr) continue;
        
        printf("MESSAGE type: %d\n", ((struct rt_msghdr *) next)->rtm_type);
        printf("        addrs: %d\n", ((struct rt_msghdr *) next)->rtm_addrs);
        printf("        flags: %d\n", ((struct rt_msghdr *) next)->rtm_flags);
        
        printf("-  family:%d %d\n", sin->sin_family, AF_INET);
        printf("   %s\n", inet_ntoa(sin->sin_addr));
        printf("gw:%s\n", inet_ntoa(sin[1].sin_addr));
    }
}

void net_ipv6_gateway() {
    int mib[6];
    mib[0] = CTL_NET;
    mib[1] = PF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_INET6;
    mib[4] = NET_RT_FLAGS;
    // see RTF_* in /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/net/route.h
    mib[5] = 2 | 1 | 0x10000000;
    size_t needed = 0;
    int res = sysctl(mib, 6, NULL, &needed, NULL, 0);
    if (res < 0) {
        perror("sysctl");
        return;
    }
    void *msg;
    printf("needed: %d\n", needed);
    msg = malloc(needed);
    if (!msg) {
        perror("malloc");
        return;
    }
    res = sysctl(mib, 6, msg, &needed, NULL, 0);
    if (res < 0) {
        perror("sysctl");
        return;
    }
    void *lim = msg + needed;
    void *next;
    for (next = msg; next < lim; next += ((struct rt_msghdr *) next)->rtm_msglen) {
        if (((struct rt_msghdr *) next)->rtm_addrs != 7) continue;
        
        struct sockaddr_in6 *sin = next + sizeof(struct rt_msghdr);
        if (sin->sin6_addr.__u6_addr.__u6_addr32[0] ||
            sin->sin6_addr.__u6_addr.__u6_addr32[1] ||
            sin->sin6_addr.__u6_addr.__u6_addr32[2] ||
            sin->sin6_addr.__u6_addr.__u6_addr32[3]
            ) continue;
        char str[INET6_ADDRSTRLEN];
        inet_ntop(sin->sin6_family, &sin->sin6_addr, str, sizeof str);

        printf("MESSAGE type: %d\n", ((struct rt_msghdr *) next)->rtm_type);
        printf("  dst:%s\n", str);
        printf("        addrs: %d\n", ((struct rt_msghdr *) next)->rtm_addrs);
        printf("        flags: %d\n", ((struct rt_msghdr *) next)->rtm_flags);
        printf("-  family:%d %d\n", sin->sin6_family, AF_INET6);
        inet_ntop(sin->sin6_family, &sin[1].sin6_addr, str, sizeof str);
        printf("-  gw:%s\n", str);
    }
}

void net_test() {
    // récupérer des infos comme la gateway par défaut via sysctl(3)
//    net_ipv4_gateway();
    net_ipv6_gateway();


    

    
    
    char str[INET6_ADDRSTRLEN];
//    char hostname[] = "www.fenyo.net";
    char hostname[] = "google.com";

    // Addresses
    
    struct ifaddrs *addresses = NULL;
    struct ifaddrs *address = NULL;

    int ret = getifaddrs(&addresses);
    if (ret != 0) {
        perror("getifaddrs");
        return;
    }
    address = addresses;

    while (address != NULL) {
        printf("%s: ", address->ifa_name);
        switch (address->ifa_addr->sa_family) {
            case AF_INET:
                printf("AF_INET ");
                struct sockaddr_in *s_in = (struct sockaddr_in *) address->ifa_addr;
                // inet_ntoa : static memory => beware at concurrency, or use inet_ntop
                printf("%s ", inet_ntoa(s_in->sin_addr));

                s_in = (struct sockaddr_in *) address->ifa_netmask;
                // inet_ntoa : static memory => beware at concurrency, or use inet_ntop
                printf("%s ", inet_ntoa(s_in->sin_addr));
                break;
                
            case AF_INET6:
                printf("AF_INET6 ");
                struct sockaddr_in6 *s_in6 = (struct sockaddr_in6 *) address->ifa_addr;
                inet_ntop(s_in6->sin6_family, &s_in6->sin6_addr, str, sizeof str);
                printf("%s ", str);
                
                s_in6 = (struct sockaddr_in6 *) address->ifa_netmask;
                inet_ntop(s_in6->sin6_family, &s_in6->sin6_addr, str, sizeof str);
                printf("%s ", str);

                printf("scope:%d ", s_in6->sin6_scope_id);
                break;
                
            case AF_LINK:
                printf("AF_LINK ");
                break;
                
            default:
                printf("%d ", address->ifa_addr->sa_family);
                break;
        }
        printf("\n");
        address = address->ifa_next;
    }

    freeifaddrs(addresses);

    // direct DNS: hostname to IP
    printf("DNS\n");
    
    struct addrinfo *infos;
    struct addrinfo hints;
    bzero(&hints, sizeof hints);
    
    hints.ai_family = PF_UNSPEC;
//    hints.ai_family = PF_INET6;

    hints.ai_flags = AI_ALL | AI_V4MAPPED;
//    hints.ai_flags = AI_ALL;
    // ATTENTION : peut bloquer plusieurs secondes avant un timeout
    ret = getaddrinfo(hostname, (char *) &hints, NULL, &infos);
//    ret = getaddrinfo(hostname, NULL, NULL, &infos);
    if (ret) {
        printf("getaddrinfo(): %s\n", gai_strerror(ret));
        return;
    }

    while (infos != NULL) {
        struct sockaddr_in *s_in;
        struct sockaddr_in6 *s_in6;

        if (hints.ai_flags & AI_CANONNAME && infos != NULL) printf("canon:%s\n", infos->ai_canonname);

        printf("%s ", hostname);
        
        switch (infos->ai_family) {
            case AF_INET:
                s_in = (struct sockaddr_in *) infos->ai_addr;
                // inet_ntoa : static memory => beware at concurrency, or use inet_ntop
                printf("AF_INET %s %d ", inet_ntoa(s_in->sin_addr), s_in->sin_port);
                break;
                
            case AF_INET6:
                s_in6 = (struct sockaddr_in6 *) infos->ai_addr;
                inet_ntop(s_in6->sin6_family, &s_in6->sin6_addr, str, sizeof str);
                printf("AF_INET6 %s ", str);
                printf("scope:%d ", s_in6->sin6_scope_id);
                break;
                
            default:
                printf("family:%d ", infos->ai_family);
                break;
        }

        printf("\n");
        infos = infos->ai_next;
    }

    freeaddrinfo(infos);
    
    // UDP v6
    printf("UDPv6\n");

    int s6 = socket(AF_INET6, SOCK_DGRAM, 0);
    if (s6 < 0) {
        perror("socket IPv6");
        return;
    }

    struct sockaddr_in6 addr6;
    bzero(&addr6, sizeof addr6);
    addr6.sin6_family = AF_INET6;
    addr6.sin6_len = sizeof addr6.sin6_addr;
    addr6.sin6_flowinfo = 0;
    addr6.sin6_port = htons(8888);
    addr6.sin6_scope_id = 0;

    //    char ip[] ="2a01:e35:8aae:bc63:222:15ff:fe3b:59a";
    char ip[] ="fe80::c2d:7e46:7d8f:6e4c%en0";
    ret = inet_pton(AF_INET6, ip, &addr6.sin6_addr);
    if (ret < 1) {
        if (ret == 0) {
            printf("can not parse IPv6 address\n");
            return;
        } else {
            perror("inet_pton");
            return;
        }
    }
    
    char buf[4096] = { 'A' };
    ssize_t len = sendto(s6, buf, sizeof buf, 0, (struct sockaddr *) &addr6, sizeof addr6);
    if (len < 1) {
        printf("len: %ld\n", len);
        perror("sendto v6");
        return;
    }
    printf("envoyés: %ld\n", len);

    // UDP v4
    int s = socket(AF_INET, SOCK_DGRAM, 0);
    if (s < 0) {
        perror("socket");
        return;
    }

    struct sockaddr_in addr;
    bzero(&addr, sizeof addr);
    addr.sin_family = AF_INET;
    addr.sin_len = sizeof addr.sin_addr;
    addr.sin_port = htons(8888);
    
    char ip2[] = "149.202.53.208";
//    char ip2[] ="10.69.184.195";
    ret = inet_pton(AF_INET, ip2, &addr.sin_addr);
    if (ret < 1) {
        if (ret == 0) {
            printf("can not parse IPv4 address\n");
            return;
        } else {
            perror("inet_pton");
            return;
        }
    }
    
    // reverse DNS: IP to hostname
    char host[512];
    ret = getnameinfo(&addr, sizeof addr, host, sizeof host, 0, 0, NI_NAMEREQD);
    if (ret) {
        printf("getnameinfo(): %s\n", gai_strerror(ret));
        return;
    }
    printf("hostname from DNS: %s\n", host);
    
    
    // Flood with UDP
//    while (1) {
//        len = sendto(s, buf, sizeof buf, 0, (struct sockaddr *) &addr, sizeof addr);
//        if (len < 1) {
//            printf("len: %ld\n", len);
//            perror("sendto v4");
//            return;
//        }
////        printf("envoyés: %ld\n", len);
//    }
}

