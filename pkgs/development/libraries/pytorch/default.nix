{ stdenv, fetchFromGitHub, cmake, symlinkJoin, utillinux, which, git, openssl
, buildPythonPackage, numpy, pyyaml, cffi, numactl, opencv3, lmdb, pkg-config
, rocr, hip, rocrand, rocblas, rocfft, rocm-cmake, rccl, rocprim, hipcub
, miopen-hip, miopengemm, rocsparse, hipsparse, rocthrust, comgr, hcc
, roctracer }:
buildPythonPackage rec {
  version = "1.0.0";
  pname = "pytorch";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "pytorch";
    rev = "c3a845bb0682f5ced87af2c8c38d1907edebfdd5";
    sha256 = "1194j8yyi2q0s3v7qi68366qx65pzzq3j8xhdfxqiiwscsicwy9l";
    fetchSubmodules = true;
  };
  PYTORCH_BUILD_VERSION = version;
  PYTORCH_BUILD_NUMBER = 0;
  nativeBuildInputs = [ cmake pkg-config utillinux which git ];
  buildInputs = [ 
    numpy.blas
    numactl
    lmdb
    opencv3
    openssl
    hcc
    hip
    rocr
    rccl
    miopen-hip
    miopengemm
    rocrand
    rocblas
    rocfft
    rocsparse
    hipsparse
    rocthrust
    comgr
    rocprim
    hipcub
    roctracer
  ];
  propagatedBuildInputs = [ cffi numpy pyyaml ];
  preConfigure = ''
    export USE_ROCM=1
    export USE_OPENCV=1
    export USE_LMDB=1
    export CXX=${hip}/bin/hipcc
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -std=c++14"
    python3 tools/amd_build/build_amd.py
    sed 's|''${CMAKE_INSTALL_CMAKEDIR}|''${CMAKE_BINARY_DIR}/lib/cmake/protobuf|g' -i third_party/protobuf/cmake/install.cmake
  '';
  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=${hip}/bin/hipcc"
    "-DUSE_CUDA=OFF"
    "-DATEN_NO_TEST=ON"
    "-DUSE_GLOO=OFF"
    "-DUSE_MKLDNN=OFF"
    "-DUSE_OPENMP=OFF"
  ];
}
