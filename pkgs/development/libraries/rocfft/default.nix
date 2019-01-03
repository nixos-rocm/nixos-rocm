{ stdenv, fetchFromGitHub, cmake, pkgconfig
, rocr, rocminfo, hcc, hip, rocm-cmake
, doCheck ? false
, boost, gtest, fftw, fftwFloat }:
stdenv.mkDerivation rec {
  name = "rocFFT";
  version = "0.8.8";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocFFT";
    rev = "v${version}";
    sha256 = "0vjwn29ih8xmb15ikvzcchcy9nj9646jj818c7ks0y5hgkbm8ynj";
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
