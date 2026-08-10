# linux/x86_64-gnu target pack

This directory is the self-contained **link SDK** for Dolet GNU/Linux
desktop executables. It lets a Windows host produce an x86-64 PIE ELF
without using a host-installed Linux linker, sysroot, or SDK.

## Ownership

- `platform.toml` owns the GNU ABI, target triple, CRT order, linker policy,
  and default native libraries.
- `resources/` owns the startup objects and link-time library images.
- `platform/linux/*.dlt` owns Linux ABI declarations and the Dolet runtime.
- `toolchains/llvm/1/hosts/<host>/host.toml` owns host executable names.

The `.so` files in `resources/` are link-time SDK inputs. They are **not**
copied beside the application and must not be packaged with it. At run time,
the ELF loader resolves the Linux machine's `libc`, `libm`, `pthread`, X11,
Vulkan loader, and the installed Vulkan ICD/GPU driver.

Console and server programs do not acquire X11 or Vulkan dependencies.
Those libraries are linked only when source imports `sys.linux.x11`,
`sys.linux.vulkan_surface`, or another package that imports them.

## Runtime contract

The current SDK baseline was captured from Ubuntu 24.04 x86-64:

- glibc 2.39 (`libc`, `libm`, `pthread`, and CRT objects)
- GCC 13.3 (`crtbeginS`, `crtendS`, and `libgcc`)
- Xlib 1.8.7
- Vulkan loader 1.3.275

The generated executables currently require glibc 2.34 or newer and a Linux
x86-64 dynamic loader at `/lib64/ld-linux-x86-64.so.2`. Desktop applications
also require an X11 client library and Vulkan loader; Vulkan rendering needs
a working vendor ICD/driver on the destination machine.

The matching license notices are stored beside the SDK binaries as
`*-COPYRIGHT` files.

## Example

```text
doletc app.dlt --target linux/x86_64-gnu -o app
```

For a libc-independent static command-line executable, use
`linux/x86_64-musl`. The musl target is intentionally not the desktop Frog
target because X11, Vulkan, and vendor GPU drivers are dynamic system
interfaces.
