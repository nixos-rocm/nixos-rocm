{ stdenv, fetchFromGitHub, lib, config, cmake, pkgconfig, libunwind, python
, rocr, hcc, hcc-unwrapped, hip, rocm-cmake, comgr, clang
, llvm, openmp, makeWrapper
, doCheck ? false
# Tensile slows the build a lot, but can produce a faster rocBLAS
, useTensile ? true, rocblas-tensile ? null
, gfortran, liblapack, boost, gtest, openblas }:
let pyenv = python.withPackages (ps:
               with ps; [pyyaml pip wheel setuptools virtualenv]); in
assert useTensile -> rocblas-tensile != null;
stdenv.mkDerivation rec {
  name = "rocblas";
  version = "3.3.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocBLAS";
    rev = "rocm-${version}";
    sha256 = "1rjwx14zq9b31n58fdfarw2ray0i51vmawvl15ciiggpk24w2gfz";
  };

  inherit doCheck;

  nativeBuildInputs = [ cmake rocm-cmake pkgconfig python ];

  buildInputs = [ libunwind pyenv hip rocr comgr llvm openmp hcc ]
                ++ stdenv.lib.optionals doCheck [ gfortran boost gtest liblapack openblas makeWrapper ];

  CXXFLAGS = "-D__HIP_PLATFORM_HCC__";
  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=${hcc}/bin/hcc"
    "-DCMAKE_C_COMPILER=${clang}/bin/clang"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DBUILD_WITH_TENSILE=${if useTensile then "ON" else "OFF"}"
    ''-DAMDGPU_TARGETS=${lib.strings.concatStringsSep ";" (config.rocmTargets or ["gfx803" "gfx900" "gfx906"])}''
  ] ++ stdenv.lib.optionals doCheck [
    "-DBUILD_CLIENTS_SAMPLES=NO"
    "-DBUILD_CLIENTS_TESTS=YES"
    "-DBUILD_CLIENTS_BENCHMARKS=NO"
    "-DLINK_BLIS=NO"
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

    substituteInPlace ./clients/benchmarks/CMakeLists.txt \
        --replace 'cblas lapack roc::rocblas' 'blas cblas lapack roc::rocblas'

    substituteInPlace ./clients/gtest/CMakeLists.txt \
        --replace 'cblas lapack roc::rocblas' 'blas cblas lapack roc::rocblas'

    patchShebangs ./clients/common/rocblas_gentest.py
  '';

  preBuild = stdenv.lib.optional doCheck ''
    cp -r ../clients/gtest/ clients/
  '';

  # not used, because GPU is not available during building
  #checkPhase = ''
  #  export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$(pwd)/library/src/"
  #  clients/staging/rocblas-test
  #'';

  postInstall = stdenv.lib.optional doCheck ''
    mkdir -p $out/bin/
    mkdir -p $out/test/
    cp clients/staging/rocblas-test $out/bin/
    cp clients/staging/rocblas_gtest.data $out/test/

    wrapProgram $out/bin/rocblas-test --add-flags "--data $out/test/rocblas_gtest.data"
  '';
}
