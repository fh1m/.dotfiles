# One pair of ears

Sound studio is shared by Arete and Homie. **Den** selects a laptop output for PC playback; the other tabs retain each machine’s own device and application controls. The route summary remains visible on the ordinary sound pages.

Choose **Stereo LAN** for PC sound on laptop headphones, USB audio or an attached monitor. **Stop** releases only this route. The laptop owns the stream; Homie uses the existing restricted reverse-control gateway. No extra network listener, copied credentials or microphone capture is involved. The route starts on request, rather than automatically at login. Brief failures receive three bounded restart attempts; after a longer interruption choose Listen again.

The panel shows the selected port, source applications, mute states, levels, format and whether the playback stream is linked. **Check signal** briefly samples the two playback monitors in RAM and reports measured peaks; it does not record microphones or save audio. This proves software signal delivery, not physical audibility. **Test PC sound** plays a quiet fading chord on Homie.

Headphones and speakers can be different ports of one device. Choose the port as well as the output. The output selection is explicit; changing a machine’s default device is not a promise that an existing capture will migrate—restart the route after a PC default-output change.

AUX is optional and mono. The inspected PowerCombi capture received digital silence from the original cable arrangement. A headphone-only jack cannot receive another output; the required input contact/cable must actually carry signal. The verified stereo LAN route does not require that cable.

PipeWire’s [pipe tunnel](https://docs.pipewire.org/page_module_pipe_tunnel.html) adapts the receiving clock instead of treating raw network PCM as a finite audio file. Both endpoints use 48 kHz stereo. Software output gain is available up to 200% through Sound studio, badge scrolling and hardware volume keys. Spotify’s own volume remains 0–100%; output amplification is separate. Existing levels are preserved. Boost can clip already-loud recordings.

## Pen and USB recovery

Homie’s tablet is an XP-Pen Star G960S Plus, using OpenTabletDriver Artist Mode, pressure and rear eraser. Native stale tablet interfaces are disabled only after the virtual artist device exists. Mapping is applied after any driver reload recreates the virtual device. Drawing controls offer explicit **Pen** and **Eraser** recovery buttons; they target only the owned scratchpad.

On 20 October the VIA hub generated repeated `clear tt … error -71`. The old tablet stayed enumerated while producing no events. A targeted hub reauthorization cleared stale interfaces; moving the tablet to a rear motherboard port restored real tip/pressure events and the user confirmed drawing. That does not certify the hub’s electrical path. [Kernel USB documentation](https://docs.kernel.org/driver-api/usb/error-codes.html) explains why protocol errors alone cannot identify the failed cable, device, firmware or controller path. No whole-controller reset or permanent permission changes were made. Homie also installs `system/etc/udev/rules.d/80-den-via-hub-power.rules` into `/etc/udev/rules.d/`: only this VIA model stays awake instead of autosuspending. This is a reversible prevention measure, not proof of electrical repair. Remove that rule, reload udev and set the hub’s `power/control` to `auto` to undo it. Retesting tablet operation through the physical hub remains a separate check; rear-port operation is confirmed.

## Media and placement checks

YouTube resolution now prints selected yt-dlp fields rather than full format/storyboard inventories. Resolved URLs live only in a small 90-second memory cache; a failed stream gets one fresh resolution attempt. Thumbnails are square; the video retains its native aspect ratio.

Popup buttons publish their actual centre, output and bar edge at activation. Popup diagnostics are available through `qs ipc --pid PID call popup-OUTPUT state`; `scripts/check-popup-placement.py --pid PID --live` clicks real controls and restores the cursor and folds afterward.

The radio’s on-demand scope uses 512 FFT bins over 2.048 MHz, with peak hold and a scrolling waterfall. A real Homie capture measured 41 frames at 19.59 frames/s; stopping left no rtl_sdr child. Power is relative and uncalibrated. Wide-band five-second captures and saved receipts remain separate.
