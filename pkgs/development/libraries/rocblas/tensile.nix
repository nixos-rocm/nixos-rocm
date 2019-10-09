{ fetchFromGitHub, buildPythonPackage, pyyaml, pytest, lib, rocminfo, hcc, rocm-smi }:
buildPythonPackage rec {
  pname = "Tensile";
  version = "2.9.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "Tensile";
    rev = with lib.versions; 
      "rocm-${lib.concatStringsSep "." [(major version) (minor version)]}";
    sha256 = "1a77dn8b4wk5pzba3261sjwcf5mrkqb086xhgpyp29im9rdm7lmv";
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
