#!/usr/bin/env bash

set -euxo pipefail

lastTrack=''
fifo='/tmp/announce-current-song.fifo.wav'
mkfifo "$fifo"
while true; do
	sleep 10
	# Get title and artist of currently-playing track.
	meta="$(qdbus org.kde.amarok /Player org.freedesktop.MediaPlayer.GetMetadata || true)"
	if ! echo "$meta" | grep -qP '^artist:'; then
		continue # Most likely not playing audio right now.
	fi
	artist="$(echo "$meta" | grep -P '^artist:' | cut -d' ' -f2-)"
	title="$(echo "$meta" | grep -P '^title:' | cut -d' ' -f2-)"
	currentTrack="$title by $artist"
	if [ "$currentTrack" == "$lastTrack" ]; then
		continue # Already announced.
	fi
	# Fade out current music volume so that the track name can be announced.
	for i in $(seq 100 -5 30); do
		qdbus org.kde.amarok /Player VolumeSet "$i"
		sleep 0.075
	done
	# Write text-to-speech data to FIFO.
	pico2wave --wave="$fifo" "Current track is $currentTrack." &
	# Play text-to-speech data from FIFO to speakers.
	paplay "$fifo"
	# Raise music volume back up.
	for i in $(seq 30 5 100); do
		qdbus org.kde.amarok /Player VolumeSet "$i"
		sleep 0.075
	done
done
