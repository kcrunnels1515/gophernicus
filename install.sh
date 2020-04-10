#!/bin/bash
TOPDIR=$(pwd)
helpme() {
  echo "There are two options:"
  echo "-b      build"
  echo "-i      install"
  echo "-c      clean"
  echo "-h      help message"
}

buildstuff() {
  cd $TOPDIR/gophernicus
  make
  cd $TOPDIR
  cd $TOPDIR/quark
  make
}

cleanstuff() {
  cd $TOPDIR/quark
  make clean
  cd $TOPDIR/gophernicus
  make clean
}

installstuff() {
  cd $TOPDIR/quark
  sudo make install
  cd $TOPDIR/gophernicus
  sudo make install
}

case $1 in
  -b) buildstuff ;;
  -i) installstuff ;;
  -c) cleanstuff ;;
  -h) helpme ;;
  *) exit 0 ;;
esac
