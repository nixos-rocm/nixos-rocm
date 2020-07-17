{ stdenv, fetchFromGitHub, cmake, pkgconfig, writeText, python, perlPackages
, device-libs, rocm-runtime, file, rocminfo, lld
, llvm, clang, clang-unwrapped, compiler-rt
}:
let perlenv = perlPackages.perl.buildEnv.override({
      extraLibs = [ perlPackages.FileWhich ];
    });
in stdenv.mkDerivation rec {
  name = "hcc";
  version = "3.3.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "hcc";
    rev = "rocm-${version}";
    sha256 = "0xgan96adz0z82qlljs1fdncj1m1w5cnkwzwzykzb62akvsf6m65";
  };
  propagatedBuildInputs = [ file rocm-runtime rocminfo ];
  nativeBuildInputs = [ cmake pkgconfig python ];
  buildInputs = [ rocm-runtime ];
  preConfigure = ''
    export LLVM_DIR=${llvm}/lib/cmake/llvm
    export CMAKE_PREFIX_PATH=${llvm}/lib/cmake/llvm:$CMAKE_PREFIX_PATH
  '';

  cmakeFlags = [
    "-DROCM_ROOT=${rocm-runtime}"
    "-DROCM_DEVICE_LIB_DIR=${device-libs}/lib"
    "-DCLANG_BIN_DIR=${clang-unwrapped}"
    "-DHCC_INTEGRATE_ROCDL=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DLLVM_LIB_DIR=${llvm}/lib"
  ];
  doCheck = false;

  # - Fix bash paths
  # - Remove use of ROCM_ROOT environment variable
  # - Don't implicitly ignore return value of posix_memalign
  # - Don't build clang and llvm as part of this build
  # - __hcc_backend__ can only be set to HCC_BACKEND_AMDGPU
  # - Fix more clang and llvm paths
  prePatch = ''
    for f in $(find lib -name '*.in'); do
      sed -e 's_#!/bin/bash_#!${stdenv.shell}_' \
          -e 's_#!/usr/bin/perl_#!${perlenv}/bin/perl_' \
          -e 's|^CLANG=$BINDIR/hcc|CLANG=${clang}/bin/clang++|' \
          -e 's|^LLVM_LINK=.*|LLVM_LINK=${llvm}/bin/llvm-link|' \
          -e 's|^LINK=.*|LINK=${llvm}/bin/llvm-link|' \
          -e 's|^LTO=.*|LTO=${llvm}/bin/llvm-lto|' \
          -e 's|^LLD=.*|LLD=${lld}/bin/ld.lld|' \
          -e 's|^OPT=.*|OPT=${llvm}/bin/opt|' \
          -e 's|^LLVM_AS=.*|LLVM_AS=${llvm}/bin/llvm-as|' \
          -e 's|^LLVM_DIS=.*|LLVM_DIS=${llvm}/bin/llvm-dis|' \
          -e 's|^LIBPATH=.*|LIBPATH=${llvm}/lib|' \
          -e 's|^CLANG_OFFLOAD_BUNDLER=.*|CLANG_OFFLOAD_BUNDLER=${clang-unwrapped}/bin/clang-offload-bundler|' \
          -i "$f"
    done
    sed -e 's|BINDIR=$(dirname $0)|BINDIR=${llvm}/bin|' \
        -e "s|EMBED=\$BINDIR/clamp-embed|EMBED=$out/bin/clamp-embed|" \
        -i lib/clamp-device.in
    sed -e 's|objcopy|${llvm}/bin/llvm-objcopy|g' \
        -i lib/clamp-embed.in
    sed -e 's|`file |`${file}/bin/file |g' -i lib/clamp-link.in
    sed -e 's|\(set(LLVM_SRC \).*|\1"${llvm.src}")|' \
        -e '\|set(LLVM_ROOT .*|d' \
        -e 's|SET(LOCAL_LLVM_INCLUDE compiler/include)|SET(LOCAL_LLVM_INCLUDE   ${llvm.src}/include)|' \
        -e 's|\(find_package(LLVM REQUIRED CONFIG PATHS \)''${CMAKE_BINARY_DIR}/compiler NO_DEFAULT_PATH)|\1${llvm})|' \
        -e '/add_subdirectory(cmake-tests)/d' \
        -e '/add_subdirectory(''${CLANG_SRC_DIR})/d' \
        -e '/get_directory_property(CLANG_VERSION DIRECTORY llvm-project\/clang DEFINITION CLANG_VERSION)/d' \
        -e '/install(PROGRAMS $<TARGET_FILE:llvm-as>/,/COMPONENT llvm-project\/llvm)/d' \
        -e '/install(FILES ''${CLANG_BIN_DIR}\/lib\/clang\/''${CLANG_VERSION}\/lib\/linux\/libclang_rt.builtins-''${RT_BUILTIN_SUFFIX}.a/,/COMPONENT llvm-project\/llvm)/d' \
        -e '/install(PROGRAMS $<TARGET_FILE:LLVMSelectAcceleratorCode>/,/^)/d' \
        -i CMakeLists.txt

    sed 's,__hcc_backend__,HCC_BACKEND_AMDGPU,g' -i include/hc.hpp

    sed 's|set(CMAKE_CXX_COMPILER "''${PROJECT_BINARY_DIR}/llvm-project/llvm/bin/clang++")|set(CMAKE_CXX_COMPILER ${clang}/bin/clang++)|' -i scripts/cmake/MCWAMP.cmake
    sed 's|CLANG=$BINDIR/hcc|CLANG=${clang}/bin/clang++|' -i lib/hc-host-assemble.in
    sed 's|LLVM_DIS=$BINDIR/llvm-dis|${llvm}/bin/llvm-dis|' -i lib/hc-kernel-assemble.in

    sed -e 's|\(my $llvm_objdump = \).*|\1"${llvm}/bin/llvm-objdump";|' \
        -e 's|\(my $clang_offload_bundler = \).*|\1"${clang-unwrapped}/bin/clang-offload-bundler";|' \
        -i lib/extractkernel.in

    sed 's|llvm-project/llvm/bin/||'g -i lib/CMakeLists.txt

    sed 's|llvm-project/llvm/bin/||'g -i tests/CMakeLists.txt
  '';

  patches = [
    ./hcc-config-path.patch
    ./no-hex-floats.patch
    ./extractkernel-paths.patch
  ];

  inherit llvm;
  postPatch = ''
    substituteInPlace hcc_config/hcc_config.cpp --subst-var out
    substituteInPlace lib/extractkernel.in --subst-var llvm --subst-var-by clang-unwrapped ${clang-unwrapped}
  '';

  # Build artifacts are used during the build (e.g. hc-host-assemble
  # and hc-kernel-assemble).
  postConfigure = ''
    export PATH=$PWD:$PATH
  '';

  # If we don't disable hardening, we get a compiler error mentioning
  # `ssp-buffer-size`, however disabling only the `"stackprotector"`
  # flag is not enough to make everything work.
  hardeningDisable = ["all"];
  # hardeningDisable = ["stackprotector"];

  postFixup = ''
    ln -s ${compiler-rt}/lib/linux/libclang_rt.builtins-x86_64.a $out/lib
  '';

  # We get several warnings about unused include paths during
  # compilation. We quiet them here, though it would be better to not
  # be passing those flags to the hcc clang.
  setupHook = writeText "setupHook.sh" ''
    export NIX_CFLAGS_COMPILE+=" -Wno-unused-command-line-argument"
  '';
}
