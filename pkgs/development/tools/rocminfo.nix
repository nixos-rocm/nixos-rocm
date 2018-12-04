{ stdenv, fetchFromGitHub, cmake, rocr, python, rocm-cmake }:

stdenv.mkDerivation rec {
  version = "2018-11-12";
  name = "rocminfo";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocminfo";
    rev = "1bb0ccc731f772bb1a553e37b41d06eb0a684926";
    sha256 = "0mrk31ysszk04841wak63zlrvmfjhw4hn0yfm3258q7vi080785z";
  };

  enableParallelBuilding = true;
  buildInputs = [ cmake rocm-cmake ];
  cmakeFlags = [
    "-DROCR_INC_DIR=${rocr}/include"
    "-DROCR_LIB_DIR=${rocr}/lib"
  ];

  patchPhase = ''
    sed 's,#!/usr/bin/python,#!${python}/bin/python,' -i rocm_agent_enumerator
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp rocminfo $out/bin
    cp rocm_agent_enumerator $out/bin
  '';
}
