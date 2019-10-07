{ fetchFromGitHub, buildPythonPackage, pyyaml, pytest, lib, rocminfo, hcc, rocm-smi }:
buildPythonPackage rec {
  pname = "Tensile";
  version = "2.7.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "Tensile";
    # rev = with lib.versions; 
    #   "rocm-${lib.concatStringsSep "." [(major version) (minor version)]}";
    # sha256 = "1yr2a67ip292jr76319nbzs4kdwnzs9v2l91zzvkyzfd0r5db7as";
    # rev = "4a6e2631cdc3beadba6ce0e6f42f3d08076290c7";
    # sha256 = "1a77dn8b4wk5pzba3261sjwcf5mrkqb086xhgpyp29im9rdm7lmv";
    rev = "596695ee129c0f558021c0f06855f046939169a6";
    sha256 = "19xqx8mbsgw8wvkjns820jmwqgxwxpw3dn2dzb8m0m91lnn8k5ra";
  };
  buildInputs = [ pyyaml pytest ];
  patchPhase = ''
    sed -e 's|locateExe("/opt/rocm/bin", "rocm_agent_enumerator")|locateExe("${rocminfo}/bin", "rocm_agent_enumerator")|' \
        -e 's|locateExe("/opt/rocm/bin", "hcc");|locateExe("${hcc}/bin", "hcc")|' \
        -e 's|locateExe("/opt/rocm/bin", "rocm-smi")|locateExe("${rocm-smi}/bin", "rocm-smi")|' \
        -e 's|locateExe("/opt/rocm/bin", "extractkernel")|locateExe("${hcc}/bin", "extractkernel")|' \
        -i Tensile/Common.py
    sed -e 's|which(\x27hcc-config\x27)|"${hcc}/bin/hcc-config"|'g \
        -e 's|which(\x27hcc\x27)|"${hcc}/bin/hcc"|' \
        -i Tensile/TensileCreateLibrary.py
  '';
}
