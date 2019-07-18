{ stdenv, fetchFromGitHub, cmake, rocr, python, rocm-cmake }:

stdenv.mkDerivation rec {
  version = "2.6.0";
  pname = "rocminfo";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocminfo";
    rev = "roc-${version}";
    sha256 = "105qzvmcilrabcaq28z5bxqhw6dpp1cwqajr29x9jnbs3grk7bwh";
  };

  enableParallelBuilding = true;
  buildInputs = [ cmake rocm-cmake ];
  cmakeFlags = [
    "-DROCM_DIR=${rocr}"
    "-DROCRTST_BLD_TYPE=Release"
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
