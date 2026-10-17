/* Only a bounded relative pointer nudge, no keyboard/button capability. */
#include <wayland-client.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include "pointer.h"
static struct wl_seat *seat;
static struct zwlr_virtual_pointer_manager_v1 *manager;
static void global(void*d,struct wl_registry*r,uint32_t name,const char*interface,uint32_t version){
 if(!strcmp(interface,"wl_seat"))seat=wl_registry_bind(r,name,&wl_seat_interface,1);
 if(!strcmp(interface,"zwlr_virtual_pointer_manager_v1"))manager=wl_registry_bind(r,name,&zwlr_virtual_pointer_manager_v1_interface,1);
}
static void removed(void*d,struct wl_registry*r,uint32_t name){}
int main(int argc,char**argv){
 if(argc!=3)return 2;char *ex,*ey;long x=strtol(argv[1],&ex,10),y=strtol(argv[2],&ey,10);if(*ex||*ey||labs(x)>16||labs(y)>16)return 2;
 struct wl_display *display=wl_display_connect(NULL);if(!display)return 3;struct wl_registry *registry=wl_display_get_registry(display);struct wl_registry_listener listener={global,removed};wl_registry_add_listener(registry,&listener,NULL);wl_display_roundtrip(display);if(!manager||!seat)return 4;
 struct zwlr_virtual_pointer_v1 *pointer=zwlr_virtual_pointer_manager_v1_create_virtual_pointer(manager,seat);wl_display_roundtrip(display);struct timespec now;clock_gettime(CLOCK_MONOTONIC,&now);
 zwlr_virtual_pointer_v1_motion(pointer,(uint32_t)(now.tv_sec*1000+now.tv_nsec/1000000),wl_fixed_from_int(x),wl_fixed_from_int(y));zwlr_virtual_pointer_v1_frame(pointer);wl_display_roundtrip(display);usleep(50000);zwlr_virtual_pointer_v1_destroy(pointer);wl_display_flush(display);wl_display_disconnect(display);return 0;
}
