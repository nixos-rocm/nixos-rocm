{stdenv, fetchFromGitHub, cmake, rocm-cmake, pkgconfig, hip, rocprim}:
stdenv.mkDerivation rec {
  name = "hipcub";
  version = "3.5.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "hipCUB";
    rev = "rocm-${version}";
    sha256 = "186kbwpy0kq5kg9cxsa9p170rdn1cz3sar69nlrqjzyx5alx1i9k";
  };
  patchPhase = ''
    sed -e '/find_package(Git/,/endif()/d' \
        -e '/download_project(/,/^[[:space:]]*)/d' \
        -i cmake/Dependencies.cmake
    sed 's,include(cmake/VerifyCompiler.cmake),,' -i CMakeLists.txt
  '';
  nativeBuildInputs = [ cmake rocm-cmake pkgconfig ];
  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=hipcc"
    # "-DHIP_PLATFORM=clang"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DBUILD_TEST=NO"
  ];
  buildInputs = [ hip rocprim ];
}
