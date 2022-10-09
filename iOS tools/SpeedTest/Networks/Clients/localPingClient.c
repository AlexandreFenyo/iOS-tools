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
int localPingClientGetLastErrorNo(void) {
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
long localPingClientGetRTT(void) {
    long retval;
    int ret;
    
    ret = pthread_mutex_lock(&mutex);
    if (ret < 0) {
        perror("nread pthread_mutex_lock");
        return -1;
    }
    
    retval = rtt;
    rtt = 0;
    
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
int localPingClientOpen(void) {
    last_errno = 0;
    rtt = 0;
    
    int ret = pthread_mutex_init(&mutex, NULL);
    if (ret < 0) perror("init pthread_mutex_init");
    
    return ret ? errno : 0;
}

// return values:
// - 0  : no error
// - > 0: value of errno after calling pthread_mutex_destroy
int localPingClientClose(void) {
    int ret = pthread_mutex_destroy(&mutex);
    if (ret < 0) perror("close pthread_mutex_destroy");
    
    return ret ? errno : 0;
}

// return values:
// - 0  : no error
// - > 0: value of errno after calling pthread_mutex_destroy
int localPingClientStop(void) {
    if (sock < 0) return -1;
    close(sock);
    return 0;
}

// https://stackoverflow.com/questions/8290046/icmp-sockets-linux
// /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include/netinet/in.h
// /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include/netinet/ip_icmp.h
int localPingClientLoop(const struct sockaddr *saddr, int count) {
    struct icmp icmp_hdr;
    struct icmp6_hdr icmp6_hdr;
    struct timeval tv;
    int ret;

    if (saddr == NULL) return -1;
    else {
        // printf("family: %d\n", saddr->sa_family);
    }
    if (saddr->sa_family != AF_INET && saddr->sa_family != AF_INET6) return -2;
    
    sock = socket(saddr->sa_family, SOCK_DGRAM, getprotobyname((saddr->sa_family == AF_INET) ? "icmp" : "icmp6")->p_proto);
    if (sock < 0) {
        perror("socket()");
        return (setLastErrorNo() << 8) - 3;
    }

    memset(&icmp_hdr, 0, sizeof icmp_hdr);
    memset(&icmp6_hdr, 0, sizeof icmp6_hdr);
    icmp_hdr.icmp_type = ICMP_ECHO;
    icmp_hdr.icmp_code = 0;
    icmp_hdr.icmp_seq = htons(12);

    icmp6_hdr.icmp6_type = ICMP6_ECHO_REQUEST;
    icmp6_hdr.icmp6_code = 0;
    icmp6_hdr.icmp6_seq = htons(12);

    unsigned short ck = 0;
    for (int i = 0; i < sizeof icmp_hdr / 2; i++) ck += ((unsigned short *) &icmp_hdr)[i];
    icmp_hdr.icmp_cksum = 0b1111111111111111 ^ ck;

    // Timeout when receive an ICMP response
    tv.tv_sec = 3;
    tv.tv_usec = 0;
    ret = setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof tv);
    if (ret < 0) {
        perror("setsockopt()");
        return (setLastErrorNo() << 8) - 4;
    }

    while (--count >= 0) {
        struct timeval tv, tv2;
        
        gettimeofday(&tv, NULL);
        ssize_t len = sendto(sock, (saddr->sa_family == AF_INET) ? (const void *) &icmp_hdr : &icmp6_hdr, (saddr->sa_family == AF_INET) ? sizeof icmp_hdr : sizeof icmp6_hdr, 0, saddr, (saddr->sa_family == AF_INET) ? sizeof(struct sockaddr_in) : sizeof(struct sockaddr_in6));
        // printf("sendto ICMP retval:%ld\n", len);
        if  (len < 0) {
            perror("sendto()");
        }
        
        char buf[10000];
        socklen_t foo = 0;
        long retval = recvfrom(sock, buf, sizeof buf, 0, NULL, &foo);
        if (retval < 0 && errno != EAGAIN) {
            printf("%d\n", errno);
            perror("recvfrom()");
            return (setLastErrorNo() << 8) - 5;
        }
        if (retval >= 0 || errno != EAGAIN) {
            gettimeofday(&tv2, NULL);
            long duration = 1000000 * (tv2.tv_sec - tv.tv_sec) + tv2.tv_usec - tv.tv_usec;
            if (setRTT(duration) < 0) return -6;
        }
        // printf("recvfrom : retval = %ld\n", retval);
        
        usleep(1000000);
    }

    ret = close(sock);
    if  (ret < 0) {
        perror("close()");
    }

    return 0;
}
