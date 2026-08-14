; Windows-specific runtime helpers for Dolet
; These are required by the MSVC/COFF linker but are NOT part of the language.
; On Linux/macOS, this file is not needed.

; Microsoft linker requires _fltused for floating-point code
@_fltused = global i32 1

; Stack probe function for Windows (large stack allocations)
define void @__chkstk() {
  ret void
}

; Pure Dolet PE process entry. Returning from a PE entrypoint only finishes
; the initial thread, so DLL-owned workers could keep the process alive.
; Match Linux `_start`: call the user's main and terminate the whole process.
declare i32 @main()
declare void @ExitProcess(i32)

define void @_start() {
  %code = call i32 @main()
  call void @ExitProcess(i32 %code)
  unreachable
}
