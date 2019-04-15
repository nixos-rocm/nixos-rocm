{ stdenv, fetchFromGitHub, cmake, rocr, python, rocm-cmake }:

stdenv.mkDerivation rec {
  version = "2019-03-26";
  name = "rocminfo";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocminfo";
    rev = "88771818c25acba81e51e37c9bf782fcc86a2c2a";
    sha256 = "1imzxfypi9kzmr53jai2pcfzi77vir421dgqh7996ifi84ykmqrz";
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
