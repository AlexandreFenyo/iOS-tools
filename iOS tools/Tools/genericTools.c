//
//  genericTools.c
//  iOS tools
//
//  Created by Alexandre Fenyo on 22/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

#include "genericTools.h"

int c_test() {
    printf("c_test\n");
    unsigned short ck = 0b1000000000000000;
    ck += 0b1000000000000001;
    ck = 0b1111111111111111 ^ ck;
    printf("ck=%d\n", ck);
    return 0;
}

fd_set getfds(int fd) {
    fd_set fds;
    __DARWIN_FD_SET(fd, &fds);
    return fds;
}
