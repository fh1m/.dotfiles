#define _GNU_SOURCE
#include <wayland-client.h>
#include <wayland-egl.h>
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>

static struct wl_compositor *compositor;
static void global(void *data, struct wl_registry *registry, uint32_t name,
                   const char *interface, uint32_t version)
{
    (void)data;
    if (!strcmp(interface, "wl_compositor"))
        compositor = wl_registry_bind(registry, name, &wl_compositor_interface,
                                      version < 4 ? version : 4);
}
static void removed(void *data, struct wl_registry *registry, uint32_t name)
{
    (void)data; (void)registry; (void)name;
}
static const struct wl_registry_listener listener = { global, removed };
static void require(int valid, const char *step)
{
    if (!valid) {
        fprintf(stderr, "PROBE_FAIL %s EGL=0x%x\n", step, eglGetError());
        exit(2);
    }
}

int main(int argc, char **argv)
{
    struct rlimit core = {0, 0};
    setrlimit(RLIMIT_CORE, &core);
    int inject = argc > 1 && !strcmp(argv[1], "fail-then-recover");
    void (*fail)(int) = (void (*)(int))dlsym(RTLD_DEFAULT, "den_egl_fail_allocations");
    int (*failures)(void) = (int (*)(void))dlsym(RTLD_DEFAULT, "den_egl_failure_count");
    require(fail && failures, "test interposer loaded");
    struct wl_display *display = wl_display_connect(NULL);
    require(display != NULL, "Wayland connection");
    struct wl_registry *registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &listener, NULL);
    require(wl_display_roundtrip(display) >= 0 && compositor != NULL, "compositor binding");
    /* A roleless surface: the allocator test never places a visible window. */
    struct wl_surface *surface = wl_compositor_create_surface(compositor);
    struct wl_egl_window *window = wl_egl_window_create(surface, 128, 128);
    EGLDisplay egl = eglGetPlatformDisplay(EGL_PLATFORM_WAYLAND_KHR, display, NULL);
    require(egl != EGL_NO_DISPLAY && eglInitialize(egl, NULL, NULL), "EGL initialization");
    require(eglBindAPI(EGL_OPENGL_ES_API), "OpenGL ES binding");
    EGLint attributes[] = {EGL_SURFACE_TYPE, EGL_WINDOW_BIT, EGL_RENDERABLE_TYPE,
        EGL_OPENGL_ES2_BIT, EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8,
        EGL_ALPHA_SIZE, 8, EGL_NONE};
    EGLConfig config;
    EGLint count;
    require(eglChooseConfig(egl, attributes, &config, 1, &count) && count == 1, "window config");
    EGLint context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};
    EGLContext context = eglCreateContext(egl, config, EGL_NO_CONTEXT, context_attributes);
    require(context != EGL_NO_CONTEXT, "context");
    EGLSurface target = eglCreateWindowSurface(egl, config, window, NULL);
    require(target != EGL_NO_SURFACE, "window surface");
    fail(inject);
    require(eglMakeCurrent(egl, target, target, context), "current surface");
    EGLint age = -2;
    EGLBoolean queried = eglQuerySurface(egl, target, EGL_BUFFER_AGE_EXT, &age);
    EGLint query_error = eglGetError();
    fail(0);
    fprintf(stderr, "PROBE query=%d age=%d error=0x%x rejected=%d\n",
            queried, age, query_error, failures());
    if (inject) require(failures() > 0, "allocation failure actually injected");
    require(eglMakeCurrent(egl, target, target, context), "recovered current surface");
    require(eglSwapInterval(egl, 0), "nonblocking swap interval");
    for (unsigned i = 0; i < 3; ++i)
        require(eglSwapBuffers(egl, target), "each post-failure swap succeeds");
    eglMakeCurrent(egl, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
    eglDestroySurface(egl, target);
    eglDestroyContext(egl, context);
    eglTerminate(egl);
    wl_egl_window_destroy(window);
    wl_surface_destroy(surface);
    wl_compositor_destroy(compositor);
    wl_registry_destroy(registry);
    wl_display_disconnect(display);
    puts("PROBE_PASS allocation and presentation recovery");
    return 0;
}
