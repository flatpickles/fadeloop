#!/bin/bash

# Check if input file and crossfade duration are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <input_file> <crossfade_duration>"
    exit 1
fi

input_file="$1"
crossfade_duration="$2"

# Get the duration of the input video
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")

# Calculate the new video length and cut point
new_length=$(echo "$duration - $crossfade_duration" | bc -l)
cut_point=$(echo "$new_length - $crossfade_duration" | bc -l)

# Check if crossfade duration is valid
if (( $(echo "$crossfade_duration > $new_length / 2" | bc -l) )); then
    echo "Error: Crossfade duration cannot be greater than half the new video length."
    exit 1
fi

# Generate output filename
output_file="${input_file%.*}_reversed_end_crossfaded.mp4"

# Perform the video and audio editing
ffmpeg -i "$input_file" -filter_complex "
[0:v]split[v1][v2];
[v1]trim=0:${cut_point},setpts=PTS-STARTPTS[vfirst];
[v2]trim=${cut_point}:${new_length},setpts=PTS-STARTPTS[vsecond];
[vsecond][vfirst]xfade=transition=fade:duration=${crossfade_duration}:offset=0,setpts=PTS-STARTPTS[vout];
[0:a]asplit[a1][a2];
[a1]atrim=0:${cut_point},asetpts=PTS-STARTPTS[afirst];
[a2]atrim=${cut_point}:${new_length},asetpts=PTS-STARTPTS[asecond];
[asecond][afirst]acrossfade=d=${crossfade_duration}:c1=tri:c2=tri[aout]
" -map "[vout]" -map "[aout]" -t ${new_length} "$output_file"

echo "Processed video saved as $output_file"