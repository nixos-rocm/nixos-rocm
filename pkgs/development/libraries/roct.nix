{ stdenv, fetchFromGitHub, cmake, pkgconfig, pciutils, numactl }:

stdenv.mkDerivation rec {
  version = "2.8.0";
  name = "roct";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCT-Thunk-Interface";
    rev = "roc-${version}";
    sha256 = "1zmrb2qydbdahy2kcmijmjn24jirm01pba9pjz4rkydra2y9y5bc";
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
