#!/bin/bash

# Turn on unofficial Bash 'strict mode'! V useful
# "Convert many kinds of hidden, intermittent, or subtle bugs into immediate, glaringly obvious errors"
# ref: http://redsymbol.net/articles/unofficial-bash-strict-mode/ 
set -euo pipefail

name=$(basename $0)
die() { 
  echo >&2 "FATAL:${name}: $*" ; exit 1
}
warn() {
  echo >&2 "WARNING:${name}: $*"
}

KEYS_DIR=keys_dir
IMG=secret.txt
SIGNFILE=image.sig

gen_keys_for()
{
[[ $# -ne 1 ]] && return
[[ "${PERSON}" = "alice" ]] && {
  PVTKEY=${KEYS_DIR}/alice_privkey.pem
  PUBKEY=${KEYS_DIR}/alice_pubkey.pem
}
[[ "${PERSON}" = "bob" ]] && {
  PVTKEY=${KEYS_DIR}/bob_privkey.pem
  PUBKEY=${KEYS_DIR}/bob_pubkey.pem
}

echo "When prompted for a 'PEM pass phrase', enter a passwd of a min of 4 characters"
# 1. Generate a private key 4096-bit RSA
openssl genrsa -aes256 -out ${PVTKEY} 4096
ls -l ${PVTKEY}
file ${PVTKEY}
# 2. Extract the public key from it
openssl rsa -in ${PVTKEY} -pubout -out ${PUBKEY}
ls -l ${PUBKEY}
file ${PUBKEY}
}

gen_keys()
{
rm -rf ${KEYS_DIR}
mkdir ${KEYS_DIR}

echo "
Generating keys for ${PERSON} ..."
gen_keys_for ${PERSON}

#echo "
#Generating keys for Bob ..."
#gen_keys_for bob
}

# Parameters:
#  $1 : image file to sign
digitally_sign_image()
{
[[ $# -eq 0 ]] && return
# 3. Hash (SHA256) the image file and Sign the digest with the pvt key
#              ┌──────────────┐
#  image  ───► │  SHA-256     │ ──► digest (32 bytes, fixed)
#              └──────────────┘
#                     │
#                     ▼
#           ┌────────────────────┐
#           │ RSA-sign with      │ ──► digital signature (blob)
#           │ PRIVATE key        │
#           └────────────────────┘
echo "Digitally signing the file \"$1\"..."
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
	echo "Usage: ${name} -p {alice|bob} {-option} [file]
 -p {person} : must be 'alice' or 'bob'
Options:
 -g          : one-time: generate private and public key pairs for Alice & Bob (asymmetric keys)
             : Here, the -p 'person' option doesn't really matter...
             : (Alice & Bob must then exchange their public keys)
 -s {file}   : sign the specified file
 -e {file}   : encrypt the specified file
 -d {file}   : decrypt the specified file
 -v {file}   : verify the specified file
 -t {file}   : test  : deliberately modify the file and try to verify; should FAIL verification
 -r              : reset : revert to original  remove keys, signature file

Suggested order that you can try:
1. reset                                                          : -r
2. generate the key pair                                          : -g
3. digitally sign an image file (f.e., u-boot-img.bin)            : -s img_file
4. verify it                                                      : -v img_file
5. run the 'test' option: it will modify the u-boot-img.bin and   : -t img_file
   try to verify it, which should Fail
Back to step 1...

Note: the digital signature is the '${SIGNFILE}' file (gen by step 3); it must be attached
and sent along with the original (plaintext/encrypted) file to the recipient."
}


#--- 'main'

[[ $# -lt 3 ]] && {
  usage ; exit 0
}

[[ "$1" != "-p" ]] && {
	echo "*** First option must be '-p {alice|bob}'
"
	usage ; exit 1
}
shift

[[ "$1" != "alice" ]] && [[ "$1" != "bob" ]] && {
	die "Person can be either 'alice' or 'bob' only"
}
[[ "$1" = "alice" ]] && {
  PERSON="alice"
  #PVTKEY=${KEYS_DIR}/alice_privkey.pem
  #PUBKEY=${KEYS_DIR}/alice_pubkey.pem
}
[[ "$1" = "bob" ]] && {
  PERSON="bob"
  #PVTKEY=${KEYS_DIR}/bob_privkey.pem
  #PUBKEY=${KEYS_DIR}/bob_pubkey.pem
}

shift
opt="$1"
case "${opt}" in
 -g)
	gen_keys
	;;
 -s)
	[[ $# -ne 2 ]] && {
		usage ; exit 1
	}
	digitally_sign_image "$2"
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
