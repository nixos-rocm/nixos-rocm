{ stdenv, fetchFromGitHub, fetchpatch, cmake, perl, python, writeText
, file, binutils-unwrapped
, llvm, clang, clang-unwrapped, lld
, device-libs, roct, rocr, rocminfo, comgr, hcc
}:
stdenv.mkDerivation rec {
  name = "hip";
  version = "3.1.1";
  src = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "HIP";
    rev = "roc-${version}";
    sha256 = "0zj3vnlnh2dhns9fzsmzscx39wxwjlkjg6mg76xyj1nfga5rl6gj";
  };
  nativeBuildInputs = [ cmake python ];
  propagatedBuildInputs = [ llvm clang lld hcc roct rocminfo device-libs rocr comgr ];

  preConfigure = ''
    export HIP_CLANG_PATH=${clang}/bin
    export DEVICE_LIB_PATH=${device-libs}/lib
  '';

  # The patch version is the last two digits of year + week number +
  # day in the week: date -d "2020-02-14" +%y%U%w
  workweek = "20065";

  cmakeFlags = [
    "-DHSA_PATH=${rocr}"
    "-DHCC_HOME=${hcc}"
    "-DHIP_COMPILER=clang"
    "-DHIP_VERSION_GITDATE=${workweek}"
    "-DCMAKE_C_COMPILER=${clang}/bin/clang"
    "-DCMAKE_CXX_COMPILER=${clang}/bin/clang++"
    "-DLLVM_ENABLE_RTTI=ON"
  ];

  # - fix bash paths
  # - fix path to rocm_agent_enumerator
  # - fix hcc path
  # - fix hcc version parsing
  # - add linker flags for libhsa-runtime64 and hc_am since libhip_hcc
  #   refers to them.
  prePatch = ''
    for f in $(find bin -type f); do
      sed -e 's,#!/usr/bin/perl,#!${perl}/bin/perl,' \
          -e 's,#!/bin/bash,#!${stdenv.shell},' \
          -i "$f"
    done

    for f in $(find . -regex '.*\.cpp\|.*\.h\(pp\)?'); do
      if grep -q __hcc_workweek__ "$f" ; then
        substituteInPlace "$f" --replace '__hcc_workweek__' '${workweek}'
      fi
    done

    sed 's,#!/usr/bin/python,#!${python}/bin/python,' -i hip_prof_gen.py

    sed -e 's,$ROCM_AGENT_ENUM = "''${ROCM_PATH}/bin/rocm_agent_enumerator";,$ROCM_AGENT_ENUM = "${rocminfo}/bin/rocm_agent_enumerator";,' \
        -e "s,^\($HIP_LIB_PATH=\).*$,\1\"$out/lib\";," \
        -e 's,^\($HIP_CLANG_PATH=\).*$,\1"${clang}/bin";,' \
        -e 's,^\($DEVICE_LIB_PATH=\).*$,\1"${device-libs}/lib";,' \
        -e 's,^\($HIP_COMPILER=\).*$,\1"clang";,' \
        -e 's,^\($HIP_RUNTIME=\).*$,\1"HCC";,' \
        -e 's,^\([[:space:]]*$HSA_PATH=\).*$,\1"${rocr}";,'g \
        -e 's,\([[:space:]]*$HOST_OSNAME=\).*,\1"nixos";,' \
        -e 's,\([[:space:]]*$HOST_OSVER=\).*,\1"${stdenv.lib.versions.majorMinor stdenv.lib.version}";,' \
        -e 's,^\([[:space:]]*\)$HIP_CLANG_INCLUDE_PATH = abs_path("$HIP_CLANG_PATH/../lib/clang/$HIP_CLANG_VERSION/include");,\1$HIP_CLANG_INCLUDE_PATH = "${clang-unwrapped}/lib/clang/$HIP_CLANG_VERSION/include";,' \
        -e 's,^\([[:space:]]*$HIPCXXFLAGS .= " -isystem $HIP_CLANG_INCLUDE_PATH\)";,\1 -isystem ${rocr}/include";,' \
        -e "s,\$HIP_PATH/\(bin\|lib\),$out/\1,g" \
        -e "s,^\$HIP_LIB_PATH=\$ENV{'HIP_LIB_PATH'};,\$HIP_LIB_PATH=\"$out/lib\";," \
        -e 's,`file,`${file}/bin/file,g' \
        -e 's,`readelf,`${binutils-unwrapped}/bin/readelf,' \
        -e 's, ar , ${binutils-unwrapped}/bin/ar ,g' \
        -e 's,\(^[[:space:]]*$HIPLDFLAGS .= \)" -lhip_hcc";,\1" -lhip_hcc -lhsa-runtime64 -lhc_am -lmcwamp";,' \
        -i bin/hipcc
    sed -e 's,$HCC_HOME/bin/llc,${llvm}/bin/llc,' \
        -e 's,^$HCC_HOME=.*,$HCC_HOME=\x27${hcc}\x27;,' \
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
    mv $out/cmake/* $out/share/cmake/hip
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
