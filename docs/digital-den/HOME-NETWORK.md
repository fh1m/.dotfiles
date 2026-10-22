# Home network · operate from evidence

## Layout and ownership

Sudo is the main router. fh1m and fh1m_5g are the two radios of the Cudy
repeater, not two independent internet connections. The owner reports a switch
uplink to the router, with Arete, Homie and other wired devices on the switch.
Keep this physical layout distinct from inferred routes: repeater/proxy ARP can
make several downstream devices appear under one MAC from upstream Wi-Fi.

Router login pages identify TP-Link TL-WR820N and Cudy RE1200. Hardware revisions,
router configuration, ISP subscription, switch model and exact repeater backhaul
remain unverified. Administrator passwords are currently unavailable; no reset,
firmware flash, DHCP, channel or household-wide setting was changed.

Neither computer bridges its LAN interfaces. Docker bridges have no physical
ports. A short packet sample found no storm; this does not rule out intermittent
loops elsewhere. Wi-Fi plus Ethernet alone does not form a bridge loop.

## Verified on Arete and Homie · 22 October 2026

- Arete's USB adapter is Realtek RTL8152, physically limited to 10/100 Ethernet.
  It negotiates 100 Mb/s full duplex. This is not a cable/driver gigabit fault.
- Homie negotiates 1000 Mb/s full duplex with its switch port. Both hosts have
  zero recorded RX errors; Homie also has zero TX errors/drops in this sample.
- AX200 Wi-Fi supports the repeater's 5 GHz connection. At the desk, observed
  signal was -39 dBm and RX PHY rate 780–866.7 Mb/s, 80 MHz. PHY rate is not
  application throughput or internet speed.
- Eight-MiB SSH transfers with compression and multiplex reuse disabled,
  explicit SO_BINDTODEVICE proxy, and counter verification: wired upload 82.8,
  download 82.6 Mb/s; 5 GHz upload 81.2, download 80.6 Mb/s. These include SSH
  startup and are short application tests, not iperf steady-state capacity.
  Earlier source-address/multiplexed SSH tests were discarded because counters
  showed the Ethernet connection had been reused.
- Homie ping from 5 GHz: five replies, zero loss, average 1.0 ms. Earlier direct
  Ethernet average 0.83 ms. Gateway and public-IP probes passed. 5 GHz HTTPS 200.
- Tailscale established a direct LAN path in ~1 ms. Fresh SSH over Homie's
  Tailscale IP passed using the existing trusted host alias/operator key.
  SSH and Tailscale are enabled on both hosts. Off-site internet traversal has
  not been tested by physically leaving this LAN in this pass.
- Local /24 host discovery was bounded and unauthenticated; it missed Homie
  despite successful SSH. Neighbour caches and ping scans are not complete
  router client inventories and must not award an "unknown device" alarm alone.

## Changes made now

Saved Wi-Fi preference: fh1m_5g priority 30, fh1m priority 20, Sudo priority 0.
NetworkManager selects this order when establishing an automatic connection;
it does not forcibly roam an already active working connection. Current profile
is fh1m_5g. Existing Ethernet metric 100 precedes Wi-Fi metric 600. Power save was
already off; no broad sysctl/TCP tuning, MTU changes or packet forwarding changes.

Previous preference values are saved privately in
`~/.local/state/den/network-audit/2026-10-22-wifi-priority-before.json`.
Restore with `nmcli connection modify NAME connection.autoconnect-priority VALUE`
using the recorded value. Connection profiles/keys stay outside Git.

The existing Ethernet/Wi-Fi Network Workbench now includes **Gateway admin** for
the selected interface. **Link / errors** reports a 100-Mb hardware ceiling or
negotiation below adapter maximum; Wi-Fi uses actual iw association/signal/rates
rather than ethtool's unsupported Ethernet report. Other existing controls:
connection profiles, gateway/public-IP checks, system DNS, trace path, explicit
ISP/ASN lookup, bounded LAN discovery and confirmed TCP probes. Scans never run
on refresh. No new always-on monitoring service was installed.

## Improvements in useful order

1. **Laptop-to-Homie speed:** a USB 3 gigabit (or 2.5-Gb if useful later) Ethernet
   adapter on a genuine USB 3 port, connected to the gigabit switch. The present
   RTL8152 cannot be made gigabit through software. Re-measure before buying a
   faster switch; Homie's link already proves at least one gigabit-capable port.
2. **Internet ceiling:** WR820N Ethernet ports are 100 Mb/s. If the ISP plan
   exceeds that, a gigabit-WAN router is required to use the subscribed speed.
   Confirm ISP upload/download and router hardware revision before purchasing.
3. **Access-point backhaul:** when a cable is available, use a proper wired AP
   rather than repeating the same 2.4-GHz radio. RE1200's own Ethernet port is
   100 Mb/s, so it remains capped even in AP mode. A gigabit dual-band AP is the
   path to faster Wi-Fi-to-Homie transfers. No unplanned repeater/AP conversion:
   confirm upstream cable and remove the redundant wireless backhaul first.
4. **Radio reliability:** Sudo and 2.4-GHz extender currently use channel 2 with
   40 MHz. Once admin access exists, assess airtime/interference over time and
   evaluate 20 MHz on 1/6/11 under legal local settings. A repeater must follow
   its uplink channel; don't independently force incompatible channels. Prefer
   the tested 5-GHz radio at the desk, retain 2.4 GHz for reach/IoT.
5. **Latency under load:** obtain ISP speeds and measure loaded WAN latency;
   only then evaluate SQM/CAKE on a capable gateway, sized to measured rates and
   router CPU. No evidence from this pass establishes bufferbloat. QoS on the
   laptop alone cannot manage the entire household WAN.
