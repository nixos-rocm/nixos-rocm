{ stdenv, fetchFromGitHub, fetchpatch, cmake, pkgconfig
, rocm-cmake, hcc, hip
, doCheck ? false, gtest }:
stdenv.mkDerivation rec {
  name = "rccl";
  version = "0.7.2-2018-11-29";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rccl";
    # rev = version;
    rev = "76cd53df7552ccf22e17f41788a68a5dbdbe445f";
    sha256 = "0cd2gfjwpx45vnixgvca19a7fibm6kf21yha8bimq5j2bv625arp";
  };
  patches = [(fetchpatch {
    name = "optional-tests.patch";
    url = "https://github.com/ROCmSoftwarePlatform/rccl/commit/b51b758bdfb1d0d43ff1c2466a88ef522e26f336.patch";
    sha256 = "0dwfb2g4ncnsk7cs5yhfl50m3iizmadrgs8p4pqxhz43m6r32nb9";
  })];
  nativeBuildInputs = [ cmake pkgconfig ];
  buildInputs = [ hcc hip ];
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
