#!/bin/bash
# Start a new week in my Org repository.

### Setup

# shellcheck disable=SC2181
script_dir="$(dirname "$(readlink -f "$0")")"
source "${script_dir}/org-create-lifelog.bash"

### Globals

# Program parameters
readonly opts=n
readonly longopts=new-lifelog

# Switch for creating a new lifelog
create_new_lifelog=false

# Target directory
readonly org_dir="${HOME}/org"

# Last week's date string (e.g. 2019-w30)
readonly last_week_date=$(date -d 'last week' +%G-w%V)

# This week's date string (e.g. 2019-w31)
readonly current_week_date=$(date +%G-w%V)

# Last week's lifelog
readonly prev_lifelog_name="lifelog-${last_week_date}.org"
readonly prev_lifelog="${org_dir}/${prev_lifelog_name}"

# Last week's encrypted lifelog
readonly prev_lifelog_name_gpg="${prev_lifelog_name}.gpg"
readonly prev_lifelog_gpg="${org_dir}/${prev_lifelog_name_gpg}"

### Functions

process_options() {
  # Process the program parameters and arguments.
  #  Arguments: none
  #  Globals:   opts, longopts, $0, $@

  local parsed_params
  if ! parsed_params=$(getopt --options=${opts} --longoptions=$longopts --name "$0" -- "$@"); then
    exit 2
  fi
  eval set -- "${parsed_params}"

  while true; do
    case "$1" in
    -n | --new-lifelog)
      create_new_lifelog=true
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Programming error"
      exit 3
      ;;
    esac
  done
}

encrypt_and_commit() {
  # Encrypt last week's lifelog and commit it in last week's Git branch.
  # Throw a warning if it doesn't exist and return.
  #  Arguments: none
  #  Globals:   org_dir, last_week_date, prev_lifelog, prev_lifelog_gpg

  if [[ ! -f ${prev_lifelog} ]]; then
    echo "[WARN] Last week's lifelog not found! [${prev_lifelog}]"
    echo "Skipping encryption and commit..."
    return
  fi

  if [[ -f ${prev_lifelog_gpg} ]]; then
    echo "[ERROR] The encrypted lifelog already exists! [${prev_lifelog_gpg}]"
    echo "Exiting."
    exit 1
  fi

  echo "-> Encrypting lifelog..."

  gpg -a -o "${prev_lifelog_gpg}" -e "${prev_lifelog}"

  if [[ $? -eq 0 ]]; then
    echo "Lifelog encrypted successfully. [${prev_lifelog_gpg}]"
  else
    echo "[ERROR] encryption failed!"
    echo "Exiting."
    exit 1
  fi

  echo "-> Committing lifelog on last week's branch..."

  local branch
  branch=$(git -C "${org_dir}" symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3)

  if [[ "${branch}" != "${last_week_date}" ]]; then
    echo "[ERROR] Can't commit on ${branch}: not last week's branch!"
    echo "Exiting."
    exit 1
  fi

  git -C "${org_dir}" add "${prev_lifelog_gpg}" && git -C "${org_dir}" commit -m "Ajout de ${prev_lifelog_name_gpg}"

  if [[ $? -eq 0 ]]; then
    echo "Encrypted lifelog committed successfully on ${branch}."
  else
    echo "[ERROR] Commit failed on branch ${branch}!"
    echo "Exiting."
    exit 1
  fi
}

merge_and_branch() {
  # Merge-squash last week's branch into master, tag the commit and create this week's branch.
  #  Arguments: none
  #  Globals:   org_dir, last_week_date, current_week_date

  echo "-> Creating squash commit on master..."
  git -C "${org_dir}" checkout master
  git -C "${org_dir}" merge --squash "${last_week_date}"
  git -C "${org_dir}" commit --allow-empty -m "Merge ${last_week_date}"

  echo "-> Tagging..."
  git -C "${org_dir}" tag "v${last_week_date}" HEAD

  echo "-> Creating a new branch for this week..."
  git -C "${org_dir}" checkout -b "${current_week_date}"
}

main() {
  # Prepare a new Org week.
  #  Arguments: none
  #  Globals:   org_dir, current_week_date
  process_options "$@"

  echo -e "\n##### Encryption and commit of last week's lifelog"
  encrypt_and_commit

  if [ "${create_new_lifelog}" = true ]; then
    echo -e "\n##### Creation of a new lifelog"
    new_lifelog "${org_dir}" "${current_week_date}"
  fi

  echo -e "\n##### Preparation of current week's branches"
  merge_and_branch
}

### Main

main "$@"
