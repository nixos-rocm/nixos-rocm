{ stdenv, fetchFromGitHub, cmake, pkgconfig, pciutils, numactl }:

stdenv.mkDerivation rec {
  version = "3.1.0";
  name = "roct";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCT-Thunk-Interface";
    rev = "roc-${version}";
    sha256 = "0k59vdhfr6f51v46s2x8palgswv4idjyy929h2i14s6vx2y99r63";
  };

  preConfigure = ''
    export cmakeFlags="$cmakeFlags -DCMAKE_MODULE_PATH=$PWD/cmake_modules"
  '';

  enableParallelBuilding = true;
  buildInputs = [ cmake pkgconfig pciutils numactl ];

  postInstall = ''
    cp -r $src/include $out
  '';
}
