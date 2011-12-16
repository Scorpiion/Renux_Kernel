#!/bin/bash

# Functions used to build Renux Linux kernel
# Copyright (C) 2011 Robert Åkerblom-Andersson
# 
# This program is free software under the GPL license, please 
# see the license.txt and gpl.txt files in the root directory

# Import build settings and kernel functions
source settings/build.conf
source script_library/kernel.bash

if [ ! -d $outputDir ] ; then
  mkdir $outputDir
fi

export JN=1

kernel.enterDir
kernel.compileUimage
kernel.compileModules
kernel.compileFirmware
kernel.install
kernel.leaveDir

