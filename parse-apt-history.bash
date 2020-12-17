#!/bin/bash

perl -pe 's/\(.*?\)(, )?//g' /var/log/apt/history.log
