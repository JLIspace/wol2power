#!/bin/sh
set -eu

LED_GPIO=504 # Power LED (active-low: 1 = PC off)
BTN_GPIO=503 # Power button GPIO

LOCK=/tmp/wol-power.lock
STATEFILE=/tmp/wol-last-press
COOLDOWN=15 # Ignore presses within this time (seconds)

exec 9>"$LOCK"
flock -x 9 # Exclusive lock (one instance only)

now=$(date +%s)

last=0
if [ -f "$STATEFILE" ]; then
  last=$(cat "$STATEFILE" 2>/dev/null || echo 0)
fi

# Cooldown check
if [ $((now - last)) -lt "$COOLDOWN" ]; then
  echo "Recently pressed - ignoring"
  exit 0
fi

# If PC is already on, do nothing
STATE=$(cat /sys/class/gpio/gpio$LED_GPIO/value)
if [ "$STATE" != "1" ]; then
  echo "PC is already on - ignoring"
  exit 0
fi

# Save press time immediately
echo "$now" > "$STATEFILE"

# Press power button once
echo 1 > /sys/class/gpio/gpio$BTN_GPIO/value
sleep 0.6
echo 0 > /sys/class/gpio/gpio$BTN_GPIO/value

# Wait for LED to change (max 8s) while keeping lock
i=0
while [ $i -lt 40 ]; do
  STATE=$(cat /sys/class/gpio/gpio$LED_GPIO/value)
  [ "$STATE" != "1" ] && break
  sleep 0.2
  i=$((i+1))
done

echo "Power press done."
