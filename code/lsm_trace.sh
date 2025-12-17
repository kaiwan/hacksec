#!/bin/bash
# lsm_trace.sh
name=$(basename $0)

die()
{
echo >&2 "FATAL: $*" ; exit 1
}
warn()
{
echo >&2 "WARNING: $*"
}

# runcmd
# Parameters
#   $1 ... : params are the command to run
runcmd()
{
	[[ $# -eq 0 ]] && return
	echo "$@"
	eval "$@"
}


#--- 'main'
[[ $# -eq 0 ]] && die "Usage: ${name} <cmd-to-trace>"
### *** NOTE *** this makes this script DANGEROUS!! we happily execute whatever cmd's passed as root !!!

cmd="$*"
runcmd "sudo trace-cmd record -p function_graph -g '*security_*' ${cmd}"
runcmd "sudo trace-cmd report > lsm_report.txt"
runcmd "ls -l lsm_report.txt"
runcmd "sudo rm -f trace.dat"

exit 0
