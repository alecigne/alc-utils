#!/bin/bash
#
# Merge PDFs into a single file.

if [ $# -lt 3 ]; then
  echo "Usage: pdfmerge input1.pdf input2.pdf [inputN.pdf ...] output.pdf"
  exit 1
fi

output="${!#}"
inputs=("${@:1:$#-1}")

gs -dBATCH -dNOPAUSE -sOutputFile="$output" -sDEVICE=pdfwrite "${inputs[@]}" >&/dev/null
