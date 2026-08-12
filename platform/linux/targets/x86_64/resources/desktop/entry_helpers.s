/* Dynamic desktop process entry and Linux/x86_64 syscall gateway.
 *
 * The ELF loader owns FS/TLS in this profile. Unlike the static Pure Dolet
 * entry point, this code must never replace FS because X11, Vulkan and
 * pthread use the loader's TLS layout.
 */

    .text

    .globl _start
    .type _start,@function
_start:
    xorl %ebp, %ebp
    movq %rdx, %r9           /* rtld_fini from the ELF loader */
    popq %rsi                /* argc */
    movq %rsp, %rdx          /* argv */
    andq $-16, %rsp
    pushq %rax               /* preserve ABI stack alignment */
    pushq %rsp               /* stack_end */
    xorl %r8d, %r8d          /* fini: init arrays are loader-owned */
    xorl %ecx, %ecx          /* init */
    leaq main(%rip), %rdi
    call __libc_start_main@PLT
    hlt
    .size _start, .-_start

    .globl __dolet_syscall6
    .type __dolet_syscall6,@function
__dolet_syscall6:
    movq %rdi, %rax
    movq %rsi, %rdi
    movq %rdx, %rsi
    movq %rcx, %rdx
    movq %r8, %r10
    movq %r9, %r8
    movq 8(%rsp), %r9
    syscall
    ret
    .size __dolet_syscall6, .-__dolet_syscall6

    .section .note.GNU-stack,"",@progbits
