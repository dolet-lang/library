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
    andq $-16, %rsp
    call main
    movl %eax, %edi
    movq $231, %rax          /* exit_group */
    syscall
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
