{ stdenv, fetchFromGitHub, cmake
, rocm-cmake, rocm-opencl-runtime, rocm-device-libs, rocm-llvm, rocm-lld
, hcc, hcc-clang-unwrapped }:
stdenv.mkDerivation {
  name = "clang-ocl";
  version = "2018-06-18";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "clang-ocl";
    rev = "799713643b5591a3b877c586ef2c7fbc012af819";
    sha256 = "172wn8drixzxv4rlz5i33l31ixbmkn1nx7asm697pa86nw2lwdm0";
  };
  propagatedBuildInputs = [ rocm-lld ];
  nativeBuildInputs = [ cmake rocm-cmake rocm-opencl-runtime hcc ];
  cmakeFlags = [
    "-DOPENCL_ROOT=${rocm-opencl-runtime}"
    "-DCLINFO=${rocm-opencl-runtime}/bin/clinfo"
    "-DCMAKE_C_COMPILER=${hcc}/bin/clang"
    "-DCMAKE_CXX_COMPILER=${hcc}/bin/clang++"
  ];
  patchPhase = ''
    sed -e 's,^BITCODE_DIR=.*$,BITCODE_DIR=${rocm-device-libs}/lib,' \
        -e 's,^CLANG=.*$,CLANG=${hcc}/bin/clang,' \
        -e 's,^LLVM_LINK=.*$,LLVM_LINK=${rocm-llvm}/bin/llvm-link,' \
        -e "s,\''${OPENCL_ROOT}/include/opencl-c.h,${hcc-clang-unwrapped}/lib/clang/7.0.0/include/opencl-c.h," \
        -e 's,#!/bin/bash,#!${stdenv.shell},' \
        -i clang-ocl.in
  '';
}
