{ stdenv, lib, fetchFromGitHub, fetchpatch, cmake, pkgconfig, numactl
, rocm-cmake, hip, comgr
, doCheck ? false, gtest }:
stdenv.mkDerivation rec {
  name = "rccl";
  version = "3.8.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rccl";
    rev = "rocm-${version}";
    sha256 = "1v0f8qszspg7v4flfiwr1qakg37i0bphq13mfii8hq7isly0fina";
  };
  nativeBuildInputs = [ cmake pkgconfig ];
  buildInputs = [ hip numactl comgr ];
  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=${hip}/bin/hipcc"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DROCM_DIR=${rocm-cmake}/share/rocm/cmake"
  ];
  inherit doCheck;
  # NIX_CFLAGS_COMPILE="-D__HIP_VDI__";

  # NOTE: This works in a nix-shell, but not with nix-build due to user groups
  checkPhase = lib.optionalString doCheck ''
    ln -s $(dirname `pwd`)/inc $(dirname `pwd`)/include
    export NIX_LDFLAGS="$NIX_LDFLAGS -L$PWD -L${gtest}/lib"
    export LD_LIBRARY_PATH=$PWD:$LD_LIBRARY_PATH
    mkdir tests
    cd tests
    cmake ../../tests -DCMAKE_CXX_COMPILER=${hip}/bin/hipcc -DCMAKE_C_COMPILER=${hip}/bin/hipcc -DROCM_DIR=${rocm-cmake}/share/rocm/cmake -DGOOGLETEST_DIR=${gtest} -DRCCL_DIR=$(dirname $(dirname `pwd`))
    make -j $NIX_BUILD_CORES
    make test
  '';
}
