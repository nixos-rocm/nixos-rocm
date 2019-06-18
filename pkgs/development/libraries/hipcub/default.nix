{stdenv, fetchFromGitHub, cmake, rocm-cmake, pkgconfig, hcc, hip-clang, rocprim}:
stdenv.mkDerivation rec {
  name = "hipcub";
  version = "2.5.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "hipCUB";
    rev = version;
    sha256 = "0llbrganhfjlqzrnxsaxxmnj75asj3xsicbidd8n6p6r31w3l9s0";
  };
  patchPhase = ''
    sed '/find_package(hcc/d' -i cmake/VerifyCompiler.cmake
    sed -e '/find_package(Git/,/endif()/d' \
        -e '/download_project(/,/^[[:space:]]*)/d' \
        -i cmake/Dependencies.cmake
  '';
  nativeBuildInputs = [ cmake rocm-cmake pkgconfig ];
  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=hcc"
    "-DHIP_PLATFORM=hcc"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"    
    "-DBUILD_TEST=NO"
  ];
  buildInputs = [ hcc hip-clang rocprim ];
}
