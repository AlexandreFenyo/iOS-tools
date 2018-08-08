//
//  localChargenClient.c
//  iOS tools
//
//  Created by Alexandre Fenyo on 08/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

#include "nettools.h"

static pthread_mutex_t mutex;
static int sock = -1;

static int last_errno;
static long nread;

// return values:
// - >= 0: last_errno value
// - < 0 : mutex error, should not happen
int localChargenClientGetLastErrorNo() {
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
static int addToNRead(long newval) {
    int ret;
    
    ret = pthread_mutex_lock(&mutex);
    if (ret < 0) {
        perror("setLastErrorNo pthread_mutex_lock");
        return -1;
    }
    
    nread += newval;
    
    ret = pthread_mutex_unlock(&mutex);
    if (ret < 0) {
        perror("setLastErrorNo pthread_mutex_unlock");
        return -1;
    }
    
    return 0;
}

// return values:
// - >= 0: nread value
// - < 0 : mutex error, should not happen
long localChargenClientGetNRead() {
    long retval;
    int ret;
    
    ret = pthread_mutex_lock(&mutex);
    if (ret < 0) {
        perror("nread pthread_mutex_lock");
        return -1;
    }
    
    retval = nread;
    
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
int localChargenClientOpen() {
    last_errno = 0;
    nread = 0;
    
    int ret = pthread_mutex_init(&mutex, NULL);
    if (ret < 0) perror("init pthread_mutex_init");
    
    return ret ? errno : 0;
}

// return values:
// - 0  : no error
// - > 0: value of errno after calling pthread_mutex_destroy
int localChargenClientClose() {
    int ret = pthread_mutex_destroy(&mutex);
    if (ret < 0) perror("close pthread_mutex_destroy");
    
    return ret ? errno : 0;
}

// return values:
// - 0  : no error
// - > 0: value of errno after calling pthread_mutex_destroy
int localChargenClientStop() {
    if (sock < 0) return -1;
    close(sock);
    return 0;
}

int localChargenClientLoop(const struct sockaddr *saddr) {
    if (saddr == NULL) return -1;
    else printf("family: %d\n", saddr->sa_family);
    if (saddr->sa_family != AF_INET && saddr->sa_family != AF_INET6) return -2;
    
    if (saddr->sa_family == AF_INET) printf("sin_port: %d\n", ((struct sockaddr_in *) saddr)->sin_port);
    if (saddr->sa_family == AF_INET6) printf("sin_port: %d\n", ((struct sockaddr_in6 *) saddr)->sin6_port);
    
    sock = socket(saddr->sa_family, SOCK_STREAM, getprotobyname("tcp")->p_proto);
    if (sock < 0) {
        perror("socket()");
        return (setLastErrorNo() << 8) - 3;
    }
    int ret = connect(sock, saddr, saddr->sa_family == AF_INET ? sizeof(struct sockaddr_in) : sizeof(struct sockaddr_in6));
    if (ret < 0) {
        perror("connect()");
        return (setLastErrorNo() << 8) - 4;
    }
    
    char buf[4096];
    long retval;
    do {
        retval = read(sock, buf, sizeof(buf));
        if (ret < 0) {
            perror("read");
            return (setLastErrorNo() << 8) - 5;
        }
        if (addToNRead(retval) < 0) return -6;
    } while (retval > 0);
    
    return 0;
}

