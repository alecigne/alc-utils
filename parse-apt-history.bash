#!/usr/bin/env bash
#
# Parse APT history so the lists of packages can be fed back to APT.

perl -pe 's/\(.*?\)(, )?//g' "/var/log/apt/history.log"
