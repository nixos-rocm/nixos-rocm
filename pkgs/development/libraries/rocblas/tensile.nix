{ stdenv, fetchFromGitHub, buildPythonPackage, pyyaml, pytest, lib, config
, rocminfo, hcc, rocm-smi }:
buildPythonPackage rec {
  pname = "Tensile";
  version = "3.3.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "Tensile";
    rev = "rocm-${version}";
    sha256 = "1n3kqdnybp8nwhni058fhad3wwz78fqwm6cv8x0p8b7g8nlg23mh";
  };
  buildInputs = [ pyyaml pytest ];

  # The last patch restores compatibility with GCC 9.2's STL.
  # See: https://github.com/ROCmSoftwarePlatform/rocBLAS/issues/845

  postPatch = ''
    sed -e 's|locateExe("/opt/rocm/bin", "rocm_agent_enumerator")|locateExe("${rocminfo}/bin", "rocm_agent_enumerator")|' \
        -e 's|locateExe("/opt/rocm/bin", "hcc");|locateExe("${hcc}/bin", "hcc")|' \
        -e 's|locateExe("/opt/rocm/bin", "rocm-smi")|locateExe("${rocm-smi}/bin", "rocm-smi")|' \
        -e 's|locateExe("/opt/rocm/bin", "extractkernel")|locateExe("${hcc}/bin", "extractkernel")|' \
        -i Tensile/Common.py
  '' + lib.optionalString (stdenv.cc.isGNU && lib.versionAtLeast stdenv.cc.version "9.2") ''
    sed 's|const Items empty;|const Items empty = {};|' -i Tensile/Source/lib/include/Tensile/EmbeddedData.hpp
  '';

  # We need patched source files in the output, so we can't symlink
  # from $src.
  preFixup = ''
    cp -r Tensile/Source $out
  '';
}
