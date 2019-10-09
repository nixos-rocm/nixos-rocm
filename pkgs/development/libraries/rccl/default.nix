{ stdenv, fetchFromGitHub, cmake, pkgconfig, numactl
, rocm-cmake, hcc, hip, comgr
, doCheck ? false, gtest }:
stdenv.mkDerivation rec {
  name = "rccl";
  version = "2.9.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rccl";
    rev = version;
    sha256 = "09540rqv6b7nrrjchkk35v2966f1l8wsanildwc38nngzfxxwcd3";
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

  # These get rccl building with hip-clang, though they likely break
  # rccl functionality
  patchPhase = ''
    sed '/.*hipDeviceAttributeHdpMemFlushCntl.*/d' -i src/transport/net.cc
    sed '/.*hipDeviceAttributeHdpMemFlushCntl.*/d' -i src/transport/p2p.cc
  '';

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
