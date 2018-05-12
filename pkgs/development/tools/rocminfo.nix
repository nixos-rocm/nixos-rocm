{ stdenv, fetchFromGitHub, cmake, rocr, python, rocm-cmake }:

stdenv.mkDerivation rec {
  version = "1.8.0";
  name = "rocminfo";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocminfo";
    rev = "8d579bf68e9471422276a1383becf5fe10c95eda";
    sha256 = "1awrg9crf4cd3zmmrs78l171xg33mby4lxch8ih3085wvbzrrb9p";
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
