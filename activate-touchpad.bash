#!/bin/bash
#
# Activate the touchpad.

xinput set-prop "$(xinput --list | grep -i 'Touchpad' | grep -oP 'id=\K\d+')" "libinput Tapping Enabled" 1
