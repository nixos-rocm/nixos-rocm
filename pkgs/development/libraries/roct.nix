{ stdenv, fetchFromGitHub, cmake, pkgconfig, pciutils, numactl }:

stdenv.mkDerivation rec {
  version = "3.0.0";
  name = "roct";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCT-Thunk-Interface";
    rev = "roc-${version}";
    sha256 = "0dxr6hdxpn3ma97lljchmn84vx1gzi6n05cxrasl9ql6f0yg5qjf";
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
