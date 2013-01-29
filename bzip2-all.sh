#!/usr/bin/env bash

# Usage:
#     bash bzip2-sll.sh dir1 dir2 dir3 ...
# For every file in the given directories, make a .bzip2 version of it next to it.
# Useful for Source Engine servers who wish to have compressed .bz2 files ready.

IFS="`echo -en "\n\b"`"
for arg; do
	for file in `find "$arg" -type f -name '*.bz2'`; do
		rm "$file"
	done
	for file in `find "$arg" -type f`; do
		echo "$file"
		bzip2 -k9 "$file"
	done
done
