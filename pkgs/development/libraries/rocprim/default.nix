{stdenv, fetchFromGitHub, lib, config, cmake, pkgconfig
, rocm-cmake, rocm-runtime, hip
, doCheck ? false, gtest ? null
}:

assert doCheck -> gtest != null;

stdenv.mkDerivation rec {
  name = "rocprim";
  version = "3.8.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocPRIM";
    rev = "rocm-${version}";
    sha256 = "0sfypzcpkknn8m4j3w8wahzgjaa8qir7rxmxywwa3vg7a2a4xmdc";
  };
  
  inherit doCheck;
  
  nativeBuildInputs = [ cmake rocm-cmake pkgconfig ];
    
  buildInputs = [ rocm-runtime hip ];

  checkInputs = [ gtest ];

  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=hipcc"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DAMDGPU_TARGETS=${lib.strings.concatStringsSep ";" (config.rocmTargets or ["gfx803" "gfx900" "gfx906"])}"
    "-DBUILD_TEST=${if doCheck then "YES" else "NO"}"
    "${if doCheck then "-DAMDGPU_TEST_TARGETS=${lib.strings.concatStringsSep ";" (config.rocmTargets or ["gfx803" "gfx900" "gfx906"])}" else ""}"
  ];
  
  patchPhase = ''
    sed -e '/find_package(Git/,/endif()/d' \
        -e '/download_project(/,/^[[:space:]]*)/d' \
        -i cmake/Dependencies.cmake
    #sed 's,include(cmake/VerifyCompiler.cmake),,' -i CMakeLists.txt
  '';
  
  checkPhase = ''
    ctest
  '';
}
