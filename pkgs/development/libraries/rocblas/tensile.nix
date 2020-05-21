{ stdenv, fetchFromGitHub, buildPythonPackage, pyyaml, pytest, lib, config
, rocminfo, rocm-smi, hip-clang }:
buildPythonPackage rec {
  pname = "Tensile";
  version = "3.5.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "Tensile";
    rev = "rocm-${version}";
    sha256 = "1pfkh64vrhykffv73p55kkiq9m2yqmi2i08bm0gzybbkny1aqpph";
  };
  buildInputs = [ pyyaml pytest ];

  # The last patch restores compatibility with GCC 9.2's STL.
  # See: https://github.com/ROCmSoftwarePlatform/rocBLAS/issues/845

  postPatch = ''
    sed -e 's|locateExe("/opt/rocm/bin", "rocm_agent_enumerator")|locateExe("${rocminfo}/bin", "rocm_agent_enumerator")|' \
        -e 's|locateExe("/opt/rocm/bin", "rocm-smi")|locateExe("${rocm-smi}/bin", "rocm-smi")|' \
        -e 's|locateExe("/opt/rocm/bin", "extractkernel")|locateExe("${hip-clang}/bin", "extractkernel")|' \
        -i Tensile/Common.py
    sed -e 's|inputOne(io, key, \*value);|inputOne(io, key.str(), *value);|' \
        -i Tensile/Source/lib/include/Tensile/llvm/YAML.hpp
  '' + lib.optionalString (stdenv.cc.isGNU && lib.versionAtLeast stdenv.cc.version "9.2") ''
    sed 's|const Items empty;|const Items empty = {};|' -i Tensile/Source/lib/include/Tensile/EmbeddedData.hpp
  '';

  # We need patched source files in the output, so we can't symlink
  # from $src.
  preFixup = ''
    cp -r Tensile/Source $out
  '';
}
