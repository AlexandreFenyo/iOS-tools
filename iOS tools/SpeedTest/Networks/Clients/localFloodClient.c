//
//  localFloodClient.c
//  iOS tools
//
//  Created by Alexandre Fenyo on 22/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

#include "localFloodClient.h"

static pthread_mutex_t mutex;
static int sock = -1;

static int last_errno;
static long nwrite;

// return values:
// - >= 0: last_errno value
// - < 0 : mutex error, should not happen
int localFloodClientGetLastErrorNo(void) {
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
static int addToNWrite(long newval) {
    int ret;
    
    if (newval == 0) return 0;
    
    ret = pthread_mutex_lock(&mutex);
    if (ret < 0) {
        perror("setLastErrorNo pthread_mutex_lock");
        return -1;
    }
    
    nwrite += newval;
    
    ret = pthread_mutex_unlock(&mutex);
    if (ret < 0) {
        perror("setLastErrorNo pthread_mutex_unlock");
        return -1;
    }
    
    return 0;
}

// return values:
// - >= 0: nwrite value
// - < 0 : mutex error, should not happen
long localFloodClientGetNWrite(void) {
    long retval;
    int ret;
    
    ret = pthread_mutex_lock(&mutex);
    if (ret < 0) {
        perror("nwrite pthread_mutex_lock");
        return -1;
    }
    
    retval = nwrite;
    
    ret = pthread_mutex_unlock(&mutex);
    if (ret < 0) {
        perror("nwrite pthread_mutex_unlock");
        return -1;
    }
    
    return retval;
}

// return values:
// - 0  : no error
// - > 0: value of errno after calling pthread_mutex_init
int localFloodClientOpen(void) {
    last_errno = 0;
    nwrite = 0;
    
    int ret = pthread_mutex_init(&mutex, NULL);
    if (ret < 0) perror("init pthread_mutex_init");
    
    return ret ? errno : 0;
}

// return values:
// - 0  : no error
// - > 0: value of errno after calling pthread_mutex_destroy
int localFloodClientClose(void) {
    int ret = pthread_mutex_destroy(&mutex);
    if (ret < 0) perror("close pthread_mutex_destroy");
    
    return ret ? errno : 0;
}

// return values:
// - 0  : no error
// - > 0: value of errno after calling pthread_mutex_destroy
int localFloodClientStop(void) {
    if (sock < 0) return -1;
    close(sock);
    return 0;
}

// https://stackoverflow.com/questions/8290046/icmp-sockets-linux
// /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include/netinet/in.h
// /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include/netinet/ip_icmp.h
int localFloodClientLoop(const struct sockaddr *saddr) {
    if (saddr == NULL) return -1;
    else {
        // printf("family: %d\n", saddr->sa_family);
    }
    if (saddr->sa_family != AF_INET && saddr->sa_family != AF_INET6) return -2;

    if (saddr->sa_family == AF_INET) ((struct sockaddr_in *) saddr)->sin_port = htons(8888);
    if (saddr->sa_family == AF_INET6) ((struct sockaddr_in6 *) saddr)->sin6_port = htons(8888);
    
    sock = socket(saddr->sa_family, SOCK_DGRAM, getprotobyname("udp")->p_proto);
    if (sock < 0) {
        perror("socket()");
        return (setLastErrorNo() << 8) - 3;
    }
    
//    // Timeout when receive an ICMP response
//    tv.tv_sec = 3;
//    tv.tv_usec = 0;
//    ret = setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof tv);
//    if (ret < 0) {
//        perror("setsockopt()");
//        return (setLastErrorNo() << 8) - 4;
//    }
    
    // on devrait partir du MTU de l'interface
    char buffer[1400];
    memset(buffer, 'A', sizeof buffer);
    while (1) {

        ssize_t len = sendto(sock, buffer, sizeof buffer, 0, saddr, (saddr->sa_family == AF_INET) ? sizeof(struct sockaddr_in) : sizeof(struct sockaddr_in6));
        if  (len < 0) {
            if (errno != ENOBUFS) {
                perror("sendto()");
                int retval = (setLastErrorNo() << 8) - 5;
                close(sock);
                return retval;
            }
            len = 0;
        }
        if (addToNWrite(len) < 0) return -6;
    }
}
