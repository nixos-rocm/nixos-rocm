{ stdenv, fetchFromGitHub, python3 }:
stdenv.mkDerivation rec {
  name = "rocm-smi";
  version = "1.9.0";
  tag = "roc-${version}";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROC-smi";
    rev = tag;
    sha256 = "0b3mqaajvlibx4fh5glncci3r0wdad9yigygjbl4lgn2wxcc4ylb";
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
