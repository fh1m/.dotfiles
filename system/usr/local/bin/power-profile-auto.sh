#!/bin/bash
online=$(cat /sys/class/power_supply/AC0/online 2>/dev/null)
if [ "$online" = "1" ]; then
    profile="performance"
else
    profile="balanced"
fi
busctl --system set-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile s "$profile"
