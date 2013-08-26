#!/usr/bin/env bash

# Dirty script to download a bunch of youtube videos
# Supports format selection and redownloading when the connection breaks
# Usage:
#     $ ./youtube-download.sh url1 url2 ...

faveFormats=(fmt46_1080p fmt37_1080p fmt45_720p fmt22_720p)
outputDirectory="$HOME/yt"

set -e

download() {
	if ! clive -F "$1" &> /dev/null; then
		echo ">>> Cannot list formats for video: '$1'"
		return 1
	fi
	formats="$(clive -F "$1" | grep fmt | head -1 | cut -d ' ' -f 1 | sed -r 's/\|/\n/g')"
	chosenFormat=''
	for f in "${faveFormats[@]}"; do
		if echo "$formats" | grep -q "$f"; then
			chosenFormat="-f '$f'"
			break
		fi
	done
	echo ">>> Downloading: '$1'"
	cd "$outputDirectory"
	while true; do
		if clive $chosenFormat "$1"; then
			break
		fi
		sleep 3
	done
	echo ">>> Done downloading: '$1'"
}

failedVideos=()
for arg; do
	echo "> Processing: '$arg'"
	if ! download "$arg"; then
		failedVideos+=("$arg")
	fi
done
if [ "${#failedVideos[@]}" -ne 0 ]; then
	echo "> Failed videos:"
	for failedVideo in "${failedVideos[@]}"; do
		echo ">>> Failed: '$failedVideo'"
	done
fi
