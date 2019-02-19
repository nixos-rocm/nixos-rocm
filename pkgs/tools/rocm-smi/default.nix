{ stdenv, fetchFromGitHub, python3 }:
stdenv.mkDerivation rec {
  name = "rocm-smi";
  version = "2.1.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROC-smi";
    rev = "roc-${version}";
    sha256 = "1v4vaxc3jmprcjhjjnb9232b12xiyykknzrmmiz08x0svqhcqpnd";
  };

  patchPhase = "sed 's,#!/usr/bin/env python,#!${python3}/bin/python3,' -i rocm-smi";
  buildPhase = null;
  installPhase = ''
    mkdir -p $out/bin
    cp rocm-smi $out/bin
  '';
  meta = {
    description = "ROC System Management Interface";
    homepage = https://github.com/RadeonOpenCompute/ROC-smi;
    license = stdenv.lib.licenses.mit;
    platforms = stdenv.lib.platforms.linux;
  };
}
