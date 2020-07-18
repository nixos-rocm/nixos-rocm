{ stdenv
, fetchFromGitHub
, src
, addOpenGLRunpath
, clang
, clang-unwrapped
, cmake
, lld
, llvm
, rocm-runtime
, rocm-thunk
, rocm-device-libs
, rocm-cmake
, comgr
, rocclr
, mesa_noglu
, python2
, libX11
, libGLU
}:

stdenv.mkDerivation rec {
  version = "3.5.0";
  tag = "roc-${version}";
  name = "rocm-opencl-runtime-${version}";
  inherit src;
  # srcs =
  #   [ # (fetchFromGitHub {
  #     #   owner = "RadeonOpenCompute";
  #     #   repo = "ROCm-OpenCL-Runtime";
  #     #   # rev = tag;
  #     #   # sha256 = "1xl2kr019az3cnkqv8wh5hpsxdnify7kvf2fxhxkn5cb79b0v5yi";
  #     #   rev = "9c84f7c281d8cbfb8445cb5b949f0b13e5d7636d";
  #     #   sha256 = stdenv.lib.fakeSha256;
  #     #   name = "ROCm-OpenCL-Runtime-${tag}-src";
  #     # })
  #     src
  #     (fetchFromGitHub {
  #       owner = "KhronosGroup";
  #       repo = "OpenCL-ICD-Loader";
  #       rev = "6c03f8b58fafd9dd693eaac826749a5cfad515f8";
  #       sha256 = "00icrlc00dpc87prbd2j1350igi9pbgkz27hc3rf73s5994yn86a";
  #       # rev = "bbdf079426d859fb8a68c332b41b714f9c87d6ad";
  #       # sha256 = "0v2yi6d3g5qshzy6pjic09c5irwgds106yvr93q62f32psfblnmy";
  #       name = "OpenCL-ICD-Loader-6c03f8b-src";
  #       # name = "OpenCL-ICD-Loader-bbdf079-src";
  #     })
  #   ];

  sourceRoot = "ROCm-OpenCL-Runtime-src";

  # We end up re-building rocm-device-libs here because the
  # rocm-opencl-runtime build couples itself so tightly to the
  # rocm-device-libs build.
  # postUnpack = ''
  #   chmod --recursive +w .
  #   mkdir ROCm-OpenCL-Runtime-src/library/
  #   # mv OpenCL-ICD-Loader-6c03f8b-src ROCm-OpenCL-Runtime-src/api/opencl/khronos/icd
  #   # rm -rf ROCm-OpenCL-Runtime-src/khronos/icd
  #   # mv OpenCL-ICD-Loader-6c03f8b-src ROCm-OpenCL-Runtime-src/khronos/icd
  #   cp -r ${rocm-device-libs.src} ROCm-OpenCL-Runtime-src/library/amdgcn
  #   chmod --recursive +w ROCm-OpenCL-Runtime-src/library/amdgcn
  # '';

  # patches = [ ./libdebug.patch ];
  # patches = [ ./link-comgr.patch ];

  # - let the rocm-device-libs build find our pre-built clang
  # - fix the ICD installation path for NixOS
  # - skip building llvm and rocm-opencl-driver
  # - fix a clang header path
  # - explicitly link libamdocl64.so to everything it
  #   needs from lld, llvm, and clang.
  # - give oclruntime a dependency on oclrocm. Without this, only
  #   parallel builds succeed because oclrocm coincidentally finishes
  #   building before the build of oclruntime starts.
  postPatch = ''
    # sed 's|set(CLANG "''${LLVM_TOOLS_BINARY_DIR}/clang''${EXE_SUFFIX}")|set(CLANG "${clang}/bin/clang")|' -i library/amdgcn/OCL.cmake

    sed 's,ICD_VENDOR_PATH,"${addOpenGLRunpath.driverLink}/etc/OpenCL/vendors/",g' -i khronos/icd/loader/linux/icd_linux.c

    # sed -e 's|add_subdirectory(compiler/llvm EXCLUDE_FROM_ALL)|find_package(Clang REQUIRED CONFIG)|' \
    #     -e 's|include_directories(''${CMAKE_SOURCE_DIR}/compiler/llvm/lib/Target/AMDGPU)|include_directories(${llvm.src}/lib/Target/AMDGPU)|' \
    #     -e 's|include_directories(''${CMAKE_BINARY_DIR}/compiler/llvm/lib/Target/AMDGPU)||' \
    #     -e '/install(PROGRAMS $<TARGET_FILE:clang> $<TARGET_FILE:lld>/,/^[[:space:]]*COMPONENT DEV)/d' \
    #     -e 's|add_subdirectory(compiler/driver EXCLUDE_FROM_ALL)||' \
    #     -i CMakeLists.txt

    # sed -e 's|''${CMAKE_SOURCE_DIR}/compiler/llvm/tools/clang/lib/Headers/opencl-c.h|${clang-unwrapped}/lib/clang/11.0.0/include/opencl-c.h|g' \
    #     -e 's|file(APPEND ''${CMAKE_CURRENT_BINARY_DIR}/libraries.amdgcn.inc "#include \"''${header}\"\n")|file(APPEND ''${CMAKE_CURRENT_BINARY_DIR}/libraries.amdgcn.inc "#include \"rocm/''${header}\"\n")|' \
    #     -i runtime/device/rocm/CMakeLists.txt

    # sed 's|\(target_link_libraries(amdocl64 [^)]*\)|\1 lldELF lldCommon clangFrontend clangCodeGen LLVMDebugInfoDWARF|' -i api/opencl/amdocl/CMakeLists.txt

    # echo 'add_dependencies(oclruntime oclrocm)' >> runtime/CMakeLists.txt
    echo 'add_dependencies(amdocl64 OpenCL)' >> amdocl/CMakeLists.txt
  '';

  cmakeFlags = [
    "-DLLVM_DIR=${llvm.out}/lib/cmake/llvm"
    "-DClang_DIR=${clang-unwrapped}/lib/cmake/clang"
    "-DAMDGPU_TARGET_TRIPLE='amdgcn-amd-amdhsa'"
    "-DUSE_COMGR_LIBRARY='yes'"
    "-DCLANG_OPTIONS_APPEND=-Wno-bitwise-conditional-parentheses"
    "-DLIBROCclr_STATIC_DIR=${rocclr}/lib/cmake"
  ];

  enableParallelBuilding = true;
  nativeBuildInputs = [ cmake rocm-cmake ];
  buildInputs = [ rocm-runtime rocm-thunk rocclr llvm lld rocm-device-libs
                  clang clang-unwrapped
                  comgr
                  mesa_noglu python2 libX11 libGLU ];

  dontStrip = true;

  preFixup = ''
    patchelf --set-rpath "$out/lib" $out/bin/clinfo
  '';
}
