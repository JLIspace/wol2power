#!/bin/sh
set -eu

LED_GPIO=504     # Power-LED
BTN_GPIO=503     # Power-Button

STATE=$(cat /sys/class/gpio/gpio$LED_GPIO/value)

# Active-Low: 1 = PC off
if [ "$STATE" != "1" ]; then
  echo "PC already ON — ignoring"
  exit 0
fi

# press power button
echo 1 > /sys/class/gpio/gpio$BTN_GPIO/value
sleep 1
echo 0 > /sys/class/gpio/gpio$BTN_GPIO/value
