{ stdenv, fetchFromGitHub, fetchpatch, cmake, perl, python, writeText
, file, binutils-unwrapped
, llvm, clang, clang-unwrapped, lld
, rocm-device-libs, rocm-thunk, rocm-runtime, rocminfo, comgr, rocclr
}:
stdenv.mkDerivation rec {
  name = "hip";
  version = "3.7.0";
  src = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "HIP";
    rev = "rocm-${version}";
    sha256 = "18bffha1v0lwmdimhbgfziv1lxyj2mw4jh4xdxivnmdqw34milf3";
  };
  nativeBuildInputs = [ cmake python ];
  propagatedBuildInputs = [ llvm clang lld rocm-thunk rocminfo rocm-device-libs rocm-runtime comgr rocclr ];

  preConfigure = ''
    export HIP_CLANG_PATH=${clang}/bin
    export DEVICE_LIB_PATH=${rocm-device-libs}/lib
  '';

  # The patch version is the last two digits of year + week number +
  # day in the week: date -d "2020-08-07" +%y%U%w
  workweek = "20315";

  cmakeFlags = [
    "-DHSA_PATH=${rocm-runtime}"
    "-DHIP_COMPILER=clang"
    "-DHIP_PLATFORM=rocclr"
    "-DHIP_VERSION_GITDATE=${workweek}"
    "-DCMAKE_C_COMPILER=${clang}/bin/clang"
    "-DCMAKE_CXX_COMPILER=${clang}/bin/clang++"
    "-DLLVM_ENABLE_RTTI=ON"
    "-DLIBROCclr_STATIC_DIR=${rocclr}/lib/cmake"
    "-DROCclr_DIR=${rocclr}"
    "-DHIP_CLANG_ROOT=${clang-unwrapped}"
  ];

  # patches = [(fetchpatch {
  #   # See https://github.com/ROCm-Developer-Tools/HIP/pull/2005
  #   name = "hiprtc-fix-PR2005";
  #   url = "https://patch-diff.githubusercontent.com/raw/ROCm-Developer-Tools/HIP/pull/2005.patch";
  #   sha256 = "1w35s2xpxny4j5llpaz912g1br9735vdfdld1nhqdvrdax2vxlc7";
  # })];

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
        -e 's,^\($DEVICE_LIB_PATH=\).*$,\1"${rocm-device-libs}/lib";,' \
        -e 's,^\($HIP_COMPILER=\).*$,\1"clang";,' \
        -e 's,^\($HIP_RUNTIME=\).*$,\1"ROCclr";,' \
        -e 's,^\([[:space:]]*$HSA_PATH=\).*$,\1"${rocm-runtime}";,'g \
        -e 's,\([[:space:]]*$HOST_OSNAME=\).*,\1"nixos";,' \
        -e 's,\([[:space:]]*$HOST_OSVER=\).*,\1"${stdenv.lib.versions.majorMinor stdenv.lib.version}";,' \
        -e 's,^\([[:space:]]*\)$HIP_CLANG_INCLUDE_PATH = abs_path("$HIP_CLANG_PATH/../lib/clang/$HIP_CLANG_VERSION/include");,\1$HIP_CLANG_INCLUDE_PATH = "${clang-unwrapped}/lib/clang/$HIP_CLANG_VERSION/include";,' \
        -e 's,^\([[:space:]]*$HIPCXXFLAGS .= " -isystem $HIP_CLANG_INCLUDE_PATH\)";,\1 -isystem ${rocm-runtime}/include";,' \
        -e "s,\$HIP_PATH/\(bin\|lib\),$out/\1,g" \
        -e "s,^\$HIP_LIB_PATH=\$ENV{'HIP_LIB_PATH'};,\$HIP_LIB_PATH=\"$out/lib\";," \
        -e 's,`file,`${file}/bin/file,g' \
        -e 's,`readelf,`${binutils-unwrapped}/bin/readelf,' \
        -e 's, ar , ${binutils-unwrapped}/bin/ar ,g' \
        -i bin/hipcc

    sed -e 's,^\($HSA_PATH=\).*$,\1"${rocm-runtime}";,' \
        -e 's,^\($HIP_CLANG_PATH=\).*$,\1"${clang}/bin";,' \
        -e 's,^\($HIP_PLATFORM=\).*$,\1"hcc";,' \
        -e 's,$HIP_CLANG_PATH/llc,${llvm}/bin/llc,' \
        -e 's, abs_path, Cwd::abs_path,' \
        -i bin/hipconfig

    sed -e '/execute_process(COMMAND git show -s --format=@%ct/,/    OUTPUT_STRIP_TRAILING_WHITESPACE)/d' \
        -e '/string(REGEX REPLACE ".*based on HCC " "" HCC_VERSION ''${HCC_VERSION})/,/string(REGEX REPLACE " .*" "" HCC_VERSION ''${HCC_VERSION})/d' \
        -e 's/\(message(STATUS "Looking for HCC in: " ''${HCC_HOME} ". Found version: " ''${HCC_VERSION})\)/string(REGEX REPLACE ".*based on HCC[ ]*(LLVM)?[ ]*([^)\\r\\n ]*).*" "\\\\2" HCC_VERSION ''${HCC_VERSION})\n\1/' \
        -i CMakeLists.txt

    sed -e 's|target_include_directories(lpl PUBLIC ''${PROJECT_SOURCE_DIR}/src)|target_include_directories(lpl PUBLIC ''${PROJECT_SOURCE_DIR}/include)|' \
        -i lpl_ca/CMakeLists.txt

    sed -e 's|_IMPORT_PREFIX}/../include|_IMPORT_PREFIX}/include|g' \
        -e 's|''${HIP_CLANG_ROOT}/lib/clang/\*/include|${clang-unwrapped}/lib/clang/*/include|' \
        -i hip-config.cmake.in
  '';

  preInstall = ''
    mkdir -p $out/lib/cmake
  '';

  # The upstream ROCclr setup wants everything built into the same
  # ROCclr output directory. We copy things into the HIP output
  # directory, since it is downstream of ROCclr in terms of dependency
  # direction. Thus we have device-libs and rocclr pieces in the HIP
  # output directory.
  postInstall = ''
    mkdir -p $out/share
    mv $out/lib/cmake $out/share/
    mv $out/cmake/* $out/share/cmake/hip
    mkdir -p $out/lib
    ln -s ${rocm-device-libs}/lib $out/lib/bitcode
    mkdir -p $out/include
    ln -s ${clang-unwrapped}/lib/clang/11.0.0/include $out/include/clang
    ln -s ${rocclr}/lib/*.* $out/lib
    ln -s ${rocclr}/include/* $out/include
  '';

  setupHook = writeText "setupHook.sh" ''
    export HIP_PATH="@out@"
    export HSA_PATH="${rocm-runtime}"
  '';
}
