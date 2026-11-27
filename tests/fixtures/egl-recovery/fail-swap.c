#define _GNU_SOURCE
#include <EGL/egl.h>
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static const char *failure_flag;
static _Thread_local EGLint pending_error = EGL_SUCCESS;

__attribute__((constructor)) static void configure_flag(void)
{
    failure_flag = getenv("DEN_EGL_FAIL_FLAG");
}

EGLBoolean eglSwapBuffers(EGLDisplay display, EGLSurface surface)
{
    if (failure_flag && access(failure_flag, F_OK) == 0) {
        pending_error = EGL_BAD_ALLOC;
        fputs("PROBE_REJECT_SWAP\n", stderr);
        return EGL_FALSE;
    }
    typedef EGLBoolean (*swap_fn)(EGLDisplay, EGLSurface);
    swap_fn real = (swap_fn)dlsym(RTLD_NEXT, "eglSwapBuffers");
    if (!real) {
        fputs("PROBE missing real EGL swap\n", stderr);
        abort();
    }
    return real(display, surface);
}

EGLint eglGetError(void)
{
    if (pending_error != EGL_SUCCESS) {
        EGLint error = pending_error;
        pending_error = EGL_SUCCESS;
        return error;
    }
    typedef EGLint (*error_fn)(void);
    error_fn real = (error_fn)dlsym(RTLD_NEXT, "eglGetError");
    if (!real) {
        fputs("PROBE missing real EGL error accessor\n", stderr);
        abort();
    }
    return real();
}
