# Trying it out
# Debian/Ubuntu: cross tools + user-mode QEMU
# $ sudo apt install gcc-aarch64-linux-gnu \
#                    qemu-user qemu-user-static
#  
# assemble + link with the cross tools
# $ aarch64-linux-gnu-as -o hello.o hello.s
# $ aarch64-linux-gnu-ld -o hello hello.o
# $ file hello
# hello: ELF 64-bit LSB executable, ARM aarch64
 
# static binary -> QEMU just runs it
# $ qemu-aarch64 ./hello
# Hello, ARM64!

	.data
msg:    .ascii  "Hello, ARM64!\n"
        len = . - msg          // length, computed at assembly time
 
        .text
        .global _start          // entry point for the linker
_start:
        // write(1, msg, len)
        mov     x0, #1          // x0 = fd (1 = stdout)
        ldr     x1, =msg        // x1 = buffer address
        mov     x2, #len        // x2 = byte count
        mov     x8, #64         // x8 = __NR_write
        svc     #0              // trap to the kernel
 
        // exit(0)
        mov     x0, #0          // x0 = status
        mov     x8, #93         // x8 = __NR_exit
        svc     #0              // trap to the kernel
# Try it:
# make
# ...
# file aarch64_hello
# aarch64_hello: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, not stripped
# $ ./aarch64_hello 
# Hello, ARM64!
#
# Whoa! How the heck did a aarch64 binary executable run on an x86_64??
# A> see this link: https://pastebin.com/0yWsjHLx
