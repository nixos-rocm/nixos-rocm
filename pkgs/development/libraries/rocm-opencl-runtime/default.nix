{ stdenv
, lib
, fetchFromGitHub
, addOpenGLRunpath
, cmake
, rocm-cmake
, clang
, clang-unwrapped
, glew
, libglvnd
, libX11
, lld
, llvm
, mesa
, numactl
, python3
, rocclr
, rocm-comgr
, rocm-device-libs
, rocm-runtime
, rocm-thunk
}:

stdenv.mkDerivation rec {
  pname = "rocm-opencl-runtime";
  version = "4.5.0";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCm-OpenCL-Runtime";
    rev = "rocm-${version}";
    hash = "sha256-0OGYF4urlscr8tMkQwo2yATXwN0DjB092KQ+CBEhfIA=";
  };

  nativeBuildInputs = [ cmake rocm-cmake ];

  buildInputs = [
    clang
    clang-unwrapped
    glew
    libglvnd
    libX11
    lld
    llvm
    mesa
    numactl
    python3
    rocm-comgr
    rocm-device-libs
    rocm-runtime
    rocm-thunk
  ];

  cmakeFlags = [
    "-DAMDGPU_TARGET_TRIPLE='amdgcn-amd-amdhsa'"
    "-DCLANG_OPTIONS_APPEND=-Wno-bitwise-conditional-parentheses"
    "-DClang_DIR=${clang-unwrapped}/lib/cmake/clang"
    # "-DLIBROCclr_STATIC_DIR=${rocclr}/lib/cmake"
    "-DLLVM_DIR=${llvm.out}/lib/cmake/llvm"
    "-DUSE_COMGR_LIBRARY=ON"
    "-DOPENCL_DIR=$sourceRoot"
    "-DROCclr_DIR=${rocclr.src}"
    "-DROCCLR_INCLUDE_DIR=${rocclr.src}/include"
    "-DAMD_OPENCL_PATH=${src}"
  ];

  dontStrip = true;

  # Remove clinfo, which is already provided through the
  # `clinfo` package.
  postInstall = ''
    rm -rf $out/bin
  '';

  # - Fix the ICD installation path for NixOS
  # - The HIP build wants cl_egl.h
  postPatch = ''
    substituteInPlace khronos/icd/loader/linux/icd_linux.c \
      --replace 'ICD_VENDOR_PATH' '"${addOpenGLRunpath.driverLink}/etc/OpenCL/vendors/"'

    substituteInPlace CMakeLists.txt --replace "PATTERN cl_egl.h EXCLUDE" ""
  '';

#    echo 'add_dependencies(amdocl OpenCL)' >> amdocl/CMakeLists.txt
  meta = with lib; {
    description = "OpenCL runtime for AMD GPUs, part of the ROCm stack";
    homepage = "https://github.com/RadeonOpenCompute/ROCm-OpenCL-Runtime";
    license = with licenses; [ asl20 mit ];
    maintainers = with maintainers; [ acowley danieldk ];
    platforms = platforms.linux;
  };
}
