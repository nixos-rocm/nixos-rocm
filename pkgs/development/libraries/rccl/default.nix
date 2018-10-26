{ stdenv, fetchFromGitHub, fetchpatch, cmake, pkgconfig
, rocm-cmake, hcc, hip
, doCheck ? false, gtest }:
stdenv.mkDerivation rec {
  name = "rccl";
  version = "0.6.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rccl";
    # rev = version;
    rev = "0b7f928e774b4847ee39ab9131907649c055ad69";
    sha256 = "0j4bfd42wvxhvviyawy9nn7s8qc7046mnci90i4b7yy86mrxzp15";
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
