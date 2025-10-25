#!/bin/bash

# Usage: script.sh <image_file>

if [ -z "$1" ]; then
	echo "Usage: script.sh <image_file>"
	exit 1
fi

image=$1

if [ ! -f $image ]; then
	echo "No such file: $image"
	exit 1
fi

# NOTE: resolution is height x width
for reso in 16x16 24x24 32x32 48x48 64x64 128x128 256x256 512x512; do
	basename=$(echo $image | sed 's/.png//')
	convert -resize $reso $image ${basename}_${reso}.png
	ls -ltr | tail -1
done
