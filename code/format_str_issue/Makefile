# Makefile
ALL := fmtstr_issue fmtstr_with_errorflag
all: ${ALL}

fmtstr_issue: fmtstr_issue.c
	gcc fmtstr_issue.c -o fmtstr_issue -Wall -Wformat-security
fmtstr_with_errorflag:
	$(info Build with -Werror=format-security )
	gcc fmtstr_issue.c -o fmtstr_issue_errflag -Wall -Werror=format-security

# Try w/ full Read-Only Relocation (relro); marks the GOT as RO
fmtstr_issue_relro: fmtstr_issue.c
	gcc -Wl,-z now fmtstr_issue.c -o fmtstr_issue_relro -Wall
	readelf -a ./fmtstr_issue_relro |grep -i relro

clean:
	rm -fv ${ALL}
