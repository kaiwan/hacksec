#!/usr/bin/env bash
#
# k3-boot-audit.sh - audit TI K3 (AM62x) boot artifacts for signing & encryption.
#
# WHAT IT CHECKS
#   [1] Container format, by magic bytes (x509-wrapped / FIT / raw arm64 Image)
#   [2] TI x509 certificate wrapping - VALIDATED via `openssl x509`, not guessed
#   [3] U-Boot FIT signature nodes (algo + key name)
#   [4] Per-FIT-node payload: plaintext / compressed / likely-encrypted
#   [5] Which signing key the artifacts are bound to
#
# DESIGN NOTES (why it is written this way)
#   - A previous version inferred "signed" from any ASN.1 SEQUENCE parsing at
#     offset 0. That false-positives on FIT magic (d0 0d fe ed -> hl=2,l=13 =>
#     "15-byte cert") and on arm64 Image MZ magic (4d 5a -> "92-byte cert").
#     Fix: parse the DER header explicitly, enforce a sane minimum length, and
#     require `openssl x509` to actually accept the carved bytes.
#   - Entropy alone cannot distinguish encryption from compression. Fix: read
#     each FIT node's DECLARED compression from dumpimage and suppress the
#     "encrypted" verdict when the node is compressed.
#   - TIFS (inside tiboot3.bin) and tifsstub-* (inside tispl.bin) are ALWAYS
#     TI-encrypted on GP/HS-FS/HS-SE alike. High entropy there proves nothing
#     about customer (SMEK) encryption. They are flagged as such.
#   - Missing tools previously degraded silently to a wrong "no-strings" verdict.
#     Fix: hard dependency check up front; abort rather than mislead.
#
# EXIT STATUS
#   0 = audit ran to completion (findings are in the report, not the exit code)
#   1 = usage error / missing dependency
#
# Usage: ./k3-boot-audit.sh <deploy-dir> [reference-key.pem]
#
set -euo pipefail

# ---------------------------------------------------------------- constants --
readonly MIN_CERT_LEN=256          # anything smaller is not an RSA/EC cert
readonly WINDOW=4096               # sliding-window size for entropy profile
readonly MAX_NODES=16              # cap per-node analysis (fitImage has dozens)
readonly H_ENCRYPTED=7.90          # bits/byte at/above which we suspect crypto
readonly H_PLAINTEXT=7.00          # bits/byte below which it is clearly plain

# Artifacts we look for, in boot order.
readonly ARTIFACTS=(tiboot3.bin tispl.bin u-boot.img fitImage Image)

# ------------------------------------------------------------------ plumbing --
usage() {
    sed -n '2,/^set -euo/p' "$0" | sed 's/^# \?//;$d'
    exit "${1:-1}"
}

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

hr()  { printf '%s\n' "------------------------------------------------------------------"; }

hdr() {
    printf '\n=================================================================\n'
    printf ' %s\n' "$*"
    printf '=================================================================\n'
}

