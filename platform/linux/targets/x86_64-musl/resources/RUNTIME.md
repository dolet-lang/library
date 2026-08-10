# x86_64 musl target runtime

These target-owned startup objects and static archives were built from the
official musl 1.2.6 release with `--prefix=/usr --disable-shared`.

They are link-time resources for Dolet-generated LLVM objects. They are not a
host toolchain and do not make the compiler platform-aware; the target manifest
selects them through the generic `pre_objects`, `post_objects`, and library
contracts.

The upstream copyright and license are preserved in `MUSL-COPYRIGHT`.
