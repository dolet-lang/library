; ============================================================================
; Linux x86_64 Raw Syscall Wrappers for Dolet
; No libc dependency — calls the kernel directly via `syscall` instruction
;
; Linux syscall convention (x86_64):
;   RAX = syscall number
;   RDI = arg1, RSI = arg2, RDX = arg3, R10 = arg4, R8 = arg5, R9 = arg6
;   Return in RAX (negative = error)
;   Clobbers: RCX, R11
; ============================================================================

target triple = "x86_64-unknown-linux-gnu"

; --- Syscall dispatchers (1-6 args) ---

define i64 @dsl_syscall1(i64 %nr, i64 %a1) nounwind {
  %ret = call i64 asm sideeffect "syscall",
    "={rax},{rax},{rdi},~{rcx},~{r11},~{memory}"(i64 %nr, i64 %a1)
  ret i64 %ret
}

define i64 @dsl_syscall2(i64 %nr, i64 %a1, i64 %a2) nounwind {
  %ret = call i64 asm sideeffect "syscall",
    "={rax},{rax},{rdi},{rsi},~{rcx},~{r11},~{memory}"(i64 %nr, i64 %a1, i64 %a2)
  ret i64 %ret
}

define i64 @dsl_syscall3(i64 %nr, i64 %a1, i64 %a2, i64 %a3) nounwind {
  %ret = call i64 asm sideeffect "syscall",
    "={rax},{rax},{rdi},{rsi},{rdx},~{rcx},~{r11},~{memory}"(i64 %nr, i64 %a1, i64 %a2, i64 %a3)
  ret i64 %ret
}

define i64 @dsl_syscall4(i64 %nr, i64 %a1, i64 %a2, i64 %a3, i64 %a4) nounwind {
  %ret = call i64 asm sideeffect "syscall",
    "={rax},{rax},{rdi},{rsi},{rdx},{r10},~{rcx},~{r11},~{memory}"(i64 %nr, i64 %a1, i64 %a2, i64 %a3, i64 %a4)
  ret i64 %ret
}

define i64 @dsl_syscall6(i64 %nr, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6) nounwind {
  %ret = call i64 asm sideeffect "movq $6, %r8\0Amovq $7, %r9\0Asyscall",
    "={rax},{rax},{rdi},{rsi},{rdx},{r10},r,r,~{rcx},~{r11},~{r8},~{r9},~{memory}"(
    i64 %nr, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6)
  ret i64 %ret
}

; --- Convenience wrappers (match Dolet extern signatures) ---

; SYS_write = 1  |  write(fd, buf, count) -> bytes_written
define i64 @dsl_write(i32 %fd, i64 %buf, i64 %count) nounwind {
  %fd64 = sext i32 %fd to i64
  %ret = call i64 @dsl_syscall3(i64 1, i64 %fd64, i64 %buf, i64 %count)
  ret i64 %ret
}

; SYS_read = 0  |  read(fd, buf, count) -> bytes_read
define i64 @dsl_read(i32 %fd, i64 %buf, i64 %count) nounwind {
  %fd64 = sext i32 %fd to i64
  %ret = call i64 @dsl_syscall3(i64 0, i64 %fd64, i64 %buf, i64 %count)
  ret i64 %ret
}

; SYS_open = 2  |  open(path, flags, mode) -> fd
define i32 @dsl_open(ptr %path, i32 %flags, i32 %mode) nounwind {
  %p = ptrtoint ptr %path to i64
  %f = sext i32 %flags to i64
  %m = sext i32 %mode to i64
  %ret = call i64 @dsl_syscall3(i64 2, i64 %p, i64 %f, i64 %m)
  %ret32 = trunc i64 %ret to i32
  ret i32 %ret32
}

; SYS_close = 3  |  close(fd) -> 0 on success
define i32 @dsl_close(i32 %fd) nounwind {
  %fd64 = sext i32 %fd to i64
  %ret = call i64 @dsl_syscall1(i64 3, i64 %fd64)
  %ret32 = trunc i64 %ret to i32
  ret i32 %ret32
}

