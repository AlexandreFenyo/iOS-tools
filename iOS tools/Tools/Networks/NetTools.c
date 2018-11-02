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

void net_test() {
   // récupérer des infos comme la gateway par défaut via sysctl(3)
    
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

