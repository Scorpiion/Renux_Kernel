#!/bin/bash

# Functions used to build Renux Linux kernel
# Copyright (C) 2011 Robert Åkerblom-Andersson
# 
# This program is free software under the GPL license, please 
# see the license.txt and gpl.txt files in the root directory

alias echo='echo -e'

function kernel.checkConfig() {
  if [ ! "$CONFIG" == "y" ] ; then
    echo "Error: No build config file, please check the file \"settings/build.conf\" and make sure there is a line saying CONFIG=\"y\"."
    exit 1
  fi
  kernel.enterDir
}

function kernel.enterDir() {
  cd $kernelDir
}

function kernel.leaveDir() {
  kernel.checkConfig
  cd $kernelDir
}

function kernel.checkout() {
  kernel.checkConfig
  gitStatus=$(git status --porcelain)
  if [ ${#gitStatus} -gt 0 ] ; then
    git add .
    git commit -a -m "Commiting changes before changing branch..."
  fi
  git checkout master
  git pull
  git checkout -b renux-kernel-$linuxVersion-$(date +%Y-%m-%d_%H_%M_%S) $linuxGitTag
}

function kernel.patch() {
  kernel.checkConfig
  echo -e "Applied patches:\n" > /tmp/patchCommit.txt
  cd $patchDir
  for dir in * ; do
    if [[ -d "$dir" ]] && [[ "$dir" != "defconfigs" ]] ; then
      echo "Applying paches from patch dir \"${dir##*/}\""
      cd $dir
      for patch in *.patch ; do
	cd $kernelDir
	echo "  Applying patch \"$patch\""
	patch -p1 -s < ${patchDir}/${dir}/${patch}
	echo "patch -p1 -s < ${patchDir}/${dir}/${patch}" >> /tmp/patchCommit.txt
      done
      echo ""
    fi
    cd $patchDir
  done
  kernel.enterDir
  git add .
  git commit -a -F /tmp/patchCommit.txt
}

function kernel.clean() {
  kernel.checkConfig
  echo "Clean kernel..."
  sleep 1
  make -j $JN ARCH=arm CROSS_COMPILE="ccache ${CC}" mrproper $extraFlags
}

function kernel.defconfig() {
  kernel.checkConfig
  echo "Configure kernel...\n"
  sleep 1
  if [ -e "${patchDir}/defconfigs/beagleboard/defconfig" ] ; then
    cp ${patchDir}/defconfigs/beagleboard/defconfig arch/arm/configs/$defconfig
  else
    cp $workDir/settings/omap3_renux_defconfig arch/arm/configs/$defconfig
  fi
  make -j $JN ARCH=arm CROSS_COMPILE="ccache ${CC}" $defconfig $extraFlags
}

function kernel.menuconfig() {
  kernel.checkConfig
  echo "Menuconfig...\n"
  sleep 1
  make -j $JN ARCH=arm CROSS_COMPILE="ccache ${CC}" menuconfig $extraFlags
}

function kernel.compileUimage() {
  kernel.checkConfig
  echo "Compile kernel...\n"
  sleep 1
  make -j $JN ARCH=arm CROSS_COMPILE="ccache ${CC}" uImage $extraFlags
}

function kernel.compileModules() {
  kernel.checkConfig
  echo "Compile modules...\n"
  sleep 1
  make -j $JN ARCH=arm CROSS_COMPILE="ccache ${CC}" modules $extraFlags
}

function kernel.compileFirmware() {
  kernel.checkConfig
  echo "Compile firmware...\n"
  sleep 1
  make -j $JN ARCH=arm CROSS_COMPILE="ccache ${CC}" firmware $extraFlags
}

function kernel.compileHeaders() {
  kernel.checkConfig
  echo "Compile headers...\n"
  sleep 1
  mkdir -p $workDir/tmp
  make -j $JN ARCH=arm CROSS_COMPILE="ccache ${CC}" headers_install INSTALL_HDR_PATH=$workDir/tmp
  cd $workDir
  tar -czf linux-headers.tar.gz $workDir/tmp/*
  rm -rf $workDir/tmp
}

function kernel.install() {
  echo "Installing uImage $outputDir/boot..."
  if [ ! -e "$outputDir/boot" ] ; then 
    mkdir -p $outputDir/boot 
  fi
  cp arch/arm/boot/uImage $outputDir/boot
  echo "Installing modules...\n"
  make ARCH=arm INSTALL_MOD_PATH=$outputDir modules_install
  echo "Installing firmware...\n"
  make ARCH=arm INSTALL_MOD_PATH=$outputDir firmware_install
  echo "Creating tar.gz package..."
  cd $outputDir
  tar -czf renux_kernel.tar.gz *
}

function kernel.deb() {
  kernel.checkConfig
  echo "Building debian kernel package...\n"
  sleep 1
  make -j $JN ARCH=arm CROSS_COMPILE="ccache ${CC}" KBUILD_DEBARCH=armel KDEB_PKGVERSION="Renux" deb-pkg
}

