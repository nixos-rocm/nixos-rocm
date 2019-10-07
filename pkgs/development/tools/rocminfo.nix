{ stdenv, fetchFromGitHub, fetchpatch, cmake, rocr, python, rocm-cmake, busybox, gnugrep }:

stdenv.mkDerivation rec {
  version = "2.8.0";
  pname = "rocminfo";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocminfo";
    rev = "roc-${version}";
    sha256 = "0k554v9y95hgksv21larwxjgqnc3c6gci09rs4m7x1dnz5sim1gj";
  };

  enableParallelBuilding = true;
  buildInputs = [ cmake rocm-cmake ];
  cmakeFlags = [
    "-DROCM_DIR=${rocr}"
    "-DROCRTST_BLD_TYPE=Release"
  ];

  prePatch = ''
    sed 's,#!/usr/bin/python,#!${python}/bin/python,' -i rocm_agent_enumerator
    sed 's,lsmod | grep ,${busybox}/bin/lsmod | ${gnugrep}/bin/grep ,' -i rocminfo.cc
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp rocminfo $out/bin
    cp rocm_agent_enumerator $out/bin
  '';
}
