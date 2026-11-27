#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdint.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

struct dri_screen;
struct dri_image;
static atomic_int rejecting, rejected;
static const char *failure_flag;

__attribute__((constructor)) static void configure_flag(void)
{
    failure_flag = getenv("DEN_EGL_FAIL_FLAG");
}

static int reject_image(void)
{
    if (!atomic_load(&rejecting) && !(failure_flag && access(failure_flag, F_OK) == 0))
        return 0;
    atomic_fetch_add(&rejected, 1);
    fputs("PROBE_REJECT_IMAGE\n", stderr);
    return 1;
}

void den_egl_fail_allocations(int active) { atomic_store(&rejecting, active); }
int den_egl_failure_count(void) { return atomic_load(&rejected); }

struct dri_image *dri_create_image(struct dri_screen *screen, int width, int height,
    int format, const uint64_t *modifiers, unsigned count, unsigned use, void *owner)
{
    if (reject_image()) return NULL;
    typedef struct dri_image *(*fn)(struct dri_screen *, int, int, int,
        const uint64_t *, unsigned, unsigned, void *);
    fn real = (fn)dlsym(RTLD_NEXT, "dri_create_image");
    if (!real) { fputs("PROBE missing real allocator\n", stderr); abort(); }
    return real(screen, width, height, format, modifiers, count, use, owner);
}

struct dri_image *dri_create_image_with_modifiers(struct dri_screen *screen,
    uint32_t width, uint32_t height, uint32_t format, uint32_t use,
    const uint64_t *modifiers, unsigned count, void *owner)
{
    if (reject_image()) return NULL;
    typedef struct dri_image *(*fn)(struct dri_screen *, uint32_t, uint32_t,
        uint32_t, uint32_t, const uint64_t *, unsigned, void *);
    fn real = (fn)dlsym(RTLD_NEXT, "dri_create_image_with_modifiers");
    if (!real) { fputs("PROBE missing real modifier allocator\n", stderr); abort(); }
    return real(screen, width, height, format, use, modifiers, count, owner);
}
