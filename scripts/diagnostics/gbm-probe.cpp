#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <gbm.h>
#include <drm_fourcc.h>
#include <fcntl.h>
#include <unistd.h>
#include <cstdio>
#include <vector>
int main(int argc,char**argv){
 if(argc<2)return 2;int fd=open(argv[1],O_RDWR|O_CLOEXEC);if(fd<0)return 3;
 auto dev=gbm_create_device(fd);auto display=eglGetPlatformDisplay(EGL_PLATFORM_GBM_KHR,dev,nullptr);EGLint major,minor;
 if(!eglInitialize(display,&major,&minor)){printf("EGL init failed %x\n",eglGetError());return 4;}eglBindAPI(EGL_OPENGL_ES_API);
 EGLint ca[]={EGL_CONTEXT_CLIENT_VERSION,2,EGL_NONE};auto ctx=eglCreateContext(display,EGL_NO_CONFIG_KHR,EGL_NO_CONTEXT,ca);
 if(!eglMakeCurrent(display,EGL_NO_SURFACE,EGL_NO_SURFACE,ctx)){printf("Context failed %x\n",eglGetError());return 5;}
 printf("renderer: %s\n",glGetString(GL_RENDERER));
 auto query=(PFNEGLQUERYDMABUFMODIFIERSEXTPROC)eglGetProcAddress("eglQueryDmaBufModifiersEXT");
 auto create=(PFNEGLCREATEIMAGEKHRPROC)eglGetProcAddress("eglCreateImageKHR");auto destroy=(PFNEGLDESTROYIMAGEKHRPROC)eglGetProcAddress("eglDestroyImageKHR");auto storage=(PFNGLEGLIMAGETARGETRENDERBUFFERSTORAGEOESPROC)eglGetProcAddress("glEGLImageTargetRenderbufferStorageOES");
 EGLint n=0;query(display,DRM_FORMAT_XRGB8888,0,nullptr,nullptr,&n);std::vector<EGLuint64KHR> mods(n);std::vector<EGLBoolean> ext(n);query(display,DRM_FORMAT_XRGB8888,n,mods.data(),ext.data(),&n);
 mods.insert(mods.begin(),DRM_FORMAT_MOD_INVALID);ext.insert(ext.begin(),EGL_FALSE);
 for(unsigned i=0;i<mods.size();++i){
  uint64_t requested=mods[i];if(ext[i])continue;auto bo=requested==DRM_FORMAT_MOD_INVALID?gbm_bo_create(dev,64,64,GBM_FORMAT_XRGB8888,GBM_BO_USE_RENDERING):gbm_bo_create_with_modifiers2(dev,64,64,GBM_FORMAT_XRGB8888,&requested,1,GBM_BO_USE_RENDERING);
  if(!bo){printf("%llx allocation failed\n",(unsigned long long)requested);continue;}
  auto mod=gbm_bo_get_modifier(bo);int dma=gbm_bo_get_fd(bo);std::vector<EGLint>a={EGL_WIDTH,64,EGL_HEIGHT,64,EGL_LINUX_DRM_FOURCC_EXT,DRM_FORMAT_XRGB8888,EGL_DMA_BUF_PLANE0_FD_EXT,dma,EGL_DMA_BUF_PLANE0_OFFSET_EXT,0,EGL_DMA_BUF_PLANE0_PITCH_EXT,(EGLint)gbm_bo_get_stride(bo)};
  if(argc<3 && mod!=DRM_FORMAT_MOD_INVALID)a.insert(a.end(),{EGL_DMA_BUF_PLANE0_MODIFIER_LO_EXT,(EGLint)mod,EGL_DMA_BUF_PLANE0_MODIFIER_HI_EXT,(EGLint)(mod>>32)});a.push_back(EGL_NONE);
  auto im=create(display,EGL_NO_CONTEXT,EGL_LINUX_DMA_BUF_EXT,nullptr,a.data());GLuint rb=0,fb=0;GLenum status=0;
  if(im){glGenRenderbuffers(1,&rb);glBindRenderbuffer(GL_RENDERBUFFER,rb);storage(GL_RENDERBUFFER,im);glGenFramebuffers(1,&fb);glBindFramebuffer(GL_FRAMEBUFFER,fb);glFramebufferRenderbuffer(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_RENDERBUFFER,rb);status=glCheckFramebufferStatus(GL_FRAMEBUFFER);}
  printf("request=%llx actual=%llx image=%s framebuffer=%x glerror=%x\n",(unsigned long long)requested,(unsigned long long)mod,im?"yes":"no",status,glGetError());
  glDeleteFramebuffers(1,&fb);glDeleteRenderbuffers(1,&rb);if(im)destroy(display,im);close(dma);gbm_bo_destroy(bo);
 }
 eglMakeCurrent(display,EGL_NO_SURFACE,EGL_NO_SURFACE,EGL_NO_CONTEXT);eglDestroyContext(display,ctx);eglTerminate(display);gbm_device_destroy(dev);close(fd);
}
