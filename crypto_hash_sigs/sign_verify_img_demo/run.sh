#!/bin/bash

#echo "
#Suggested order that you can try:
#1. reset                                                          : -r
#2. generate the key pair                                          : -g
#3. digitally sign an image file (f.e., u-boot-img.bin)            : -s img_file
#4. verify it                                                      : -v img_file
#5. run the 'test' option: it will modify the u-boot-img.bin and   : -t img_file
#   try to verify it, which should Fail"

PRG=./sign_verify_img_demo.sh
IMG=./u-boot-img.bin

echo ; echo "1. reset"
${PRG} -r
echo ; echo "2. generate the key pair"
${PRG} -g
echo ; echo "3. digitally sign an image file"
${PRG} -s ${IMG}
echo ; echo "4. verify the image file"
${PRG} -v ${IMG}
echo ; echo "5. modify and test the image file"
${PRG} -t ${IMG}

