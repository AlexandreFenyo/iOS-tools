//
//  NetTools.c
//  iOS tools
//
//  Created by Alexandre Fenyo on 15/06/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

#include "NetTools.h"

void net_test() {
    char str[INET6_ADDRSTRLEN];
    char hostname[] = "www.fenyo.net";

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

    // DNS
    
    struct addrinfo *infos;
    struct addrinfo hints;
    bzero(&hints, sizeof hints);
    
    hints.ai_family = PF_UNSPEC;
    hints.ai_flags = AI_ALL | AI_V4MAPPED;
    ret = getaddrinfo(hostname, (char *) &hints, NULL, &infos);
    if (ret != 0) {
        perror("getaddrinfo");
        return;
    }

    if (hints.ai_flags & AI_CANONNAME && infos != NULL) printf("canon:%s \n", infos->ai_canonname);

    while (infos != NULL) {
        struct sockaddr_in *s_in;
        struct sockaddr_in6 *s_in6;
        
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

    // UDP v6
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
    
    // char ip[] ="2a01:e35:8aae:bc63:222:15ff:fe3b:59a";
    char ip2[] ="1.2.3.4";
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

    // Flood with UDP
    while (1) {
        len = sendto(s, buf, sizeof buf, 0, (struct sockaddr *) &addr, sizeof addr);
        if (len < 1) {
            printf("len: %ld\n", len);
            perror("sendto v4");
            return;
        }
//        printf("envoyés: %ld\n", len);
    }
}
