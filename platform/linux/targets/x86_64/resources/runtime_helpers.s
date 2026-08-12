/* Pure Dolet Linux/x86_64 runtime boundary.
 *
 * This file contains only operations that require machine ABI instructions:
 * process entry, syscall register shuffling, FS setup, and clone's child-stack
 * trampoline. Allocation, files, synchronization, processes, networking, and
 * all policy remain in platform/linux/*.dlt.
 */

    .text

    .globl _start
    .type _start,@function
_start:
    xorl %ebp, %ebp

    /* Reserve one page for main-thread TLS/arena state. */
    movq $9, %rax
    xorq %rdi, %rdi
    movq $4096, %rsi
    movq $3, %rdx
    movq $34, %r10
    movq $-1, %r8
    xorq %r9, %r9
    syscall
    testq %rax, %rax
    js .Lstartup_failed

    leaq 16(%rax), %rsi
    leaq 32(%rax), %rcx
    movq %rcx, 8(%rax)
    movq $158, %rax
    movq $0x1002, %rdi       /* ARCH_SET_FS */
    syscall
    testq %rax, %rax
    js .Lstartup_failed

    andq $-16, %rsp
    call main
    movl %eax, %edi
    movq $231, %rax          /* exit_group */
    syscall

.Lstartup_failed:
    movl $127, %edi
    movq $231, %rax
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

    .globl __dolet_linux_arena_state
    .type __dolet_linux_arena_state,@function
__dolet_linux_arena_state:
    movq %fs:-8, %rax
    ret
    .size __dolet_linux_arena_state, .-__dolet_linux_arena_state

    .globl __dolet_linux_heap_state
    .type __dolet_linux_heap_state,@function
__dolet_linux_heap_state:
    leaq __dolet_heap_state(%rip), %rax
    ret
    .size __dolet_linux_heap_state, .-__dolet_linux_heap_state

    .globl __dolet_thread_spawn
    .type __dolet_thread_spawn,@function
__dolet_thread_spawn:
    pushq %rbx
    pushq %r12
    pushq %r13
    movq %rdi, %r12          /* Dolet entry function */
    movq %rsi, %r13          /* closure/environment */

    movq $9, %rax            /* mmap */
    xorq %rdi, %rdi
    movq $1048576, %rsi
    movq $3, %rdx
    movq $34, %r10
    movq $-1, %r8
    xorq %r9, %r9
    syscall
    testq %rax, %rax
    js .Lthread_failed
    movq %rax, %rbx

    movq $1048576, 8(%rbx)
    movq %r12, 16(%rbx)
    movq %r13, 24(%rbx)
    leaq 72(%rbx), %rax
    movq %rax, 56(%rbx)      /* fs:-8 -> arena state */
    leaq 64(%rbx), %r8       /* child FS base */

    leaq 1048576(%rbx), %rsi
    andq $-16, %rsi
    subq $16, %rsi
    movq %rbx, 0(%rsi)

    movq $56, %rax           /* clone */
    movq $0x003d0f00, %rdi   /* VM|FS|FILES|SIGHAND|THREAD|SYSVSEM|SETTLS|PARENT_SETTID|CHILD_CLEARTID */
    movq %rbx, %rdx          /* parent_tid */
    movq %rbx, %r10          /* child_tid / futex word */
    syscall
    testq %rax, %rax
    jz .Lthread_child
    js .Lthread_clone_failed

    movq %rbx, %rax
    popq %r13
    popq %r12
    popq %rbx
    ret

.Lthread_child:
    movq 0(%rsp), %rbx
    movq 16(%rbx), %rax
    movq 24(%rbx), %rdi
    call *%rax
    xorl %edi, %edi
    movq $60, %rax
    syscall
    hlt

.Lthread_clone_failed:
    movq $11, %rax           /* munmap */
    movq %rbx, %rdi
    movq $1048576, %rsi
    syscall
.Lthread_failed:
    xorq %rax, %rax
    popq %r13
    popq %r12
    popq %rbx
    ret
    .size __dolet_thread_spawn, .-__dolet_thread_spawn

    .globl __dolet_thread_join
    .type __dolet_thread_join,@function
__dolet_thread_join:
    testq %rdi, %rdi
    jz .Ljoin_done
    pushq %rbx
    movq %rdi, %rbx
.Ljoin_wait:
    movl 0(%rbx), %edx
    testl %edx, %edx
    jz .Ljoin_release
    movq $202, %rax          /* futex */
    movq %rbx, %rdi
    xorq %rsi, %rsi          /* FUTEX_WAIT */
    xorq %r10, %r10          /* no timeout */
    xorq %r8, %r8
    xorq %r9, %r9
    syscall
    jmp .Ljoin_wait
.Ljoin_release:
    movq 8(%rbx), %rsi
    testq %rsi, %rsi
    jz .Ljoin_pop
    movq $11, %rax           /* munmap */
    movq %rbx, %rdi
    syscall
.Ljoin_pop:
    popq %rbx
.Ljoin_done:
    ret
    .size __dolet_thread_join, .-__dolet_thread_join

    .bss
    .p2align 6
__dolet_heap_state:
    .zero 64

    .section .note.GNU-stack,"",@progbits
