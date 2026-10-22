# Spock research ledger · 22 October 2026

Completed **120 targeted search queries**, submitted in 30 batches of four. This counts queries, not unique studies or fully read sources. Supplemental spot checks are not included in that count. Search results are discovery evidence; deployable claims below require upstream documentation or live tests. Primary documentation outranks community anecdotes. Some searches returned irrelevant, old or inaccessible material; those results do not establish a capability.

## Decisions informed by research

| Area | Finding / limitation | Design consequence | Primary reference |
|---|---|---|---|
| DNS filtering | Domain filtering cannot distinguish advertisements and wanted content hosted on the same domain. | One AdGuard Home instance; browser content blocking remains complementary. No universal ad-free claim. | [AdGuard FAQ](https://adguard-dns.io/kb/adguard-home/faq/) |
| DNS availability | Upstream fallback does not repair a dead Pi. Multiple resolvers can be used concurrently by clients. | Pilot first; distinguish strict filtering from fail-open internet. Two addresses on one Pi are not redundancy. | [AdGuard configuration](https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration) |
| Native DNS | Ubuntu resolved already owns loopback port 53. | Bind filtering DNS explicitly to selected LAN/Tailscale addresses; preserve OS resolver until verified. | [AdGuard setup](https://adguard-dns.io/kb/adguard-home/getting-started/) |
| Pi-hole alternative | Ubuntu/ARM deployment has supported prerequisites. | Valid alternative, not installed beside AdGuard on the same DNS port. | [Pi-hole prerequisites](https://docs.pi-hole.net/main/prerequisites/) |
| Radio UI | OpenWebRX supports browser audio/waterfalls and multiple SDR devices. | Reuse it for actual demodulation instead of writing another SDR application. | [OpenWebRX source](https://github.com/jketterl/openwebrx) |
| Sensor radio | rtl_433 supports ARM64 and many sensor protocols across several ISM bands. | Convert explicitly selected owned sensors to MQTT and engineering observations. | [rtl_433 source](https://github.com/merbanan/rtl_433) |
| Aircraft | readsb/tar1090 provide a purpose-built receiver/map. | Optional 1090 MHz mission; antenna and real reception required. | [readsb](https://github.com/wiedehopf/readsb), [tar1090](https://github.com/wiedehopf/tar1090) |
| Maritime | AIS-catcher has a built-in offline-capable browser viewer. | Useful underwater/maritime connection, but coverage must be measured at the actual location. | [AIS-catcher viewer](https://jvde-github.github.io/AIS-catcher-docs/configuration/output/web-viewer/) |
| Weather satellites | Legacy NOAA APT tutorials can refer to retired spacecraft. | Verify current satellite/transmitter status before scheduling any pass. No fake NOAA live feed. | [SatDump](https://docs.satdump.org/), [NOAA operations](https://www.ospo.noaa.gov/) |
| Remote access | Tailscale subnet routing needs forwarding, route approval and access policy; common LAN prefixes can overlap away from home. | Keep Spock as optional remote LAN gateway; avoid blindly accepting home routes on the home LAN. | [Subnet routers](https://tailscale.com/docs/features/subnet-routers) |
| ROS | Ubuntu 24.04 maps to ROS Jazzy ARM64 packages. | Keep Humble projects isolated; no assumption of transparent cross-distro ROS interoperability. | [ROS Jazzy Ubuntu](https://docs.ros.org/en/jazzy/Installation/Ubuntu-Install-Debs.html) |
| Telemetry | Mosquitto supports authentication and access control. | Local sensor/event bus with per-client topic ownership, not an anonymous shell/robot-command bus. | [Mosquitto](https://mosquitto.org/documentation/authentication-methods/) |
| Notifications | ntfy defaults can allow anonymous access; attachments/cache consume storage. | Private authenticated topics, disabled or tightly bounded attachments and short retention. | [ntfy configuration](https://docs.ntfy.sh/config/) |
| Monitoring | Gatus supports HTTP/TCP/DNS checks and memory/SQLite storage. Uptime Kuma has a richer interactive monitor UI. | One monitoring component, not a stack of overlapping dashboards; health supports useful missions rather than being the product. | [Gatus source](https://github.com/TwiN/gatus), [Uptime Kuma](https://github.com/louislam/uptime-kuma) |
| Reading | FreshRSS has feeds, APIs, OPML and access control. | Keep a research inbox available while Homie is in Windows; learned notes stay in Obsidian. | [FreshRSS](https://freshrss.github.io/FreshRSS/en/admins/03_Installation.html) |
| Dashboard | Glance supports feed/status aggregation and custom data views. | Optional browser view; do not replace existing Quickshell controls or repeat every bar button. | [Glance](https://github.com/glanceapp/glance) |
| History | Atuin supports a self-hosted sync server, with an additional database/configuration to maintain. | Optional private cross-host history; inspect installed version and privacy filters before selecting its database. | [Atuin setup](https://docs.atuin.sh/main/self-hosting/server-setup/) |
| Sync versus backup | Syncthing propagates deletions and modifications. | Small sync relay is optional; independent versioned off-device backup is mandatory for critical service state. | [Syncthing FAQ](https://docs.syncthing.net/users/faq.html) |
| Storage | Container logs, application databases, images and recordings can exhaust a 16 GB card. | Native compact binaries where practical; bounded logs; large artifacts go to Homie/external storage. | [Docker log rotation](https://docs.docker.com/engine/logging/drivers/json-file/), [journald](https://www.freedesktop.org/software/systemd/man/latest/journald.conf.html) |
| Heavy services | Immich/Jellyfin have significant RAM/storage/acceleration requirements. | Keep media transcoding, photo indexing and training on Homie; do not fill Spock to demonstrate activity. | [Immich requirements](https://docs.immich.app/install/requirements/), [Jellyfin hardware](https://jellyfin.org/docs/general/administration/hardware-selection/) |
| Multiarchitecture | Native ARM nodes can complement amd64 builds, but building consumes CPU/storage. | Short bounded ARM acceptance jobs, with heavy builds on Homie or cross-compilation. | [Docker build strategies](https://docs.docker.com/build/building/multi-platform/) |
| Recovery | Hardware watchdog is for an unresponsive system manager, not an unreachable router. | Do not reboot a healthy DNS/radio node merely because its gateway ignores ping. | [systemd watchdog](https://www.freedesktop.org/software/systemd/man/latest/systemd-system.conf.html) |

## Community evidence: inspiration, not guarantees

- [Pi 4 home lab / sensors](https://www.reddit.com/r/homelab/comments/1vlak99/raspberry_pi_4_homelab_nas_monitoring_air_quality/): one owner's experience combining always-on services and sensor experiments; uses external storage/UPS, so not an apples-to-apples resource promise for this SD-only Pi.
- [DNS/SD failure discussion](https://www.reddit.com/r/homelab/comments/zrtysf/): a concrete reminder that a tiny DNS service can still take the household offline when its storage fails; not an estimate of SD failure probability.
- [Pi-hole outage discussion](https://www.reddit.com/r/pihole/comments/1i3om84/): shows why query evidence and recovery testing matter; no claim that a restart diagnoses the cause.
- HN queries were included below, but mixed/weak search matches are not presented as HN consensus or attributed advice.

## Exact query record

1. **Pi health** — site.raspberrypi.com documentation computers raspberry pi 4 power supply undervoltage throttled

2. **Pi health** — site.raspberrypi.com documentation computers raspberry pi 4 gigabit ethernet

3. **Pi health** — site.raspberrypi.com documentation computers microSD wear logging

4. **Pi health** — site.freedesktop.org systemd RuntimeWatchdogSec watchdog reboot network

5. **Pi health** — site.netplan.readthedocs.io default routes metrics wifi ethernet

6. **DNS** — site.adguard-dns.io adguard home getting started systemd resolved port 53

7. **DNS** — site.docs.pi-hole.net prerequisites Raspberry Pi supported operating systems

8. **DNS** — site.adguard-dns.io adguard home configuration querylog retention

9. **DNS** — site.docs.pi-hole.net unbound recursive DNS guide

10. **DNS** — site.tailscale.com docs DNS nameservers split DNS override local

11. **availability** — site.github.com louislam uptime-kuma arm64 requirements storage

12. **availability** — site.github.com louislam uptime-kuma wiki notification ping DNS monitoring

13. **availability** — site.prometheus.io docs blackbox exporter probes

14. **availability** — site.oss.oetiker.ch smokeping latency packet loss

15. **availability** — site.github.com netdata netdata raspberry pi memory storage

16. **backups** — site.restic.readthedocs.io backup repository check restore retention

17. **backups** — site.borgbackup.readthedocs.io raspberry pi backup repository

18. **backups** — site.docs.syncthing.net users FAQ synchronization not backup

19. **backups** — site.raspberrypi.com documentation computers remote access backup

20. **backups** — site.freedesktop.org journald SystemMaxUse RuntimeMaxUse Storage volatile

21. **home automation** — site.home-assistant.io installation raspberrypi Raspberry Pi 4 storage SSD

22. **home automation** — site.home-assistant.io installation linux container requirements

23. **home automation** — site.zigbee2mqtt.io guide adapters raspberry pi MQTT

24. **home automation** — site.mosquitto.org documentation authentication access control persistence

25. **home automation** — site.nodered.org docs getting started raspberrypi

26. **robotics** — site.docs.ros.org humble Ubuntu 24.04 jazzy Raspberry Pi arm64

27. **robotics** — site.docs.ros.org jazzy Installation Ubuntu arm64

28. **robotics** — site.docs.ros.org jazzy discovery server Fast DDS

29. **robotics** — site.zenoh.io docs ROS2 bridge DDS raspberry pi

30. **robotics** — site.foxglove.dev docs bridge ROS2 websocket

31. **robotics evidence** — site.mcap.dev guides python robotics recording

32. **robotics evidence** — site.foxglove.dev docs self hosting data storage

33. **robotics evidence** — site.robotwebtools.github.io rosbridge security websocket

34. **robotics evidence** — site.micro.ros.org raspberry pi agent microcontroller

35. **robotics evidence** — site.docs.ros.org jazzy deployment security DDS network

36. **network tools** — site.tailscale.com docs subnet routers IP forwarding SNAT

37. **network tools** — site.tailscale.com docs subnet router high availability overlap

38. **network tools** — site.openwrt.org SQM bridge raspberry pi ethernet bottleneck

39. **network tools** — site.nlnetlabs.nl documentation unbound raspberry pi cache

40. **network tools** — site.ntop.org guides ntopng raspberry pi traffic monitoring limitations

41. **storage** — site.openmediavault.org Raspberry Pi SD card flashmemory plugin

42. **storage** — site.docs.paperless-ngx.com setup requirements arm64

43. **storage** — site.docs.immich.app install requirements RAM storage

44. **storage** — site.freshrss.github.io FreshRSS requirements raspberry pi

45. **storage** — site.github.com linkwarden linkwarden system requirements

46. **research reading** — site.freshrss.github.io documentation user query feeds

47. **research reading** — site.github.com RSS-Bridge rss-bridge supported bridges

48. **research reading** — site.changedetection.io self hosted Raspberry Pi browser memory

49. **research reading** — site.docs.karakeep.app installation requirements

50. **research reading** — site.wallabag.org self hosted requirements documentation

51. **developer tools** — site.forgejo.org docs installation arm64 system requirements

52. **developer tools** — site.docs.gitea.com installation database SQLite

53. **developer tools** — site.docs.atuin.sh self hosting server encryption

54. **developer tools** — site.docs.ntfy.sh install access control attachments retention

55. **developer tools** — site.gotify.net docs install authentication

56. **jobs** — site.docs.celeryq.dev Raspberry Pi workers queue memory

57. **jobs** — site.docs.github.com self hosted runners security persistent environments

58. **jobs** — site.woodpecker-ci.org docs arm64 agent

59. **jobs** — site.docs.docker.com build cloud cross compilation emulation arm64

60. **jobs** — site.docs.docker.com build building multi platform native nodes

61. **music fun** — site.music-assistant.io Raspberry Pi players requirements

62. **music fun** — site.github.com librespot-org librespot raspberry pi connect

63. **music fun** — site.mopidy.com documentation raspberry pi

64. **music fun** — site.snapcast.github.io documentation multiroom audio

65. **music fun** — site.docs.jellyfin.org hardware selection raspberry pi

66. **radio fun** — site.openwebrx.de raspberry pi requirements RTL SDR

67. **radio fun** — site.sdr-enthusiasts.gitbook.io ads-b raspberry pi docker ultrafeeder

68. **radio fun** — site.rtl-sdr.com raspberry pi readsb ADS-B antenna 1090

69. **radio fun** — site.satdump.org docs raspberry pi satellite decoding

70. **radio fun** — site.sigidwiki.com legality radio reception privacy

71. **network safety** — site.caddyserver.com docs automatic https internal local network

72. **network safety** — site.doc.traefik.io raspberry pi reverse proxy Docker socket security

73. **network safety** — site.tailscale.com docs serve HTTPS tailnet services

74. **network safety** — site.docs.docker.com engine security rootless firewall ufw

75. **network safety** — site.ubuntu.com server docs security automatic updates reboot

76. **Pi efficiency** — site.raspberrypi.com documentation configuration cooling throttling temperature

77. **Pi efficiency** — site.kernel.org zram admin guide writeback memory

78. **Pi efficiency** — site.freedesktop.org systemd resource-control MemoryMax CPUQuota

79. **Pi efficiency** — site.docs.docker.com configure logging drivers local json-file rotation

80. **Pi efficiency** — site.raspberrypi.com documentation raspberry pi 4 USB boot SSD

81. **human practices** — site.reddit.com r selfhosted raspberry pi services regret SD card

82. **human practices** — site.news.ycombinator.com Raspberry Pi home server DNS Pi hole outage

83. **human practices** — site.reddit.com r homelab raspberry pi 4 useful projects low power

84. **human practices** — site.news.ycombinator.com self hosting maintenance home lab

85. **human practices** — site.reddit.com r raspberry_pi creative useful projects home server

86. **dashboards** — site.gethomepage.dev installation configuration security

87. **dashboards** — site.homarr.dev docs installation requirements Raspberry Pi

88. **dashboards** — site.dashy.to docs requirements raspberry pi

89. **dashboards** — site.heimdall.site application dashboard requirements

90. **dashboards** — site.glanceapp.io documentation raspberry pi memory

91. **learning and fun** — site.kiwix.org raspberry pi offline library hotspot

92. **learning and fun** — site.kolibri.readthedocs.io raspberry pi installation

93. **learning and fun** — site.project-radiant.eu raspberry pi home lab citizen science

94. **learning and fun** — site.boinc.berkeley.edu raspberry pi arm64 science projects

95. **learning and fun** — site.raspberrypi.com news raspberry pi star trek projects

96. **resilience** — site.networkd-dispatcher.readthedocs.io network recovery reboot

97. **resilience** — site.freedesktop.org systemd networkd ConfigureWithoutCarrier IgnoreCarrierLoss

98. **resilience** — site.netplan.readthedocs.io critical optional routes metric

99. **resilience** — site.raspberrypi.com documentation vcgencmd get_throttled bitmask

100. **resilience** — site.ubuntu.com server docs openssh security ufw backups

101. **radio and filtering follow-up** — site.adguard-dns.io adguard home FAQ YouTube ads DNS blocking

102. **radio and filtering follow-up** — site.docs.pi-hole.net YouTube ads same domain DNS

103. **radio and filtering follow-up** — site.openwebrx.de Raspberry Pi 4 Ubuntu 24.04 packages RTL SDR

104. **radio and filtering follow-up** — site.github.com jketterl openwebrx raspberry pi 4 requirements

105. **radio and filtering follow-up** — site.triqqr.github.io rtl_433 supported devices MQTT

106. **radio and filtering follow-up** — site.github.com merbanan rtl_433 MQTT supported devices

107. **radio and filtering follow-up** — site.github.com wiedehopf readsb tar1090 raspberry pi

108. **radio and filtering follow-up** — site.sdr-enthusiasts.gitbook.io ultrafeeder single SDR receiver multiple services

109. **radio and filtering follow-up** — site.raspberrypi.com news software defined radio raspberry pi

110. **radio and filtering follow-up** — site.rtl-sdr.com NOAA 15 18 19 decommissioned 2025 APT

111. **radio and filtering follow-up** — site.wmo.int NOAA satellites APT decommissioned 2025

112. **radio and filtering follow-up** — site.satdump.org Meteor LRPT raspberry pi decoding

113. **radio and filtering follow-up** — site.github.com AIS-catcher AIS-catcher raspberry pi web viewer

114. **radio and filtering follow-up** — site.github.com rtl-airband RTL SDR raspberry pi

115. **radio and filtering follow-up** — site.esphome.io guides getting started MQTT home assistant

116. **radio and filtering follow-up** — site.docs.ros.org jazzy Raspberry Pi Ubuntu arm64

117. **radio and filtering follow-up** — site.docs.pi-hole.net clients fallback secondary DNS bypass blocking

118. **radio and filtering follow-up** — site.adguard-dns.io adguard home upstream fallback bootstrap DNS

119. **radio and filtering follow-up** — site.github.com AdguardTeam AdGuardHome arm64 release checksums

120. **radio and filtering follow-up** — site.news.ycombinator.com "rtl_433"

## Batch source trail

These are candidate sources returned for each four-query batch, not a claim that every query independently returned each source. Cached/versioned documentation must be checked against installed versions before deployment.

### Queries 1, 2, 3, 4

- [systemd-system.conf](https://www.freedesktop.org/software/systemd/man/256/systemd-user.conf.html)
- [Raspberry Pi computer hardware - Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html?hash=a6be966c70758bbcd9f5115c4096cf2c)
- [Raspberry Pi computer hardware - Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html?source=post_page-----192f9877df3----------------------)
- [systemd](https://freedesktop.org/software/systemd/man/latest/systemd.html)
- [Raspberry Pi computer hardware - Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html)
- [March](https://datasheets.raspberrypi.com/rpi4/raspberry-pi-4-datasheet.pdf)

### Queries 5, 6, 7, 8

- [Getting started | AdGuard DNS Knowledge Base](https://adguard-dns.io/kb/adguard-home/getting-started/)
- [Prerequisites - Pi-hole documentation](https://docs.pi-hole.net/main/prerequisites/?h=webserver)
- [FAQ · AdguardTeam/AdGuardHome Wiki · GitHub](https://github.com/AdguardTeam/AdGuardHome/wiki/FAQ/34d124e1c7700b4da1c838f96c45045f7d89b19d)
- [Getting Started · AdguardTeam/AdGuardHome Wiki · GitHub](https://github.com/AdguardTeam/AdGuardHome/wiki/Getting-Started/826151b5c0ed0fed255673e0645fb5140f3f6cb6)
- [Configuration · AdguardTeam/AdGuardHome Wiki · GitHub](https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration/3b27176bfcc752535f7e09582f880d11238716cf)
- [Configuration · AdguardTeam/AdGuardHome Wiki · GitHub](https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration)

### Queries 9, 10, 11, 12

- [unbound - Pi-hole documentation](https://docs.pi-hole.net/guides/unbound/)
- [DNS in Tailscale · Tailscale Docs](https://tailscale.com/docs/reference/dns-in-tailscale?q=split+dns)
- [Linux DNS configuration issue · Tailscale Docs](https://tailscale.com/docs/reference/messages/client/resolv-conf-overwritten)
- [uptime-kuma/README.md at master · louislam/uptime-kuma · GitHub](https://github.com/louislam/uptime-kuma/blob/master/README.md?plain=1)
- [DNS problems with internal services and DNS rebinding protection · Tailscale Docs](https://tailscale.com/docs/reference/faq/dns-rebinding)
- [This was last updated on December 28, 2021.](https://www.electrical-forensics.com/Linux/unbound_pdf/unbound_Pi-hole_documentation.pdf)

### Queries 13, 14, 15, 16

- [SmokePing - About SmokePing](https://oss.oetiker.ch/smokeping/)
- [SmokePing Latency Page for](https://smokeping.oetiker.ch/?target=_charts)
- [netdata/README.md at master · netdata/netdata · GitHub](https://github.com/netdata/netdata/blob/master/README.md?plain=1)
- [SmokePing - Reading the Graphs](https://smokeping.org/smokeping/doc/reading.en.html)
- [Understanding and using the multi-target exporter pattern | Prometheus](https://prometheus.io/docs/guides/multi-target-exporter/)
- [restic/doc/faq.rst at master · restic/restic · GitHub](https://github.com/restic/restic/blob/master/doc/faq.rst)

### Queries 17, 18, 19, 20

- [FAQ — Syncthing documentation](https://docs.syncthing.net/users/faq)
- [journald.conf](https://www.freedesktop.org/software/systemd/man/247/journald.conf.html)
- [systemd-journald.service](https://www.freedesktop.org/software/systemd/man/261/systemd-journald.html)
- [FAQ — Syncthing documentation](https://docs.syncthing.net/users/faq.html?highlight=symbolic)
- [Configuration - Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/computers/configuration.html?userCode=ahxhg8oc)
- [FAQ](https://docs.syncthing.net/pdf/FAQ.pdf)

### Queries 21, 22, 23, 24

- [Supported Adapters | Zigbee2MQTT](https://www.zigbee2mqtt.io/guide/adapters/)
- [Raspberry Pi - Home Assistant](https://www.home-assistant.io/installation/raspberrypi)
- [Getting started | Zigbee2MQTT](https://www.zigbee2mqtt.io/guide/getting-started/)
- [Adapter settings | Zigbee2MQTT](https://www.zigbee2mqtt.io/guide/configuration/adapter-settings.html)
- [Authentication methods | Eclipse Mosquitto](https://mosquitto.org/documentation/authentication-methods/)
- [GitHub - home-assistant/operating-system: :beginner: Home Assistant Operating System · GitHub](https://github.com/home-assistant/operating-system)

### Queries 25, 26, 27, 28

- [Running on Raspberry Pi : Node-RED](https://nodered.org/docs/getting-started/raspberrypi)
- [Getting Started : Node-RED](https://nodered.org/docs/getting-started/)
- [Install Ubuntu on the Raspberry Pi - Project documentation](https://ubuntu.com/hardware/docs/boards/how-to/ubuntu_supported/raspberry-pi/)
- [Running Node-RED locally : Node-RED](https://nodered.org/docs/getting-started/local)
- [Ubuntu (deb packages) — ROS 2 Documentation: Jazzy documentation](https://repo.test.ros2.org/en/jazzy/Installation/Ubuntu-Install-Debs.html)
- [Ubuntu 24.04 & ROS2 Jazzy Installation Guide](https://hcr.cs.umass.edu/courses/compsci603/projects/Compsci_603_Project0_Preparation_ROS2.pdf)

### Queries 29, 30, 31, 32

- [Foxglove Bridge | Foxglove Docs](https://docs.foxglove.dev/docs/fleet/bridge)
- [Storage mode | Foxglove Docs](https://docs.foxglove.dev/docs/data/primary-sites/storage-mode)
- [Live | Foxglove Docs](https://docs.foxglove.dev/docs/visualization/connecting/live)
- [Introduction | MCAP](https://mcap.dev/guides)
- [Pricing | Foxglove](https://www.foxglove.dev/pricing)
- [Foxglove Cloud, bring your own storage | Foxglove Docs](https://docs.foxglove.dev/docs/data/primary-sites/foxglove-managed-setup)

### Queries 33, 34, 35, 36

- [Site-to-site networking · Tailscale Docs](https://tailscale.com/docs/features/site-to-site)
- [Deployment Guidelines — ROS 2 Documentation: Jazzy documentation](https://repo.test.ros2.org/en/jazzy/Tutorials/Advanced/Security/Deployment-Guidelines.html)
- [ROSBridge Guide - 3we Robot Platform](https://docs.3we.org/rosbridge_guide/)
- [Route traffic · Tailscale Docs](https://tailscale.com/docs/route)
- [Raspberry Pi - RosFit Docs](https://docs.rosfit.dev/raspberry-pi)
- [How to use secure websocket (wss) in rosbridge websocket server? · RobotWebTools rosbridge_suite · Discussion #759 · GitHub](https://github.com/RobotWebTools/rosbridge_suite/discussions/759)

### Queries 37, 38, 39, 40

- [Set up high availability · Tailscale Docs](https://tailscale.com/kb/1115/subnet-failover/)
- [Troubleshoot overlapping subnet route failover · Tailscale Docs](https://tailscale.com/docs/reference/troubleshooting/network-configuration/overlapping-subnet-route-failover)
- [ntopng – ntop](https://www.ntop.org/products/traffic-analysis/ntopng/)
- [Command Line Options — ntopng v.7.1.261018 documentation](https://ntop.org/guides/ntopng/cli_options/cli_options.html)
- [Unbound by NLnet Labs — Unbound 1.25.2 documentation](https://unbound.docs.nlnetlabs.nl/)
- [Unbound User Manual](https://unbound.docs.nlnetlabs.nl/_/downloads/en/latest/pdf/)

### Queries 41, 42, 43, 44

- [Requirements | Immich](https://docs.immich.app/install/requirements/)
- [Quick start | Immich](https://docs.immich.app/overview/quick-start/)
- [Setup - Paperless-ngx](https://docs.paperless-ngx.com/setup/)
- [Immich User Guide](https://doccompiler.ai/api/v1/jobs/shared/job_1776317887818_52fe0208/download/immich-app__immich__UserGuide.pdf)
- [FAQs - Paperless-ngx](https://docs.paperless-ngx.com/faq/)
- [FAQ | Immich](https://docs.immich.app/FAQ/)

### Queries 45, 46, 47, 48

- [docs/docs/self-hosting/setup.md at main · linkwarden/docs · GitHub](https://github.com/linkwarden/docs/blob/main/docs/self-hosting/setup.md)
- [User queries · FreshRSS](https://freshrss.github.io/FreshRSS/en/users/user_queries.html)
- [Linkwarden — Bookmarks and web archives on your own server](https://fossary.com/apps/linkwarden)
- [rss-bridge/README.md at master · RSS-Bridge/rss-bridge · GitHub](https://github.com/RSS-Bridge/rss-bridge/blob/master/README.md?plain=1)
- [Releases · RSS-Bridge/rss-bridge · GitHub](https://github.com/RSS-Bridge/rss-bridge/releases)
- [  * AlfaBankByBridge](https://www.alfabank.by) (#2349)

### Queries 49, 50, 51, 52

- [Self-host wallabag](https://wallabag.org/self-hosting/)
- [Requirements – wallabag documentation](https://doc.wallabag.org/admin/installation/requirements/)
- [Minimal Installation | Karakeep](https://docs.karakeep.app/installation/minimal-install/)
- [Installation | Forgejo – Beyond coding. We forge.](https://forgejo.org/docs/latest/admin/installation/)
- [Installation from binary | Gitea Documentation](https://docs.gitea.com/installation/install-from-binary/)
- [Forgejo](https://forgejo.org/download/)

### Queries 53, 54, 55, 56

- [Configuration - ntfy](https://docs.ntfy.sh/config/?h=access)
- [Server Setup - Atuin Docs](https://docs.atuin.sh/main/self-hosting/server-setup/)
- [Sending messages - ntfy](https://docs.ntfy.sh/publish/)
- [Installation - ntfy](https://docs.ntfy.sh/install/)
- [Configuration and defaults — Celery 5.6.3 documentation](https://docs.celeryq.dev/en/stable/userguide/configuration.html)
- [Optimizing — Celery 5.7.0rc1 documentation](https://docs.celeryq.dev/en/main/userguide/optimizing.html)

### Queries 57, 58, 59, 60

- [Multi-platform builds | Docker Docs](https://docs.docker.com/build/building/multi-platform/)
- [Agent | Woodpecker CI](https://woodpecker-ci.org/docs/administration/configuration/agent)
- [docs/content/actions/reference/security/secure-use.md at main · github/docs · GitHub](https://github.com/github/docs/blob/main/content/actions/reference/security/secure-use.md)
- [Security for self-managed runners | GitLab Docs](https://docs.gitlab.com/runner/security/)
- [Self-hosted runners reference - GitHub Docs](https://docs.github.com/en/actions/reference/runners/self-hosted-runners)
- [docs/content/admin/enforcing-policies/enforcing-policies-for-your-enterprise/enforcing-policies-for-github-actions-in-your-enterprise.md at main · github/docs · GitHub](https://github.com/github/docs/blob/main/content/admin/enforcing-policies/enforcing-policies-for-your-enterprise/enforcing-policies-for-github-actions-in-your-enterprise.md)

### Queries 61, 62, 63, 64

- [Raspberry Pi - Mopidy](https://docs.mopidy.com/stable/guides/raspberrypi/)
- [Installation - Music Assistant](https://www.music-assistant.io/installation/)
- [GitHub - snapcast/snapcast: Synchronous multiroom audio player · GitHub](https://github.com/Snapcast/snapcast)
- [GitHub - snapcast/snapcast: Synchronous multiroom audio player · GitHub](https://github.com/snapcast/snapcast)
- [System packages - Mopidy](https://docs.mopidy.com/latest/installation/packages/)
- [Mopidy - Mopidy](https://docs.mopidy.com/)

### Queries 65, 66, 67, 68

- [Hardware Selection | Jellyfin](https://jellyfin.org/docs/general/administration/hardware-selection/)
- [GitHub - sdr-enthusiasts/docker-adsb-ultrafeeder: ADSB-Ultrafeeder is an all-in-one ADSB container with readsb, tar1090, graphs1090, autogain, multi-feeder, and mlat-hub built in · GitHub](https://github.com/sdr-enthusiasts/docker-adsb-ultrafeeder)
- [Build an ADS-B Receiver: Raspberry Pi and RTL-SDR · N4LLZ](https://n4llz.com/guides/adsb-receiver)
- [RTL-SDR Tutorial: Cheap ADS-B Aircraft RADAR](https://www.rtl-sdr.com/adsb-aircraft-radar-with-rtl-sdr/)
- [Prepare the Application Environment | ADS-B Reception, Decoding & Sharing with Docker](https://sdr-enthusiasts.gitbook.io/ads-b/foundations/prepare-the-project-environment)
- [Hardware Acceleration | Jellyfin](https://jellyfin.org/docs/general/post-install/transcoding/hardware-acceleration/)

### Queries 69, 70, 71, 72

- [Automatic HTTPS — Caddy Documentation](https://caddyserver.com/docs/automatic-https?trk=public_post_comment-text)
- [HTTPS quick-start — Caddy Documentation](https://caddyserver.com/docs/quick-starts/https)
- [Global options (Caddyfile) — Caddy Documentation](https://caddyserver.com/docs/caddyfile/options)
- [Docker | Traefik | v1.7](https://doc.traefik.io/traefik/v1.7/configuration/backends/docker/)
- [SatDump: SatDump](https://docs.satdump.org/)
- [Caddy - The Ultimate Server with Automatic HTTPS](https://caddyserver.com/?trk=public_post_main-feed-card-text)

### Queries 73, 74, 75, 76

- [Automatic updates - Ubuntu Server documentation](https://ubuntu.com/server/docs/how-to/software/automatic-updates/)
- [Rootless mode | Docker Docs](https://docs.docker.com/engine/security/rootless/)
- [Security updates - Ubuntu security documentation](https://documentation.ubuntu.com/security/security-updates/)
- [tailscale serve command · Tailscale Docs](https://tailscale.com/docs/reference/tailscale-cli/serve)
- [Docker Engine security | Docker Docs](https://docs.docker.com/engine/security/)
- [Enabling HTTPS · Tailscale Docs](https://tailscale.com/docs/how-to/set-up-https-certificates)

### Queries 77, 78, 79, 80

- [JSON File logging driver | Docker Docs](https://docs.docker.com/engine/logging/drivers/json-file/)
- [zram: Compressed RAM-based block devices — The Linux Kernel documentation](https://docs.kernel.org/admin-guide/blockdev/zram.html)
- [Raspberry Pi computer hardware - Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html)
- [zram: Compressed RAM-based block devices — The Linux Kernel documentation](https://www.kernel.org/doc/html/v7.2/admin-guide/blockdev/zram.html)
- [systemd.resource-control](https://www.freedesktop.org/software/systemd/man/249/systemd.resource-control.html)
- [Raspberry Pi computer hardware - Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html?hash=a6be966c70758bbcd9f5115c4096cf2c)

### Queries 81, 82, 83, 84

- [Raspberry Pi 4 homelab — NAS, monitoring, air quality, Grafana and a bunch of experiments](https://www.reddit.com/r/homelab/comments/1vlak99/raspberry_pi_4_homelab_nas_monitoring_air_quality/)
- [My Pi 4 started as a server and slowly became my home monitoring system](https://www.reddit.com/r/raspberry_pi/comments/1vlar0q/my_pi_4_started_as_a_server_and_slowly_became_my/)
- [My tiny homelab](https://www.reddit.com/r/minilab/comments/1r5q6ie/my_tiny_homelab/)
- [My first Homelab](https://www.reddit.com/r/homelab/comments/1w258uf/my_first_homelab/)
- [How to utilise 4 rpis](https://www.reddit.com/r/selfhosted/comments/1s9vtzx/how_to_utilise_4_rpis/)
- [Raspberry Pi requirments for homelabbing](https://www.reddit.com/r/homelab/comments/1u390wq/raspberry_pi_requirments_for_homelabbing/)

### Queries 85, 86, 87, 88

- [Getting started | Homarr documentation](https://homarr.dev/docs/getting-started/)
- [homepage/docs/installation/index.md at dev · gethomepage/homepage · GitHub](https://github.com/gethomepage/homepage/blob/dev/docs/installation/index.md)
- [Frequently Asked Questions | Homarr documentation](https://homarr.dev/docs/community/faq/)
- [Prerequisites | Homarr documentation](https://homarr.dev/docs/1.41.0/getting-started/)
- [Configuration - Homepage](https://gethomepage.dev/configs/)
- [Installation | gethomepage/homepage | DeepWiki](https://deepwiki.com/gethomepage/homepage/3-installation-guide)

### Queries 89, 90, 91, 92

- [Install Kolibri - Kolibri User Guide](https://kolibri.readthedocs.io/en/latest/install/)
- [Heimdall Application Dashboard](https://heimdall.site/docs)
- [GitHub - SRM9506/pi-survival-server: Offline-first Raspberry Pi survival server — Kiwix knowledge base, survival document library, offline maps, and a self-hosted WiFi hotspot for zero-internet emergency access. · GitHub](https://github.com/SRM9506/pi-survival-server)
- [GitHub - reidwallace/prepperpi: Offline knowledge server for Raspberry Pi — Wi-Fi hotspot with Kiwix, web UI, and manual/automatic update options. · GitHub](https://github.com/reidwallace/prepperpi)
- [Kiwix - Hotspots](https://get.kiwix.org/en/solutions/hotspots/)
- [Kolibri User Guide](https://app.readthedocs.org/projects/kolibri/downloads/pdf/release-v0.13.x/)

### Queries 93, 94, 95, 96

- [News - Raspberry Pi](https://www.raspberrypi.com/news/)
- [Choosing BOINC projects](https://www.boinc.org/projects.php)
- [Download BOINC client software for Linux (x64 and ARM64)](https://boinc.berkeley.edu/download_all.php?platform=linuxx64)
- [Install BOINC](https://boinc.ssl.berkeley.edu/download.php)
- [OpenBSD/arm64](https://www.openbsd.org/arm64.html)
- [Raspberry Pi Projects - Projects to Make with Raspberry Pi](https://www.raspberrypi.com/resources/make/)

### Queries 97, 98, 99, 100

- [systemd.network](https://freedesktop.org/software/systemd/man/latest/systemd.network.html)
- [systemd.network](https://www.freedesktop.org/software/systemd/man/latest/systemd.network.html)
- [Raspberry Pi OS - Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/usage/c/raspberry-pi.html)
- [OpenSSH server - Ubuntu Server documentation](https://ubuntu.com/server/docs/how-to/security/openssh-server/)
- [Version:](https://data.engrie.be/RaspberryPi/Raspberry_Pi_-_Part_01_-_Gather_Information-Hardware.pdf)
- [How to Benchmark a Raspberry Pi Using Vcgencmd | Tom's Hardware](https://www.tomshardware.com/how-to/raspberry-pi-benchmark-vcgencmd)

### Queries 101, 102, 103, 104

- [Supported Hardware - jketterl/openwebrx GitHub Wiki](https://github-wiki-see.page/m/jketterl/openwebrx/wiki/Supported-Hardware)
- [FAQ · AdguardTeam/AdGuardHome Wiki · GitHub](https://github.com/AdguardTeam/AdGuardHome/wiki/FAQ/e16675d08a036ae40bfae311564e01e888b91b71)
- [openwebrx/README.md at develop · jketterl/openwebrx · GitHub](https://github.com/jketterl/openwebrx/blob/develop/README.md)
- [Setup Guide - jketterl/openwebrx GitHub Wiki](https://github-wiki-see.page/m/jketterl/openwebrx/wiki/Setup-Guide)
- [Install Ubuntu on the Raspberry Pi - Project documentation](https://ubuntu.com/hardware/docs/boards/how-to/ubuntu_supported/raspberry-pi/)
- [Getting Started using Docker - jketterl/openwebrx GitHub Wiki](https://github-wiki-see.page/m/jketterl/openwebrx/wiki/Getting-Started-using-Docker)

### Queries 105, 106, 107, 108

- [Releases · merbanan/rtl_433 · GitHub](https://github.com/merbanan/rtl_433/releases)
- [GitHub - wiedehopf/readsb: ADS-B decoder swiss knife · GitHub](https://github.com/wiedehopf/readsb)
- [wiedehopf · GitHub](https://github.com/wiedehopf)
- [readsb/README.md at dev · wiedehopf/readsb · GitHub](https://github.com/wiedehopf/readsb/blob/dev/README.md)
- [Install readsb on Raspberry Pi: ADS-B Decoder Setup — AvioADSB Docs](https://avioadsb.org/docs/blog/2026-10-11-readsb-install-raspberry-pi)
- [GitHub - jpluimers/wiedehopf.readsb: ADS-B decoder swiss knife · GitHub](https://github.com/jpluimers/wiedehopf.readsb)

### Queries 109, 110, 111, 112

- [APT](https://www.rtl-sdr.com/tag/apt/)
- [WXSAT FREQUENCIES](https://leshamilton.co.uk/satfreq.htm)
- [The End of APT - McBainsite](https://mcbainsite.co.uk/the-end-of-apt/)
- [Packages Noaa Apt - Renegade-Penguin/Hammunition GitHub Wiki](https://github-wiki-see.page/m/Renegade-Penguin/Hammunition/wiki/Packages-Noaa-Apt)
- [MeshSat — Autonomous Satellite Reception on Raspberry Pi](https://www.meshsat.info/)
- [Automating weather satellite reception with SatDump's CLI | Jacopo's Wonderland](https://a-centauri.com/articoli/automating-satellite-reception-with-satdump-cli)

### Queries 113, 114, 115, 116

- [Web Viewer - AIS-catcher Docs](https://jvde-github.github.io/AIS-catcher-docs/configuration/output/web-viewer/)
- [Install Ubuntu on the Raspberry Pi - Project documentation](https://ubuntu.com/hardware/docs/boards/how-to/ubuntu_supported/raspberry-pi/)
- [ROS 2 on Raspberry Pi — ROS 2 Documentation: Jazzy documentation](https://repo.test.ros2.org/en/jazzy/How-To-Guides/Installing-on-Raspberry-Pi.html)
- [Native ROS 2 Jazzy Debian packages for Raspberry Pi OS / Debian Trixie (arm64) - ROS General - Open Robotics Discourse](https://discourse.openrobotics.org/t/native-ros-2-jazzy-debian-packages-for-raspberry-pi-os-debian-trixie-arm64/51965)
- [Installation · rtl-airband/RTLSDR-Airband Wiki · GitHub](https://github.com/rtl-airband/RTLSDR-Airband/wiki/Installation)
- [GitHub - rtl-airband/RTLSDR-Airband: Multichannel AM/NFM demodulator · GitHub](https://github.com/rtl-airband/RTLSDR-Airband)

### Queries 117, 118, 119, 120

- [Configuration · AdguardTeam/AdGuardHome Wiki · GitHub](https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration/3b27176bfcc752535f7e09582f880d11238716cf)
- [Possible DNS leaks | AdGuard Knowledge Base](https://adguard.com/kb/archive/adguard-for-windows/solving-problems/dns-leaks/)
- [Releases · AdguardTeam/AdGuardHome · GitHub](https://github.com/AdguardTeam/AdGuardHome/releases?after=v0.107.0-b.4)
- [Enable Network-Wide DNS Blocking with Pi-hole | Edward Angert](https://edwardangert.com/docs/pi-hole/network-level-blocking/)
- [AdGuard Home – setup guide](https://sergeibabko.github.io/AdGuard-Home-Setup-Guide/)
- [#7842 The Boostrap DNS servers are ignored on AdGuard Home when resolving the Fallback DNS servers · AdGuardHome | baike.dev](https://baike.dev/en/tools/adguardteam-adguardhome/issues/7842)
