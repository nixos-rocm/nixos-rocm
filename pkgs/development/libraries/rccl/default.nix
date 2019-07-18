{ stdenv, fetchFromGitHub, cmake, pkgconfig, numactl
, rocm-cmake, hcc, hip
, doCheck ? false, gtest }:
stdenv.mkDerivation rec {
  name = "rccl";
  version = "2.6.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rccl";
    rev = version;
    sha256 = "0pg7vgscbbsyxqgcvwy0m2dr9b7bvwzda11k6b23b718wmzlylql";
  };
  nativeBuildInputs = [ cmake pkgconfig ];
  buildInputs = [ hcc hip numactl ];
  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=${hcc}/bin/hcc"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DROCM_DIR=${rocm-cmake}/share/rocm/cmake"
    "-DBUILD_DOC=OFF"
  ];
  inherit doCheck;

  # NOTE: This works in a nix-shell, but not with nix-build due to user groups
  checkPhase = stdenv.lib.optionalString doCheck ''
    ln -s $(dirname `pwd`)/inc $(dirname `pwd`)/include
    export NIX_LDFLAGS="$NIX_LDFLAGS -L$PWD -L${gtest}/lib"
    export LD_LIBRARY_PATH=$PWD:$LD_LIBRARY_PATH
    mkdir tests
    cd tests
    cmake ../../tests -DCMAKE_CXX_COMPILER=${hcc}/bin/hcc -DCMAKE_C_COMPILER=${hcc}/bin/clang -DROCM_DIR=${rocm-cmake}/share/rocm/cmake -DGOOGLETEST_DIR=${gtest} -DRCCL_DIR=$(dirname $(dirname `pwd`))
    make -j $NIX_BUILD_CORES
    make test
  '';
}
