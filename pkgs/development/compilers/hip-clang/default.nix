{ stdenv, fetchFromGitHub, cmake, perl, python, writeText
, clang, device-libs, hcc, roct, rocr, rocminfo }:
stdenv.mkDerivation rec {
  name = "hip";
  version = "20190515";
  src = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "HIP";
    rev = "70f01fad7319417ac48dd77dcdaada7123733a26";
    sha256 = "1dir3vv80ly1h2zzqc98zn5dgjh76p6sjl9wx1slbd7sq4hgv7hp";
  };
  nativeBuildInputs = [ cmake python ];
  propagatedBuildInputs = [ clang roct rocminfo device-libs ];
  buildInputs = [ clang device-libs rocr ];

  preConfigure = ''
    export HIP_CLANG_PATH=${clang}/bin
    export DEVICE_LIB_PATH=${device-libs}/lib
  '';

  # The patch version is the last two digits of year + week number +
  # day in the week: date -d "2019-05-15" +%y%U%w
  cmakeFlags = [
    "-DHSA_PATH=${rocr}"
    "-DHCC_HOME=${hcc}"
    "-DHIP_COMPILER=clang"
    "-DHIP_VERSION_PATCH=19193"
    "-DCMAKE_C_COMPILER=${clang}/bin/clang"
    "-DCMAKE_CXX_COMPILER=${clang}/bin/clang++"
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

    sed 's,#!/usr/bin/python,#!${python}/bin/python,' -i hip_prof_gen.py

    sed -e 's,$ROCM_AGENT_ENUM = "''${ROCM_PATH}/bin/rocm_agent_enumerator";,$ROCM_AGENT_ENUM = "${rocminfo}/bin/rocm_agent_enumerator";,' \
        -e 's,^\([[:space:]]*$HSA_PATH=\).*$,\1"${rocr}";,' \
        -e 's,^\([[:space:]]*$HCC_HOME=\).*$,\1"${hcc}";,' \
        -e 's,\([[:space:]]*$HOST_OSNAME=\).*,\1"nixos";,' \
        -e 's,\([[:space:]]*$HOST_OSVER=\).*,\1"${stdenv.lib.versions.majorMinor stdenv.lib.version}";,' \
        -e 's,/opt/rocm/llvm/bin,${clang}/bin,' \
        -e 's,^\([[:space:]]*\)$DEVICE_LIB_PATH = "/opt/rocm/lib",\1$DEVICE_LIB_PATH="${device-libs}/lib",' \
        -e 's,^\([[:space:]]*\)$HIP_CLANG_INCLUDE_PATH = "$HIP_CLANG_PATH/../lib/clang/$HIP_CLANG_VERSION/include";,\1$HIP_CLANG_INCLUDE_PATH = "${clang}/resource-root/include";,' \
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
