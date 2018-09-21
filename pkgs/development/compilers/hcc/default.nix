{ stdenv, fetchFromGitHub, cmake, pkgconfig, writeText, python
, rocm-device-libs, rocr, file, rocminfo, rocm-lld
, hcc-llvm, hcc-clang, hcc-clang-unwrapped, hcc-compiler-rt }:
stdenv.mkDerivation rec {
  name = "hcc";
  version = "1.9.0";
  tag = "roc-${version}";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "hcc";
    # 1.9.x branch
    rev = "ec91fedbbe48d1c621ea08a493bc11869a10eedd";
    sha256 = "0ym9s1w3vml7xin0lq9z0y28lsdag36dhgwx06y6kdnsfb4nm7xf";
  };
  propagatedBuildInputs = [ file rocr rocminfo ];
  nativeBuildInputs = [ cmake pkgconfig python ];
  buildInputs = [ rocr ];
  cmakeFlags = [
    "-DROCM_ROOT=${rocr}"
    "-DROCM_DEVICE_LIB_DIR=${rocm-device-libs}/lib"
    "-DCLANG_BIN_DIR=${hcc-clang-unwrapped}"
    "-DHCC_INTEGRATE_ROCDL=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DLLVM_LIB_DIR=${hcc-llvm}/lib"
  ];
  doCheck = false;

  # - Fix bash paths
  # - Remove use of ROCM_ROOT environment variable
  # - Don't implicitly ignore return value of posix_memalign
  # - Don't build clang and llvm as part of this build
  # - __hcc_backend__ can only be set to HCC_BACKEND_AMDGPU
  # - Fix more clang and llvm paths
  patchPhase = ''
    for f in $(find lib -name '*.in'); do
      sed -e 's_#!/bin/bash_#!${stdenv.shell}_' \
          -e 's|^CLANG=$BINDIR/hcc|CLANG=${hcc-clang}/bin/clang++|' \
          -e 's|^LLVM_LINK=.*|LLVM_LINK=${hcc-llvm}/bin/llvm-link|' \
          -e 's|^LINK=.*|LINK=${hcc-llvm}/bin/llvm-link|' \
          -e 's|^LTO=.*|LTO=${hcc-llvm}/bin/llvm-lto|' \
          -e 's|^LLD=.*|LLD=${rocm-lld}/bin/ld.lld|' \
          -e 's|^OPT=.*|OPT=${hcc-llvm}/bin/opt|' \
          -e 's|^LLVM_AS=.*|LLVM_AS=${hcc-llvm}/bin/llvm-as|' \
          -e 's|^LLVM_DIS=.*|LLVM_DIS=${hcc-llvm}/bin/llvm-dis|' \
          -e 's|^LIBPATH=.*|LIBPATH=${hcc-llvm}/lib|' \
          -e 's|^CLANG_OFFLOAD_BUNDLER=.*|CLANG_OFFLOAD_BUNDLER=${hcc-clang-unwrapped}/bin/clang-offload-bundler|' \
          -i "$f"
    done
    sed -e 's|BINDIR=$(dirname $0)|BINDIR=${hcc-llvm}/bin|' \
        -e "s|EMBED=\$BINDIR/clamp-embed|EMBED=$out/bin/clamp-embed|" \
        -i lib/clamp-device.in

    sed 's/\(posix_memalign(&memptr, alignment, size)\)/(void)\1/' -i include/kalmar_aligned_alloc.h

    sed -e 's|SET(LOCAL_LLVM_INCLUDE compiler/include)|SET(LOCAL_LLVM_INCLUDE   ${hcc-llvm.src}/include)|' \
        -e '/add_subdirectory(cmake-tests)/d' \
        -e '/add_subdirectory(''${CLANG_SRC_DIR})/d' \
        -e '/get_directory_property(CLANG_VERSION DIRECTORY clang DEFINITION CLANG_VERSION)/d' \
        -e '/install(PROGRAMS $<TARGET_FILE:LLVMAMDGPUDesc>/,/^)$/d' \
        -e '/install(PROGRAMS $<TARGET_FILE:llvm-as>/,/COMPONENT compiler)/d' \
        -e '/install(FILES ''${CLANG_BIN_DIR}\/lib\/clang\/''${CLANG_VERSION}\/lib\/linux\/libclang_rt.builtins-''${RT_BUILTIN_SUFFIX}.a/,/COMPONENT compiler)/d' \
        -i CMakeLists.txt

    sed 's,__hcc_backend__,HCC_BACKEND_AMDGPU,g' -i include/hc.hpp

    sed 's|set(CMAKE_CXX_COMPILER "''${PROJECT_BINARY_DIR}/compiler/bin/clang++")|set(CMAKE_CXX_COMPILER ${hcc-clang}/bin/clang++)|' -i scripts/cmake/MCWAMP.cmake
    sed 's|CLANG=$BINDIR/hcc|CLANG=${hcc-clang}/bin/clang++|' -i lib/hc-host-assemble.in
    sed 's|LLVM_DIS=$BINDIR/llvm-dis|${hcc-llvm}/bin/llvm-dis|' -i lib/hc-kernel-assemble.in
  '';

  # Scripts like hc-host-assemble and hc-kernel-assemble are placed in
  # compiler/bin and used during the build.
  postConfigure = ''
    export PATH="$(pwd)/compiler/bin:$PATH"
  '';

  # If we don't disable hardening, we get a compiler error mentioning
  # `ssp-buffer-size`, however disabling only the `"stackprotector"`
  # flag is not enough to make everything work.
  hardeningDisable = ["all"];
  # hardeningDisable = ["stackprotector"];

  postFixup = ''
    ln -s ${hcc-compiler-rt}/lib/linux/libclang_rt.builtins-x86_64.a $out/lib
  '';

  # We get several warnings about unused include paths during
  # compilation. We quiet them here, though it would be better to not
  # be passing those flags to the hcc clang.
  setupHook = writeText "setupHook.sh" ''
    export NIX_CFLAGS_COMPILE+=" -Wno-unused-command-line-argument"
  '';
}
