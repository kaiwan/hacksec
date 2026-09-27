#!/bin/bash
# authors: claude opus 5.5 and kaiwan
name=$(basename $0)
set -euo pipefail


function interpret_report()
{
local REPORT=$1
[[ ! -f ${REPORT} ]] && {
  echo "\"${REPORT}\" not found?"
  return
}

# Count of CVEs per status
jq -r '[.package[].issue[].status] | group_by(.) | .[] | "\(.[0])\t\(length)"' ${REPORT}

# Which packages carry the most Unpatched CVEs?
jq -r '.package[] | [.name, ([.issue[] | select(.status=="Unpatched")] | length)]
       | select(.[1] > 0) | "\(.[1])\t\(.[0])"' ${REPORT} | sort -rn | head -20

# Unpatched CVEs as a table, sorted by CVSSv3 (highest first)
jq -r '.package[] | .name as $n | .version as $v | .issue[]
       | select(.status=="Unpatched")
       | [$n, $v, .id, (.scorev3 // "")] | @tsv' ${REPORT} \
  | sort -t$'\t' -k4,4gr | column -t -s$'\t' | less -S
}

DEPLOYDIR=../deploy-ti/images/am62xx-evm
IMAGENAME=core-image-minimal
function generate_report()
{
local NM=${DEPLOYDIR}/${IMAGENAME}

echo "Note:
- The image name is currently \"${IMAGENAME}\"
- The location of relevant Yocto artifacts (the .rootfs.{vex|sbom-cve-check.spdx}.json files) are currently set to this value : \"${DEPLOYDIR}\"
Update in the script as required.

Generating the report now...
"

local CMD="sbom-cve-check \
	--sbom-path ${NM}-am62xx-evm.rootfs.sbom-cve-check.spdx.json  \
	--yocto-vex-manifest ${NM}-am62xx-evm.rootfs.vex.json  \
	--export-type yocto-cve-check-manifest \
	--export-path ${1}"
echo "${CMD}"
eval "${CMD}" && ls -lh "${1}"
}

function usage()
{
echo "Usage: ${name} {option}
  -g path-to-Yocto-JSON-CVE-report : generates the JSON report to the path specified
     (curr assume the image is '${IMAGENAME}' and location of JSON files is '${DEPLOYDIR}').
  -i path-to-Yocto-JSON-CVE-report : interprets the specified JSON report, providing only relevant stats
                                     Tip: redirect the output to a file"
}

#-- 'main'

[[ $# -eq 0 ]] && {
  usage ; exit 1
}

#-- getopts
# arg debugging
#echo "
#Params: # = $# : $*
#"

# Loop through options using the built-in getopts
# ":" at the start enables silent error reporting (custom handling)
# "hvo:" means -h and -v are flags, and -o requires an argument
#while getopts ":hvo:" opt; do
while getopts ":hg:i:" opt; do
    case ${opt} in
        h)
            usage
            exit 0
            ;;
        g)
	    #echo "g passed; $OPTARG"
	    generate_report "${OPTARG}"
            ;;
        i)
	    #echo "i passed"
	    interpret_report "${OPTARG}"
            ;;
        \?)
            echo "Invalid option: -${OPTARG}" >&2
            exit 1
            ;;
        :)
            echo "Option -${OPTARG} requires an argument." >&2
            exit 1
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done
exit 0
