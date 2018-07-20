{ stdenv, fetchFromGitHub, cmake, pkgconfig, pciutils, numactl }:

stdenv.mkDerivation rec {
  version = "1.8.2";
  name = "roct";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCT-Thunk-Interface";
    rev = "roc-${version}";
    sha256 = "0yng7jfiq5d8h4qcavndw6frb75wp815ccp91xws61xxh1v96388";
  };

  preConfigure = ''
    export cmakeFlags="$cmakeFlags -DCMAKE_MODULE_PATH=$PWD/cmake_modules"
  '';

  enableParallelBuilding = true;
  buildInputs = [ cmake pkgconfig pciutils numactl ];

  postInstall = ''
    cp -r $src/include $out
  '';

  fixupPhase = ''
    mv $out/libhsakmt/* $out
    rmdir $out/libhsakmt
  '';
}
