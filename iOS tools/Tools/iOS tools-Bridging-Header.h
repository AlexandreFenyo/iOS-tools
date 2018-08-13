//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

int localChargenClientOpen();
int localChargenClientClose();
int localChargenClientStop();
int localChargenClientGetLastErrorNo();
long localChargenClientGetNRead();
int localChargenClientLoop(const struct sockaddr *saddr);

int localDiscardClientOpen();
int localDiscardClientClose();
int localDiscardClientStop();
int localDiscardClientGetLastErrorNo();
long localDiscardClientGetNWrite();
int localDiscardClientLoop(const struct sockaddr *saddr);

void net_test();
