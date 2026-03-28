#!/usr/bin/env bash

set -euo pipefail

SANDBOXES="${HOME}/etc/sandboxes"
BWRAP_HOME="/home/sandbox"
SANDBOX=""
PROJECT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--sandbox)
      SANDBOX="${SANDBOXES}/$2"
      shift 2
      ;;
    -p|--project)
      PROJECT="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

[[ -n "${SANDBOX}" ]] || { echo "Missing required --sandbox" >&2; exit 1; }
[[ -n "${PROJECT}" ]] || { echo "Missing required --project" >&2; exit 1; }

echo "SANDBOX is ${SANDBOX}, PROJECT is ${PROJECT}."
read -p "Run the sandbox? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

SANDBOX_HOME="${SANDBOX}/home"

mkdir -p ${SANDBOX_HOME}

PROFILE="${SANDBOX}/.sbx-profile"
BWRAP_EXTRA=()

if [[ -f "${PROFILE}" ]]; then
  source "${PROFILE}"
fi

SBX_ETC="${SANDBOX}/etc"

exec bwrap \
  --tmpfs /tmp \
  --dev /dev \
  --proc /proc \
  --unshare-uts \
  --hostname codex-sandbox \
  --die-with-parent \
  --ro-bind /bin /bin \
  --ro-bind /lib /lib \
  --ro-bind /lib64 /lib64 \
  --ro-bind /usr /usr \
  --ro-bind /etc/resolv.conf /etc/resolv.conf \
  --ro-bind /etc/hosts /etc/hosts \
  --ro-bind "${SBX_ETC}/passwd" /etc/passwd \
  --ro-bind "${SBX_ETC}/group" /etc/group \
  --ro-bind "${SBX_ETC}/nsswitch.conf" /etc/nsswitch.conf \
  --ro-bind /etc/ssl /etc/ssl \
  --ro-bind /usr/share/zoneinfo /usr/share/zoneinfo \
  --bind "${SANDBOX_HOME}" "${BWRAP_HOME}" \
  --setenv HOME "${BWRAP_HOME}" \
  --setenv USER sandbox \
  --setenv LOGNAME sandbox \
  "${BWRAP_EXTRA[@]}" \
  --bind "${PROJECT}" "${BWRAP_HOME}/${PROJECT}" \
  --chdir "${BWRAP_HOME}" \
  bash --noprofile --norc
