pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// CPU, memory and network counters for the bar. The HUD (step 5) reuses the
// per-thread figures, which come free from the same /proc/stat read.
Singleton {
    id: root

    // 0..100 across all threads.
    property real cpuPercent: 0
    // One 0..100 entry per thread, in /proc/stat order.
    property var cpuThreads: []

    property real memTotalKib: 0
    property real memUsedKib: 0
    readonly property real memTotalGib: memTotalKib / 1048576
    readonly property real memUsedGib: memUsedKib / 1048576
    readonly property real memPercent: memTotalKib > 0 ? memUsedKib / memTotalKib * 100 : 0

    // Seconds since boot. Cheap enough to keep running: the HUD footer and the
    // power menu both show it.
    property real uptimeSeconds: 0

    // Bytes per second.
    property real netRxRate: 0
    property real netTxRate: 0

    // Recent rates, oldest first. The bar sparkline takes the last 12 points and
    // the HUD's takes 13, so keep a little more than either needs.
    readonly property int netHistoryLength: 16
    property var netRxHistory: []
    property var netTxHistory: []

    // --- CPU ----------------------------------------------------------------
    // Previous cumulative jiffies, keyed by cpu line index (0 = aggregate).
    property var _cpuPrev: []

    FileView {
        id: statFile

        path: "/proc/stat"
        printErrors: false
        onLoaded: root._readCpu(text())
    }

    function _readCpu(contents: string): void {
        if (!contents)
            return;

        const rows = [];
        for (const line of contents.split("\n")) {
            if (!line.startsWith("cpu"))
                break;
            const parts = line.split(/\s+/);
            const nums = parts.slice(1).map(Number);
            // user nice system idle iowait irq softirq steal ...
            const idle = (nums[3] || 0) + (nums[4] || 0);
            let total = 0;
            for (const n of nums)
                total += n || 0;
            rows.push({
                idle,
                total
            });
        }
        if (rows.length === 0)
            return;

        const prev = _cpuPrev;
        if (prev.length === rows.length) {
            const usage = rows.map((row, i) => {
                const dTotal = row.total - prev[i].total;
                const dIdle = row.idle - prev[i].idle;
                if (dTotal <= 0)
                    return 0;
                return Math.max(0, Math.min(100, (dTotal - dIdle) / dTotal * 100));
            });
            cpuPercent = usage[0];
            cpuThreads = usage.slice(1);
        }
        _cpuPrev = rows;
    }

    // --- Memory -------------------------------------------------------------
    FileView {
        id: memFile

        path: "/proc/meminfo"
        printErrors: false
        onLoaded: {
            const contents = text();
            const total = contents.match(/MemTotal:\s+(\d+)/);
            const available = contents.match(/MemAvailable:\s+(\d+)/);
            if (!total || !available)
                return;
            root.memTotalKib = Number(total[1]);
            root.memUsedKib = Number(total[1]) - Number(available[1]);
        }
    }

    // --- Uptime -------------------------------------------------------------
    FileView {
        id: uptimeFile

        path: "/proc/uptime"
        printErrors: false
        onLoaded: {
            const value = parseFloat(text().split(" ")[0]);
            if (isFinite(value))
                root.uptimeSeconds = value;
        }
    }

    // --- Network ------------------------------------------------------------
    property real _rxPrev: -1
    property real _txPrev: -1
    property real _netStamp: 0

    property string netInterfaces: ""
    property bool netSampleValid: false
    Process {
        id: netSampler
        running: true
        command: ["/home/fh1m/.local/bin/sensei-net-sampler"]
        stdout: SplitParser { onRead: data => {
            try {
                const sample=JSON.parse(data);
                root.netRxRate=sample.rx;root.netTxRate=sample.tx;
                root.netInterfaces=sample.interfaces.join(" + ");root.netSampleValid=sample.valid;
                root.netRxHistory=root.netRxHistory.concat(sample.rx).slice(-root.netHistoryLength);
                root.netTxHistory=root.netTxHistory.concat(sample.tx).slice(-root.netHistoryLength);
                if(sample.interfaces.length)Machine.netInterface=sample.interfaces[0];
            } catch(e) {console.warn("Network sample",e);}
        } }
        onExited: netRetry.restart()
    }
    Timer {id:netRetry;interval:3000;onTriggered:netSampler.running=true}

    // --- Polling ------------------------------------------------------------
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            uptimeFile.reload();
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: memFile.reload()
    }
}
