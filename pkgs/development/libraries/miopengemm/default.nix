{ stdenv, fetchFromGitHub, cmake
, rocm-cmake, rocm-opencl-runtime, hcc }:
stdenv.mkDerivation rec {
  name = "miopengemm";
  version = "1.1.6";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "MIOpenGEMM";
    rev = version;
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
