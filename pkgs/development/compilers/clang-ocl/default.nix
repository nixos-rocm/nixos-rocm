{ stdenv, fetchFromGitHub, cmake
, rocm-cmake, rocm-opencl-runtime, rocm-device-libs, rocm-llvm, rocm-lld
, hcc, hcc-clang-unwrapped, amd-clang, amd-clang-unwrapped }:
stdenv.mkDerivation rec {
  name = "clang-ocl";
  version = "2.10.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "clang-ocl";
    rev = "roc-${version}";
    sha256 = "0498785cw8v68lamip4ly0c6pmadqr1m2hxl57la6p6lg80bf63v";
  };
  propagatedBuildInputs = [ rocm-lld ];
  nativeBuildInputs = [ cmake rocm-cmake rocm-opencl-runtime hcc ];
  cmakeFlags = [
    "-DOPENCL_ROOT=${rocm-opencl-runtime}"
    "-DCLINFO=${rocm-opencl-runtime}/bin/clinfo"
    "-DCMAKE_C_COMPILER=${amd-clang}/bin/clang"
    "-DCMAKE_CXX_COMPILER=${amd-clang}/bin/clang++"
  ];
  patchPhase = ''
    sed -e 's,^BITCODE_DIR=.*$,BITCODE_DIR=${rocm-device-libs}/lib,' \
        -e 's,^CLANG=.*$,CLANG=${amd-clang}/bin/clang,' \
        -e 's,^LLVM_LINK=.*$,LLVM_LINK=${rocm-llvm}/bin/llvm-link,' \
        -e "s,\''${OPENCL_ROOT}/include/opencl-c.h,${amd-clang-unwrapped}/lib/clang/10.0.0/include/opencl-c.h," \
        -e 's,#!/bin/bash,#!${stdenv.shell},' \
        -e '/$BITCODE_DIR\/irif.amdgcn.bc \\/d' \
        -i clang-ocl.in
  '';
}
