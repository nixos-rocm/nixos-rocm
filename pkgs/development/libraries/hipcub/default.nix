{stdenv, fetchFromGitHub, cmake, rocm-cmake, pkgconfig, hcc, hip-clang, rocprim}:
stdenv.mkDerivation rec {
  name = "hipcub";
  version = "2.7";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "hipCUB";
    rev = "rocm-${version}";
    sha256 = "1id4j0cp9lqzkqnhb5kyv2fmkbi0qqp9z8mmr5p7gnrlx8fxka1r";
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
    "-DHIP_PLATFORM=clang"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"    
    "-DBUILD_TEST=NO"
  ];
  buildInputs = [ hip-clang rocprim ];
}
