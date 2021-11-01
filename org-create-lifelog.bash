#!/bin/bash
# Create a new lifelog for a given week in my Org repository.

### Setup

# shellcheck disable=SC2181

### Constants

# Target directory
default_target_dir="${HOME}/org"

# Target week's string (e.g. 2019-w31)
default_week_string=$(date +%Y-w%V)

### Functions

new_lifelog() {
  # Create a lifelog in a given directory for a given week.
  #  Arguments: target directory, week string (e.g. 2021-w44)
  #  Globals: none

  local target_dir=$1
  local week_string=$2
  local lifelog_path="${target_dir}/lifelog-${week_string}.org"

  echo "Creating new lifelog to ${lifelog_path}..."

  if [[ -f ${lifelog_path} ]]; then
    echo "[ERROR] The lifelog already exists!"
    echo "Exiting."
    exit 1
  fi

  declare -A weekdays
  weekdays=([1]=lun. [2]=mar. [3]=mer. [4]=jeu. [5]=ven. [6]=sam. [7]=dim.)

  cat >"${lifelog_path}" <<EOF
#+TITLE: Lifelog ${week_string}

$(for i in $(seq 7 -1 1); do
    day_number=$(date '+%u')
    offset=$((i - day_number))
    date=$(date -d "${offset} days" -I)
    weekday=${weekdays[$i]}
    org_date="* [${date} ${weekday}]"
    echo "${org_date}"
  done)
EOF

  if [[ $? -ne 0 ]]; then
    echo "[ERROR] Lifelog creation failed!"
    echo "Exiting."
    exit 1
  fi

  echo "Lifelog created successfully."
}

main() {
  # Wrapper around `new_lifelog'.
  #  Arguments: target directory, week string (e.g. 2021-w44)
  #  Globals: default_target_dir, default_week_string
  local target_dir=${1:-${default_target_dir}}
  local week_string=${2:-${default_week_string}}
  new_lifelog "${target_dir}" "${week_string}"
}

### Main

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
