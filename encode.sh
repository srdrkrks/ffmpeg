#!/bin/sh

function die
{
	echo ERROR
	echo "$@"
	exit 1
}

if [ $# != 1 ]; then
	echo "Usage: sh encode.sh <your_video_filename>" >&2
	exit 1
fi

if [ ! -e "$1" ]; then
	echo "Input video file $1 does not exist" >&2
	exit 1
fi

# In case ffmpeg is installed, use that one
if `which ffmpeg 1>/dev/null 2>/dev/null`; then
	FFMPEG_EXE_PATH=`which ffmpeg 2>/dev/null`
else
	FFMPEG_EXE_PATH=./ffmpeg
fi

echo "Using FFmpeg executable path $FFMPEG_EXE_PATH"

if [ ! -e "$FFMPEG_EXE_PATH" ]; then
	echo FFmpeg not found. Make sure you extracted the ffmpeg executable in this directory, or change the path in encode.sh
	exit 1
fi

# Find the video aspect ratio
"$FFMPEG_EXE_PATH" -i "$1" >video.info 2>&1

ASPECT_RATIO=`grep -E "Video:.*DAR [1-9][0-9]*:[1-9][0-9]*" video.info | grep -oE "DAR [1-9][0-9]*:[1-9][0-9]*" | grep -oE "[1-9][0-9]*:[1-9][0-9]*"`

if [ "$ASPECT_RATIO" = "" ]; then
	# Not all videos have a DAR flag, else we can take the video resolution as display size
	ASPECT_RATIO=`grep -E "Stream.*Video:.*, *[1-9][0-9]*x[1-9][0-9]*" video.info | grep -oE "[1-9][0-9]*x[1-9][0-9]*" | sed -E s/x/:/`
fi

# Extract DAR
WIDTH=`echo $ASPECT_RATIO | cut -d ':' -f 1`
HEIGHT=`echo $ASPECT_RATIO | cut -d ':' -f 2`

echo Video display aspect ratio determined to be $WIDTH:$HEIGHT

"$FFMPEG_EXE_PATH" -i "$1" -vf "[orig] transpose=dir=1 [orig]; [orig] split [a][b]; [b] alphaextract [alphaAsGrayscale]; [alphaAsGrayscale] pad=iw*2:ih:iw:0 [alphaAsGrayscalePadded]; [alphaAsGrayscalePadded][a] overlay" -vcodec mpeg4 -s 3072x864  -b 5300000  -acodec aac -strict experimental -ar 22050 out.alpha.3g2
