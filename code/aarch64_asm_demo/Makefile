# Makefile

# update for your cross toolchain
CXX := aarch64-none-linux-gnu-
AS := ${CXX}as
CC := ${CXX}gcc
LD := ${CXX}ld

all: aarch64_hello
aarch64_hello: hello.s
	${AS} -o aarch64_hello.o hello.s
	${LD} -o aarch64_hello aarch64_hello.o
	file aarch64_hello
clean:
	rm -f aarch64_hello.o aarch64_hello
