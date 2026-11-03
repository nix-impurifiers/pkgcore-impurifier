# SPDX-License-Identifier: MIT
{ pkgs }:
let
  py = pkgs.python3Packages;
  snakeoil = py.buildPythonPackage {
    pname = "snakeoil";
    version = "0.11.8.dev0";
    pyproject = true;
    src = pkgs.fetchurl {
      url = "https://github.com/pkgcore/snakeoil/archive/b5dfa3468196725f330ceea7ea0645a28ea89ac2.tar.gz";
      hash = "sha256-4ZuBx4krin3wNWk5/ovvL/7hcMUofh0Zw0jOuHPXO8U=";
    };
    build-system = [ py.flit-core ];
    pythonImportsCheck = [ "snakeoil" ];
  };
  landlock = py.buildPythonPackage {
    pname = "py-landlock";
    version = "0.1.1";
    pyproject = true;
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/83/aa/6dc19aa2393cf4d2288fe3647ade6308d66c2deb233e40e592ddce7c6330/py_landlock-0.1.1.tar.gz";
      hash = "sha256-kX6DkX6okywfEGti6Ch0VCCUc4FDYAt328zYjeq8VlY=";
    };
    build-system = [ py.setuptools ];
    pythonImportsCheck = [ "py_landlock" ];
  };
  package = py.buildPythonPackage {
    pname = "pkgcore";
    version = "0.12.49.dev0";
    pyproject = true;
    src = pkgs.fetchurl {
      url = "https://github.com/pkgcore/pkgcore/archive/005740032561a5f471fd963afc95b80c390fef03.tar.gz";
      hash = "sha256-jGtC101q33Ea67v2qAprGOWzfj1+rNFohItomE6AM0E=";
    };
    build-system = [
      py.flit-core
      snakeoil
    ];
    dependencies = [
      snakeoil
      py.lxml
      landlock
    ];
    postPatch = ''
      patchShebangs data
      # Apply ROOT before looking up live files, as install/replace already do.
      # Offsetting old_cset afterwards silently leaves all target-root files.
      python3 - <<'PYTHON'
      from pathlib import Path
      path = Path('src/pkgcore/merge/engine.py')
      source = path.read_text()
      old = 'o.cset_sources["old_cset"] = post_curry(\n                o.generate_offset_cset, o.cset_sources["old_cset"]'
      new = old.replace('old_cset', 'raw_old_cset')
      assert source.count(old) == 1
      path.write_text(source.replace(old, new))
      PYTHON
    '';
    postInstall = ''
      cat > $out/${pkgs.python3.sitePackages}/pkgcore/_const.py <<PYTHON
      INSTALL_PREFIX = "$out"
      DATA_PATH = "$out/share/pkgcore"
      CONFIG_PATH = "$out/share/pkgcore/config"
      LIBDIR_PATH = "$out/lib/pkgcore"
      EBD_PATH = "$out/lib/pkgcore/ebd"
      INJECTED_BIN_PATH = ()
      PYTHON
    '';
    pythonImportsCheck = [ "pkgcore.scripts.pmerge" ];
  };
in
{
  inherit package;
}
