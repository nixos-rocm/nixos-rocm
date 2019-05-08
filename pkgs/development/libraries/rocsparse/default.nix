{stdenv, fetchFromGitHub, cmake, rocm-cmake, hcc, hip, rocprim, hipcub}:
stdenv.mkDerivation rec {
  name = "rocsparse";
  version = "2.4.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocSPARSE";
    rev = with stdenv.lib.versions; 
          "rocm-${stdenv.lib.concatStringsSep 
                    "." [(major version) (minor version)]}";

    sha256 = "1n2x13v4is11ld3228yklk0xcc01ndwakiysnnry9j0ixzcjic0r";
  };
  patchPhase = ''
    sed -e '/find_package(Git/,/endif()/d' \
        -i cmake/Dependencies.cmake
    sed '/project(rocsparse LANGUAGES CXX)/d' -i CMakeLists.txt
    sed 's/\(cmake_minimum_required.*\)$/\1\nproject(rocsparse LANGUAGES CXX)/' -i CMakeLists.txt
  '';
  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=hcc"
    "-DHIP_PLATFORM=hcc"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"    
    "-DBUILD_TEST=NO"
  ];
  nativeBuildInputs = [ cmake rocm-cmake ];
  buildInputs = [ hcc hip rocprim hipcub ];
  
}
