{stdenv, fetchFromGitHub, fetchpatch, cmake, rocm-cmake, hip, hcc, rocprim, hipcub, comgr}:
stdenv.mkDerivation rec {
  name = "rocsparse";
  version = "3.3.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocSPARSE";
    rev = "rocm-${version}";
    sha256 = "1csmd89s03xs3c93x8jh9sb99ap63cx6d2mdl8h4f6rdj52viqa6";
  };

  postPatch = ''
    sed -e '/find_package(Git REQUIRED)/d' \
        -e '/include(cmake\/DownloadProject\/DownloadProject.cmake)/d' \
        -e '/find_package(hcc REQUIRED CONFIG PATHS ''${CMAKE_PREFIX_PATH})/d' \
        -i cmake/Dependencies.cmake
    sed '/project(rocsparse LANGUAGES CXX)/d' -i CMakeLists.txt
    sed 's/\(cmake_minimum_required.*\)$/\1\nproject(rocsparse LANGUAGES CXX)/' -i CMakeLists.txt
    sed 's|#include <rocprim/rocprim_hip.hpp>|#include <rocprim/rocprim.hpp>|' -i library/src/conversion/rocsparse_coosort.cpp
    sed 's|#include <rocprim/rocprim_hip.hpp>|#include <rocprim/rocprim.hpp>|' -i library/src/conversion/rocsparse_csrsort.cpp
  '';

  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=hipcc"
    "-DHIP_COMPILER=clang"
    "-DHIP_PLATFORM=hcc"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DBUILD_TEST=NO"
    "-DCMAKE_PREFIX_PATH=${rocm-cmake}/share/rocm/cmake"
  ];
  nativeBuildInputs = [ cmake rocm-cmake ];
  buildInputs = [ hip hcc rocprim hipcub comgr ];

}
