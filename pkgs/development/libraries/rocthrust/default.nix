{ stdenv, lib, fetchFromGitHub, fetchpatch, cmake
, rocm-cmake, hip, rocprim, comgr
, gtest, doCheck ? false }:
stdenv.mkDerivation rec {
  name = "rocthrust";
  version = "3.5.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocThrust";
    rev = "rocm-${version}";
    sha256 = "0fiwg0ncnj48vqi5b16n9jf6bkk0xlji4hyk55hzswr6n1lzg9pr";
  };

  postPatch = ''
    sed -e '/find_package(Git/,/endif()/d' \
        -e 's,\(set(ROCPRIM_ROOT \).*,\1${rocprim} CACHE PATH ""),' \
        -e '/download_project(/,/)/d' \
        -i cmake/Dependencies.cmake
    sed '/project(rocthrust LANGUAGES CXX)/d' -i CMakeLists.txt
    sed 's/\(cmake_minimum_required.*\)$/\1\nproject(rocthrust LANGUAGES CXX)/' -i CMakeLists.txt
  '';

  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=hipcc"
    "-DHIP_PLATFORM=hcc"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DBUILD_TEST=${if doCheck then "YES" else "NO"}"
  ];
  nativeBuildInputs = [ cmake rocm-cmake ];
  buildInputs = [ hip rocprim comgr ] ++ lib.optionals doCheck [ gtest ];
}
