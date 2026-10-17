# Engineering pass / research decisions

Read during the approved planning pass, 17 October 2026. This ledger records concrete uses, not a popularity ranking or a claim that inspiration proves an educational or emotional benefit.

| Source and evidence type | Useful finding / limitation | Applied decision |
|---|---|---|
| [Docker readiness](https://docs.docker.com/compose/how-tos/startup-order/), official | Container startup order alone does not establish application readiness | Separate configuration preflight from running/healthy claims; don't auto-launch from discovery |
| [Docker security](https://docs.docker.com/engine/security/), official | Daemon access is a consequential privilege | No arbitrary GUI commands, automatic permission fixes or implicit container deletion |
| [udev manual source](https://github.com/systemd/systemd/blob/main/man/udev.xml), primary implementation docs | Stable properties and transition events can identify devices independently of node numbering | Private passports; ambiguous matches explicit; event-driven inventory |
| [ROS topic statistics](https://repo.test.ros2.org/en/jazzy/Concepts/Intermediate/About-Topic-Statistics.html), official documentation mirror | Statistics require meaningful observed data and configuration | Bounded graph discovery is labelled discovery; zero nodes is not a healthy vehicle |
| [MCAP ROS guide](https://mcap.dev/guides/getting-started/ros-2), official | Explicit ROS bag storage plugin and topics | Probe installed Humble help, bound capture and verify actual recorded topic; preserve empty-fixture failures |
| [Qt ScrollView](https://doc.qt.io/qt-6/qml-qtquick-controls-scrollview.html), official | Viewport sizing and content sizing have separate contracts | Camera and engineering controls scroll within the real output height |
| [Quickshell IPC](https://quickshell.org/docs/v0.2.1/types/Quickshell.Io/IpcHandler/), official | Typed IPC can expose existing actions without a new server | Per-output action surfaces; backend remains the validator |
| [GNOME displays](https://help.gnome.org/gnome-help/display-dual-monitors.html), official UX reference | Arrange, apply and confirm with recovery | Integrated editor with watchdog rollback independent of QML |
| [RFC5545](https://www.rfc-editor.org/rfc/rfc5545.html), standard | Calendar identity and lifecycle matter beyond a displayed title | Source-qualified review IDs, no duplicate editable learning records; not a claim of a new full CalDAV implementation |
| [MLflow tracking](https://mlflow.org/docs/latest/ml/tracking/tracking-api), official API | Parameters, metrics and artifacts are distinct experiment concerns | Small structured receipt contract; do not require a tracking server for every shell run |
| [Human–AI interaction guidelines](https://www.microsoft.com/en-us/research/publication/guidelines-for-human-ai-interaction/), research | Context, correction and user control matter; not evidence that a mascot treats loneliness | Verified transitions, visible provenance, no inferred emotional state; quiet controls and no nagging |
| [wl_shimeji](https://github.com/CluelessCatBurger/wl_shimeji), project implementation | Existing Wayland desktop characters offer useful movement references | Preserve the existing lightweight Den renderer; don't introduce another always-on pet stack |
| [nwg-displays](https://github.com/nwg-piotr/nwg-displays), project implementation | Established graphical wlroots display tooling already exists | Keep it as recovery rather than reimplement its entire ecosystem |

Engineering inferences, verified locally: stable host-bound actions should be reused across launcher/panel/instrument/receipt cards; one serial queue is sufficient initially; Markdown knowledge, code and large recordings should keep their existing owners. These are design tradeoffs, not conclusions established by the research papers. Actual runtime checks and limitations are recorded in [the execution ledger](ENGINEERING-PASS.md).
