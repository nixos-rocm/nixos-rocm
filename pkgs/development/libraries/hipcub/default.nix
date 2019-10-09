{stdenv, fetchFromGitHub, cmake, rocm-cmake, pkgconfig, hcc, hip-clang, rocprim}:
stdenv.mkDerivation rec {
  name = "hipcub";
  version = "2.9.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "hipCUB";
    rev = version;
    sha256 = "1ipqjac17pv1cvraqfxcfg3rzncww46rnlfgb6rzyjcbg6h2p0si";
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
