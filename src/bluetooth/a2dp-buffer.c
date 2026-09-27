#define _GNU_SOURCE
#include <dlfcn.h>
#include <sys/socket.h>
#include <bluetooth/bluetooth.h>
#include <bluetooth/l2cap.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <pthread.h>
#include <stdlib.h>
/* Apply only to the authorized headset's outgoing Bluetooth L2CAP socket.
 * PipeWire reads back SO_SNDBUF, so its queue accounting sees the real size.
 * Do not touch ALSA, TCP, PulseAudio, HFP/SCO or unrelated Bluetooth devices.
 */
static int (*original)(int,int,int,const void*,socklen_t);
static pthread_once_t resolver_once = PTHREAD_ONCE_INIT;
static void resolve_original(void) { original = dlsym(RTLD_NEXT, "setsockopt"); }
int setsockopt(int fd, int level, int option, const void *value, socklen_t size) {
    pthread_once(&resolver_once, resolve_original);
    if (!original) { errno = ENOSYS; return -1; }
    if (level == SOL_SOCKET && option == SO_SNDBUF && value && size == sizeof(int)) {
        struct sockaddr_l2 peer = {0}; socklen_t peer_size = sizeof(peer);
        bdaddr_t headset;
        const char *address = getenv("SENSEI_A2DP_ADDRESS");
        if (!address || str2ba(address, &headset)) return original(fd,level,option,value,size);
        int prior_errno = errno;
        if (getpeername(fd, (struct sockaddr *)&peer, &peer_size) == 0 &&
            peer.l2_family == AF_BLUETOOTH && peer_size >= sizeof(peer) &&
            !memcmp(peer.l2_bdaddr.b, headset.b, sizeof(headset.b)) &&
            btohs(peer.l2_psm) == 0x19) {
            int requested; memcpy(&requested,value,sizeof(requested));
            if (requested > 0 && requested <= 32768) {
                int enlarged = requested > 10922 ? 32768 : requested * 3;
                errno = prior_errno;
                int result = original(fd,level,option,&enlarged,sizeof(enlarged));
                if (result == 0) fprintf(stderr,"Sensei A2DP buffer: %d -> %d bytes requested (headset only)\n",requested,enlarged);
                return result;
            }
        }
        errno = prior_errno;
    }
    return original(fd,level,option,value,size);
}
