#!/bin/sh

case "$1" in
    *.zip)
        # Use zipinfo to display the contents of the zip file
        zipinfo "${1}"
        exit 0
        ;;
    *)
        bat -p --theme ansi -f "${1}" || batcat -p --theme ansi -f "${1}" || cat "${1}"
        exit 0
        ;;
esac