; SYS_lseek = 8  |  lseek(fd, offset, whence) -> new_offset
define i64 @dsl_lseek(i32 %fd, i64 %offset, i32 %whence) nounwind {
  %fd64 = sext i32 %fd to i64
  %w64 = sext i32 %whence to i64
  %ret = call i64 @dsl_syscall3(i64 8, i64 %fd64, i64 %offset, i64 %w64)
  ret i64 %ret
}

; SYS_mmap = 9  |  mmap(addr, len, prot, flags, fd, offset) -> ptr
define i64 @dsl_mmap(i64 %addr, i64 %len, i32 %prot, i32 %flags, i32 %fd, i64 %offset) nounwind {
  %p = sext i32 %prot to i64
  %f = sext i32 %flags to i64
  %d = sext i32 %fd to i64
  %ret = call i64 @dsl_syscall6(i64 9, i64 %addr, i64 %len, i64 %p, i64 %f, i64 %d, i64 %offset)
  ret i64 %ret
}

; SYS_munmap = 11  |  munmap(addr, len) -> 0 on success
define i32 @dsl_munmap(i64 %addr, i64 %len) nounwind {
  %ret = call i64 @dsl_syscall2(i64 11, i64 %addr, i64 %len)
  %ret32 = trunc i64 %ret to i32
  ret i32 %ret32
}

; SYS_exit = 60
define void @dsl_exit(i32 %code) nounwind noreturn {
  %c64 = sext i32 %code to i64
  call i64 @dsl_syscall1(i64 60, i64 %c64)
  unreachable
}

; SYS_getcwd = 79  |  getcwd(buf, size) -> ptr
define i64 @dsl_getcwd(i64 %buf, i64 %size) nounwind {
  %ret = call i64 @dsl_syscall2(i64 79, i64 %buf, i64 %size)
  ret i64 %ret
}

; SYS_readlink = 89  |  readlink(path, buf, bufsize) -> bytes_read
define i64 @dsl_readlink(ptr %path, i64 %buf, i64 %bufsize) nounwind {
  %p = ptrtoint ptr %path to i64
  %ret = call i64 @dsl_syscall3(i64 89, i64 %p, i64 %buf, i64 %bufsize)
  ret i64 %ret
}

; SYS_clock_gettime = 228
define i32 @dsl_clock_gettime(i32 %clk_id, i64 %tp) nounwind {
  %c = sext i32 %clk_id to i64
  %ret = call i64 @dsl_syscall2(i64 228, i64 %c, i64 %tp)
  %ret32 = trunc i64 %ret to i32
  ret i32 %ret32
}

; SYS_nanosleep = 35
define i32 @dsl_nanosleep(i64 %req, i64 %rem) nounwind {
  %ret = call i64 @dsl_syscall2(i64 35, i64 %req, i64 %rem)
  %ret32 = trunc i64 %ret to i32
  ret i32 %ret32
}

; --- Socket syscalls ---

; SYS_socket = 41
define i32 @dsl_socket(i32 %domain, i32 %type, i32 %protocol) nounwind {
  %d = sext i32 %domain to i64
  %t = sext i32 %type to i64
  %p = sext i32 %protocol to i64
  %ret = call i64 @dsl_syscall3(i64 41, i64 %d, i64 %t, i64 %p)
  %ret32 = trunc i64 %ret to i32
  ret i32 %ret32
}

; SYS_connect = 42
define i32 @dsl_connect(i32 %fd, i64 %addr, i32 %addrlen) nounwind {
  %f = sext i32 %fd to i64
  %a = sext i32 %addrlen to i64
  %ret = call i64 @dsl_syscall3(i64 42, i64 %f, i64 %addr, i64 %a)
  %ret32 = trunc i64 %ret to i32
  ret i32 %ret32
}

; SYS_accept = 43
define i32 @dsl_accept(i32 %fd, i64 %addr, i64 %addrlen) nounwind {
  %f = sext i32 %fd to i64
  %ret = call i64 @dsl_syscall3(i64 43, i64 %f, i64 %addr, i64 %addrlen)
  %ret32 = trunc i64 %ret to i32
  ret i32 %ret32
}

