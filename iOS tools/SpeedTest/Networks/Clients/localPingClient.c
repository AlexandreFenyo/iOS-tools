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

#define RTT_TIMEOUT 3
#define ICMP_ID 0xafaf

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
    struct timeval tv_now;

    // strange behaviour: for an IPv4 packet, when seq is incremente and reach 80 (50h), setting htons(seq) in icmp_hdr.icmp_hun.ih_idseq.icd_seq will not give any reply!
    // solution: I do not use htons for IPv4 packets
    unsigned short seq = 0x10;

    int is_v4;
    int ret;
    
    if (saddr == NULL) return -1;
    if (saddr->sa_family != AF_INET && saddr->sa_family != AF_INET6) return -2;
    
    is_v4 = (saddr->sa_family == AF_INET) ? 1 : 0;
    
    sock = socket(saddr->sa_family, SOCK_DGRAM, getprotobyname(is_v4 ? "icmp" : "icmp6")->p_proto);
    if (sock < 0) {
        perror("socket()");
        return (setLastErrorNo() << 8) - 3;
    }
    
    // Timeout when receive an ICMP response
    tv_now.tv_sec = RTT_TIMEOUT;
    tv_now.tv_usec = 0;
    ret = setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv_now, sizeof tv_now);
    if (ret < 0) {
        perror("setsockopt()");
        return (setLastErrorNo() << 8) - 4;
    }
    
    int first_loop = 1;
    while (--count >= 0) {
        struct timeval tv_send;
        
        if (!first_loop) usleep(1000000);
        else first_loop = 0;
        
        seq++;
        
        if (is_v4) {
            memset(&icmp_hdr, 0, sizeof icmp_hdr);
            icmp_hdr.icmp_type = ICMP_ECHO;
            icmp_hdr.icmp_code = 0;
            icmp_hdr.icmp_hun.ih_idseq.icd_id = htons(ICMP_ID);
            // strange behaviour: for an IPv4 packet, when seq is incremente and reach 80 (50h), setting htons(seq) in icmp_hdr.icmp_hun.ih_idseq.icd_seq will not give any reply!
            // solution: I do not use htons for IPv4 packets
            // icmp_hdr.icmp_hun.ih_idseq.icd_seq = htons(seq);
            icmp_hdr.icmp_hun.ih_idseq.icd_seq = seq;
            // printf("envoi seq %d %d\n", seq, htons(seq));

            unsigned short ck = 0;
            for (int i = 0; i < sizeof icmp_hdr / 2; i++) ck += ((unsigned short *) &icmp_hdr)[i];
            icmp_hdr.icmp_cksum = 0b1111111111111111 ^ ck;
        } else {
            memset(&icmp6_hdr, 0, sizeof icmp6_hdr);
            icmp6_hdr.icmp6_type = ICMP6_ECHO_REQUEST;
            icmp6_hdr.icmp6_code = 0;
            icmp6_hdr.icmp6_id = htons(ICMP_ID);
            icmp6_hdr.icmp6_seq = htons(seq);
        }
        
        gettimeofday(&tv_send, NULL);
        ssize_t len = sendto(sock, is_v4 ? (const void *) &icmp_hdr : &icmp6_hdr, is_v4 ? sizeof icmp_hdr : sizeof icmp6_hdr, 0, saddr, is_v4 ? sizeof(struct sockaddr_in) : sizeof(struct sockaddr_in6));
        if  (len < 0) {
            perror("sendto()");
        }
        
        // il faut boucler car il y en a peut etre une file d'attente d'où les décalages d'ID
        
        char buf[10000];
        socklen_t foo = 0;
        
        int redo_loop;
        do {
            redo_loop = 0;
            long retval = recvfrom(sock, buf, sizeof buf, 0, NULL, &foo);
            if (retval < 0 && errno != EAGAIN) {
                perror("recvfrom()");
                return (setLastErrorNo() << 8) - 5;
            }
            
            // Dump the content of the received buffer
            // or (int bar = 0; bar < retval; bar++) { printf("XXXX buf[%d]=0x%x\n", bar, (unsigned char) (buf[bar])); }
            
            if (is_v4) {
                struct icmp *icmp_p;
                if (retval != 48 || buf[0] != 0x45) {
                    printf("unattended ICMP size: %u\n", (int) retval);
                    redo_loop = 1;
                }
                icmp_p = (struct icmp *) (20 + (void *) buf);
                if (icmp_p->icmp_code != 0) {
                    printf("unattended ICMP code received: %d\n", icmp_p->icmp_code);
                    redo_loop = 1;
                }
                if (icmp_p->icmp_type != 0) {
                    printf("unattended ICMP type received: %d\n", icmp_p->icmp_type);
                    redo_loop = 1;
                }
                if (ntohs(icmp_p->icmp_hun.ih_idseq.icd_id) != ICMP_ID) {
                    printf("unattended ICMP id received: %d\n", ntohs(icmp_p->icmp_hun.ih_idseq.icd_id));
                    redo_loop = 1;
                }
                // strange behaviour: for an IPv4 packet, when seq is incremente and reach 80 (50h), setting htons(seq) in icmp_hdr.icmp_hun.ih_idseq.icd_seq will not give any reply!
                // solution: I do not use htons for IPv4 packets
                // if (ntohs(icmp_p->icmp_hun.ih_idseq.icd_seq) != seq) {
                if (icmp_p->icmp_hun.ih_idseq.icd_seq != seq) {
                    // printf("unattended ICMP seq received: %d instead of %d\n", ntohs(icmp_p->icmp_hun.ih_idseq.icd_seq), seq);
                    printf("unattended ICMP seq received: %d instead of %d\n", icmp_p->icmp_hun.ih_idseq.icd_seq, seq);
                    redo_loop = 1;
                }
            } else {
                struct icmp6_hdr *icmp6_hdr_p;
                if (retval != 8) {
                    printf("unattended ICMPv6 size: %u\n", (int) retval);
                    redo_loop = 1;
                }
                icmp6_hdr_p = (struct icmp6_hdr *) buf;
                if (icmp6_hdr_p->icmp6_code != 0) {
                    printf("unattended ICMPv6 code received: %d\n", icmp6_hdr_p->icmp6_code);
                    redo_loop = 1;
                }
                if (icmp6_hdr_p->icmp6_type != 0x81) {
                    printf("unattended ICMPv6 type received: %d\n", icmp6_hdr_p->icmp6_type);
                    redo_loop = 1;
                }
                if (ntohs(icmp6_hdr_p->icmp6_id) != ICMP_ID) {
                    printf("unattended ICMPv6 id received: %d\n", ntohs(icmp6_hdr_p->icmp6_id));
                    redo_loop = 1;
                }
                if (ntohs(icmp6_hdr_p->icmp6_seq) != seq) {
                    printf("unattended ICMPv6 seq received: %d instead of %d\n", ntohs(icmp6_hdr_p->icmp6_seq), seq);
                    redo_loop = 1;
                }
            }
            
            gettimeofday(&tv_now, NULL);
            long duration = 1000000 * (tv_now.tv_sec - tv_send.tv_sec) + tv_now.tv_usec - tv_send.tv_usec;
            if (redo_loop == 0) {
                if (setRTT(duration) < 0) return -6;
            }
            
        } while (redo_loop == 1 && 1000000 * (tv_now.tv_sec - tv_send.tv_sec) + tv_now.tv_usec - tv_send.tv_usec < 1000000 * RTT_TIMEOUT);
    }
    
    ret = close(sock);
    if  (ret < 0) {
        perror("close()");
    }
    
    return 0;
}
