#!/usr/bin/env bash

case "$1" in
  mirror)
    xrandr --output DP-2 --mode 1920x1080 --primary \
           --output HDMI-0 --mode 1920x1080 --above DP-2
    ;;

  laptop)
    xrandr --output DP-1 --off \
           --output DP-2 --mode 1920x1080 --primary
    ;;

  720)
    xrandr --fb 1920x1080 \
           --output DP-2 --mode 1920x1080 --primary --pos 0x0 \
           --output HDMI-0 --mode 1280x720 --same-as DP-2 --scale-from 1920x1080
    ;;

  *)
    echo "Usage: $0 {mirror|laptop|720}"
    exit 1
    ;;
esac
