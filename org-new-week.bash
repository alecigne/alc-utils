#!/bin/bash

# Target directories
ORG_DIR="${HOME}/org"

# Last week's date string (e.g. 2019-w30)
LAST_WEEK_DATE=$(date -d 'last week' +%Y-w%V)

# This week's date string (e.g. 2019-w31)
CURRENT_WEEK_DATE=$(date +%Y-w%V)

# Last week's lifelog
LIFELOG_FILENAME="lifelog-${LAST_WEEK_DATE}.org"
LIFELOG_FILE="${ORG_DIR}/${LIFELOG_FILENAME}"

# Last week's encrypted lifelog
LIFELOG_FILENAME_GPG="${LIFELOG_FILENAME}.gpg"
LIFELOG_FILE_GPG="${ORG_DIR}/${LIFELOG_FILENAME_GPG}"

# Next lifelog
LIFELOG_FILENAME_NEXT="lifelog-${CURRENT_WEEK_DATE}.org"
LIFELOG_FILE_NEXT="${ORG_DIR}/${LIFELOG_FILENAME_NEXT}"

# Encrypt last week's lifelog

echo "##### Encryption of last week's lifelog"

echo "-> Checking if last week's lifelog exists..."

if [[ -f ${LIFELOG_FILE} ]]; then
    echo "OK - last week's lifelog exists. [${LIFELOG_FILE}]."
else
    echo "ERROR - last week's lifelog not found! [${LIFELOG_FILE}]"
    echo "Exiting."
    exit 1
fi

echo "-> Checking if encrypted lifelog already exists..."

if [[ -f ${LIFELOG_FILE_GPG} ]]; then
    echo "ERROR - the encrypted lifelog already exists! [${LIFELOG_FILE_GPG}]"
    echo "Exiting."
    exit 1
else
    echo "OK - the encrypted lifelog doesn't already exist. [${LIFELOG_FILE_GPG}]"
fi

echo "-> Encrypting lifelog..."

gpg -a -o ${LIFELOG_FILE_GPG} -e ${LIFELOG_FILE}

if [[ $? -eq 0 ]]; then
    echo "OK - encrypted lifelog created successfully. [${LIFELOG_FILE_GPG}]"
else
    echo "ERROR - encrypted lifelog creation failed! [${LIFELOG_FILE_GPG}]"
    echo "Exiting."
    exit 1
fi

echo "##### DONE."

# Commiting the encrypted lifelog

echo -e "\n##### Commiting encrypted lifelog"

echo "-> Checking current branch..."

BRANCH=$(git -C ${ORG_DIR} symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3)

if [[ "${BRANCH}" != "${LAST_WEEK_DATE}" ]]; then
    echo "ERROR - wrong branch! [${BRANCH}]"
    echo "Exiting."
    exit 1
else
    echo "OK - we are on the right branch. [${BRANCH}]"
fi

echo "-> Commiting encrypted lifelog on last week's branch..."

git -C ${ORG_DIR} add "${LIFELOG_FILE_GPG}"
git -C ${ORG_DIR} commit -m "Ajout de ${LIFELOG_FILENAME_GPG}"

echo "##### DONE."

# Creating a new lifelog

echo -e "\n##### Creation of a new lifelog"

echo "-> Checking if new lifelog already exists..."

if [[ -f ${LIFELOG_FILE_NEXT} ]]; then
    echo "ERROR - the new lifelog already exists! [${LIFELOG_FILE_NEXT}]"
    echo "Exiting."
    exit 1
else
    echo "OK - the new lifelog doesn't already exist. [${LIFELOG_FILE_NEXT}]"
fi
    
echo "-> Creating a new lifelog..."

# TODO Commencer au lundi de la semaine courante (sinon tout est décalé)

declare -A weekdays
weekdays=([0]=lun. [1]=mar. [2]=mer. [3]=jeu. [4]=ven. [5]=sam. [6]=dim.)

cat > ${LIFELOG_FILE_NEXT} << EOF
#+TITLE: Lifelog ${CURRENT_WEEK_DATE}

$(for i in $(seq 6 -1 0)
do
    DATE=$(date -d "+$i days" -I)
    WEEKDAY=${weekdays[$i]}
    ORG_DATE="* [${DATE} ${WEEKDAY}]"
    echo "${ORG_DATE}"
done)
EOF

if [[ $? -eq 0 ]]; then
    echo "OK - new lifelog created successfully. [${LIFELOG_FILE_NEXT}]"
else
    echo "ERROR - new lifelog creation failed! [${LIFELOG_FILE_NEXT}]"
    echo "Exiting."
    exit 1
fi

echo "##### DONE."

# Preparing a new branch

# Prepare the next branch (e.g. 2019-w30 -> 2019-w31)
prepare_next_branch () {
    echo "-> Preparing new branch in $1"
    echo "Creating squash commit on master..."
    git -C $1 checkout master
    git -C $1 merge --squash ${LAST_WEEK_DATE}
    git -C $1 commit -m "Merge ${LAST_WEEK_DATE}"
    echo "Tagging..."
    git -C $1 tag v${LAST_WEEK_DATE} HEAD
    echo "-> Creating a new branch for this week..."
    git -C $1 checkout -b ${CURRENT_WEEK_DATE}
}

echo -e "\n##### Preparation of current week's branches"

prepare_next_branch ${ORG_DIR}

echo "##### DONE."
