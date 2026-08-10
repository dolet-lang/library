target triple = "x86_64-unknown-linux-gnu"

; Each OS thread receives an independent 24-byte scope-arena state block.
; initialexec is valid for the main executable and avoids pthread-key lookup
; overhead on every arena access.
@__dolet_linux_arena_tls = internal thread_local(initialexec) global [24 x i8] zeroinitializer, align 8

define i64 @__dolet_linux_arena_state() nounwind readnone {
entry:
  %address = ptrtoint ptr @__dolet_linux_arena_tls to i64
  ret i64 %address
}
