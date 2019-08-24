{ stdenv, fetchFromGitHub, cmake, perl, python, writeText
, llvm, clang, clang-unwrapped, device-libs, hcc, roct, rocr, rocminfo, comgr}:
stdenv.mkDerivation rec {
  name = "hip";
  version = "2.7.0";
  src = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "HIP";
    rev = "roc-${version}";
    sha256 = "0ibklghp9h598phh6dizkyxnk3syj9mv4bip5bfai0d5l5l6iyl6";
  };
  nativeBuildInputs = [ cmake python ];
  propagatedBuildInputs = [ clang roct rocminfo device-libs ];
  buildInputs = [ clang device-libs rocr comgr ];

  preConfigure = ''
    export HIP_CLANG_PATH=${clang}/bin
    export DEVICE_LIB_PATH=${device-libs}/lib
    export HIP_RUNTIME=VDI
  '';

  # The patch version is the last two digits of year + week number +
  # day in the week: date -d "2019-07-18" +%y%U%w
  cmakeFlags = [
    "-DHSA_PATH=${rocr}"
    "-DHCC_HOME=${hcc}"
    "-DHIP_COMPILER=clang"
    "-DHIP_VERSION_PATCH=19284"
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
        -e "s,^\(\$HIP_VDI_HOME=\).*$,\1\"$out\";," \
        -e 's,^\($HIP_LIB_PATH=\).*$,\1"${clang-unwrapped}/lib";,' \
        -e 's,^\($HIP_CLANG_PATH=\).*$,\1"${clang}/bin";,' \
        -e 's,^\($DEVICE_LIB_PATH=\).*$,\1"${device-libs}/lib";,' \
        -e 's,^\($HIP_COMPILER=\).*$,\1"clang";,' \
        -e 's,^\($HIP_RUNTIME=\).*$,\1"clang";,' \
        -e 's,^\([[:space:]]*$HSA_PATH=\).*$,\1"${rocr}";,'g \
        -e 's,^\([[:space:]]*$HCC_HOME=\).*$,\1"${hcc}";,' \
        -e 's,\([[:space:]]*$HOST_OSNAME=\).*,\1"nixos";,' \
        -e 's,\([[:space:]]*$HOST_OSVER=\).*,\1"${stdenv.lib.versions.majorMinor stdenv.lib.version}";,' \
        -e 's,^\([[:space:]]*\)$HIP_CLANG_INCLUDE_PATH = abs_path("$HIP_CLANG_PATH/../lib/clang/$HIP_CLANG_VERSION/include");,\1$HIP_CLANG_INCLUDE_PATH = "${clang-unwrapped}/lib/clang/$HIP_CLANG_VERSION/include";,' \
        -e 's,^\(    $HIPCXXFLAGS .= " -std=c++11 -isystem $HIP_CLANG_INCLUDE_PATH\)";,\1 -isystem ${rocr}/include";,' \
        -i bin/hipcc
    sed -e 's,\([[:space:]]*$HCC_HOME=\).*$,\1"${hcc}";,' \
        -e 's,$HCC_HOME/bin/llc,${llvm}/bin/llc,' \
        -i bin/hipconfig

    sed -e '/execute_process(COMMAND git show -s --format=@%ct/,/    OUTPUT_STRIP_TRAILING_WHITESPACE)/d' \
        -e '/string(REGEX REPLACE ".*based on HCC " "" HCC_VERSION ''${HCC_VERSION})/,/string(REGEX REPLACE " .*" "" HCC_VERSION ''${HCC_VERSION})/d' \
        -e 's/\(message(STATUS "Looking for HCC in: " ''${HCC_HOME} ". Found version: " ''${HCC_VERSION})\)/string(REGEX REPLACE ".*based on HCC[ ]*(LLVM)?[ ]*([^)\\r\\n ]*).*" "\\\\2" HCC_VERSION ''${HCC_VERSION})\n\1/' \
        -i CMakeLists.txt
  '';

  preInstall = ''
    mkdir -p $out/lib/cmake
  '';

  postInstall = ''
    mkdir -p $out/share
    mv $out/lib/cmake $out/share/
    mkdir -p $out/lib
    ln -s ${device-libs}/lib $out/lib/bitcode
    mkdir -p $out/include
    ln -s ${clang-unwrapped}/lib/clang/10.0.0/include $out/include/clang
  '';

  setupHook = writeText "setupHook.sh" ''
    export HIP_PATH="@out@"
    export HSA_PATH="${rocr}"
  '';
}
