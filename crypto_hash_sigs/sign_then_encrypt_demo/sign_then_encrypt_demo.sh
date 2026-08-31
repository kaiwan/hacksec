#!/bin/bash
# ref: https://opensource.com/article/21/4/encryption-decryption-openssl

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

echo "
Before proceeding further, first ensure you exchange your public key with your peer;
(for Alice, like this perhaps: scp keys_dir/alice_pubkey.pem  bob@<IPaddr>:~/.ssh/
  and vice-versa.)
(Save it like this:
 If you're Alice : ~/.ssh/bob_pubkey.pem
 If you're Bob   : ~/.ssh/alice_pubkey.pem
)"
#gen_keys_for bob
}

# Parameters:
#  $1 : file to sign
digitally_sign_file()
{
[[ $# -eq 0 ]] && return
# 3. Hash (SHA256) the image file and Sign the digest with the pvt key
#              ┌──────────────┐
#   file  ───► │  SHA-256     │ ──► digest (32 bytes, fixed)
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
openssl dgst -sha256 -sign ${SIGNING_KEY} -out ${SIGNFILE} ${1}
echo "Signed"
}

# Parameters:
#  $1 : file to sign
encrypt_file()
{
[[ $# -eq 0 ]] && return
echo "Encrypting the file \"$1\"..."
openssl pkeyutl -encrypt -inkey ${RECIPIENT_PUBKEY} -pubin -in ${FILE} -out ${FILE}.enc
#openssl rsautl -encrypt -inkey ${RECIPIENT_PUBKEY} -pubin -in ${FILE} -out ${FILE}.enc
# "The command rsautl was deprecated in version 3.0. Use 'pkeyutl' instead."
echo "Encrypted as ${FILE}.enc"
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
 -p {person} : first parameter: MUST be passed as 'alice' or 'bob'

Options:
 -g          : one-time: generate private and public key pairs for Alice & Bob (asymmetric keys)
             : Here, the -p 'person' option doesn't really matter...
             : (Alice & Bob must then exchange their public keys)

 -s {file}   : prepare for send (via sign-then-encrypt) the specified file to the recipient

 -d {file}   : decrypt the specified file
 -v {file}   : verify the specified file

 -t {file}   : test  : deliberately modify the file and try to verify; should FAIL verification
 -r          : reset : revert to original  remove keys, signature file

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
set +u
[[ "$1" = "-r" ]] && {
	rm -rf ${KEYS_DIR}
	echo "Reset done"
	exit 0
}
[[ "$1" != "-p" ]] && {
	echo "*** First parameter must be '-p {alice|bob}'
"
	usage ; exit 1
}
set -u
[[ $# -lt 3 ]] && {
  usage ; exit 0
}

shift

[[ "$1" != "alice" ]] && [[ "$1" != "bob" ]] && {
	die "Person can be either 'alice' or 'bob' only"
}
[[ "$1" = "alice" ]] && {
  PERSON="alice"
  MY_PVTKEY=keys_dir/alice_privkey.pem
  SIGNING_KEY=keys_dir/alice_privkey.pem
  RECIPIENT_PUBKEY=~/.ssh/bob_pubkey.pem
}
[[ "$1" = "bob" ]] && {
  PERSON="bob"
  MY_PVTKEY=keys_dir/bob_privkey.pem
  SIGNING_KEY=keys_dir/bob_privkey.pem
  RECIPIENT_PUBKEY=~/.ssh/alice_pubkey.pem
}

errmsg2="First generate the keys and exchange the public ones only."
#echo "# = $#, val = $@"
if [[ "$2" != "-g" ]] ; then
  [[ ! -f ${MY_PVTKEY} ]] && die "Your private key not found. ${errmsg2}"
  [[ ! -f ${SIGNING_KEY} ]] && die "Recipient's signing key not found. ${errmsg2}"
  [[ ! -f ${RECIPIENT_PUBKEY} ]] && die "Recipient's public key not found. ${errmsg2}"
fi

shift
opt="$1"
case "${opt}" in
 -g)
	gen_keys
	;;
 -s)                           # sign-then-encrypt
	[[ $# -ne 2 ]] && {
		usage ; exit 1
	}
	FILE="$2"
	digitally_sign_file ${FILE}
	#---
	# NOTE! We CAN skip the encryption; we then have a signed plaintext file
	#  (the signature image.sig Must be attached when sending to the recipient).
	# If we DO encrypt it - via the classic sign-then-encrypt - then we have a
	# signed encrypted file
	encrypt_file ${FILE}

	# send ${FILE}.enc to recipient, typically via scp
	;;
 -d)                           # decrypt
	[[ $# -ne 2 ]] && {
		usage ; exit 1
	}
	FILE="$2" # the .enc file
	OUTFILE="${FILE%.enc}"
	rm -f ${OUTFILE}
	openssl pkeyutl -decrypt -inkey ${MY_PVTKEY} -in ${FILE} > ${OUTFILE}
	#openssl rsautl -decrypt -inkey ${MY_PVTKEY} -in ${FILE} > ${OUTFILE}
	# "The command rsautl was deprecated in version 3.0. Use 'pkeyutl' instead."
	# Due to the 'set -euo pipefail', it will abort if the above cmd fails
	echo "Successfully decrypted as ${OUTFILE}"
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
# -r)
#	rm -rf ${KEYS_DIR}
#	echo "Reset done"
#	#diff u-boot-img.bin u-boot-img.bin.orig
#	;;
 *)     usage ; exit 1
	;;
esac
exit 0
