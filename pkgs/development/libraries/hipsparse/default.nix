{stdenv, fetchFromGitHub, cmake, rocsparse, hip, hcc, rocr, rocm-cmake, comgr, gtest

# Tests are broken as they require downloading and pre-processing
# several files
# , doCheck ? true
}:
let doCheck = false; in
stdenv.mkDerivation rec {
  pname = "hipsparse";
  version = "3.3.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "hipSPARSE";
    rev = "rocm-${version}";
    sha256 = "1hasarrh0lxm2bcbpnyk33vg5kdnmbj9bb6gs1wp3pi6s1c148c3";
  };

  nativeBuildInputs = [ cmake rocm-cmake ] ++ stdenv.lib.optional doCheck gtest;
  buildInputs = [ rocsparse hip hcc rocr comgr ];
  cmakeFlags = [
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DCMAKE_CXX_COMPILER=${hip}/bin/hipcc"
  ] ++ stdenv.lib.optional doCheck "-DBUILD_CLIENTS_TESTS=YES";
  patchPhase = ''
    sed -e 's|find_package(Git REQUIRED)||' \
        -i cmake/Dependencies.cmake
  '';
}