[[ $# -ge 1 ]] || usage 1
[[ "$1" == "-h" || "$1" == "--help" ]] && usage 0

readonly DIR="${1%/}"
readonly REFKEY="${2:-}"

[[ -d "$DIR" ]] || die "not a directory: $DIR"
[[ -z "$REFKEY" || -f "$REFKEY" ]] || die "reference key not found: $REFKEY"

WORK="$(mktemp -d)" || die "mktemp failed"
readonly WORK
trap 'rm -rf -- "$WORK"' EXIT INT TERM

# ------------------------------------------------------- dependency checking --
check_deps() {
    local missing=() t
    for t in openssl xxd python3 dumpimage strings dd awk; do
        command -v "$t" >/dev/null 2>&1 || missing+=("$t")
    done
    if ((${#missing[@]})); then
        printf 'Missing required tools: %s\n\n' "${missing[*]}" >&2
        printf 'Install hints:\n' >&2
        printf '  strings/xxd  -> apt install binutils xxd\n'           >&2
        printf '  dumpimage    -> apt install u-boot-tools\n'           >&2
        printf '  openssl      -> apt install openssl\n'                >&2
        die "aborting rather than producing a misleading report"
    fi
}

# ------------------------------------------------------------ entropy helper --
write_entropy_helper() {
    cat > "$WORK/ent.py" <<'PY'
import sys, math, collections

def H(b):
    if not b:
        return 0.0
    c = collections.Counter(b)
    n = len(b)
    return max(0.0, -sum((v / n) * math.log2(v / n) for v in c.values()))

mode, path = sys.argv[1], sys.argv[2]
skip = int(sys.argv[3]) if len(sys.argv) > 3 else 0
data = open(path, 'rb').read()[skip:]

if mode == 'h':
    print(f"{H(data):.3f}")
elif mode == 'win':
    W = int(sys.argv[4])
    for off in range(0, len(data), W):
        w = data[off:off + W]
        if len(w) < W // 2:
            break
        h = H(w)
        print(f"  +0x{off + skip:07x}  {h:5.2f}  {'#' * int(h * 5)}")
PY
}

entropy()      { python3 "$WORK/ent.py" h   "$1" "${2:-0}"; }
entropy_win()  { python3 "$WORK/ent.py" win "$1" "${2:-0}" "$WINDOW"; }

# Float compare without bc: use awk.
fge() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a>=b)}'; }
flt() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a< b)}'; }

# ------------------------------------------------------------ format probing --
magic4() { xxd -p -l 4 "$1" 2>/dev/null || echo "????????"; }

# Parse a DER SEQUENCE header at offset 0. Echoes total length (hl+body).
# Returns non-zero if offset 0 is not a plausible DER SEQUENCE.
der_seq_len() {
    local f="$1" b0 b1 l1 hl len
    b0="$(xxd -p -l 1 -s 0 "$f" 2>/dev/null)" || return 1
    [[ "$b0" == "30" ]] || return 1
    b1="$(xxd -p -l 1 -s 1 "$f")"
    l1=$((16#$b1))
    if   (( l1 <  0x80 )); then hl=2; len=$l1
    elif (( l1 == 0x81 )); then hl=3; len=$((16#$(xxd -p -l 1 -s 2 "$f")))
    elif (( l1 == 0x82 )); then hl=4; len=$((16#$(xxd -p -l 2 -s 2 "$f")))
    elif (( l1 == 0x83 )); then hl=5; len=$((16#$(xxd -p -l 3 -s 2 "$f")))
    else return 1
    fi
    echo $(( hl + len ))
}

# Carve + validate a real x509 cert at offset 0.
# Echoes "<total_len> <der_path>" on success; returns 1 otherwise.
probe_x509() {
    local f="$1" total der
    total="$(der_seq_len "$f")" || return 1
    (( total >= MIN_CERT_LEN )) || return 1          # kills the 15B/92B FPs
    der="$WORK/$(basename "$f").cert.der"
    head -c "$total" "$f" > "$der" 2>/dev/null || return 1
    openssl x509 -inform DER -in "$der" -noout 2>/dev/null || return 1
    echo "$total $der"
}

fmt_of() {
    local f="$1" m
    m="$(magic4 "$f")"
    case "$m" in
        d00dfeed)   echo "FIT" ;;
        30[0-9a-f]*) if probe_x509 "$f" >/dev/null 2>&1; then
                         echo "x509+payload"
                     else
                         echo "raw" ; fi ;;
        *)  # arm64 Image carries "ARM\x64" at offset 0x38
            if [[ "$(xxd -p -l 4 -s 56 "$f" 2>/dev/null)" == "41524d64" ]]; then
                echo "arm64-Image"
            else
                echo "raw"
            fi ;;
    esac
}

# --------------------------------------------------------- payload verdicts --
# classify <file> <skip> <declared_compression> -> verdict string
classify() {
    local f="$1" skip="${2:-0}" comp="${3:-unknown}" h plain

    h="$(entropy "$f" "$skip")"

    # NB: do NOT use `grep -q` here. Under `set -o pipefail`, grep -q exits on
    # first match, closes the pipe, `strings` dies of SIGPIPE, the pipeline
    # returns non-zero, and every file is silently misreported as having no
    # code strings. `grep -c` consumes all input, so no SIGPIPE.
    local hits
    hits="$(strings -n 8 "$f" 2>/dev/null \
            | grep -icE 'U-Boot|BL31|OP-TEE|Trusted Firmware|Linux version|GCC:' \
            || true)"
    if [[ "${hits:-0}" -gt 0 ]]; then plain="yes"; else plain="no"; fi

    printf '%s|' "$h"
    if [[ "$plain" == "yes" ]]; then
        printf 'PLAINTEXT (code strings found)'
    elif [[ "$comp" != "uncompressed" && "$comp" != "unknown" && -n "$comp" ]]; then
        printf 'COMPRESSED (%s) - entropy uninformative' "$comp"
    elif fge "$h" "$H_ENCRYPTED"; then
        printf 'HIGH ENTROPY - possibly ENCRYPTED'
    elif flt "$h" "$H_PLAINTEXT"; then
        printf 'PLAINTEXT (low entropy)'
    else
        printf 'AMBIGUOUS'
    fi
    printf '\n'
}

# ------------------------------------------------------------ FIT inspection --
fit_nodes() {   # -> "idx name size compression" per line
    dumpimage -l "$1" 2>/dev/null | awk '
        /^ Image [0-9]+ \(/ {
            if (have) print idx, name, size, comp
            idx=$2; name=$3; gsub(/[()]/,"",name)
            size="?"; comp="unknown"; have=1; next
        }
        /Data Size:/   { size=$3 }
        /Compression:/ { comp=$2 }
        END { if (have) print idx, name, size, comp }
    '
}

fit_signatures() {
    dumpimage -l "$1" 2>/dev/null \
        | awk '/Sign algo:/ {$1=$2=""; sub(/^ +/,""); print}' \
        | sort -u
}

extract_node() {
    local fit="$1" idx="$2" out="$3"
    dumpimage -T flat_dt -p "$idx" -o "$out" "$fit" >/dev/null 2>&1 && return 0
    dumpimage            -p "$idx" -o "$out" "$fit" >/dev/null 2>&1 && return 0
    return 1
}

# Nodes that are TI-encrypted regardless of device type / customer keys.
is_ti_blob() {
    case "$1" in
        tifsstub-*|tifs*|sysfw*) return 0 ;;
        *) return 1 ;;
    esac
}

# ====================================================================== main ==
check_deps
write_entropy_helper

hdr "TI K3 / AM62x Boot Chain Audit"
printf ' Deploy dir : %s\n' "$DIR"
printf ' Date       : %s\n' "$(date -u '+%Y-%m-%d %H:%M:%SZ')"
printf ' openssl    : %s\n' "$(openssl version 2>/dev/null)"
printf ' dumpimage  : %s\n' "$(dumpimage -V 2>&1 | head -1 || true)"

# -------- [1] container format + top-level x509 -------------------------------
hdr "[1] Container format & top-level TI x509 signing"
printf '%-16s %-10s %-14s %s\n' FILE MAGIC FORMAT "TI x509 CERT"
hr
declare -A FMT=() CERTLEN=() CERTDER=()
for f in "${ARTIFACTS[@]}"; do
    p="$DIR/$f"
    if [[ ! -f "$p" ]]; then
        printf '%-16s %-10s %-14s %s\n' "$f" "-" "-" "MISSING"
        continue
    fi
    fmt="$(fmt_of "$p")"; FMT[$f]="$fmt"
    certinfo="not x509-wrapped"
    if out="$(probe_x509 "$p" 2>/dev/null)"; then
        CERTLEN[$f]="${out%% *}"; CERTDER[$f]="${out##* }"
        certinfo="SIGNED (cert ${CERTLEN[$f]} B)"
    fi
    printf '%-16s %-10s %-14s %s\n' "$f" "$(magic4 "$p")" "$fmt" "$certinfo"
done
hr
printf ' NOTE: "not x509-wrapped" is expected for FIT containers - their\n'
printf '       signing lives in FIT signature nodes, checked in section [3].\n'

# -------- [2] x509-wrapped artifacts ------------------------------------------
for f in "${ARTIFACTS[@]}"; do
    [[ -n "${CERTLEN[$f]:-}" ]] || continue
    p="$DIR/$f"; der="${CERTDER[$f]}"; cl="${CERTLEN[$f]}"

    hdr "[2] $f - certificate & payload"
    openssl x509 -inform DER -in "$der" -noout -subject -issuer 2>/dev/null \
        | sed 's/^/  /'
    printf '  key        : %s\n' \
        "$(openssl x509 -inform DER -in "$der" -noout -text 2>/dev/null \
            | awk '/Public-Key:/{gsub(/[()]/,""); print $2, $3; exit}')"
    printf '  sig alg    : %s\n' \
        "$(openssl x509 -inform DER -in "$der" -noout -text 2>/dev/null \
            | awk '/Signature Algorithm:/{print $3; exit}')"
    printf '  cert size  : %s B\n' "$cl"
    printf '  payload    : %s B (after cert)\n' "$(( $(stat -c%s "$p") - cl ))"

    IFS='|' read -r h verdict < <(classify "$p" "$cl" uncompressed)
    printf '  payload H  : %s bits/byte\n' "$h"
    printf '  verdict    : %s\n' "$verdict"

    printf '\n  Sliding-window entropy profile (window=%s B, offset from file start):\n' "$WINDOW"
    entropy_win "$p" "$cl" | head -80 || true
    printf '\n  READ THIS AS: a flat ~7.9+ region is TIFS, which TI ships\n'
    printf '  encrypted on GP/HS-FS/HS-SE alike. The R5 SPL region (~5.5-6.8)\n'
    printf '  is the part customer SMEK encryption would change.\n'
done

# -------- [3] FIT containers ---------------------------------------------------
for f in "${ARTIFACTS[@]}"; do
    p="$DIR/$f"
    [[ -f "$p" && "${FMT[$f]:-}" == "FIT" ]] || continue

    hdr "[3] $f - FIT nodes & signatures"

    sigs="$(fit_signatures "$p")"
    if [[ -n "$sigs" ]]; then
        printf ' FIT signature nodes present:\n'
        printf '%s\n' "$sigs" | sed 's/^/   /'
        if printf '%s' "$sigs" | grep -qi 'custMpk'; then
            printf '   >> key name "custMpk" = TI DUMMY KEY (not a customer key)\n'
        fi
    else
        printf ' FIT signature nodes: NONE FOUND\n'
        printf '   >> this container is not signed by U-Boot FIT verified boot.\n'
        printf '   >> (TI x509 wrapping of individual nodes is checked below.)\n'
    fi

    printf '\n %-4s %-22s %10s %-14s %6s  %s\n' \
        IDX NODE SIZE COMPRESSION H VERDICT
    hr
    n=0
    while read -r idx name size comp; do
        [[ -n "$idx" ]] || continue
        if (( n >= MAX_NODES )); then
            printf ' ... (remaining nodes not analysed; MAX_NODES=%s)\n' "$MAX_NODES"
            break
        fi
        n=$((n+1))

        out="$WORK/${f}.node${idx}.bin"
        if ! extract_node "$p" "$idx" "$out"; then
            printf ' %-4s %-22s %10s %-14s %6s  %s\n' \
                "$idx" "$name" "$size" "$comp" "-" "EXTRACT FAILED"
            continue
        fi

        # Is this node itself TI x509-wrapped?
        nskip=0; nsig="unsigned"
        if nout="$(probe_x509 "$out" 2>/dev/null)"; then
            nskip="${nout%% *}"; nsig="x509(${nskip}B)"
        fi

        IFS='|' read -r h verdict < <(classify "$out" "$nskip" "$comp")
        is_ti_blob "$name" && verdict="$verdict [TI-encrypted blob - expected]"

        printf ' %-4s %-22s %10s %-14s %6s  %s\n' \
            "$idx" "$name" "$size" "$comp" "$h" "$nsig / $verdict"
    done < <(fit_nodes "$p")
    hr
done

# -------- [4] key binding ------------------------------------------------------
hdr "[4] Key binding"
if [[ -n "$REFKEY" ]]; then
    refmod="$(openssl rsa -in "$REFKEY" -noout -modulus 2>/dev/null \
           || openssl rsa -pubin -in "$REFKEY" -noout -modulus 2>/dev/null || true)"
    if [[ -z "$refmod" ]]; then
        printf ' Could not read an RSA key from %s\n' "$REFKEY"
    else
        for f in "${ARTIFACTS[@]}"; do
            [[ -n "${CERTDER[$f]:-}" ]] || continue
            openssl x509 -inform DER -in "${CERTDER[$f]}" -noout -pubkey \
                > "$WORK/c.pub" 2>/dev/null || continue
            cm="$(openssl rsa -pubin -in "$WORK/c.pub" -noout -modulus 2>/dev/null || true)"
            if [[ -n "$cm" && "$cm" == "$refmod" ]]; then
                printf ' %-16s MATCH   -> bound to %s\n' "$f" "$REFKEY"
            else
                printf ' %-16s NO MATCH vs %s\n' "$f" "$REFKEY"
            fi
        done
    fi
else
    printf ' (no reference key given - pass custMpk.pem as arg 2 to compare)\n'
    printf ' Cert public-key fingerprints:\n'
    for f in "${ARTIFACTS[@]}"; do
        [[ -n "${CERTDER[$f]:-}" ]] || continue
        fp="$(openssl x509 -inform DER -in "${CERTDER[$f]}" -noout -pubkey 2>/dev/null \
              | openssl pkey -pubin -outform DER 2>/dev/null | sha256sum | cut -c1-32)"
        printf '   %-16s SHA256(SPKI)[0:32] = %s\n' "$f" "$fp"
    done
fi

# -------- [5] summary ----------------------------------------------------------
hdr "[5] How to read this report"
cat <<'EOF'
 SIGNING
   tiboot3.bin  -> must show "SIGNED (cert ~2000+ B)" in [1].
   tispl.bin /
   u-boot.img   -> FIT: check [3]. Either FIT signature nodes are listed,
                   OR each node shows x509(NNNN B). One of the two must hold.
   fitImage     -> FIT signature nodes with sha512,rsa4096:<keyname>.

 ENCRYPTION  (customer SMEK - only possible on HS-SE)
   Look at the per-node H column in [3]:
     H < 7.0                      -> plaintext
     compression != uncompressed  -> entropy meaningless, node is compressed
     H >= 7.9 AND uncompressed
         AND node is not tifsstub/tifs -> candidate for real encryption
   If every non-TI node is plaintext/compressed, NOTHING is customer-encrypted.
   On HS-FS that is the expected result: no SMEK is fused, so there is no
   customer key to encrypt to.

 KEY
   Key name "custMpk" or a modulus matching the in-tree custMpk.pem means the
   TI DUMMY key. The private half is public - this is a working pipeline, not
   a root of trust. Only a fused SMPK (HS-SE) makes it one.

 LIMITS OF THIS SCRIPT (read before drawing conclusions)
   - Entropy is evidence, not proof. The authoritative encryption flag lives
     in TI-private x509 extensions whose OIDs are documented under NDA in
     TI_SECURE_DEV_PKG / core-secdev-k3. Check the cert template there.
   - It does not verify signatures cryptographically, only that a valid cert
     is present and which key it binds to.
   - It does not check the U-Boot DTB for the embedded FIT public key.
EOF

exit 0
