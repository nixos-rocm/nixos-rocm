{ stdenv, fetchFromGitHub, cmake, pkgconfig, libunwind, python
, rocr, hcc, hcc-unwrapped, hcc-lld, hip, rocm-cmake, comgr, clang
, doCheck ? false
# Tensile slows the build a lot, but can produce a faster rocBLAS
, useTensile ? true, rocblas-tensile ? null
, gfortran, liblapack, boost, gtest }:
let pyenv = python.withPackages (ps:
               with ps; [pyyaml pip wheel setuptools virtualenv]); in
assert useTensile -> rocblas-tensile != null;
stdenv.mkDerivation rec {
  name = "rocblas";
  version = "2.9.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocBLAS";
    rev = with stdenv.lib.versions;
      "rocm-${stdenv.lib.concatStringsSep "." [(major version) (minor version)]}";
    sha256 = "0niw49bkq7wyh7a4k3250g4mz7837g0kv66brqyq4gisvdgs8f83";
  };
  nativeBuildInputs = [ cmake rocm-cmake pkgconfig python hcc-unwrapped ];

  buildInputs = [ libunwind pyenv hip rocr comgr ]
                ++ stdenv.lib.optionals doCheck [ gfortran boost gtest liblapack ];

  CXXFLAGS = "-D__HIP_PLATFORM_HCC__ -D__clang__ -D__HIP__ -fdeclspec";
  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=${hip}/bin/hipcc"
    "-DCMAKE_C_COMPILER=${clang}/bin/clang"
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
    "-DTensile_CODE_OBJECT_VERSION=V3"
    "-DTensile_COMPILER=hipcc"
  ];

  patchPhase = ''
    patchShebangs ./header_compilation_tests.sh
    sed -e '/include(virtualenv)/d' \
        -e '/virtualenv_install.*/d' \
        -e '/list( APPEND CMAKE_PREFIX_PATH \/opt\/rocm\/hcc \/opt\/rocm\/hip )/d' \
        -e 's,if( CMAKE_CXX_COMPILER MATCHES ".*/hcc$" ),if( TRUE ),' \
        -i CMakeLists.txt
    sed '/add_custom_command(/,/^ )/d' -i library/src/CMakeLists.txt
  '';
}
