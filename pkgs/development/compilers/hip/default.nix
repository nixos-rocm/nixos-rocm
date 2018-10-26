{ stdenv, fetchFromGitHub, cmake, perl, writeText
, hcc, roct, rocr, rocminfo }:
stdenv.mkDerivation rec {
  name = "hip";
  version = "1.9.1";
  src = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "HIP";
    rev = "roc-${version}";
    sha256 = "1y9zm9lh81gr18yrz9q6i247f5sn74yn6dnrz4k7v61swbg7i8rm";
  };
  nativeBuildInputs = [ cmake ];
  propagatedBuildInputs = [ hcc roct rocminfo ];
  buildInputs = [ hcc ];

  # The patch version is the last two digits of year + week number +
  # day in the week: date -d "2018-09-05" +%y%U%w
  cmakeFlags = [
    "-DHSA_PATH=${rocr}"
    "-DHCC_HOME=${hcc}"
    "-DHIP_PLATFORM='hcc'"
    "-DHIP_VERSION_PATCH=18353"
  ];

  # - fix bash paths
  # - fix path to rocm_agent_enumerator
  # - fix hcc path
  # - fix hcc version parsing
  patchPhase = ''
    for f in $(find bin -type f); do
      sed -e 's,#!/usr/bin/perl,#!${perl}/bin/perl,' \
          -e 's,#!/bin/bash,#!${stdenv.shell},' \
          -i "$f"
    done

    sed -e 's,$ROCM_AGENT_ENUM = "''${ROCM_PATH}/bin/rocm_agent_enumerator";,$ROCM_AGENT_ENUM = "${rocminfo}/bin/rocm_agent_enumerator";,' \
        -e 's,^\([[:space:]]*$HSA_PATH=\).*$,\1"${rocr}";,' \
        -e 's,^\([[:space:]]*$HCC_HOME=\).*$,\1"${hcc}";,' \
        -e 's,\([[:space:]]*$HOST_OSNAME=\).*,\1"nixos";,' \
        -e 's,\([[:space:]]*$HOST_OSVER=\).*,\1"${stdenv.lib.version}";,' \
        -i bin/hipcc
    sed -i 's,\([[:space:]]*$HCC_HOME=\).*$,\1"${hcc}";,' -i bin/hipconfig

    sed -e '/execute_process(COMMAND git show -s --format=@%ct/,/    OUTPUT_STRIP_TRAILING_WHITESPACE)/d' \
        -e '/string(REGEX REPLACE ".*based on HCC " "" HCC_VERSION ''${HCC_VERSION})/,/string(REGEX REPLACE " .*" "" HCC_VERSION ''${HCC_VERSION})/d' \
        -e 's/\(message(STATUS "Looking for HCC in: " ''${HCC_HOME} ". Found version: " ''${HCC_VERSION})\)/string(REGEX REPLACE ".*based on HCC[ ]*(LLVM)?[ ]*([^)\\r\\n ]*).*" "\\\\2" HCC_VERSION ''${HCC_VERSION})\n\1/' \
        -i CMakeLists.txt
  '';

  postInstall = ''
    mkdir -p $out/share
    mv $out/lib/cmake $out/share/
  '';

  setupHook = writeText "setupHook.sh" ''
    export HIP_PATH="@out@"
  '';
}
