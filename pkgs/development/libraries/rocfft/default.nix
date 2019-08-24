{ stdenv, fetchFromGitHub, cmake, pkgconfig
, rocr, rocminfo, hcc, hip, rocm-cmake
, doCheck ? false
, boost, gtest, fftw, fftwFloat }:
stdenv.mkDerivation rec {
  name = "rocFFT";
  version = "2.7";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocFFT";
    rev = "rocm-${version}";
    sha256 = "1q10qsy7grch2ibc686z1yl0bgnrzfp5lxfy2jnasfbk0nys1mc7";
  };

  # Building this package is very RAM intensive: individual clang
  # processes use over 6GB of RAM.
  enableParallelBuilding = false;

  nativeBuildInputs = [ cmake rocm-cmake pkgconfig rocminfo ];
  buildInputs = [ hcc hip rocr boost ]
    ++ stdenv.lib.optionals doCheck [ gtest fftwFloat fftw ];
  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=${hcc}/bin/hcc"
    "-DHSA_HEADER=${rocr}/include"
    "-DHSA_LIBRARY=${rocr}/lib/libhsa-runtime64.so"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
  ] ++ stdenv.lib.optionals doCheck [
    "-DBUILD_CLIENTS_TESTS=ON"
    "-DBUILD_CLIENTS_BENCHMARKS=ON"
  ];
}
