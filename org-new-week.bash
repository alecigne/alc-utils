#!/bin/bash
#
# Start a new week in my Org repository.
# shellcheck disable=SC2181

### Variables

# Target directory
ORG_DIR="${HOME}/org"

# Last week's date string (e.g. 2019-w30)
LAST_WEEK_DATE=$(date -d 'last week' +%Y-w%V)

# This week's date string (e.g. 2019-w31)
CURRENT_WEEK_DATE=$(date +%Y-w%V)

# Last week's lifelog
PREV_LIFELOG_NAME="lifelog-${LAST_WEEK_DATE}.org"
PREV_LIFELOG="${ORG_DIR}/${PREV_LIFELOG_NAME}"

# Last week's encrypted lifelog
PREV_LIFELOG_NAME_GPG="${PREV_LIFELOG_NAME}.gpg"
PREV_LIFELOG_GPG="${ORG_DIR}/${PREV_LIFELOG_NAME_GPG}"

# Next lifelog
NEXT_LIFELOG_NAME="lifelog-${CURRENT_WEEK_DATE}.org"
NEXT_LIFELOG="${ORG_DIR}/${NEXT_LIFELOG_NAME}"

### Functions

###
# Description:
#   Encrypt last week's lifelog and commit it in last week's Git branch.
# Globals:
#   PREV_LIFELOG, PREV_LIFELOG_GPG
# Arguments:
#   None
encrypt_and_commit() {
  if [[ ! -f ${PREV_LIFELOG} ]]; then
    echo "WARNING - last week's lifelog not found! [${PREV_LIFELOG}]"
    echo "Skipping encryption and commit..."
    return
  fi

  if [[ -f ${PREV_LIFELOG_GPG} ]]; then
    echo "ERROR - the encrypted lifelog already exists! [${PREV_LIFELOG_GPG}]"
    echo "Exiting."
    exit 1
  fi

  echo "-> Encrypting lifelog..."

  gpg -a -o "${PREV_LIFELOG_GPG}" -e "${PREV_LIFELOG}"

  if [[ $? -eq 0 ]]; then
    echo "Lifelog encrypted successfully. [${PREV_LIFELOG_GPG}]"
  else
    echo "ERROR - encryption failed!"
    echo "Exiting."
    exit 1
  fi

  echo "-> Committing lifelog on last week's branch..."

  BRANCH=$(git -C "${ORG_DIR}" symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3)

  if [[ "${BRANCH}" != "${LAST_WEEK_DATE}" ]]; then
    echo "ERROR - can't commit on ${BRANCH}: not last week's branch!"
    echo "Exiting."
    exit 1
  fi

  git -C "${ORG_DIR}" add "${PREV_LIFELOG_GPG}" && git -C "${ORG_DIR}" commit -m "Ajout de ${PREV_LIFELOG_NAME_GPG}"

  if [[ $? -eq 0 ]]; then
    echo "Encrypted lifelog committed successfully on ${BRANCH}."
  else
    echo "ERROR - commit failed on branch ${BRANCH}!"
    echo "Exiting."
    exit 1
  fi
}

###
# Description:
#   Create a new lifelog.
# Globals:
#   NEXT_LIFELOG
# Arguments:
#   None
new_lifelog() {
  if [[ -f ${NEXT_LIFELOG} ]]; then
    echo "ERROR - the new lifelog already exists! [${NEXT_LIFELOG}]"
    echo "Exiting."
    exit 1
  fi

  declare -A weekdays
  weekdays=([1]=lun. [2]=mar. [3]=mer. [4]=jeu. [5]=ven. [6]=sam. [7]=dim.)

  cat >"${NEXT_LIFELOG}" <<EOF
#+TITLE: Lifelog ${CURRENT_WEEK_DATE}

$(for i in $(seq 7 -1 1); do
    DAY_NUMBER=$(date '+%u')
    OFFSET=$((i - DAY_NUMBER))
    DATE=$(date -d "${OFFSET} days" -I)
    WEEKDAY=${weekdays[$i]}
    ORG_DATE="* [${DATE} ${WEEKDAY}]"
    echo "${ORG_DATE}"
  done)
EOF

  if [[ $? -ne 0 ]]; then
    echo "ERROR - new lifelog creation failed! [${NEXT_LIFELOG}]"
    echo "Exiting."
    exit 1
  fi

  echo "New lifelog created successfully. [${NEXT_LIFELOG}]"
}

###
# Description:
#   Merge-squash last week's branch into master, tag the commit and create this week's branch.
# Globals:
#   ORG_DIR
# Arguments:
#   None
merge_and_branch() {
  echo "-> Creating squash commit on master..."
  git -C "${ORG_DIR}" checkout master
  git -C "${ORG_DIR}" merge --squash "${LAST_WEEK_DATE}"
  git -C "${ORG_DIR}" commit -m "Merge ${LAST_WEEK_DATE}"

  echo "-> Tagging..."
  git -C "${ORG_DIR}" tag "v${LAST_WEEK_DATE}" HEAD

  echo "-> Creating a new branch for this week..."
  git -C "${ORG_DIR}" checkout -b "${CURRENT_WEEK_DATE}"
}

### Main

echo -e "\n##### Encryption and commit of last week's lifelog"
encrypt_and_commit

echo -e "\n##### Creation of a new lifelog"
new_lifelog

echo -e "\n##### Preparation of current week's branches"
merge_and_branch
