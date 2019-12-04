{stdenv, fetchFromGitHub, cmake, rocm-cmake, pkgconfig, hcc, hip-clang, rocprim}:
stdenv.mkDerivation rec {
  name = "hipcub";
  version = "2.10.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "hipCUB";
    rev = version;
    sha256 = "0i7lv20bsyzyr38vnfj8d720s85q0l5z39m0f6cqmv33nw99hc3q";
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
