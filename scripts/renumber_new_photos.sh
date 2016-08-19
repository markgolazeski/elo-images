#!/bin/bash

# Prerequisite to this script is
# mogrify -format png *.jpg

MV_INSTEAD_OF_CP=false

indir=$1
counter=$2
if [ -z "$indir" ]; then
  echo "Directory of new images not passed in as first argument"
  exit
fi

if [ -z "$counter" ]; then
  echo "Starting counter not passed in as second argument"
  exit
fi

echo "Starting at counter: $counter"
sleep 3

find $1 -depth 1 -iname \*.png -and -not -iname \*\.q\.png | while read file
do
  new_filename="${indir}/${counter}.png"
  COMMAND="echo"
  if [ "${MV_INSTEAD_OF_CP}" = true ]; then
    COMMAND="mv"
  else
    COMMAND="cp"
  fi
  ${COMMAND} "${file}" "${new_filename}"
  counter="$((${counter}+1))"
done
