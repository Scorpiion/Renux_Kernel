#!/bin/bash

# Functions used to build Renux Linux kernel
# Copyright (C) 2011 Robert Åkerblom-Andersson
# 
# This program is free software under the GPL license, please 
# see the license.txt and gpl.txt files in the root directory

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
    if [[ -d "$dir" ]] ; then
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
  echo -e "Clean kernel...\n"
  sleep 1
  make -j $JN ARCH=arm CROSS_COMPILE="ccache ${CC}" mrproper $extraFlags
}

function kernel.defconfig() {
  kernel.checkConfig
  echo -e "Configure kernel...\n"
  sleep 1
  if [ -e "${patchDir}/defconfig" ] ; then
    cp ${patchDir}/defconfig arch/arm/configs/$defconfig
  else
    cp $workDir/settings/omap3_renux_defconfig arch/arm/configs/$defconfig
  fi
  make -j $JN ARCH=arm CROSS_COMPILE="ccache ${CC}" $defconfig $extraFlags
}

function kernel.menuconfig() {
  kernel.checkConfig
  echo -e "Menuconfig...\n"
  sleep 1
  make -j $JN ARCH=arm CROSS_COMPILE="ccache ${CC}" menuconfig $extraFlags
}

function kernel.compileUimage() {
  kernel.checkConfig
  echo -e "Compile kernel...\n"
  sleep 1
  make -j $JN ARCH=arm CROSS_COMPILE="ccache ${CC}" uImage $extraFlags
  if [ "$?" != "0" ] ; then exit; fi
}

function kernel.compileModules() {
  kernel.checkConfig
  echo -e "Compile modules...\n"
  sleep 1
  make -j $JN ARCH=arm CROSS_COMPILE="ccache ${CC}" modules $extraFlags
  if [ "$?" != "0" ] ; then exit; fi
}

function kernel.compileFirmware() {
  kernel.checkConfig
  echo -e "Compile firmware...\n"
  sleep 1
  make -j $JN ARCH=arm CROSS_COMPILE="ccache ${CC}" firmware $extraFlags
  if [ "$?" != "0" ] ; then exit; fi
}

function kernel.compileHeaders() {
  kernel.checkConfig
  echo -e "\nCompile headers..."
  sleep 1
  mkdir -p $workDir/tmp
  make -j $JN ARCH=arm CROSS_COMPILE="ccache ${CC}" headers_install INSTALL_HDR_PATH=$workDir/tmp
  if [ "$?" != "0" ] ; then exit; fi
  cd $workDir/tmp
  if [ -e linux-headers.tar.gz ] ; then
    rm linux-headers.tar.gz
  fi
  tar -czf linux-headers.tar.gz *
  mv linux-headers.tar.gz $outputDir
  cd $workDir
  rm -rf $workDir/tmp
  kernel.enterDir
}

function kernel.install() {
  echo -e "\nInstalling uImage $outputDir/boot..."
  if [ ! -e "$outputDir/boot" ] ; then 
    mkdir -p $outputDir/boot 
  else
    rm -rf $outputDir/boot/*
  fi
  cp arch/arm/boot/uImage $outputDir/boot

  if [ -d $outputDir/lib ] ; then
    rm -rf $outputDir/lib/*
  fi
  echo -e "\nInstalling modules..."
  make ARCH=arm INSTALL_MOD_PATH=$outputDir modules_install
  if [ "$?" != "0" ] ; then exit; fi
  echo -e "\nInstalling firmware..."
  make ARCH=arm INSTALL_MOD_PATH=$outputDir firmware_install
  if [ "$?" != "0" ] ; then exit; fi

  echo -e "\nCreating tar.gz package..."
  cd $outputDir
  if [ -e renux_kernel.tar.gz ] ; then
    rm renux_kernel.tar.gz
  fi
  tar -czf renux_kernel.tar.gz *
}

# TODO later
# function kernel.deb() {
#   kernel.checkConfig
#   echo "Building debian kernel package...\n"
#   sleep 1
#   make -j $JN ARCH=arm CROSS_COMPILE="ccache ${CC}" KBUILD_DEBARCH=armel KDEB_PKGVERSION="Renux" deb-pkg
# }

