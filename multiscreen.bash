#!/usr/bin/env bash

usage() {
  echo "Usage: $(basename "$0") {extend|laptop|mirror|diagnose}"
}

diagnose() {
  local displays

  if ! displays=$(xrandr --query 2>&1); then
    echo "Unable to query displays with xrandr:" >&2
    echo "$displays" >&2
    return 1
  fi

  echo "Connected displays:"
  awk '
    $2 == "connected" {
      role = $1 == "DP-2" ? "laptop" : ($1 == "HDMI-0" ? "external" : "other")
      primary = $3 == "primary"
      geometry = primary ? $4 : $3
      if (geometry !~ /^[0-9]+x[0-9]+\+/) geometry = "not active"
      printf "  %-8s %-10s %s%s\n", $1, "(" role ")", geometry,
             primary ? " [primary]" : ""
      found = 1
    }
    END {
      if (!found) print "  No connected displays found."
    }
  ' <<< "$displays"
}

case "${1:-}" in
  extend)
    xrandr --fb 1920x2160 \
           --output DP-2 --mode 1920x1080 --primary --pos 0x1080 \
           --output HDMI-0 --mode 1920x1080 --pos 0x0 --transform none
    ;;

  laptop)
    xrandr --fb 1920x1080 \
           --output HDMI-0 --off \
           --output DP-2 --mode 1920x1080 --primary --pos 0x0
    ;;

  mirror)
    xrandr --fb 1920x1080 \
           --output DP-2 --mode 1920x1080 --primary --pos 0x0 \
           --output HDMI-0 --mode 1280x720 --same-as DP-2 --scale-from 1920x1080
    ;;

  diagnose)
    diagnose
    ;;

  *)
    usage
    exit 1
    ;;
esac
