# Product

pkgcore is its own native transaction target. Reuse PMS overlay concepts while
validating actual pmerge semantics independently of Portage. Nix builds the
application; pkgcore owns host files; the shared engine owns profile generations.
Original code is MIT. A native Nix provider/installer remains deferred.

See ../../README.md for the public API and verified native limitations.
