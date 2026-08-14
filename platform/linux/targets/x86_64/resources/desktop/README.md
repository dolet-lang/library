# Linux desktop link SDK

This directory is the target-owned link boundary for graphical
`linux/x86_64` applications. It is selected automatically when resolved Dolet
source declares X11 or Vulkan; applications still use the single public
`linux/x86_64` target.

- `entry_helpers.o` preserves ELF-loader TLS, enters through
  `__libc_start_main` (so libc/pthread initialization and finalization follow
  the System V ABI), and provides the syscall gateway.
- `runtime_helpers.o` supplies Dolet arena/heap state and opaque pthread-backed
  thread handles for loader-compatible desktop threads.
- `exports.map` keeps Dolet application functions local to the executable.
  Names such as `read`, `write`, `socket`, and `connect` therefore cannot
  interpose on libc calls made inside X11, Vulkan, or their dependencies.
- `libX11.so`, `libvulkan.so`, `libpthread.so`, and `libc.so` are link-time SDK inputs.
  Their SONAMEs bind deployed applications to the target Linux system's
  runtime libraries; these files are not copied beside an application.

The ordinary static profile remains CRT-free and libc-free. The desktop
profile depends on the Linux system loader only where third-party system APIs
make that ABI boundary unavoidable.
