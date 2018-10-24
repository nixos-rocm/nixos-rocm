{ stdenv
, fetchFromGitHub
, libGL_driver
, cmake
, rocr
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
  version = "1.9.1";
  tag = "roc-${version}";
  name = "rocm-opencl-runtime-${version}";
  srcs =
    [ (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "ROCm-OpenCL-Runtime";
        rev = tag;
        sha256 = "1vrs1810w8xhh839agqvb153xlg78azfz3wvpdgr3g2ic7hfs7nv";
        name = "ROCm-OpenCL-Runtime-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "KhronosGroup";
        repo = "OpenCL-ICD-Loader";
        rev = "b342ff7b7f70a4b3f2cfc53215af8fa20adc3d86";
        sha256 = "104l33xxras1cadn6xxkas8dl2ss6wi4dlqjqh103ww83g95108x";
        name = "OpenCL-ICD-Loader-b342ff7-src";
      })
    ];

  sourceRoot = "ROCm-OpenCL-Runtime-${tag}-src";

  # We end up re-building rocm-device-libs here because the
  # rocm-opencl-runtime build couples itself so tightly to the
  # rocm-device-libs build.
  postUnpack = ''
    chmod --recursive +w .
    mkdir ROCm-OpenCL-Runtime-${tag}-src/library/
    mv OpenCL-ICD-Loader-b342ff7-src ROCm-OpenCL-Runtime-${tag}-src/api/opencl/khronos/icd
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
  patchPhase = ''
    sed 's|set (CMAKE_OCL_COMPILER ''${LLVM_TOOLS_BINARY_DIR}/clang)|set (CMAKE_OCL_COMPILER ${rocm-clang}/bin/clang)|' -i library/amdgcn/OCL.cmake

    sed 's,"/etc/OpenCL/vendors/","${libGL_driver.driverLink}/etc/OpenCL/vendors/",g' -i api/opencl/khronos/icd/icd_linux.c

    sed -e 's|add_subdirectory(compiler/llvm)|find_package(Clang REQUIRED CONFIG)|' \
        -e 's|add_subdirectory(compiler/driver)|include_directories(${rocm-opencl-driver.src}/src)|' \
        -e 's|include_directories(''${CMAKE_SOURCE_DIR}/compiler/llvm/lib/Target/AMDGPU)|include_directories(${rocm-llvm.src}/lib/Target/AMDGPU)|' \
        -i CMakeLists.txt

    sed 's|''${CMAKE_SOURCE_DIR}/compiler/llvm/tools/clang/lib/Headers/opencl-c.h|${rocm-clang-unwrapped}/lib/clang/7.0.0/include/opencl-c.h|g' -i runtime/device/rocm/CMakeLists.txt

    sed 's|\(target_link_libraries(amdocl64 [^)]*\)|\1 lldELF lldCommon LLVMDebugInfoDWARF LLVMAMDGPUCodeGen LLVMAMDGPUAsmParser LLVMAMDGPUDisassembler LLVMX86CodeGen LLVMX86AsmParser clangFrontend clangCodeGen|' -i api/opencl/amdocl/CMakeLists.txt
  '';

  cmakeFlags = [
    "-DLLVM_DIR=${rocm-llvm.out}/lib/cmake/llvm"
    "-DClang_DIR=${rocm-clang-unwrapped}/lib/cmake/clang"
    "-DLLD_INCLUDE_DIR=${rocm-lld}/include"
    "-DAMDGPU_TARGET_TRIPLE='amdgcn-amd-amdhsa'"
  ];

  enableParallelBuilding = true;
  buildInputs = [ cmake rocr rocm-llvm rocm-lld rocm-device-libs
                  rocm-clang rocm-clang-unwrapped rocm-opencl-driver
                  mesa_noglu python2 libX11 ];

  #cmakeBuildType = "Debug";
  dontStrip = true;

  preFixup = ''
    patchelf --set-rpath "$out/lib" $out/bin/clinfo
    ln -s $out/lib/libOpenCL.so.1.2 $out/lib/libOpenCL.so.1
    ln -s $out/lib/libOpenCL.so.1 $out/lib/libOpenCL.so
  '';
}
