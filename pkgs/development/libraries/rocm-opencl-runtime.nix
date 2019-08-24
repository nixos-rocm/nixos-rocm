{ stdenv
, fetchFromGitHub
, libGL_driver
, cmake
, rocr
, roct
, rocm-llvm
, rocm-lld
, rocm-device-libs
, rocm-clang
, rocm-clang-unwrapped
, rocm-opencl-driver
, mesa_noglu
, python2
, libX11
}:

stdenv.mkDerivation rec {
  version = "2.7.0";
  tag = "roc-${version}";
  name = "rocm-opencl-runtime-${version}";
  srcs =
    [ (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "ROCm-OpenCL-Runtime";
        rev = tag;
        sha256 = "1p3znl0w8c137iqv2q6dv3q7a8di37nzmz4wlxvix7p4fqw87am0";
        name = "ROCm-OpenCL-Runtime-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "KhronosGroup";
        repo = "OpenCL-ICD-Loader";
        rev = "261c1288aadd9dcc4637aca08332f603e6c13715";
        sha256 = "1dg8qnsw5v96sz21xs6ayv5ih8zq5ng0l4mjcl1rm4cn75g0gz9k";
        name = "OpenCL-ICD-Loader-261c128-src";
      })
    ];

  sourceRoot = "ROCm-OpenCL-Runtime-${tag}-src";

  # We end up re-building rocm-device-libs here because the
  # rocm-opencl-runtime build couples itself so tightly to the
  # rocm-device-libs build.
  postUnpack = ''
    chmod --recursive +w .
    mkdir ROCm-OpenCL-Runtime-${tag}-src/library/
    mv OpenCL-ICD-Loader-261c128-src ROCm-OpenCL-Runtime-${tag}-src/api/opencl/khronos/icd
    cp -r ${rocm-device-libs.src} ROCm-OpenCL-Runtime-${tag}-src/library/amdgcn
    chmod --recursive +w ROCm-OpenCL-Runtime-${tag}-src/library/amdgcn
  '';

  # - let the rocm-device-libs build find our pre-built clang
  # - fix the ICD installation path for NixOS
  # - skip building llvm and rocm-opencl-driver, but
  #   lets this build find the private header files it needs from
  #   those builds.
  # - fix a clang header path
  # - explicitly link libamdocl64.so to everything it
  #   needs from lld, llvm, and clang.
  # - give oclruntime a dependency on oclrocm. Without this, only
  #   parallel builds succeed because oclrocm coincidentally finishes
  #   building before the build of oclruntime starts.
  patchPhase = ''
    sed 's|set(CLANG "''${LLVM_TOOLS_BINARY_DIR}/clang''${EXE_SUFFIX}")|set(CLANG "${rocm-clang}/bin/clang")|' -i library/amdgcn/OCL.cmake

    sed 's,"/etc/OpenCL/vendors/","${libGL_driver.driverLink}/etc/OpenCL/vendors/",g' -i api/opencl/khronos/icd/icd_linux.c

    sed -e 's|add_subdirectory(compiler/llvm EXCLUDE_FROM_ALL)|find_package(Clang REQUIRED CONFIG)|' \
        -e 's|add_subdirectory(compiler/driver EXCLUDE_FROM_ALL)|include_directories(${rocm-opencl-driver.src}/src)|' \
        -e 's|include_directories(''${CMAKE_SOURCE_DIR}/compiler/llvm/lib/Target/AMDGPU)|include_directories(${rocm-llvm.src}/lib/Target/AMDGPU)|' \
        -e 's|include_directories(''${CMAKE_BINARY_DIR}/compiler/llvm/lib/Target/AMDGPU)||' \
        -e '/install(PROGRAMS $<TARGET_FILE:clang> $<TARGET_FILE:lld>/,/        COMPONENT libraries)/d' \
        -i CMakeLists.txt

    sed -e 's|''${CMAKE_SOURCE_DIR}/compiler/llvm/tools/clang/lib/Headers/opencl-c.h|${rocm-clang-unwrapped}/lib/clang/9.0.0/include/opencl-c.h|g' \
        -e 's|file(APPEND ''${CMAKE_CURRENT_BINARY_DIR}/libraries.amdgcn.inc "#include \"''${header}\"\n")|file(APPEND ''${CMAKE_CURRENT_BINARY_DIR}/libraries.amdgcn.inc "#include \"rocm/''${header}\"\n")|' \
        -i runtime/device/rocm/CMakeLists.txt

    sed 's|\(target_link_libraries(amdocl64 [^)]*\)|\1 lldELF lldCommon clangFrontend clangCodeGen LLVMDebugInfoDWARF|' -i api/opencl/amdocl/CMakeLists.txt

    echo 'add_dependencies(oclruntime oclrocm)' >> runtime/CMakeLists.txt
  '';

  cmakeFlags = [
    "-DLLVM_DIR=${rocm-llvm.out}/lib/cmake/llvm"
    "-DClang_DIR=${rocm-clang-unwrapped}/lib/cmake/clang"
    "-DAMDGPU_TARGET_TRIPLE='amdgcn-amd-amdhsa'"
  ];

  enableParallelBuilding = true;
  buildInputs = [ cmake rocr roct rocm-llvm rocm-lld rocm-device-libs
                  rocm-clang rocm-clang-unwrapped rocm-opencl-driver
                  mesa_noglu python2 libX11 ];

  dontStrip = true;

  preFixup = ''
    patchelf --set-rpath "$out/lib" $out/bin/clinfo
    ln -s $out/lib/x86_64/libOpenCL.so.1.2 $out/lib/x86_64/libOpenCL.so.1
    ln -s $out/lib/x86_64/* $out/lib
  '';
}
