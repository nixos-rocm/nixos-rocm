{stdenv, fetchFromGitHub, fetchpatch, cmake, rocm-cmake, hip, rocprim, hipcub}:
stdenv.mkDerivation rec {
  name = "rocsparse";
  version = "2.6.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocSPARSE";
    rev = with stdenv.lib.versions; 
          "rocm-${stdenv.lib.concatStringsSep 
                    "." [(major version) (minor version)]}";
    sha256 = "1xxjcfbzk99q9vz7yxiy6d1sc9g7w8vgai0xdzxqswh1vigpkbwp";
  };

  postPatch = ''
    sed -e '/find_package(Git/,/endif()/d' \
        -i cmake/Dependencies.cmake
    sed '/project(rocsparse LANGUAGES CXX)/d' -i CMakeLists.txt
    sed 's/\(cmake_minimum_required.*\)$/\1\nproject(rocsparse LANGUAGES CXX)/' -i CMakeLists.txt
    sed 's|#include <rocprim/rocprim_hip.hpp>|#include <rocprim/rocprim.hpp>|' -i library/src/conversion/rocsparse_coosort.cpp
    sed 's|#include <rocprim/rocprim_hip.hpp>|#include <rocprim/rocprim.hpp>|' -i library/src/conversion/rocsparse_csrsort.cpp
  '';

  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=hipcc"
    "-DHIP_PLATFORM=hcc"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"    
    "-DBUILD_TEST=NO"
    "-DCMAKE_PREFIX_PATH=${rocm-cmake}/share/rocm/cmake"
  ];
  nativeBuildInputs = [ cmake rocm-cmake ];
  buildInputs = [ hip rocprim hipcub ];
  
}
