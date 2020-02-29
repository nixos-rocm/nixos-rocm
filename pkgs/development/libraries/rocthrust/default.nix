{stdenv, fetchFromGitHub, fetchpatch, cmake, rocm-cmake, hip, rocprim, comgr
, hcc
, gtest, doCheck ? false }:
stdenv.mkDerivation rec {
  name = "rocthrust";
  version = "3.1.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocThrust";
    rev = version;
    sha256 = "0bzypsm9lnsw424iqmfxv3l6854fnl7whj5gfzkpvdasgrfl5zd3";
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
  buildInputs = [ hcc hip rocprim comgr ] ++ stdenv.lib.optionals doCheck [ gtest ];

}
