#!/bin/bash
#
# Reduce the size of a PDF.

### Functions

usage () {
    cat <<HELP_USAGE
  Utilisation : $(basename ${0}) <input_file> <output_file>
HELP_USAGE
}

### Main

if [[ $# -ne 2 ]] ; then
    usage
    exit
fi

echo "Creating PDF ${2} with reduced size..."
gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile="${2}" "${1}"
if [ $? -eq 0 ]; then echo "Done."; fi

# Merge PDFs
# gs -dNOPAUSE -sDEVICE=pdfwrite -sOUTPUTFILE=tests.pdf -dBATCH tests_1.pdf tests_2.pdf
