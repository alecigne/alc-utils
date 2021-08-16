#!/bin/bash
#
# Save a splitted copy of a PDF.

if [ $# -lt 4 ]; then
  echo "Usage: pdfsplit input.pdf first_page last_page output.pdf"
  exit 1
fi

yes | gs -dBATCH -sOutputFile="$4" -dFirstPage="$2" -dLastPage="$3" -sDEVICE=pdfwrite "$1" >&/dev/null
