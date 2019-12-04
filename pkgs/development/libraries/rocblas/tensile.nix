{ fetchFromGitHub, buildPythonPackage, pyyaml, pytest, lib, config, rocminfo, hcc, rocm-smi }:
buildPythonPackage rec {
  pname = "Tensile";
  # version = "2.10.0";
  version = "20191126";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "Tensile";
    # rev = with lib.versions;
    #   "rocm-${lib.concatStringsSep "." [(major version) (minor version)]}";
    # sha256 = "16f3419srklh3c5d5s11vjwk5s16k831l6zbgvwbmc26gk5i5qky";
    rev = "b4f5d1f996b9ce8fbe35972f94cddeb1346bd597";
    sha256 = "0gd7wlbgrn5gl74m6w95i9qkiac6042n4zbz6dwkzbllv29fly6y";
  };
  buildInputs = [ pyyaml pytest ];

  postPatch = ''
    sed -e 's|locateExe("/opt/rocm/bin", "rocm_agent_enumerator")|locateExe("${rocminfo}/bin", "rocm_agent_enumerator")|' \
        -e 's|locateExe("/opt/rocm/bin", "hcc");|locateExe("${hcc}/bin", "hcc")|' \
        -e 's|locateExe("/opt/rocm/bin", "rocm-smi")|locateExe("${rocm-smi}/bin", "rocm-smi")|' \
        -e 's|locateExe("/opt/rocm/bin", "extractkernel")|locateExe("${hcc}/bin", "extractkernel")|' \
        -i Tensile/Common.py
  '';

  # We need patched source files in the output, so we can't symlink
  # from $src.
  preFixup = ''
    cp -r Tensile/Source $out
  '';
}
