{ stdenv, fetchFromGitHub, fetchpatch, cmake, rocr, python, rocm-cmake, busybox, gnugrep }:

stdenv.mkDerivation rec {
  version = "2.7.0";
  pname = "rocminfo";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocminfo";
    rev = "roc-${version}";
    sha256 = "0nwx8rl7if7ffs25790q7phdzkw82bjpfs1wsqwwpg1gx7z28lg9";
  };

  enableParallelBuilding = true;
  buildInputs = [ cmake rocm-cmake ];
  cmakeFlags = [
    "-DROCM_DIR=${rocr}"
    "-DROCRTST_BLD_TYPE=Release"
    "-DCMAKE_CXX_FLAGS=-Wno-error=format-truncation"
  ];
  patches = [ (fetchpatch {
    url = "https://github.com/RadeonOpenCompute/rocminfo/commit/4d1d2a16958d6da8c9d56eaf266b43aea70350ce.patch";
    sha256 = "1gx7hz17rgvmbvlblvkps5a43cjxm0svb4b6gh5rb9ff37dbhii0";
  })];

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
