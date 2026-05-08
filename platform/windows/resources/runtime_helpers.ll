; Windows-specific runtime helpers for Dolet
; These are required by the MSVC/COFF linker but are NOT part of the language.
; On Linux/macOS, this file is not needed.

; Microsoft linker requires _fltused for floating-point code
@_fltused = global i32 1

; Stack probe function for Windows (large stack allocations)
define void @__chkstk() {
  ret void
}
