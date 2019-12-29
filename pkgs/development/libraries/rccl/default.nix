{ stdenv, fetchFromGitHub, fetchpatch, cmake, pkgconfig, numactl
, rocm-cmake, hcc, hip, comgr
, doCheck ? false, gtest }:
stdenv.mkDerivation rec {
  name = "rccl";
  version = "3.0.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rccl";
    rev = version;
    sha256 = "1mxmn0zsijvgk1mkfvsqji0czqlc4p9x45p31i8xiahhc59qq68w";
  };
  nativeBuildInputs = [ cmake pkgconfig ];
  buildInputs = [ hcc hip numactl comgr ];
  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=${hip}/bin/hipcc"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DROCM_DIR=${rocm-cmake}/share/rocm/cmake"
    "-DBUILD_DOC=OFF"
  ];
  inherit doCheck;

  # Revert a patch that removed gfx803 as a GPU target
  patches = [ (fetchpatch {
    url = "https://github.com/ROCmSoftwarePlatform/rccl/commit/58a6e535f6bf62742e1f2431f77ad2e34114d51a.patch";
    sha256 = "02n8pk998gvn7ivkk36l3pnsraxgjc09bfbifydizpj1qka5kwg5";
    revert = true;
  })];

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
