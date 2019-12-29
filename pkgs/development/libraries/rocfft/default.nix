{ stdenv, fetchFromGitHub, cmake, pkgconfig
, rocr, rocminfo, clang, hcc, hip, rocm-cmake, comgr
, doCheck ? false
, boost, gtest, fftw, fftwFloat }:
stdenv.mkDerivation rec {
  name = "rocFFT";
  version = "3.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocFFT";
    rev = "rocm-${version}";
    sha256 = "1ihrnc9sprw8fa9vfs1hylq83rw7akvr2lymvq9l48rb30fhp1fb";
  };

  # Building this package is very RAM intensive: individual clang
  # processes use over 6GB of RAM.
  enableParallelBuilding = false;
  CXXFLAGS = "-D__HIP_PLATFORM_HCC__ -D__HIP__";

  nativeBuildInputs = [ cmake rocm-cmake pkgconfig rocminfo ];
  buildInputs = [ hcc hip rocr boost comgr ]
    ++ stdenv.lib.optionals doCheck [ gtest fftwFloat fftw ];
  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=${hip}/bin/hipcc"
    "-DHSA_HEADER=${rocr}/include"
    "-DHSA_LIBRARY=${rocr}/lib/libhsa-runtime64.so"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DUSE_HIP_CLANG=YES"
  ] ++ stdenv.lib.optionals doCheck [
    "-DBUILD_CLIENTS_TESTS=ON"
    "-DBUILD_CLIENTS_BENCHMARKS=ON"
  ];

}
