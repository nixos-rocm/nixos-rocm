{stdenv, fetchFromGitHub, cmake, rocsparse, hip, hcc, rocr, rocm-cmake, comgr, gtest

# Tests are broken as they require downloading and pre-processing
# several files
# , doCheck ? true
}:
let doCheck = false; in
stdenv.mkDerivation rec {
  pname = "hipsparse";
  version = "3.1";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "hipSPARSE";
    rev = "rocm-${version}";
    sha256 = "0x904z7d8lmk4d1h3cx8y8vw2fky9z81nw2bhvc0gn83j9gfxb4z";
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
