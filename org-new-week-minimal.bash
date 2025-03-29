#!/bin/bash

# TODO Fill this :)
org_dir=""
readonly last_week_date=$(date -d 'last week' +%Y-w%V)
readonly current_week_date=$(date +%Y-w%V)
readonly new_tag="v${last_week_date}"

echo "Squashing branch ${last_week_date} on master..."
git -C "${org_dir}" checkout master
git -C "${org_dir}" merge --squash "${last_week_date}"
git -C "${org_dir}" commit --allow-empty -m "Merge ${last_week_date}"

echo "Tagging master with tag ${new_tag}"
git -C "${org_dir}" tag "${new_tag}" HEAD

echo "Creating branch ${current_week_date} for this week..."
git -C "${org_dir}" checkout -b "${current_week_date}"
