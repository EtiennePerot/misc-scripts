#!/bin/sh

pwd=`pwd`

for i in "$@"; do
	filedir=$(dirname "$i")
	filename=$(basename "$i")
	InfoFormat=$(soxi -e "$i")
	InfoDepth=$(soxi -b "$i")
	InfoFreq=$(soxi -r "$i")
	if [ ${filedir:0:1} == "/" ]; then
		outdir="$filedir/spectrums"
	else
		outdir="$pwd/$filedir/spectrums"
	fi
	mkdir -p "$outdir"
	sox "$i" -n spectrogram -h -p 6 -x 2000 -y 800 -c "$InfoFormat $InfoDepth bits @ $InfoFreq Hz" -t "$filename" -o "$outdir/$filename.png"
	if [ $? -eq 0 ]; then
		echo "$filename.png" created successfully
	else
		echo "Error creating $filename.png - Stopping."
		exit -1
	fi
done
