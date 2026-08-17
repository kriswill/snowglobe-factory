#!/bin/sh
DIRECTORY_ROOT="$(readlink -f "${1:-"$PWD"}")"
find "$DIRECTORY_ROOT" -type f -not -path "*/.*" | while read -r file; do
	sed -i 's|snowglobe-lib|snowglobe-factory|g' "$file"
done
