#!/bin/bash

# For convert you must have installed ffmpeg util
# Script in first start create two folders `in` and `out`
# In folder `in` should be stored video files
# Folder `out` is used for the converted files


SCRIPT_DIR=`dirname "$0"`

INPUT_DIR="$SCRIPT_DIR/in"
OUTPUT_DIR="$SCRIPT_DIR/out"
VIDEO_BITRATE="1200"
AUDIO_BITRATE="128k"


echo $INPUT_DIR
echo $OUTPUT_DIR

close () {
	echo "Press any key"
	read item
	osascript -e 'tell application "Terminal" to quit' &
	exit
}

begin () {
	echo -n "Do you want convert video files from folder ./in/ ? (y/n) "

	read item
	case "$item" in
	    y|Y) echo "Begin convert"
	        ;;
	    n|N) echo "Exit"
	        close
	        ;;
	    *) echo "Exit"
	        close
	        ;;
	esac
}

create_dir () {
	mkdir -p $INPUT_DIR
	mkdir -p $OUTPUT_DIR
}

check_if_input_dir_empty () {
	if [ ! "$(ls -A $INPUT_DIR)" ]; then echo -e "\n Folder ./$INPUT_DIR/ is empty \n "; close; fi
}

check_file_to_video_content () {
	if ! ffprobe -v quiet  "$1"
	then
		echo -e "\n $1 - is broken or not video file \n"
		return 1
	else
		eval $(ffprobe -v quiet -of flat=s=_  -show_entries format=format_name "$1")
		if [[ ! $format_format_name == "tty" ]]
		then
			return 0
		else
			echo -e "\n $1 - is broken or not video file \n"
			return 1
		fi
	fi
}

set_ffmpeg_params () {
	AUDIO_PREF="-c:a aac"
	VIDEO_PREF="-c:v libx264"

	# AUDIO_PREF="-c:a copy"
	# VIDEO_PREF="-c:v copy"
	# streams_stream_0_codec_name="h264"
	# streams_stream_1_codec_name="aac"

	eval $(ffprobe -v quiet -of flat=s=_  -show_entries stream=codec_name "$1")
	if [[ ! $streams_stream_0_codec_name == "h264" ]]
	then
		VIDEO_PREF="-c:v libx264"
	fi
	
	if [[ ! $streams_stream_1_codec_name == aac ]]
	then
		AUDIO_PREF="-c:a aac"
	fi
}

convert_video () {
	FILE=${1##*/}
        ffmpeg -v info -hide_banner -i "$1" $VIDEO_PREF -x264opts bitrate=$VIDEO_BITRATE:vbv-maxrate=$VIDEO_BITRATE:vbv-bufsize=200:nal-hrd=cbr:force-cfr=1 -r 30 \
        -movflags +faststart -pix_fmt yuv420p -preset slow -tune film \
        $AUDIO_PREF -ar 44100 -b:a $AUDIO_BITRATE "$OUTPUT_DIR/${FILE%.*}.mp4"
}

#####      #####
# BEGIN SCRIPT #
#####      #####

create_dir

begin

check_if_input_dir_empty


for i in $INPUT_DIR/*
do
	if check_file_to_video_content "$i"
	then
		set_ffmpeg_params "$i"
		echo -e "\n\n\n $i --- $VIDEO_PREF $AUDIO_PREF \n"
		convert_video "$i"
	fi
done


close
