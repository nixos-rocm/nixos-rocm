{stdenv, fetchFromGitHub, cmake, rocsparse, hip, rocr, rocm-cmake, gtest

# Tests are broken as they require downloading and pre-processing
# several files
# , doCheck ? true
}:
let doCheck = false; in
stdenv.mkDerivation rec {
  pname = "hipsparse";
  version = "2.6";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "hipSPARSE";
    rev = "rocm-${version}";
    sha256 = "14slds44ippm3kcaj8v2w99rj3cbxrwsc83d17vk8xw838j4fl39";
  };

  nativeBuildInputs = [ cmake rocm-cmake ] ++ stdenv.lib.optional doCheck gtest;
  buildInputs = [ rocsparse hip rocr ];
  cmakeFlags = [
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
  ] ++ stdenv.lib.optional doCheck "-DBUILD_CLIENTS_TESTS=YES";
  patchPhase = ''
    sed -e 's|find_package(Git REQUIRED)||' \
        -i cmake/Dependencies.cmake
  '';
}
