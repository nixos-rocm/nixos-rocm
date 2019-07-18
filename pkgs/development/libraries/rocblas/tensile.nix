{ fetchFromGitHub, buildPythonPackage, pyyaml, pytest, lib, rocminfo, hcc, rocm-smi }:
buildPythonPackage rec {
  pname = "Tensile";
  version = "2.6.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "Tensile";
    rev = with lib.versions; 
      "rocm-${lib.concatStringsSep "." [(major version) (minor version)]}";
    sha256 = "09qql1br23ldjmp61lgwgylsbdhwjysg9s022ivsjw6ix1cc5p8z";
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