6. **Stable Den services:** reserve DHCP leases for Homie and other fixed
   services at the router after access is recovered. Keep router DHCP authoritative;
   do not run competing DHCP on Homie. Keep mDNS for LAN and verified Tailscale
   identity for away access. Avoid publicly exposing SSH, SMB or control APIs.
7. **Monitoring:** existing on-demand diagnostics first. If historical outages
   justify it, run Uptime Kuma on Homie with local durable storage and only a few
   checks: gateway, DNS, external HTTPS, SSH and chosen Den services. Homie powers
   off/dual-boots, so its absence must not take household internet or DNS down.
8. **Optional filtered DNS:** AdGuard Home is useful for logs/filtering, not an
   automatic speed boost. Pilot on one client first. Preserve local names and
   provide genuinely available DNS redundancy before router-wide rollout. Do not
   make sleeping/Windows-booted Homie the only household resolver.

## Router control and recovery checklist

A Wi-Fi password is not necessarily a router administrator password. Recover the
existing login from the owner's password manager/ISP paperwork or an authenticated
browser session, without exporting credentials. If unavailable, arrange an ISP
assisted recovery; factory reset is a separate planned outage requiring PPPoE/WAN,
VLAN, DHCP, Wi-Fi and remote-access settings first.

After authenticated access, export a configuration backup to private storage,
record hardware/firmware revisions, and inspect WAN negotiation, DHCP leases,
reservations, repeater mode/backhaul, radio channels/security, firmware support,
UPnP/port forwards, admin access policy and logs. Change one setting at a time;
retain a wired management path and a documented rollback. Never flash by model
name alone. Do not install OpenWrt until exact revision/support/resources are known.

## Reliability limits and follow-up acceptance

Two laptop interfaces share one router/ISP; this is link redundancy, not internet
redundancy. Carrier loss normally removes the wired route. An upstream outage
while Ethernet carrier stays up may not trigger failover, and Wi-Fi to the same
failed router cannot repair that outage. True WAN failover needs an independent
ISP/cellular uplink and a gateway with tested failure detection.

Next controlled checks: physical router/switch/repeater cable map; independent
WAN throughput/loaded latency; unplug/replug Ethernet while a disposable flow
runs; move away from both repeaters and reconnect; reboot Homie and verify its
share/job services; internet-down/local-LAN-up; router configuration restore.
These tests were not silently simulated on the owner's active household network.

## Sources behind the decisions

- NetworkManager preference/metric semantics:
  https://networkmanager.pages.freedesktop.org/NetworkManager/NetworkManager/nm-settings-nmcli.html
- TP-Link WR820N port/radio specifications:
  https://www.tp-link.com/ph/home-networking/wifi-router/tl-wr820n/
- Cudy RE1200 port/AP/repeater specifications:
  https://www.cudy.com/en-eu/products/re1200-1-0
- Intel channel/width guidance (not a substitute for local measurements):
  https://www.intel.com/content/www/us/en/support/articles/000058989/wireless/intel-killer-wi-fi-products.html
- SQM prerequisites, CPU cost and measurement-first setup:
  https://openwrt.org/docs/guide-user/network/traffic-shaping/sqm
- Tailscale direct/relayed connection distinction:
  https://tailscale.com/docs/reference/connection-types
- DHCP reservation behavior:
  https://www.tp-link.com/in/support/faq/182/
- Uptime Kuma upstream: https://github.com/louislam/uptime-kuma
- AdGuard Home setup/backup: https://adguard-dns.io/kb/adguard-home/getting-started/
- OpenWrt constrained-device warning:
  https://openwrt.org/supported_devices/432_warning

## Dropout investigation · same evening

At 19:11:55 the RTL8152 reported carrier off. At 19:12:17 the entire USB hub
and its audio/Ethernet children disconnected; the adapter re-enumerated one
second later. Further Ethernet carrier transitions occurred at 19:13:33,
19:15:39 and 19:15:48. Wired DHCP repeatedly timed out and the interface had no
carrier by 19:27. The owner could not confirm whether the hub/cable was moved.
This proves physical-link interruption, not whether its cause was intentional
unplugging, hub power, cable or switch port. Do not label it fixed by software.
The selected 5-GHz association had no recorded deauthentication after the
intentional band change; Wi-Fi carried the default route after wired failure.

A separate reproducible control-path defect was found: mDNS offered Homie's IPv6
link-local address first, while Homie's firewall explicitly dropped its SSH
traffic. IPv4 SSH worked. Short health-check deadlines could expire on the
blocked address and falsely report an available peer offline. Den's Arete→Homie
SSH calls now explicitly use IPv4; private SSH aliases also select that family.
Pinned host keys, authentication and firewall remain intact. No remote action
is replayed after an error. Fresh IPv4 authentication passed; five actual Den
status checks reported authenticated in approximately 0.1 seconds each.

Private backup: `~/.local/state/den/network-audit/2026-10-22-dropout-before/`.
Bounded probe log: `~/.local/state/den/network-audit/dropout-check-2026-10-22.jsonl`.
Regression tests assert IPv4 transport in both Den control and continuity paths.
No input-sharing service, compositor or system network service was restarted.

Remaining physical acceptance: confirm link LEDs, reseat the Ethernet lead,
try another switch port/cable and, if the whole hub resets without movement,
test its power/upstream connection. Preserve Wi-Fi while doing this. Recheck
DHCP and a sustained local transfer after carrier returns. Persistent carrier
loss is below the IP/DNS layer; changing DNS or installing a watchdog cannot
repair it. Separate cellular/WAN backup is needed for an actual ISP outage.
