{ stdenv, fetchFromGitHub, fetchpatch, lib, config, cmake, pkgconfig
, rocm-runtime, rocminfo, clang, hip, rocm-cmake, comgr
, boost 
, doCheck ? false, gtest ? null, fftw ? null, fftwFloat ? null 
}:

assert doCheck -> gtest != null
               && fftw != null
               && fftwFloat != null;

stdenv.mkDerivation rec {
  name = "rocFFT";
  version = "3.8.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocFFT";
    rev = "rocm-${version}";
    sha256 = "129jvg3jl723wixfnw0w3ljjgjz49jkdwcp80layzlh2xifqm880";
  };

  # Building this package is very RAM intensive: individual clang
  # processes use over 6GB of RAM.
  #enableParallelBuilding = false;
  
  CXXFLAGS = "-D__HIP_PLATFORM_HCC__ -D__HIP__ ";

  nativeBuildInputs = [ cmake rocm-cmake pkgconfig rocminfo ];
  
  buildInputs = [ hip rocm-runtime boost comgr ];
  
  checkInputs = [ gtest fftwFloat fftw ];
  
  cmakeFlags = [
    "-DUSE_HIP_CLANG=ON"
    "-DCMAKE_CXX_COMPILER=${hip}/bin/hipcc"
    # "-DHSA_HEADER=${rocm-runtime}/include"
    # "-DHSA_LIBRARY=${rocm-runtime}/lib/libhsa-runtime64.so"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DAMDGPU_TARGETS=${lib.strings.concatStringsSep ";" (config.rocmTargets or [ "gfx803" "gfx900" "gfx906" ])}"
  ] ++ stdenv.lib.optionals doCheck [
    "-DBUILD_CLIENTS_TESTS=ON"
    "-DBUILD_CLIENTS_BENCHMARKS=ON"
  ];

}
