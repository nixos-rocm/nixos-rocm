{stdenv, fetchFromGitHub, cmake, rocsparse, hip, rocm-runtime, rocm-cmake, comgr, gtest

# Tests are broken as they require downloading and pre-processing
# several files
# , doCheck ? true
}:
let doCheck = false; in
stdenv.mkDerivation rec {
  pname = "hipsparse";
  version = "3.5.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "hipSPARSE";
    rev = "rocm-${version}";
    sha256 = "0zyvvkhyr6cn6dcyi7fh2q5f1w0afcmvzjdalq0bjad77psy0sb2";
  };

  nativeBuildInputs = [ cmake rocm-cmake ] ++ stdenv.lib.optional doCheck gtest;
  buildInputs = [ rocsparse hip rocm-runtime comgr ];
  cmakeFlags = [
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DCMAKE_CXX_COMPILER=${hip}/bin/hipcc"
  ] ++ stdenv.lib.optional doCheck "-DBUILD_CLIENTS_TESTS=YES";
  patchPhase = ''
    sed -e 's|find_package(Git REQUIRED)||' \
        -i cmake/Dependencies.cmake
  '';
}
