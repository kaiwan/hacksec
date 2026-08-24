#!/bin/bash

# Turn on unofficial Bash 'strict mode'! V useful
# "Convert many kinds of hidden, intermittent, or subtle bugs into immediate, glaringly obvious errors"
# ref: http://redsymbol.net/articles/unofficial-bash-strict-mode/ 
set -euo pipefail

name=$(basename $0)
PVTKEY=privkey.pem
PUBKEY=pubkey.pem
IMG=u-boot-img.bin
SIGNFILE=image.sig

gen_keys()
{
echo "Generating keys..."
rm -f *.pem *.sig || true
# 1. Generate a private key 4096-bit RSA
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out ${PVTKEY}
ls -l ${PVTKEY}
file ${PVTKEY}

# 2. Extract the public key from it
openssl pkey -in ${PVTKEY} -pubout -out ${PUBKEY}
ls -l ${PUBKEY}
file ${PUBKEY}
}

# Parameters:
#  $1 : image file to sign
sign_image()
{
[[ $# -eq 0 ]] && return
# 3. Hash (SHA256) the image file and Sign the digest with the pvt key
#              ┌──────────────┐
#  image  ───► │  SHA-256     │ ──► digest (32 bytes, fixed)
#              └──────────────┘
#                     │
#                     ▼
#           ┌────────────────────┐
#           │ RSA-sign with      │ ──► signature (blob)
#           │ PRIVATE key        │
#           └────────────────────┘
echo "Signing the image file \"$1\"..."
echo "Just FYI: digest = sha256sum of image file:"
sha256sum ${1}
openssl dgst -sha256 -sign ${PVTKEY} -out ${SIGNFILE} ${1}
echo "Signed"
}

# Parameters:
#  $1 : image file to verify
verify_image()
{
#------------ On target device
# 4. Verification: hash the image, apply public key to signature file ->
#    recovers the digest put in by signer
#  image ──► SHA-256 ──► digest_computed
#                              │
#                              ▼
#                        ┌───────────┐
#   signature ─────────► │ RSA-verify│ ──► digest_recovered
#   public key ────────► └───────────┘
#                              │
#              digest_computed == digest_recovered ?
#                   YES → authentic     NO → reject
# Must match!
[[ $# -eq 0 ]] && return
echo "Verifying the image file \"$1\"..."
openssl dgst -sha256 -verify ${PUBKEY} -signature ${SIGNFILE} ${1}
}

usage()
{
	echo "Usage: ${name} {-option} [image_file]
Options:
 -g              : generate pvt and pub key pair (asymmetric keys)
 -s {image-file} : sign the specified image file
 -v {image-file} : verify the specified image file
 -t {image_file} : test  : deliberately modify the image and try to verify; should FAIL verification
 -r              : reset : revert to original u-boot-img.bin, remove keys, signature file

Suggested order that you can try:
1. reset
2. generate the key pair
3. sign an image file
4. verify it
5. run the 'test' option: it will modify the u-boot-img.bin and try to verify it, which should Fail
Back to step 1..."
}


#--- 'main'

[[ $# -eq 0 ]] && {
  usage ; exit 0
}

opt="$1"
case "${opt}" in
 -g)
	gen_keys
	;;
 -s)
	[[ $# -ne 2 ]] && {
		usage ; exit 1
	}
	sign_image "$2"
	;;
 -v)
	[[ $# -ne 2 ]] && {
		usage ; exit 1
	}
	verify_image "$2"
	;;
 -t)
	[[ $# -ne 2 ]] && {
		usage ; exit 1
	}
	# change boot order!
	sed -i 's,boot_targets=mmc1 mmc0 usb pxe dhcp,boot_targets=usb mmc0 mmc1 pxe dhcp,' u-boot-img.bin
	diff u-boot-img.bin u-boot-img.bin.orig || true
	verify_image ${2}
	;;
 -r)
	rm -f *.pem *.sig || true
	cp u-boot-img.bin.orig u-boot-img.bin
	echo "Reset done"
	diff u-boot-img.bin u-boot-img.bin.orig
	;;
 *)     usage ; exit 1
	;;
esac
exit 0
