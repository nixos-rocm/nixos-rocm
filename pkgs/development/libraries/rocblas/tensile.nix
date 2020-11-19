{ stdenv, lib, config, fetchFromGitHub
, buildPythonPackage, pyyaml, pytest, msgpack
, rocminfo, rocm-smi, hip-clang }:
buildPythonPackage rec {
  pname = "Tensile";
  version = "3.9.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "Tensile";
    rev = "rocm-${version}";
    sha256 = "0xrv7fvdj4g14l65rzrfajpx4wg7ldd2jh5rc7bzl22qd217iv9a";
  };
  buildInputs = [ pyyaml pytest ];
  propagatedBuildInputs = [ msgpack ];

  # The last patch restores compatibility with GCC 9.2's STL.
  # See: https://github.com/ROCmSoftwarePlatform/rocBLAS/issues/845

  postPatch = ''
    sed -e 's|locateExe("/opt/rocm/bin", "rocm_agent_enumerator")|locateExe("${rocminfo}/bin", "rocm_agent_enumerator")|' \
        -e 's|locateExe("/opt/rocm/bin", "rocm-smi")|locateExe("${rocm-smi}/bin", "rocm-smi")|' \
        -e 's|locateExe("/opt/rocm/bin", "extractkernel")|locateExe("${hip-clang}/bin", "extractkernel")|' \
        -i Tensile/Common.py
  '';

  # We need patched source files in the output, so we can't symlink
  # from $src.
  preFixup = ''
    cp -r Tensile/Source $out
  '';
}
