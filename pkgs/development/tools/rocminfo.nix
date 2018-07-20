{ stdenv, fetchFromGitHub, cmake, rocr, python, rocm-cmake }:

stdenv.mkDerivation rec {
  version = "1.8.2";
  name = "rocminfo";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocminfo";
    rev = "6ce80261127b15f4f226bb89c4182603420d3e6e";
    sha256 = "1jlvdqlqg49r4lpw14gmix1790pwkhyvhjnmfw06phvgwvm3q46v";
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
