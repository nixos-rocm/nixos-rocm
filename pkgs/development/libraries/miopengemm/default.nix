{ stdenv, fetchFromGitHub, cmake
, rocm-cmake, rocm-opencl-runtime, hcc }:
stdenv.mkDerivation {
  name = "miopengemm";
  version = "2019-07-18";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "MIOpenGEMM";
    rev = "6275a879995b58a6e0b8cca7b1ad8421a5e02ade";
    sha256 = "18204r5fj0ch4vcr833xi0fshjfzd8jxf7jdsblkv1n193fl2668";
  };
  nativeBuildInputs = [ cmake rocm-cmake ];
  buildInputs = [ rocm-opencl-runtime ];
  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=${hcc}/bin/hcc"
    "-DOPENCL_INCLUDE_DIRS=${rocm-opencl-runtime}/include"
    "-DOPENCL_LIBRARIES=${rocm-opencl-runtime}/lib/libOpenCL.so"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
  ];
}
