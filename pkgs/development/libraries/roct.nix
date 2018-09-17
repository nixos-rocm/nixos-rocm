{ stdenv, fetchFromGitHub, cmake, pkgconfig, pciutils, numactl }:

stdenv.mkDerivation rec {
  version = "1.9.0";
  name = "roct";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCT-Thunk-Interface";
    rev = "roc-${version}";
    sha256 = "18qk90q6rx6c0bk4z9r9zbygma2bi0yzd3srb7r1iw3g46qp2bn4";
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
