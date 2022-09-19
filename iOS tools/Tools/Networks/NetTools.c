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

__uint16_t _ntohs(__uint16_t x) {
    return ntohs(x);
}

// From OSX net/route.h:
// /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/net/route.h
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
    if (nextValidAddr(&address) == -1) {
        freeifaddrs(addresses);
        return -3;
    }
    while (--ifindex >= 0) {
        address = address->ifa_next;
        if (address == NULL) {
            freeifaddrs(addresses);
            return -4;
        }
        if (nextValidAddr(&address) == -1) {
            freeifaddrs(addresses);
            return -3;
        }
    }

    if (address->ifa_addr->sa_family == AF_INET) {
        struct sockaddr_in *s_in = (struct sockaddr_in *) address->ifa_addr;
        if (salen < sizeof(struct sockaddr_in)) {
            freeifaddrs(addresses);
            return -5;
        }
        memcpy(sa, s_in, sizeof(struct sockaddr_in));

        struct sockaddr_in *netmask = (struct sockaddr_in *) address->ifa_netmask;
        mask_len = countBits(&netmask->sin_addr, sizeof netmask->sin_addr);
    } else {
        struct sockaddr_in6 *s_in6 = (struct sockaddr_in6 *) address->ifa_addr;
        if (salen < sizeof(struct sockaddr_in6)) {
            freeifaddrs(addresses);
            return -6;
        }
        memcpy(sa, s_in6, sizeof(struct sockaddr_in6));
        
        struct sockaddr_in6 *netmask = (struct sockaddr_in6 *) address->ifa_netmask;
        mask_len = countBits(&netmask->sin6_addr, sizeof netmask->sin6_addr);
    }
    
    freeifaddrs(addresses);
    return mask_len;
}

int getlocalgatewayipv4(int gwindex, struct sockaddr *sa, socklen_t salen) {
    int mib[6] = { CTL_NET, PF_ROUTE, 0, AF_INET, NET_RT_FLAGS, 2 | 1 | 0x10000000 };

    size_t needed = 0;
    if (sysctl(mib, 6, NULL, &needed, NULL, 0) < 0) {
        perror("sysctl");
        return -1;
    }

    void *msg;
    if (!(msg = malloc(needed))) {
        perror("malloc");
        return -2;
    }

    if (sysctl(mib, 6, msg, &needed, NULL, 0) < 0) {
        perror("sysctl");
        free(msg);
        return -3;
    }

    for (void *next = msg; next < msg + needed; next += ((struct rt_msghdr *) next)->rtm_msglen) {
        // Is it a route with a gateway?
        // initialement ça marchait avec la valeur 2, maintenant on a la valeur 39, mais si on ne teste pas, on a bien les routes qu'on attend
        // if (((struct rt_msghdr *) next)->rtm_addrs != 2) continue;

        struct sockaddr_in *sin = next + sizeof(struct rt_msghdr);
        // Is it a default route?
        if (sin->sin_addr.s_addr) continue;
        
        if (gwindex-- == 0) {
            memcpy(sa, sin + 1, sizeof(struct sockaddr_in));
            free(msg);
            return 0;
        }
    }

    free(msg);
    return -4;
}

