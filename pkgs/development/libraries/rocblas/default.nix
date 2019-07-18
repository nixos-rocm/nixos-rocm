{ stdenv, fetchFromGitHub, cmake, pkgconfig, libunwind, python
, rocr, hcc, hcc-lld, hip, rocm-cmake
, doCheck ? false
# Tensile slows the build a lot, but can produce a faster rocBLAS
, useTensile ? true, rocblas-tensile ? null
, gfortran, liblapack, boost, gtest }:
let pyenv = python.withPackages (ps:
               with ps; [pyyaml pip wheel setuptools virtualenv]); in
assert useTensile -> rocblas-tensile != null;
stdenv.mkDerivation rec {
  name = "rocblas";
  version = "2.6.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocBLAS";
    rev = with stdenv.lib.versions; 
      "rocm-${stdenv.lib.concatStringsSep 
                "." [(major version) (minor version)]}";
    sha256 = "1zydaqrp03yd0plq3cvcw425wad9v5wraikqbdjp0djfmcd6xv2g";
  };
  nativeBuildInputs = [ cmake rocm-cmake pkgconfig python ];

  buildInputs = [ libunwind pyenv hip rocr ]
    ++ stdenv.lib.optionals doCheck [ gfortran boost gtest liblapack ];

  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=${hip}/bin/hipcc"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DBUILD_WITH_TENSILE=${if useTensile then "ON" else "OFF"}"
  ] ++ stdenv.lib.optionals doCheck [
    "-DBUILD_CLIENTS_SAMPLES=YES"
    "-DBUILD_CLIENTS_TESTS=YES"
    "-DBUILD_CLIENTS_BENCHMARKS=YES"
  ] ++ stdenv.lib.optionals useTensile [
    "-DVIRTUALENV_HOME_DIR=${rocblas-tensile}"
    "-DTensile_TEST_LOCAL_PATH=${rocblas-tensile}"
    "-DTensile_ROOT=${rocblas-tensile}/bin"
    "-DTensile_LOGIC=hip_lite"
  ];

  patchPhase = ''
    sed -e '/include(virtualenv)/d' \
        -e '/virtualenv_install.*/d' \
        -e 's|/opt/rocm/hcc|${hcc}|' \
        -e 's|/opt/rocm/hip|${hip}|' \
        -i CMakeLists.txt
  '';
}
