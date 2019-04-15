{ stdenv, fetchFromGitHub, cmake
, rocm-cmake, rocm-opencl-runtime, hcc }:
stdenv.mkDerivation {
  name = "miopengemm";
  version = "2018-04-03";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "MIOpenGEMM";
    rev = "9547fb9e8499a5a9f16da83b1e6b749de82dd9fb";
    sha256 = "0n02kd1687a8m3ilfrkpdxswnh83mcm4i48gf6irw7dzgdgyxczy";
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
