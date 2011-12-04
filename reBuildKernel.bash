#!/bin/bash

# Functions used to build Renux Linux kernel
# Copyright (C) 2011 Robert Åkerblom-Andersson
# 
# This program is free software under the GPL license, please 
# see the license.txt and gpl.txt files in the root directory

# Import build settings and kernel functions
source settings/build.conf
source script_library/kernel.bash

mkdir $outputDir
kernel.enterDir
# kernel.menuconfig
# kernel.compileUimage
# kernel.compileModules
# kernel.compileFirmware
# kernel.deb
kernel.install
kernel.leaveDir