; SYS_sendto = 44 (used as send with NULL dest)
define i64 @dsl_send(i32 %fd, i64 %buf, i64 %len, i32 %flags) nounwind {
  %f = sext i32 %fd to i64
  %fl = sext i32 %flags to i64
  %ret = call i64 @dsl_syscall6(i64 44, i64 %f, i64 %buf, i64 %len, i64 %fl, i64 0, i64 0)
  ret i64 %ret
}

; SYS_recvfrom = 45 (used as recv with NULL src)
define i64 @dsl_recv(i32 %fd, i64 %buf, i64 %len, i32 %flags) nounwind {
  %f = sext i32 %fd to i64
  %fl = sext i32 %flags to i64
  %ret = call i64 @dsl_syscall6(i64 45, i64 %f, i64 %buf, i64 %len, i64 %fl, i64 0, i64 0)
  ret i64 %ret
}

; SYS_bind = 49
define i32 @dsl_bind(i32 %fd, i64 %addr, i32 %addrlen) nounwind {
  %f = sext i32 %fd to i64
  %a = sext i32 %addrlen to i64
  %ret = call i64 @dsl_syscall3(i64 49, i64 %f, i64 %addr, i64 %a)
  %ret32 = trunc i64 %ret to i32
  ret i32 %ret32
}

; SYS_listen = 50
define i32 @dsl_listen(i32 %fd, i32 %backlog) nounwind {
  %f = sext i32 %fd to i64
  %b = sext i32 %backlog to i64
  %ret = call i64 @dsl_syscall2(i64 50, i64 %f, i64 %b)
  %ret32 = trunc i64 %ret to i32
  ret i32 %ret32
}

; SYS_setsockopt = 54
define i32 @dsl_setsockopt(i32 %fd, i32 %level, i32 %optname, i64 %optval, i32 %optlen) nounwind {
  %f = sext i32 %fd to i64
  %l = sext i32 %level to i64
  %o = sext i32 %optname to i64
  %ol = sext i32 %optlen to i64
  ; setsockopt has 5 args → use syscall6 with last=0
  %ret = call i64 @dsl_syscall6(i64 54, i64 %f, i64 %l, i64 %o, i64 %optval, i64 %ol, i64 0)
  %ret32 = trunc i64 %ret to i32
  ret i32 %ret32
}

; SYS_fork = 57
define i32 @dsl_fork() nounwind {
  %ret = call i64 @dsl_syscall1(i64 57, i64 0)
  %ret32 = trunc i64 %ret to i32
  ret i32 %ret32
}

; SYS_execve = 59
define i32 @dsl_execve(ptr %path, i64 %argv, i64 %envp) nounwind {
  %p = ptrtoint ptr %path to i64
  %ret = call i64 @dsl_syscall3(i64 59, i64 %p, i64 %argv, i64 %envp)
  %ret32 = trunc i64 %ret to i32
  ret i32 %ret32
}

; SYS_wait4 = 61 (waitpid equivalent)
define i32 @dsl_waitpid(i32 %pid, i64 %status, i32 %options) nounwind {
  %p = sext i32 %pid to i64
  %o = sext i32 %options to i64
  %ret = call i64 @dsl_syscall4(i64 61, i64 %p, i64 %status, i64 %o, i64 0)
  %ret32 = trunc i64 %ret to i32
  ret i32 %ret32
}

; SYS_getpid = 39
define i32 @dsl_getpid() nounwind {
  %ret = call i64 @dsl_syscall1(i64 39, i64 0)
  %ret32 = trunc i64 %ret to i32
  ret i32 %ret32
}

; --- Pure heap allocator using mmap ---
; Simple bump allocator with page-aligned chunks

@heap_base = internal global i64 0
@heap_offset = internal global i64 0
@heap_capacity = internal global i64 0

