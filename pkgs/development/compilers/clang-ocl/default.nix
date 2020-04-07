{ stdenv, fetchFromGitHub, cmake
, rocm-cmake, rocm-opencl-runtime, rocm-device-libs, rocm-llvm, rocm-lld
, hcc, clang, clang-unwrapped }:
stdenv.mkDerivation rec {
  name = "clang-ocl";
  version = "3.3.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "clang-ocl";
    rev = "rocm-${version}";
    sha256 = "1majwzl3h9xx87rnk4bzl9vw0jf0fcwdknxvyk7snygaqyxjzqmj";
  };
  propagatedBuildInputs = [ rocm-lld ];
  nativeBuildInputs = [ cmake rocm-cmake rocm-opencl-runtime hcc ];
  cmakeFlags = [
    "-DOPENCL_ROOT=${rocm-opencl-runtime}"
    "-DCLINFO=${rocm-opencl-runtime}/bin/clinfo"
    "-DCMAKE_C_COMPILER=${clang}/bin/clang"
    "-DCMAKE_CXX_COMPILER=${clang}/bin/clang++"
  ];
  patchPhase = ''
    sed -e 's,^BITCODE_DIR=.*$,BITCODE_DIR=${rocm-device-libs}/lib,' \
        -e 's,^CLANG=.*$,CLANG=${clang}/bin/clang,' \
        -e 's,^LLVM_LINK=.*$,LLVM_LINK=${rocm-llvm}/bin/llvm-link,' \
        -e "s,\''${OPENCL_ROOT}/include/opencl-c.h,${clang-unwrapped}/lib/clang/10.0.0/include/opencl-c.h," \
        -e 's,#!/bin/bash,#!${stdenv.shell},' \
        -e '/$BITCODE_DIR\/irif.amdgcn.bc \\/d' \
        -i clang-ocl.in
  '';
}
