#!/bin/bash

RM_INTERMIDATE_FILE=false

indir=$1
if [ -z "$indir" ]; then
  echo "Directory of pngs not passed in as argument"
  exit
fi

#files=
#  echo $files
#exit

for file in `find $1 -iname \*.png -and -not -iname \*\.q\.png`
do
  echo "Starting from $file"
  background_file="${file%.*}.resized.png"
  background_q_file="${file%.*}.q.png"

  # generate file with 533 as smaller dimension
  convert "${file}" -resize 533x700\> "${background_file}"
  pngquant --speed 1 "${background_file}" --output "${background_q_file}"
  if [ "${RM_INTERMIDATE_FILE}" = true ]
  then
    rm ${background_file}
  fi
done
