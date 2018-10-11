{ stdenv, fetchFromGitHub, cmake, pkgconfig
, rocr, rocminfo, hcc, hip, rocm-cmake
, doCheck ? false
, boost, gtest, fftw, fftwFloat }:
stdenv.mkDerivation rec {
  name = "rocFFT";
  version = "2018-10-05";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocFFT";
    rev = "e32b45a42a8cb16253130bb372ee557cd9e5443e";
    sha256 = "0mg3g4wn32akpvyvs4wk9g6lrd8qp7r8g3pih2709s5a2qwwgg5z";
  };

  # Building this package is very RAM intensive: individual clang
  # processes use over 6GB of RAM.
  enableParallelBuilding = false;

  nativeBuildInputs = [ cmake rocm-cmake pkgconfig ];
  buildInputs = [ hcc hip rocr ]
    ++ stdenv.lib.optionals doCheck [ boost gtest fftwFloat fftw ];
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
