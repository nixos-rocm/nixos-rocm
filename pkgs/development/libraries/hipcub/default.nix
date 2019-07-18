{stdenv, fetchFromGitHub, cmake, rocm-cmake, pkgconfig, hcc, hip-clang, rocprim}:
stdenv.mkDerivation rec {
  name = "hipcub";
  version = "2.6.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "hipCUB";
    rev = version;
    sha256 = "09wsfh0v1wf7ws0ywq4isrwds8zb7rn34d0zp10l3irjkhb16a50";
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
