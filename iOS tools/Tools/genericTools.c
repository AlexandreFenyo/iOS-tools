//
//  genericTools.c
//  iOS tools
//
//  Created by Alexandre Fenyo on 22/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

#include "genericTools.h"

#include <sys/_types/_fd_def.h>

int c_test(void) {
    printf("c_test\n");
    unsigned short ck = 0b1000000000000000;
    ck += 0b1000000000000001;
    ck = 0b1111111111111111 ^ ck;
    printf("ck=%d\n", ck);
    return 0;
}

fd_set getfds(int fd) {
    fd_set fds;
    bzero(&fds, sizeof fds);
    __DARWIN_FD_SET(fd, &fds);
    return fds;
}
