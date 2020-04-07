{ stdenv, fetchFromGitHub, python3 }:
stdenv.mkDerivation rec {
  name = "rocm-smi";
  version = "3.3.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROC-smi";
    rev = "roc-${version}";
    sha256 = "1mwz81pjag6hcyiaj5f1nfcfp8l1ak8xd84mw3wni28ds18w4p59";
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
