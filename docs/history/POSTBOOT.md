# Verified postboot result — 2026-09-27

## Working configuration
Kernel 7.2.8-1-cachyos. Chrome default NVIDIA graphics, XWayland + ANGLE Vulkan, Intel iHD VA-API decode explicitly selected by PCI render node. No preload shim, disabled sandbox, system-wide NVIDIA graphics environment, or replacement system video driver is needed.

The previous native NVIDIA Wayland path reproducibly crashed Intel Hyprland with execbuf ENOMEM and a Mesa native-fence failure. This matches NVIDIA/open-gpu-kernel-modules issue 1037. XWayland avoids that path. Intel native Wayland remains available in Training mode. Actual normal Chrome GPU process maps iHD_drv_video.so and opens both render nodes (chrome-live-hybrid-path.json).

## Playback evidence
- 4K H.264 sustained: VaapiVideoDecoder, platform decoder true, NVIDIA Vulkan renderer, 613 frames, one initial dropped frame; zero additional drops after warm-up. Multiple loops completed. Captured video image verified, not just acceleration labels.
- 4K VP9: hardware decoder true, 169 frames, five initial drops, playback progressing.
- 4K HEVC: hardware decoder true, 169 frames, four initial drops, playback progressing.
- Same 4K H.264 clip, steady CPU measurement: hardware 1.55 CPU-seconds / 12.5548 wall seconds; software 17.31 / 12.7828. Approximately 91% less normalized CPU work. These are synthetic local tests, not a guarantee for every streaming service.
- NVIDIA direct NVDEC + rendering in mpv: 4K, zero decoder drops and zero presentation drops. MPV desktop launcher uses sensei-video. Training selects Intel VA-API for new player launches.
- Training on/off verified actual Chrome Intel then NVIDIA, graceful restarts and saved tabs. Other already-running GPU applications need relaunching; active CUDA jobs are not killed.
- Idle NVIDIA: P8, 0% activity, 300/405 MHz, about 4.36 W, 36 MiB at the measured moment.

## Desktop and boot
Both panels scale 2: eDP-1 3840x2160@60 at 0x0; DP-2 3840x1100@60.02 at 0x1080; brightness 100%. Reload uses dofile for personal configuration layers, so scaling/layout survive reloads. Hyprland configerrors empty; no failed system or user services. Monitor CPU/process/storage/network data present; Chrome GPU control refreshes immediately on creation. Diagnostic snapshot selects live Hyprland instance 0.

Obsolete NVreg_UsePageAttributeTable option removed with backup. Main initramfs rebuilt successfully with NVIDIA modules. Optional missing Renesas firmware warning is unrelated to this laptop's Intel USB controller; no USB drivers disabled.

Boot remains measured at 32.321s: firmware 6.318, loader 6.954, kernel .926, initrd 2.705, userspace 15.416. GDM logged in at userspace ~4s, while plymouth-quit-wait lingered 11.273s. This target timing is not the same as first usable desktop frame. No boot-speed improvement is claimed; next boot is needed to measure the rebuilt image. Firmware/BIOS logo is not modified.

Latest memory snapshot: 11.31 GiB available with the current application workload; Chrome PSS ~440 MiB, Quickshell ~413 MiB. These are not equivalent to the earlier many-tab workload. Memory pressure zero.

Intel compositor remains heavily loaded while rendering this dual-4K desktop. Samples showed ~94% render engine use, about 12.5 W. Reduced blur, 30 Hz ticker and SDR precision tests did not sufficiently improve overall rendering; restored original blur, ticker, precision and effects. New render scheduling enabled; automatic direct scanout permitted where eligible, but the tested NVIDIA XWayland fullscreen window did not qualify. No claim that compositor load is solved or that all hardware limits are removed.

## Limits and rollback
RTX2060 and UHD630 lack AV1 hardware decode; AV1-only streams still need software decoding. Prefer VP9/H.264 streams when available; DRM and service-specific limits remain. CPU JavaScript and tab data are not offloaded into VRAM.

Chrome rollback: sensei-chrome mode intel; sensei-chrome restart. Original profiles remain backed up under chrome-profile/profiles. Do not overwrite a live profile or newer browsing databases. To undo media launcher override, remove only the user mpv.desktop override (or restore mpv-before-hardware.desktop if present). Boot option backup: root/etc/modprobe.d/nvidia-before-obsolete-cleanup.conf.

Sources: https://github.com/NVIDIA/open-gpu-kernel-modules/issues/1037 ; https://raw.githubusercontent.com/chromium/chromium/154.0.8037.57/media/gpu/vaapi/vaapi_wrapper.cc ; https://developer.nvidia.com/video-encode-decode-support-matrix ; https://mpv.io/manual/master/ .
