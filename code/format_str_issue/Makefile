# Makefile

ALL := fmtstr_issue fmtstr_issue_relro
all: ${ALL}

fmtstr_issue: fmtstr_issue.c
	# -Wformat-security is On by default
	gcc fmtstr_issue.c -o fmtstr_issue -Wall #-Werror=format-security

# Try w/ full Read-Only Relocation (relro); marks the GOT as RO
fmtstr_issue_relro: fmtstr_issue.c
	gcc -Wl,-z,now fmtstr_issue.c -o fmtstr_issue_relro -Wall
	readelf -a ./fmtstr_issue_relro |grep -i relro
clean:
	rm -fv fmtstr_issue fmtstr_issue_relro
