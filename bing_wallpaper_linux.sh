#!/bin/bash

# Bing image url
binghost="https://www.bing.com"
bingJsonUrl="/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US"
bingImageUrl=$(curl "$binghost$bingJsonUrl" | grep -o -P '(?<=\"url\":\").*?(?=\")')

# Where to download
if [ -z "$1" ]
then
downloadPath="$HOME/Pictures/bing/background.jpg"
else
	downloadPath=$1
fi

# Ohter options for default download path
# downloadPath = "~/Pictures/bing/background.jpg" # for MATE environment 

# Downlaod bing image
curl "$binghost$bingImageUrl" > "$downloadPath"
