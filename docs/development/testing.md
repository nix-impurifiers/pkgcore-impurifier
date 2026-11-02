# Testing

Run `nix flake check -L`. The emitter contract checks PMS metadata, license files,
and reference-free transport. QEMU runs pinned native pkgcore inside real Gentoo
OpenRC userspace, with the shared writable Nix store and preinstalled Nix.

The VM checks failed net substitution, read-only commands with pending intent,
native blocker rejection, explicit flavor replacement, native config deletion
on unmerge and protection on upgrade, batched reconciliation, source-free native
binpkgs after GC, lifecycle failures/retries, users, directory-only changes,
service admin intent, direct pmerge phase activation, foreign-root guards, and
native driver dependency/refresh. This is not a full Gentoo boot or Nix installer.
