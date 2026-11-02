#!/usr/bin/python3
# SPDX-License-Identifier: MIT
"""Run native pmerge, then reconcile package-owned Nix intent."""
from pathlib import Path
import subprocess
import sys


def main():
    args = sys.argv[1:]
    if any(arg in {"--root", "--prefix", "--domain"}
           or arg.startswith(("--root=", "--prefix=", "--domain=")) for arg in args):
        raise ValueError("foreign root/domain selection cannot activate the host")
    status = subprocess.run(["pmerge", *args]).returncode
    if any(arg in {"-p", "--pretend", "-f", "--fetchonly", "--fetch-only", "-h", "--help", "--version", "--list-sets"} for arg in args):
        return status
    engine = Path("/usr/sbin/nix-profile-engine")
    activation = subprocess.run([str(engine), "reconcile"]).returncode if engine.exists() else 0
    return status or activation


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError) as error:
        print("pkgcore-impurifier: " + str(error), file=sys.stderr)
        sys.exit(1)
