#!/bin/sh
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin

readonly SCRIPT=$(basename "$0")
readonly VERSION='1.1.0'
RESOLUTIONS=(1920x1200 1920x1080 UHD)
MONITOR="0" # 0 means all monitors

usage() {
cat <<EOF
Usage:
  $SCRIPT [options]
  $SCRIPT -h | --help
  $SCRIPT --version

Options:
  -f --force                     Force download of picture. This will overwrite
                                 the picture if the filename already exists.
  -s --ssl                       Communicate with bing.com over SSL.
  -q --quiet                     Do not display log messages.
  -n --filename <file name>      The name of the downloaded picture. Defaults to
                                 the upstream name.
  -p --picturedir <picture dir>  The full path to the picture download dir.
                                 Will be created if it does not exist.
                                 [default: $HOME/Pictures/bing-wallpapers/]
  -r --resolution <resolution>   The resolution of the image to retrieve.
                                 Supported resolutions: ${RESOLUTIONS[*]}
  --resolutions <resolutions>    The resolutions of the image try to retrieve.
                                 eg.: --resolutions "1920x1200 1920x1080 UHD"
  -m --monitor <num>             Set wallpaper only on certain monitor (1,2,3...)                                                       
  -h --help                      Show this screen.
  --version                      Show version.
EOF
}

print_message() {
    if [ ! "$QUIET" ]; then
        printf "%s\n" "${1}"
    fi
}

download_image_curl () {
    local RES=$1
    FILEURLWITHRES=$(echo "$FILEURL" | sed -e "s/tmb/$RES/")
    FILENAME=${FILEURLWITHRES/th\?id=/}
    FILEWHOLEURL="$PROTO://bing.com/$FILEURLWITHRES"

    if [ $FORCE ] || [ ! -f "$PICTURE_DIR/$FILENAME" ]; then
        find $PICTURE_DIR -type f -iname \*.jpg -delete
        print_message "Downloading: $FILENAME..."
        curl --fail -Lo "$PICTURE_DIR/$FILENAME" "$FILEWHOLEURL"
        if [ "$?" == "0" ]; then
            FILEPATH="$PICTURE_DIR/$FILENAME"
            return
        fi

        FILEPATH=""
        return
    else
        print_message "Skipping download: $FILENAME..."
        FILEPATH="$PICTURE_DIR/$FILENAME"
        return
    fi
}

set_wallpaper () {
    local FILEPATH=$1
    local MONITOR=$2

    if [ "$MONITOR" -ge 1 ] 2>/dev/null; then
    print_message "Setting wallpaper for monitor: $MONITOR"
    osascript - << EOF
        set tlst to {}
        tell application "System Events"
            set tlst to a reference to every desktop
            set picture of item $MONITOR of tlst to "$FILEPATH"
        end tell
EOF
    else
        osascript -e 'tell application "System Events" to tell every desktop to set picture to "'$FILEPATH'"'
    fi
}

# Defaults
PICTURE_DIR="$HOME/Pictures/bing-wallpapers/"

# Option parsing
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -r|--resolution)
            RESOLUTION="$2"
            shift
            ;;
        -p|--picturedir)
            PICTURE_DIR="$2"
            shift
            ;;
        -n|--filename)
            FILENAME="$2"
            shift
            ;;
        -m|--monitor)
            MONITOR="$2"
            shift
            ;;
        -f|--force)
            FORCE=true
            ;;
        -s|--ssl)
            SSL=true
            ;;
        -q|--quiet)
            QUIET=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --resolutions)
            RESOLUTIONS="$2"
            shift
            ;;
        --version)
            printf "%s\n" $VERSION
            exit 0
            ;;
        *)
            (>&2 printf "Unknown parameter: %s\n" "$1")
            usage
            exit 1
            ;;
    esac
    shift
done

# Set options
[ $QUIET ] && CURL_QUIET='-s'
[ $SSL ]   && PROTO='https'   || PROTO='http'

# Create picture directory if it doesn't already exist
mkdir -p "${PICTURE_DIR}"

# Parse bing.com and acquire picture URL(s)
FILEURL=( $(curl -sL https://www.bing.com | \
    grep -Eo "th\?id=.*?.jpg") )

if [ $RESOLUTION ]; then
    download_image_curl $RESOLUTION
    if [ "$FILEPATH" ]; then
        set_wallpaper $FILEPATH $MONITOR
    fi
    exit 1
fi

for RESOLUTION in "${RESOLUTIONS[@]}"
    do
        download_image_curl $RESOLUTION
        if [ "$FILEPATH" ]; then
            set_wallpaper $FILEPATH $MONITOR
            exit 1
        fi
    done