int getlocalgatewayipv6(int gwindex, struct sockaddr *sa, socklen_t salen) {
    int mib[6] = { CTL_NET, PF_ROUTE, 0, AF_INET6, NET_RT_FLAGS, 2 | 1 | 0x10000000 };
    
    size_t needed = 0;
    if (sysctl(mib, 6, NULL, &needed, NULL, 0) < 0) {
        perror("sysctl");
        return -1;
    }
    
    void *msg;
    if (!(msg = malloc(needed))) {
        perror("malloc");
        return -2;
    }
    
    if (sysctl(mib, 6, msg, &needed, NULL, 0) < 0) {
        perror("sysctl");
        free(msg);
        return -3;
    }
    
    for (void *next = msg; next < msg + needed; next += ((struct rt_msghdr *) next)->rtm_msglen) {
        // Is it a route with a gateway?
        // initialement ça marchait avec la valeur 7, maintenance c'est 39, mais si on ne teste pas, on a bien les routes qu'on attend
        // if (((struct rt_msghdr *) next)->rtm_addrs != /*7*/ 39) continue;
      
        // Is it a default route?
        struct sockaddr_in6 *sin = next + sizeof(struct rt_msghdr);
        
        if (sin->sin6_addr.__u6_addr.__u6_addr32[0] ||
            sin->sin6_addr.__u6_addr.__u6_addr32[1] ||
            sin->sin6_addr.__u6_addr.__u6_addr32[2] ||
            sin->sin6_addr.__u6_addr.__u6_addr32[3]
            ) continue;

        if ((((sin+1)->sin6_addr.__u6_addr.__u6_addr32[0] & 0x0000c0ff) == 0x80fe ||
            ((sin+1)->sin6_addr.__u6_addr.__u6_addr32[0] & 0x0000c0ff) == 0x81fe) &&
            (sin+1)->sin6_addr.__u6_addr.__u6_addr32[1] == 0 &&
            (sin+1)->sin6_addr.__u6_addr.__u6_addr32[2] == 0 &&
            (sin+1)->sin6_addr.__u6_addr.__u6_addr32[3] == 0) continue;

        if (gwindex-- == 0) {
//            printf("addr: %x %x %x %x\n", sin->sin6_addr.__u6_addr.__u6_addr32[0],
//                  sin->sin6_addr.__u6_addr.__u6_addr32[1],
//                  sin->sin6_addr.__u6_addr.__u6_addr32[2],
//                  sin->sin6_addr.__u6_addr.__u6_addr32[3]);
            memcpy(sa, sin + 1, sizeof(struct sockaddr_in6));
            free(msg);
            return 0;
        }
    }
    
    free(msg);
    return -4;
}

//struct tv32 {
//    u_int32_t tv32_sec;
//    u_int32_t tv32_usec;
//};
#define MAXPACKETLEN    131072
#define ICMP6ECHOLEN    8       /* icmp echo header len excluding time */

int multicasticmp6() {
    printf("\n\n1--- START multicast icmp6\n");

    struct addrinfo hints, *res;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET6;
    hints.ai_socktype = SOCK_DGRAM;
    hints.ai_protocol = IPPROTO_UDP;
    int ret = getaddrinfo("ff02::1%en0", NULL, &hints, &res);
    if (ret) {
        perror("getaddrinfo");
        return -1;
    }
    struct sockaddr_in6 dst;
    memcpy(&dst, res->ai_addr, res->ai_addrlen);

    int s = socket(PF_INET6, SOCK_DGRAM,  IPPROTO_ICMPV6);
    if (s < 0) {
        perror("socket");
        return -1;
    }

    struct msghdr smsghdr;
    memset(&smsghdr, 0, sizeof(smsghdr));
    u_char outpack[MAXPACKETLEN];
    struct icmp6_hdr *icp;
    struct iovec iov[1];
    icp = (struct icmp6_hdr *)outpack;
    memset(icp, 0, sizeof(struct icmp6_hdr));
    icp->icmp6_type = ICMP6_ECHO_REQUEST;
    icp->icmp6_id = 55;
    icp->icmp6_seq = ntohs(0);
    smsghdr.msg_name = (caddr_t)&dst;
    smsghdr.msg_namelen = sizeof(dst);
    memset(&iov, 0, sizeof(iov));
    iov[0].iov_base = (caddr_t)icp;
    iov[0].iov_len = ICMP6ECHOLEN;
    smsghdr.msg_iov = iov;
    smsghdr.msg_iovlen = 1;

    long i = sendmsg(s, &smsghdr, 0);
    printf("SENDMSG returnd %ld\n\n", i);
    perror("sendmsg");

    freeaddrinfo(res);
    return 0;
}

void net_test() {
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

