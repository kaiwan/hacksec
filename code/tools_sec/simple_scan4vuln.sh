#!/bin/bash
# scan4vuln.sh
# (Very) simple scanner.. try D Wheeler's 'flawfinder' too.
#
# Last Updated : 28Feb2017
# Created      : 28Feb2017
# 
# Author:
# Kaiwan N Billimoria
# kaiwan -at- kaiwantech -dot- com
# kaiwanTECH
# 
# License:
# MIT License.
name=$(basename $0)

VERBOSE=0
STARTDIR=.
TMP=mytmp

# SCAN MODE:
# Set to 0 to scan ONLY ELF binary executable files [default]
# Set to 1 to scan ONLY C source files (incl *.[chsS])
gcSCAN_MODE=1

# set to cross-compiler prefix, as required
CXX=""  # arm-none-linux-gnueabi-

# the 'bad' boys; separate them with a '|' symbol (for the egrep)
BADFUNCS_BIN="gets|strcat|strlen|strcmp|strcpy|sprintf|scanf|realpath|getopt|getpass|streadd|strecpy|strtrns|getwd|system"
#BADFUNCS_BIN="main|_start|printf|gets|strlen|strcmp|strcpy|sprintf|scanf"
BADFUNCS_CSRC="gets|strcat|strlen|strcmp|strcpy|sprintf|scanf|realpath|getopt|getpass|streadd|strecpy|strtrns|getwd|system"
#BADFUNCS_CSRC="main|_start|printf|gets|strlen|strcmp|strcpy|sprintf|scanf"

# $1 = file to "scan"
scanit()
{
 [ $# -ne 1 ] && return 1
 if [ ${gcSCAN_MODE} -eq 0 ] ; then
   # Note! nm fails for stripped binaries, use objdump
   file ${1} | grep -q "not stripped" && {
     ${CXX}nm ${1} |grep " [Tt] " |egrep "${BADFUNCS_BIN}"
     ${CXX}objdump -d ${1} |egrep "${BADFUNCS_BIN}"
     #${CXX}readelf -s ${1} |egrep "${BADFUNCS_BIN}"
   } || {
     ${CXX}objdump -d ${1} |egrep "${BADFUNCS_BIN}"
     #${CXX}readelf -s ${1} |egrep "${BADFUNCS_BIN}" |grep -v GLIBC
   }
 else
   egrep -w -Hn --color=auto "${BADFUNCS_CSRC}" ${1}
 fi
 
 return 0
}

main()
{
local i=1
local stat

if [ ${gcSCAN_MODE} -eq 1 ] ; then
  find ${STARTDIR} -type f -name "*.[chsS]" > ${TMP}
else
  find ${STARTDIR} -type f > ${TMP}
fi

local total=$(wc -l ${TMP} |cut -d' ' -f1)
[ ${total} -eq 0 ] && {
	echo "${name}: no file candidates found, aborting..."
	exit 1
}

[ ${gcSCAN_MODE} -eq 1 ] && msg1="Source files" || msg1="Binary executables"
msg2="Found a total of ${total} files, scanning them now"
echo "From: ${STARTDIR} :
Mode: ${msg1} only: (to change mode, edit the config var gcSCAN_MODE)

${msg2} in mode \"${msg1}\"  ...
"

IFS=$'\n'
for fil in $(cat ${TMP})
do
  #echo "fil: ${fil}"
  if [ ${gcSCAN_MODE} -eq 0 ] ; then
    file ${fil} | grep -q "ELF.*executable" || continue
  #elif [ ${gcSCAN_MODE} -eq 1 ] ; then
  #  file ${fil} | grep -q "ELF.*executable" || continue
  fi

  printf "${i}: scanning ${fil} ...\n"
  scanit ${fil}
  let i=i+1
done
rm -f ${TMP}
}


### starts here

[ $# -lt 1 ] && {
  echo "Usage: ${name} code-start-folder(s)"
  exit 1
}
[ ! -d $1 ] && {
  #echo "${name}: start-folder $1 invalid? Check if it's a valid file ..."
  [ ! -f $1 ] && {
    echo "Input invalid, aborting..." ; exit 1
  } || {
    scanit $1
    exit 0
  }
}
STARTDIR="$@"
main
exit 0
