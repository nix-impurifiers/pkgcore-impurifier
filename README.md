# pkgcore-impurifier

Build PMS overlays that transport Nix applications through native pkgcore
`pmerge` transactions. pkgcore owns package files, configuration and integration;
the [impurifier engine](https://github.com/nix-impurifiers/impurifier) realizes
closures and atomically publishes `/opt/nix/profile`. Original code is MIT.
Application and upstream tooling licenses remain their own.

```nix
let
  impurifier = inputs.pkgcore-impurifier.lib.pkgcore-impurifier { inherit pkgs; };
in impurifier.makeOverlay {
  packages = [
    impurifier.runtimeOverlay
    (impurifier.makeOfflineEbuild { pkg = pkgs.hello; })
  ];
}
```

Put the output at a persistent path and register it in the selected Portage
configuration's `repos.conf`. Install `sys-apps/pkgcore-impurifier`, then run
`pkgcore-impurifier --oneshot app-misc/hello-offline`. The flake's `adapter`
package bootstraps that same command before the runtime is installed. Native
Nix and Python providers must already exist; `makeRuntimeOverlay` accepts
`nixDependency` and other dependency overrides. A native Nix installer is
explicitly deferred.

`makeNetEbuild`, `makeOfflineEbuild`, `makePackage`, `buildEbuild`, and
`makeOverlay` expose the PMS emitter. `makePackage` returns `net` and `offline`
outputs. They use distinct package names and conflicting native dependencies.
This pkgcore resolver rejects a conflicting installed flavor; remove it with
`pkgcore-impurifier --unmerge app-misc/hello-net` before installing
`app-misc/hello-offline`. This is two native transactions, so there is an
availability gap. The pinned native pkgcore client also deletes edited configuration
on unmerge, including a flavor switch. Back up configuration before removal.
Same-name upgrades use native CONFIG_PROTECT; the adapter does not override
upstream file ownership policy. Offline payloads include the complete closure; the net
variant retains its declared Nix installable. Runtime dependency versions
currently derive from the pinned shared engine source timestamp.

Application arguments include native `hostDependencies`, `category`, `license`,
`licenseFiles`, configuration files, users, directories, lifecycle hooks and
explicit host library bindings. SPDX application license IDs are the default;
provide matching license files for custom native names. PMS-incompatible
versions need an explicit `version`. `buildEbuild` defaults to no activation.
`makeOverlay` merges versions and manifests while rejecting conflicting files.
OpenRC and native shadow tools are the defaults; explicit systemd and runit
service declarations select those protocols. Configuration uses CONFIG_PROTECT.

The adapter waits for actual `pmerge` and reconciles once after the transaction,
including failed transactions that may have modified native inventory. Phase
hooks defer only when the waiting adapter is a live ancestor. Direct `pmerge`
uses per-package phase activation. Unrelated native driver updates must use the
adapter or be followed by `nix-profile-engine reconcile`. This does not install
Portage's `post_emerge` hook or assume pkgcore calls it. Native command failure
and activation failure both produce a failing adapter status; retry reconcile
after repairing unresolved intent. Failed realization retains the published
profile. Help, pretend and fetch-only commands do not activate pending intent.
Foreign root/domain options are rejected by the adapter; phase hooks independently
reject a foreign target root. This is a host adapter.

`nix flake check -L` uses QEMU, the real pinned pkgcore client, and pinned Gentoo
OpenRC userspace. The fixture supplies Nix and Python beforehand. The outer
kernel is NixOS; these checks do not establish a full Gentoo boot or installer.
Upstream Python dependencies and native pkgcore tooling are pinned separately
in `nix/tools.nix`; public emitters need only the standard library and Nix tools.

## Native payloads and bundled clients

`makeNativeEbuild { name; version; payload; license; dependencies?; ... }` emits
a native overlay from a producer-prepared filesystem tree, without activation
or an implicit Nix dependency. The producer supplies a working target layout;
this does not relocate binaries. The VM uses actual pmerge with a separate native
ROOT, executes the installed static payload in that root without `/nix`, then
upgrades and removes it. The native target needs its ordinary package database
and world-file foundation.

`makeRuntimeOverlay` optionally accepts `bundledNixStore` and
`bundledNixNotices`. Supply a static ELF client and its upstream notices. Bundling
omits the default native Nix requirement; Python remains required. Compatible
external clients take precedence, explicit `IMPURIFIER_NIX_STORE` disables
fallback, and failed mutations are never retried through another client. A
separate bundled-client VM repeats the original pkgcore lifecycle suite with an
incompatible external candidate. Nix provisioning remains deferred.

The pinned pkgcore SDK corrects separate-ROOT unmerge to apply its root offset
before the live-files intersection. The original SDK checked host-root files
first, dropped them from the removal set, then removed only inventory. The VM
requires the installed files to disappear; this fixture fix changes no emitted
package format. Other native client versions need their own separate-root
unmerge compatibility check.
