target triple = "x86_64-unknown-linux-gnu"

; The system ELF loader owns TLS for desktop processes. Initial-exec TLS is
; resolved once by the loader and keeps the arena-state lookup as cheap as a
; direct FS-relative address without colliding with glibc/X11/Vulkan TLS.
@__dolet_linux_arena_tls = internal thread_local(initialexec) global [24 x i8] zeroinitializer, align 8
@__dolet_heap_state = internal global [64 x i8] zeroinitializer, align 64

declare i64 @__dolet_syscall6(i64, i64, i64, i64, i64, i64, i64)
declare i32 @pthread_create(ptr, ptr, ptr, ptr)
declare i32 @pthread_join(i64, ptr)

define i64 @__dolet_linux_arena_state() nounwind readnone {
entry:
  %address = ptrtoint ptr @__dolet_linux_arena_tls to i64
  ret i64 %address
}

define i64 @__dolet_linux_heap_state() nounwind readnone {
entry:
  %address = ptrtoint ptr @__dolet_heap_state to i64
  ret i64 %address
}

define internal ptr @__dolet_pthread_start(ptr %raw_context) nounwind {
entry:
  %entry_slot = getelementptr i8, ptr %raw_context, i64 8
  %argument_slot = getelementptr i8, ptr %raw_context, i64 16
  %entry_address = load i64, ptr %entry_slot, align 8
  %argument = load i64, ptr %argument_slot, align 8
  %entry_function = inttoptr i64 %entry_address to ptr
  %ignored = call i64 %entry_function(i64 %argument)
  ret ptr null
}

define i64 @__dolet_thread_spawn(i64 %entry_address, i64 %argument) nounwind {
entry:
  %mapping = call i64 @__dolet_syscall6(i64 9, i64 0, i64 4096, i64 3, i64 34, i64 -1, i64 0)
  %failed = icmp slt i64 %mapping, 0
  br i1 %failed, label %return_zero, label %create

create:
  %context = inttoptr i64 %mapping to ptr
  %entry_slot = getelementptr i8, ptr %context, i64 8
  %argument_slot = getelementptr i8, ptr %context, i64 16
  store i64 %entry_address, ptr %entry_slot, align 8
  store i64 %argument, ptr %argument_slot, align 8
  %result = call i32 @pthread_create(ptr %context, ptr null, ptr @__dolet_pthread_start, ptr %context)
  %created = icmp eq i32 %result, 0
  br i1 %created, label %return_mapping, label %release

release:
  %ignored_unmap = call i64 @__dolet_syscall6(i64 11, i64 %mapping, i64 4096, i64 0, i64 0, i64 0, i64 0)
  br label %return_zero

return_mapping:
  ret i64 %mapping

return_zero:
  ret i64 0
}

define void @__dolet_thread_join(i64 %handle) nounwind {
entry:
  %is_zero = icmp eq i64 %handle, 0
  br i1 %is_zero, label %done, label %join

join:
  %context = inttoptr i64 %handle to ptr
  %thread = load i64, ptr %context, align 8
  %ignored_join = call i32 @pthread_join(i64 %thread, ptr null)
  %ignored_unmap = call i64 @__dolet_syscall6(i64 11, i64 %handle, i64 4096, i64 0, i64 0, i64 0, i64 0)
  br label %done

done:
  ret void
}
