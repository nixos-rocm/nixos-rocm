{ stdenv, lib, fetchFromGitHub, lib, config, cmake, pkgconfig, libunwind, python
, rocm-runtime, hip, rocm-cmake, comgr, clang, compiler-rt
, llvm, openmp, makeWrapper, msgpack
, doCheck ? false, gtest ? null
# Tensile slows the build a lot, but can produce a faster rocBLAS
, useTensile ? true, rocblas-tensile ? null
, gfortran, liblapack, boost, openblas 
}:

assert doCheck -> gtest != null;
assert useTensile -> rocblas-tensile != null;

let pyenv = python.withPackages (ps:
        with ps; [pyyaml pip wheel setuptools virtualenv]
  );

in stdenv.mkDerivation rec {
  name = "rocblas";
  version = "3.9.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocBLAS";
    rev = "rocm-${version}";
    sha256 = "1qn3jh82z32ab2cmcg7y517sysrd1wa7xc0wq86v9g3lim217n5i";
  };

  inherit doCheck;

  nativeBuildInputs = [ cmake rocm-cmake pkgconfig python ];

  buildInputs = [ libunwind pyenv rocm-runtime comgr llvm compiler-rt openmp 
                  hip gfortran msgpack ];

  checkInputs = [ boost gtest liblapack openblas makeWrapper ];

  CXXFLAGS = "-D__HIP_PLATFORM_HCC__";
  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=${hip}/bin/hipcc"
    "-DCMAKE_C_COMPILER=${clang}/bin/clang"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DBUILD_WITH_TENSILE=${if useTensile then "ON" else "OFF"}"
    "-DTensile_COMPILER=hipcc"
    "-DAMDGPU_TARGETS=${lib.strings.concatStringsSep ";" (config.rocmTargets or [ "gfx803" "gfx900" "gfx906" ])}"
  ] ++ lib.optionals doCheck [
    "-DBUILD_CLIENTS_SAMPLES=NO"
    "-DBUILD_CLIENTS_TESTS=YES"
    "-DBUILD_CLIENTS_BENCHMARKS=NO"
    "-DLINK_BLIS=NO"
  ] ++ lib.optionals useTensile [
    "-DVIRTUALENV_HOME_DIR=${rocblas-tensile}"
    "-DTensile_TEST_LOCAL_PATH=${rocblas-tensile}"
    "-DTensile_ROOT=${rocblas-tensile}"
    "-DCMAKE_POLICY_DEFAULT_CMP0074=NEW"
    "-DTensile_LOGIC=asm_full"
    "-DTensile_LIBRARY_FORMAT=msgpack"
    "-DTensile_ARCHITECTURE=${if (builtins.hasAttr "rocmTargets" config && builtins.length config.rocmTargets == 1) then builtins.elemAt config.rocmTargets 0 else "all"}"
    "-DTensile_CODE_OBJECT_VERSION=V3"
  ];

  # sed '/add_custom_command(/,/^ )/d' -i library/src/CMakeLists.txt
  prePatch = ''
    patchShebangs ./header_compilation_tests.sh
    sed -e '/include(virtualenv)/d' \
        -e '/virtualenv_install.*/d' \
        -i CMakeLists.txt

    substituteInPlace ./clients/benchmarks/CMakeLists.txt \
        --replace 'cblas lapack roc::rocblas' 'blas cblas lapack roc::rocblas'

    substituteInPlace ./clients/gtest/CMakeLists.txt \
        --replace 'cblas lapack roc::rocblas' 'blas cblas lapack roc::rocblas'

    patchShebangs ./clients/common/rocblas_gentest.py
  '';

  preBuild = lib.optional doCheck ''
    cp -r ../clients/gtest/ clients/
  '';

  # not used, because GPU is not available during building
  #checkPhase = ''
  #  export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$(pwd)/library/src/"
  #  clients/staging/rocblas-test
  #'';

  postInstall = lib.optional doCheck ''
    mkdir -p $out/bin/
    mkdir -p $out/test/
    cp clients/staging/rocblas-test $out/bin/
    cp clients/staging/rocblas_gtest.data $out/test/

    wrapProgram $out/bin/rocblas-test --add-flags "--data $out/test/rocblas_gtest.data"
  '';
}
