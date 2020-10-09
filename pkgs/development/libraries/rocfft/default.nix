{ stdenv, fetchFromGitHub, fetchpatch, cmake, pkgconfig
, rocm-runtime, rocminfo, clang, hip, rocm-cmake, comgr
, doCheck ? false
, boost, gtest, fftw, fftwFloat }:
stdenv.mkDerivation rec {
  name = "rocFFT";
  version = "3.5.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocFFT";
    rev = "${version}";
    sha256 = "03cxfx40gg817pm1lknpi7vma17wfqggprxd8vz8hlipxd3cisng";
  };

  # Building this package is very RAM intensive: individual clang
  # processes use over 6GB of RAM.
  enableParallelBuilding = false;
  CXXFLAGS = "-D__HIP_PLATFORM_HCC__ -D__HIP__";

  nativeBuildInputs = [ cmake rocm-cmake pkgconfig rocminfo ];
  buildInputs = [ hip rocm-runtime boost comgr ]
    ++ stdenv.lib.optionals doCheck [ gtest fftwFloat fftw ];
  cmakeFlags = [
    # "-DUSE_HIP_CLANG=YES"
    "-DCMAKE_CXX_COMPILER=${hip}/bin/hipcc"
    # "-DHSA_HEADER=${rocm-runtime}/include"
    # "-DHSA_LIBRARY=${rocm-runtime}/lib/libhsa-runtime64.so"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
  ] ++ stdenv.lib.optionals doCheck [
    "-DBUILD_CLIENTS_TESTS=ON"
    "-DBUILD_CLIENTS_BENCHMARKS=ON"
  ];

}
