{stdenv, fetchFromGitHub, cmake, rocsparse, hip, hcc, rocr, rocm-cmake, comgr, gtest

# Tests are broken as they require downloading and pre-processing
# several files
# , doCheck ? true
}:
let doCheck = false; in
stdenv.mkDerivation rec {
  pname = "hipsparse";
  version = "3.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "hipSPARSE";
    rev = "rocm-${version}";
    sha256 = "1gjifv1va5zriv5jajcvc9d91m9gqbnkpyvd398p4jfz225ifxln";
  };

  nativeBuildInputs = [ cmake rocm-cmake ] ++ stdenv.lib.optional doCheck gtest;
  buildInputs = [ rocsparse hip hcc rocr comgr ];
  cmakeFlags = [
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
  ] ++ stdenv.lib.optional doCheck "-DBUILD_CLIENTS_TESTS=YES";
  patchPhase = ''
    sed -e 's|find_package(Git REQUIRED)||' \
        -i cmake/Dependencies.cmake
  '';
}
