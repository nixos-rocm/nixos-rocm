{ stdenv, fetchFromGitHub, lib, config, cmake, pkgconfig, libunwind, python
, rocr, hcc, hcc-unwrapped, hip, rocm-cmake, comgr, clang
, llvm, openmp
, doCheck ? false
# Tensile slows the build a lot, but can produce a faster rocBLAS
, useTensile ? true, rocblas-tensile ? null
, gfortran, liblapack, boost, gtest }:
let pyenv = python.withPackages (ps:
               with ps; [pyyaml pip wheel setuptools virtualenv]); in
assert useTensile -> rocblas-tensile != null;
stdenv.mkDerivation rec {
  name = "rocblas";
  # version = "2.10.0";
  version = "20191126";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocBLAS";
    # rev = with stdenv.lib.versions;
    #   "rocm-${stdenv.lib.concatStringsSep "." [(major version) (minor version)]}";
    # sha256 = "1dfjj04f23v73wgr4mvpmw8xk5gmnky5vq6jzcy9jcm4jxc5wiyi";
    rev = "19a08bfee2750a76f412882bd1f4a72a454ef81c";
    sha256 = "1p3jnhq2svryg3js5l56jb0kdii47av846y8j2bkmf8shrkmlax0";
  };
  nativeBuildInputs = [ cmake rocm-cmake pkgconfig python ];

  buildInputs = [ libunwind pyenv hip rocr comgr llvm openmp hcc ]
                ++ stdenv.lib.optionals doCheck [ gfortran boost gtest liblapack ];

  CXXFLAGS = "-D__HIP_PLATFORM_HCC__";
  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=${hcc}/bin/hcc"
    "-DCMAKE_C_COMPILER=${clang}/bin/clang"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DBUILD_WITH_TENSILE=${if useTensile then "ON" else "OFF"}"
    ''-DAMDGPU_TARGETS=${lib.strings.concatStringsSep ";" (config.rocmTargets or ["gfx803" "gfx900" "gfx906"])}''
  ] ++ stdenv.lib.optionals doCheck [
    "-DBUILD_CLIENTS_SAMPLES=YES"
    "-DBUILD_CLIENTS_TESTS=YES"
    "-DBUILD_CLIENTS_BENCHMARKS=YES"
  ] ++ stdenv.lib.optionals useTensile [
    "-DVIRTUALENV_HOME_DIR=${rocblas-tensile}"
    "-DTensile_TEST_LOCAL_PATH=${rocblas-tensile}"
    "-DTensile_ROOT=${rocblas-tensile}"
    "-DCMAKE_POLICY_DEFAULT_CMP0074=NEW"
    "-DTensile_LOGIC=hip_lite"
  ];

  patchPhase = ''
    patchShebangs ./header_compilation_tests.sh
    sed -e '/include(virtualenv)/d' \
        -e '/virtualenv_install.*/d' \
        -e '/list( APPEND CMAKE_PREFIX_PATH \/opt\/rocm\/hcc \/opt\/rocm\/hip )/d' \
        -i CMakeLists.txt
    sed '/add_custom_command(/,/^ )/d' -i library/src/CMakeLists.txt
  '';
}
