#!/bin/bash

# Check if input file and crossfade duration are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <input_file> <duration>"
    exit 1
fi

input_file="$1"
duration="$2"

# Check if the input file has an audio stream
has_audio=$(ffprobe -i "$input_file" -show_streams -select_streams a -loglevel error)
if [ -n "$has_audio" ]; then
    echo "Error: This script does not support videos with audio tracks. Please remove the audio from your input video and try again."
    exit 1
fi

# Get the duration of the input video
input_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")

# Detect the frame rate of the input video
detected_fps=$(ffprobe -v error -select_streams v -count_packets -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$input_file")
forced_fps=$(echo "scale=2; $detected_fps" | bc)

# Calculate the start point of C
c_start=$(echo "$input_duration - $duration" | bc -l)

# Generate output filename
output_file="${input_file%.*}_fadeloop.mp4"

# Create temporary files
temp_a="${input_file%.*}_temp_a.mp4"
temp_b="${input_file%.*}_temp_b.mp4"
temp_c="${input_file%.*}_temp_c.mp4"
temp_d="${input_file%.*}_temp_d.mp4"

# Trim the video into three parts: A, B, and C
ffmpeg -i "$input_file" -t ${duration} -r ${forced_fps} -filter:v "fps=${forced_fps}" "${temp_a}"
ffmpeg -i "$input_file" -ss ${duration} -t $(echo "$c_start - $duration" | bc -l) -r ${forced_fps} -filter:v "fps=${forced_fps}" "${temp_b}"
ffmpeg -i "$input_file" -ss ${c_start} -r ${forced_fps} -filter:v "fps=${forced_fps}" "${temp_c}"

# Create composite video D by crossfading C into A
ffmpeg -i "${temp_c}" -i "${temp_a}" -filter_complex "
[0:v][1:v]xfade=transition=fade:duration=${duration}:offset=0,format=yuv420p
" -r ${forced_fps} "${temp_d}"

# Concatenate B and D
ffmpeg -i "${temp_b}" -i "${temp_d}" -filter_complex "
[0:v][1:v]concat=n=2:v=1:a=0,format=yuv420p
" -r ${forced_fps} "${output_file}"

# Clean up temporary files
rm "${temp_a}" "${temp_b}" "${temp_c}" "${temp_d}"

echo "Processed video saved as $output_file"