#!/bin/bash

if [ $# -lt 2 ] ; then
  echo "Usage: $0 relativePatchToPatchDirectory relativePathToLinuxDirectory"
  exit 1
fi

if [ ! -d "$1" ] ; then
  echo "Can't find directory \"$1\""
  exit 2
else
  patchDir=$PWD/$1
fi
if [ ! -d "$2" ] ; then
  echo "Can't find directory \"$2\""
  exit 3
else 
  kernelDir=$PWD/$2
fi

cd $patchDir
for dir in * ; do
  cd $patchDir
  echo "Applying paches from patch dir \"${dir##*/}\""
  cd $dir
  for patch in * ; do
    cd $kernelDir
    echo "  Applying patch \"$patch\""
    patch -p1 -s < ${patchDir}${dir}/${patch}
  done
  echo ""
done


