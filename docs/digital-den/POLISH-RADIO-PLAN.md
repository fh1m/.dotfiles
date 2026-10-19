# Den media, motion and radio pass — 2026-10-20

Preserve shared main, private account state and input escape controls. No disk,
bootloader, credential-copy or unattended radio service changes.

1. [ ] Reproduce media failure; fix native overlay controls, bounded stream recovery,
   aspect ratio, immersive lyrics and hover-safe auto-hide.
2. [ ] Soften focus pulse; inspect cursor policy without taking input away.
3. [ ] Validate Zondo sprite boundaries and one-character presentation; smooth motion.
4. [ ] Verify widget output ownership and coalesced brightness on both hosts.
5. [ ] Configure Homie's detected XP-Pen 28bd:0918 and its existing drawing tools.
6. [ ] Install receiver tools for actual RTL2838 0bda:2838; bounded USB test and
   spectrum capture; useful themed Radio widget/button only with receiver present.
7. [ ] Validate on both machines, document measured limits, commit and deploy main.

Radio tool ownership: librtlsdr for hardware, Gqrx for real receiver/waterfall,
rtl_power for explicit bounded spectrum receipts, rtl_433 for explicit own-sensor
experiments. One receiver owner at a time; no background scans, bias-tee activation,
EEPROM writes, network listener or private-communication decoding.
