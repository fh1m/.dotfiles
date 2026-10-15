# Two hosts, different jobs

| | Arete | Homie |
|---|---|---|
| Machine | ASUS ZenBook Pro Duo UX581GV | ASUS TUF B450M-PLUS GAMING desktop |
| CPU | Intel Core i7-9750H, 6 cores / 12 threads | AMD Ryzen 5 3600X, 6 cores / 12 threads |
| RAM | 16 GiB | 16 GiB, 2 × 8 GiB DDR4 |
| GPU | Intel display + RTX 2060 compute | GTX 1660 SUPER, 6 GiB, direct display |
| Built-in displays | 3840 × 2160 + 3840 × 1100 ScreenPad, scale 2 | — |
| Desk displays | Two MSI MP225, 1920 × 1080 at 100 Hz | LG 1920 × 1080 at 75 Hz |
| Network | Wired LAN; Wi-Fi fallback | Wired gigabit negotiated during this audit |
| Storage role | Portable work and learning | SATA system + data disks + preserved NVMe installations |

Both GPUs remain on separate hosts; this is not a pooled-memory GPU configuration. Distributed training is a future project, not a capability claimed by this deployment.

Homie has five physical drives: Dahua 256 GB system SSD, Transcend 120 GB Datasets SSD, Revenger 256 GB Windows SSD, Toshiba 1 TB Storage HDD, and WD_BLACK SN7100 1 TB NVMe with preserved installations. Six data filesystems are exposed through UUID-based automounts. Device letters are not stable identities.

SMART health reported passing on all five. Four completed short-test logs were clean; the Revenger's stored log was stale despite a completed current status, so it is not counted as a fifth verified clean log. The Transcend has historical CRC errors; monitor whether they increase. These observations are not a guarantee of drive health.

Native NVIDIA, CUDA/PyTorch, Docker CDI and NVENC checks have passed on Homie. Firmware boot reliability still needs physical unattended acceptance. Existing RAM firmware speed was 2133 MT/s despite 3200-rated modules; no DOCP change or overclock was performed.
