{ stdenv
, fetchFromGitHub
, addOpenGLRunpath
, cmake
, rocr
, roct
, rocm-llvm
, rocm-lld
, rocm-device-libs
, rocm-clang
, rocm-clang-unwrapped
, rocm-cmake
, comgr
, mesa_noglu
, python2
, libX11
, libGLU
}:

stdenv.mkDerivation rec {
  version = "3.1.0";
  tag = "roc-${version}";
  name = "rocm-opencl-runtime-${version}";
  srcs =
    [ (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "ROCm-OpenCL-Runtime";
        rev = tag;
        sha256 = "1fp91bx0vlgb5fq0rjzmm10dvhbf1h5p9jd3jac01nj8xxpg2rgk";
        name = "ROCm-OpenCL-Runtime-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "KhronosGroup";
        repo = "OpenCL-ICD-Loader";
        rev = "6c03f8b58fafd9dd693eaac826749a5cfad515f8";
        sha256 = "00icrlc00dpc87prbd2j1350igi9pbgkz27hc3rf73s5994yn86a";
        name = "OpenCL-ICD-Loader-6c03f8b-src";
      })
    ];

  sourceRoot = "ROCm-OpenCL-Runtime-${tag}-src";

  # We end up re-building rocm-device-libs here because the
  # rocm-opencl-runtime build couples itself so tightly to the
  # rocm-device-libs build.
  postUnpack = ''
    chmod --recursive +w .
    mkdir ROCm-OpenCL-Runtime-${tag}-src/library/
    mv OpenCL-ICD-Loader-6c03f8b-src ROCm-OpenCL-Runtime-${tag}-src/api/opencl/khronos/icd
    cp -r ${rocm-device-libs.src} ROCm-OpenCL-Runtime-${tag}-src/library/amdgcn
    chmod --recursive +w ROCm-OpenCL-Runtime-${tag}-src/library/amdgcn
  '';

  # patches = [ ./libdebug.patch ];
  patches = [ ./link-comgr.patch ];

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
    sed 's|set(CLANG "''${LLVM_TOOLS_BINARY_DIR}/clang''${EXE_SUFFIX}")|set(CLANG "${rocm-clang}/bin/clang")|' -i library/amdgcn/OCL.cmake

    sed 's,ICD_VENDOR_PATH,"${addOpenGLRunpath.driverLink}/etc/OpenCL/vendors/",g' -i api/opencl/khronos/icd/loader/linux/icd_linux.c

    sed -e 's|add_subdirectory(compiler/llvm EXCLUDE_FROM_ALL)|find_package(Clang REQUIRED CONFIG)|' \
        -e 's|include_directories(''${CMAKE_SOURCE_DIR}/compiler/llvm/lib/Target/AMDGPU)|include_directories(${rocm-llvm.src}/lib/Target/AMDGPU)|' \
        -e 's|include_directories(''${CMAKE_BINARY_DIR}/compiler/llvm/lib/Target/AMDGPU)||' \
        -e '/install(PROGRAMS $<TARGET_FILE:clang> $<TARGET_FILE:lld>/,/^[[:space:]]*COMPONENT DEV)/d' \
        -e 's|add_subdirectory(compiler/driver EXCLUDE_FROM_ALL)||' \
        -i CMakeLists.txt

    sed -e 's|''${CMAKE_SOURCE_DIR}/compiler/llvm/tools/clang/lib/Headers/opencl-c.h|${rocm-clang-unwrapped}/lib/clang/10.0.0/include/opencl-c.h|g' \
        -e 's|file(APPEND ''${CMAKE_CURRENT_BINARY_DIR}/libraries.amdgcn.inc "#include \"''${header}\"\n")|file(APPEND ''${CMAKE_CURRENT_BINARY_DIR}/libraries.amdgcn.inc "#include \"rocm/''${header}\"\n")|' \
        -i runtime/device/rocm/CMakeLists.txt

    sed 's|\(target_link_libraries(amdocl64 [^)]*\)|\1 lldELF lldCommon clangFrontend clangCodeGen LLVMDebugInfoDWARF|' -i api/opencl/amdocl/CMakeLists.txt

    echo 'add_dependencies(oclruntime oclrocm)' >> runtime/CMakeLists.txt
  '';

  cmakeFlags = [
    "-DLLVM_DIR=${rocm-llvm.out}/lib/cmake/llvm"
    "-DClang_DIR=${rocm-clang-unwrapped}/lib/cmake/clang"
    "-DAMDGPU_TARGET_TRIPLE='amdgcn-amd-amdhsa'"
    "-DUSE_COMGR_LIBRARY='yes'"
    "-DCLANG_OPTIONS_APPEND=-Wno-bitwise-conditional-parentheses"
  ];

  enableParallelBuilding = true;
  nativeBuildInputs = [ cmake rocm-cmake ];
  buildInputs = [ rocr roct rocm-llvm rocm-lld rocm-device-libs
                  rocm-clang rocm-clang-unwrapped
                  comgr
                  mesa_noglu python2 libX11 libGLU ];

  dontStrip = true;

  preFixup = ''
    patchelf --set-rpath "$out/lib" $out/bin/x86_64/clinfo
    ln -s $out/bin/x86_64/* $out/bin
    rm -f $out/lib/libOpenCL*
    ln -s $out/lib/x86_64/* $out/lib
  '';
}