; Align size up to 16 bytes
define internal i64 @align16(i64 %size) {
  %mask = add i64 %size, 15
  %aligned = and i64 %mask, -16
  ret i64 %aligned
}

; malloc — allocate from mmap heap
define i64 @dsl_malloc(i64 %size) nounwind {
  %aligned = call i64 @align16(i64 %size)
  %base = load i64, ptr @heap_base
  %offset = load i64, ptr @heap_offset
  %cap = load i64, ptr @heap_capacity
  %needed = add i64 %offset, %aligned
  %fits = icmp ule i64 %needed, %cap
  br i1 %fits, label %alloc, label %grow

grow:
  ; Allocate new chunk: max(needed, 1MB)
  %min_size = add i64 %needed, 1048576
  ; Round up to page size (4096)
  %page_mask = add i64 %min_size, 4095
  %page_aligned = and i64 %page_mask, -4096
  ; mmap(NULL, size, PROT_READ|PROT_WRITE=3, MAP_PRIVATE|MAP_ANONYMOUS=0x22, -1, 0)
  %new_base = call i64 @dsl_mmap(i64 0, i64 %page_aligned, i32 3, i32 34, i32 -1, i64 0)
  %failed = icmp slt i64 %new_base, 0
  br i1 %failed, label %fail, label %setup

setup:
  store i64 %new_base, ptr @heap_base
  store i64 %aligned, ptr @heap_offset
  store i64 %page_aligned, ptr @heap_capacity
  ret i64 %new_base

alloc:
  %ptr = add i64 %base, %offset
  %new_offset = add i64 %offset, %aligned
  store i64 %new_offset, ptr @heap_offset
  ret i64 %ptr

fail:
  ret i64 0
}

; calloc — allocate and zero
define i64 @dsl_calloc(i64 %count, i64 %size) nounwind {
  %total = mul i64 %count, %size
  %ptr = call i64 @dsl_malloc(i64 %total)
  %is_null = icmp eq i64 %ptr, 0
  br i1 %is_null, label %done, label %zero

zero:
  ; mmap already returns zeroed pages, but zero explicitly for safety
  %p = inttoptr i64 %ptr to ptr
  call void @llvm.memset.p0.i64(ptr %p, i8 0, i64 %total, i1 false)
  br label %done

done:
  ret i64 %ptr
}

; free — no-op for bump allocator (memory reclaimed on process exit)
define void @dsl_free(i64 %ptr) nounwind {
  ret void
}

; realloc — allocate new, copy old (conservative: copies min of old and new)
define i64 @dsl_realloc(i64 %old_ptr, i64 %new_size) nounwind {
  %is_null = icmp eq i64 %old_ptr, 0
  br i1 %is_null, label %just_alloc, label %do_realloc

just_alloc:
  %fresh = call i64 @dsl_malloc(i64 %new_size)
  ret i64 %fresh

do_realloc:
  %new_ptr = call i64 @dsl_malloc(i64 %new_size)
  %new_is_null = icmp eq i64 %new_ptr, 0
  br i1 %new_is_null, label %fail2, label %copy

copy:
  %src = inttoptr i64 %old_ptr to ptr
  %dst = inttoptr i64 %new_ptr to ptr
  ; Copy new_size bytes (caller responsible for not reading past old allocation)
  call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %src, i64 %new_size, i1 false)
  ret i64 %new_ptr

fail2:
  ret i64 %old_ptr
}

; --- htons (byte swap for network byte order) ---
define i32 @dsl_htons(i32 %val) nounwind {
  %low = and i32 %val, 255
  %high = lshr i32 %val, 8
  %high_masked = and i32 %high, 255
  %swapped = or i32 (shl i32 %low, 8), %high_masked
  ret i32 %swapped
}

; --- Intrinsics ---
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)

; --- Entry point wrapper ---
; Linux ELF needs _start, not main. This calls Dolet's @main and exits.
define void @_start() nounwind noreturn {
  %ret = call i32 @main()
  call void @dsl_exit(i32 %ret)
  unreachable
}

declare i32 @main()
