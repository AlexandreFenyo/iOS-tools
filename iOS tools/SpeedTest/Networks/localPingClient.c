//
//  localPingClient.c
//  iOS tools
//
//  Created by Alexandre Fenyo on 08/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

#include "localPingClient.h"

static pthread_mutex_t mutex;
static int sock = -1;

static int last_errno;
static long rtt;

// return values:
// - >= 0: last_errno value
// - < 0 : mutex error, should not happen
int localPingClientGetLastErrorNo() {
    int retval, ret;
    
    ret = pthread_mutex_lock(&mutex);
    if (ret < 0) {
        perror("errno pthread_mutex_lock");
        return -1;
    }
    
    retval = last_errno;
    
    ret = pthread_mutex_unlock(&mutex);
    if (ret < 0) {
        perror("errno pthread_mutex_unlock");
        return -1;
    }
    
    return retval;
}

// return values:
// - 0  : no error
// - < 0: mutex error, should not happen
static int setLastErrorNo() {
    int ret = pthread_mutex_lock(&mutex);
    if (ret < 0) {
        perror("setLastErrorNo pthread_mutex_lock");
        return -1;
    }
    
    last_errno = errno;
    
    ret = pthread_mutex_unlock(&mutex);
    if (ret < 0) {
        perror("setLastErrorNo pthread_mutex_unlock");
        return -1;
    }
    
    return 0;
}

// return values:
// - 0  : no error
// - < 0: mutex error, should not happen
static int setRTT(long newval) {
    int ret;
    
    ret = pthread_mutex_lock(&mutex);
    if (ret < 0) {
        perror("setLastErrorNo pthread_mutex_lock");
        return -1;
    }
    
    rtt = newval;
    
    ret = pthread_mutex_unlock(&mutex);
    if (ret < 0) {
        perror("setLastErrorNo pthread_mutex_unlock");
        return -1;
    }
    
    return 0;
}

// return values:
// - >= 0: RTT value
// - < 0 : mutex error, should not happen
long localPingClientGetRTT() {
    long retval;
    int ret;
    
    ret = pthread_mutex_lock(&mutex);
    if (ret < 0) {
        perror("nread pthread_mutex_lock");
        return -1;
    }
    
    retval = rtt;
    
    ret = pthread_mutex_unlock(&mutex);
    if (ret < 0) {
        perror("nread pthread_mutex_unlock");
        return -1;
    }
    
    return retval;
}

// return values:
// - 0  : no error
// - > 0: value of errno after calling pthread_mutex_init
int localPingClientOpen() {
    last_errno = 0;
    rtt = 0;
    
    int ret = pthread_mutex_init(&mutex, NULL);
    if (ret < 0) perror("init pthread_mutex_init");
    
    return ret ? errno : 0;
}

// return values:
// - 0  : no error
// - > 0: value of errno after calling pthread_mutex_destroy
int localPingClientClose() {
    int ret = pthread_mutex_destroy(&mutex);
    if (ret < 0) perror("close pthread_mutex_destroy");
    
    return ret ? errno : 0;
}

// return values:
// - 0  : no error
// - > 0: value of errno after calling pthread_mutex_destroy
int localPingClientStop() {
    if (sock < 0) return -1;
    close(sock);
    return 0;
}

// https://stackoverflow.com/questions/8290046/icmp-sockets-linux
// /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include/netinet/in.h
// /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include/netinet/ip_icmp.h
int localPingClientLoop(const struct sockaddr *saddr) {
    struct icmp icmp_hdr;
    struct icmp6_hdr icmp6_hdr;
    memset(&icmp_hdr, 0, sizeof icmp_hdr);
    memset(&icmp6_hdr, 0, sizeof icmp6_hdr);
    icmp_hdr.icmp_type = ICMP_ECHO;
    icmp_hdr.icmp_code = 0;
    icmp_hdr.icmp_seq = htons(12);
    icmp6_hdr.icmp6_type = ICMP6_ECHO_REQUEST;
    icmp6_hdr.icmp6_code = 0;

    if (saddr == NULL) return -1;
    else printf("family: %d\n", saddr->sa_family);
    if (saddr->sa_family != AF_INET && saddr->sa_family != AF_INET6) return -2;
    
    if (saddr->sa_family == AF_INET) printf("sin_port: %d\n", ((struct sockaddr_in *) saddr)->sin_port);
    if (saddr->sa_family == AF_INET6) printf("sin_port: %d\n", ((struct sockaddr_in6 *) saddr)->sin6_port);
    
    sock = socket(saddr->sa_family, SOCK_DGRAM, getprotobyname((saddr->sa_family == AF_INET) ? "icmp" : "icmp6")->p_proto);

    if (sock < 0) {
        perror("socket()");
        return (setLastErrorNo() << 8) - 3;
    }

    ssize_t len = sendto(sock, (saddr->sa_family == AF_INET) ? &icmp_hdr : &icmp6_hdr, (saddr->sa_family == AF_INET) ? sizeof icmp_hdr : sizeof icmp6_hdr, 0, saddr, (saddr->sa_family == AF_INET) ? sizeof(struct sockaddr_in) : sizeof(struct sockaddr_in6));
    printf("sendto ICMP retval:%ld\n", len);
    if  (len < 0) {
        perror("sendto");
    }
    
    // retval == 0: EOF
    return 0;
}
