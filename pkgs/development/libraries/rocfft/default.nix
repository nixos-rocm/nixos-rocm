{ stdenv, fetchFromGitHub, cmake, pkgconfig
, rocr, rocminfo, hcc, hip, rocm-cmake
, doCheck ? false
, boost, gtest, fftw, fftwFloat }:
stdenv.mkDerivation rec {
  name = "rocFFT";
  version = "2018-10-11";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocFFT";
    rev = "29bb4908f033f3fb96339c5f3efb972f65c148ca";
    sha256 = "0napb6zhb7bj7jwrvai2x96vn1b37zn3hbvkfgamz47gbiwlxan9";
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
