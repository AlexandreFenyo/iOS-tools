//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

int localChargenClientOpen();
int localChargenClientClose();
int localChargenClientStop();
int localChargenClientGetLastErrorNo();
long localChargenClientGetNRead();
int localChargenClientLoop(const struct sockaddr *saddr);

void net_test();
