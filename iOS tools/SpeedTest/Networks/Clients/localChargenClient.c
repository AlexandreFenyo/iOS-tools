//
//  localChargenClient.c
//  iOS tools
//
//  Created by Alexandre Fenyo on 08/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

#include "localChargenClient.h"

static pthread_mutex_t mutex;
static int sock = -1;

static int last_errno = 0;
static long nread = 0;

// return values:
// - >= 0: last_errno value
// - < 0 : mutex error, should not happen
int localChargenClientGetLastErrorNo(void) {
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
static int setLastErrorNo(void) {
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

static int clearLastErrorNo(void) {
    int ret = pthread_mutex_lock(&mutex);
    if (ret < 0) {
        perror("clearLastErrorNo pthread_mutex_lock");
        return -1;
    }
    
    last_errno = 0;
    
    ret = pthread_mutex_unlock(&mutex);
    if (ret < 0) {
        perror("clearLastErrorNo pthread_mutex_unlock");
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
    last_errno = 0;
    
    ret = pthread_mutex_unlock(&mutex);
    if (ret < 0) {
        perror("setLastErrorNo pthread_mutex_unlock");
        return -1;
    }
    
    return 0;
}

static int setNRead(long newval) {
    int ret;
    
    ret = pthread_mutex_lock(&mutex);
    if (ret < 0) {
        perror("setLastErrorNo pthread_mutex_lock");
        return -1;
    }
    
    nread = newval;
    if (nread > 0) last_errno = 0;

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
long localChargenClientGetNRead(void) {
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
int localChargenClientOpen(void) {
    last_errno = 0;
    nread = 0;
    
    int ret = pthread_mutex_init(&mutex, NULL);
    if (ret < 0) perror("init pthread_mutex_init");
    
    return ret ? errno : 0;
}

// return values:
// - 0  : no error
// - > 0: value of errno after calling pthread_mutex_destroy
int localChargenClientClose(void) {
    nread = -1;
    int ret = pthread_mutex_destroy(&mutex);
    if (ret < 0) perror("close pthread_mutex_destroy");
    
    return ret ? errno : 0;
}

// return values:
// - 0  : no error
// - > 0: value of errno after calling pthread_mutex_destroy
int localChargenClientStop(void) {
    if (sock < 0) return -1;
    close(sock);
    return 0;
}

int localChargenClientLoop(const struct sockaddr *saddr) {
    clearLastErrorNo();
    
    if (saddr == NULL) return -1;
    else {
        // printf("family: %d\n", saddr->sa_family);
    }
    if (saddr->sa_family != AF_INET && saddr->sa_family != AF_INET6) return -2;
    
    if (saddr->sa_family == AF_INET) {
        ((struct sockaddr_in *) saddr)->sin_port = htons(19);
        // printf("sin_port: %d\n", ((struct sockaddr_in *) saddr)->sin_port);
    }
    if (saddr->sa_family == AF_INET6) {
        ((struct sockaddr_in6 *) saddr)->sin6_port = htons(19);
        // printf("sin_port: %d\n", ((struct sockaddr_in6 *) saddr)->sin6_port);
    }
    
    sock = socket(saddr->sa_family, SOCK_STREAM, getprotobyname("tcp")->p_proto);
    if (sock < 0) {
        perror("socket()");
        int retval = (setLastErrorNo() << 8) - 3;
        setNRead(-1);
        return retval;
    }
    int ret = connect(sock, saddr, saddr->sa_family == AF_INET ? sizeof(struct sockaddr_in) : sizeof(struct sockaddr_in6));
    if (ret < 0) {
        perror("connect()");
        int retval = (setLastErrorNo() << 8) - 4;
        setNRead(-1);
        return retval;
    }
    
    char buf[4096];
    long retval;
    do {
        retval = read(sock, buf, sizeof(buf));
        if (retval < 0) {
            perror("read");
            int retval = (setLastErrorNo() << 8) - 5;
            setNRead(-1);
            return retval;
        }
        if (addToNRead(retval) < 0) return -6;
    } while (retval > 0);
    
    // retval == 0: EOF
    return 0;
}
