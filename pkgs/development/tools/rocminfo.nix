{ stdenv, fetchFromGitHub, cmake, rocr, python }:

stdenv.mkDerivation rec {
  version = "1.7.0";
  name = "rocminfo";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocminfo";
    rev = "fd277f3";
    sha256 = "0q7yl109gm6vn3s0zzldzfazyfkm57i41inxgil0wd7l6v73bs5s";
  };

  enableParallelBuilding = true;
  buildInputs = [ cmake ];
  cmakeFlags = [ "-DROCM_DIR=${rocr}" ];

  patchPhase = ''
    sed 's,#!/usr/bin/python,#!${python}/bin/python,' -i rocm_agent_enumerator
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp rocminfo $out/bin
    cp rocm_agent_enumerator $out/bin
  '';
}
