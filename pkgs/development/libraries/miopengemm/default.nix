{ stdenv, fetchFromGitHub, cmake
, rocm-cmake, rocm-opencl-runtime, hcc }:
stdenv.mkDerivation rec {
  name = "miopengemm";
  version = "1.1.6dev";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "MIOpenGEMM";
    # rev = version;
    rev = "b51a12523676451bf38bfcf0506a0745e80ac64f";
    sha256 = "065gwnjspf6zs6n2pjw2hxjmp9m47q9jngr5snqmh1gv9qvj1b3i";
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
