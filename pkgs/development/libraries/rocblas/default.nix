{ stdenv, fetchFromGitHub, cmake, pkgconfig, libunwind, python
, rocr, hcc, hcc-lld, hip, rocm-cmake, comgr
, doCheck ? false
# Tensile slows the build a lot, but can produce a faster rocBLAS
, useTensile ? true, rocblas-tensile ? null
, gfortran, liblapack, boost, gtest }:
let pyenv = python.withPackages (ps:
               with ps; [pyyaml pip wheel setuptools virtualenv]); in
assert useTensile -> rocblas-tensile != null;
stdenv.mkDerivation rec {
  name = "rocblas";
  version = "2.7.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocBLAS";
    # rev = with stdenv.lib.versions;
    #   "rocm-${stdenv.lib.concatStringsSep
    #             "." [(major version) (minor version)]}";
    # sha256 = "0ydzbwxq84ng1ka1ax78mvqx3g37ckbwz2l23iqg7l1qa1q0ymmg";
    # rev = "39b5e1e3d73f11821babd9ccfd796fc63e16a12c";
    # sha256 = "0niw49bkq7wyh7a4k3250g4mz7837g0kv66brqyq4gisvdgs8f83";

    rev = "2b1befc1e791998f00f1bf1e71f7ca4b2490cb2c";
    sha256 = "1qvkn208qf6zxdr9vlx70rm68vmcdxskg745i026xczpk107faxk";
  };
  nativeBuildInputs = [ cmake rocm-cmake pkgconfig python ];

  buildInputs = [ libunwind pyenv hip rocr comgr ]
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
    patchShebangs ./header_compilation_tests.sh
    sed -e '/include(virtualenv)/d' \
        -e '/virtualenv_install.*/d' \
        -e 's|/opt/rocm/hcc|${hcc}|' \
        -e 's|/opt/rocm/hip|${hip}|' \
        -i CMakeLists.txt
    sed '/add_custom_command(/,/^ )/d' -i library/src/CMakeLists.txt
  '';
}
