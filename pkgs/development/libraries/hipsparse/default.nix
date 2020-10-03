{stdenv, fetchFromGitHub, cmake, gfortran, rocsparse, rocprim, hip, rocm-runtime, rocm-cmake, comgr

# Tests are broken as they require downloading and pre-processing
# several files
, doCheck ? false, gtest ? null
}:

assert doCheck -> gtest != null;

stdenv.mkDerivation rec {
  pname = "hipsparse";
  version = "3.8.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "hipSPARSE";
    rev = "rocm-${version}";
    sha256 = "0h5q6f9f9vhr05aryxx5iapkd2n2zhsv1w09lm3q6pnpy87y6kd3";
  };

  inherit doCheck;

  nativeBuildInputs = [ cmake rocm-cmake ];
  
  buildInputs = [ gfortran rocsparse rocprim hip rocm-runtime comgr ];

  checkInputs = [ gtest ];
  
  cmakeFlags = [
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DCMAKE_CXX_COMPILER=${hip}/bin/hipcc"
  ] ++ stdenv.lib.optional doCheck "-DBUILD_CLIENTS_TESTS=YES";
  patchPhase = ''
    sed -e 's|find_package(Git REQUIRED)||' \
        -i cmake/Dependencies.cmake
  '';
}
