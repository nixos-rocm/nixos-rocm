{stdenv, fetchFromGitHub, cmake, rocm-cmake, pkgconfig, hcc, hip, rocprim}:
stdenv.mkDerivation rec {
  name = "hipcub";
  version = "3.1.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "hipCUB";
    rev = version;
    sha256 = "1b6a9grmvssgzzdwj945sgbv98d7ipcfkln91hpa9qx9jkpzyw8i";
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
