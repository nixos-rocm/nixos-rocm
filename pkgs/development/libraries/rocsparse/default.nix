{ stdenv, fetchFromGitHub, fetchpatch, lib, config, cmake, gfortran
, rocm-cmake, hip, rocprim, hipcub, comgr 
, doCheck ? false, gtest ? null
}:

assert doCheck -> gtest != null;

stdenv.mkDerivation rec {
  name = "rocsparse";
  version = "3.8.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocSPARSE";
    rev = "rocm-${version}";
    sha256 = "144i9y7lcawixsfc9d9bbrx4w2jr6vnamx12jkyms7y1gln75qpf";
  };

  inherit doCheck;

  postPatch = ''
    sed -e '/find_package(Git REQUIRED)/d' \
        -e '/include(cmake\/DownloadProject\/DownloadProject.cmake)/d' \
        -e '/find_package(hcc REQUIRED CONFIG PATHS ''${CMAKE_PREFIX_PATH})/d' \
        -i cmake/Dependencies.cmake
    sed '/project(rocsparse LANGUAGES CXX)/d' -i CMakeLists.txt
    sed 's/\(cmake_minimum_required.*\)$/\1\nproject(rocsparse LANGUAGES CXX)/' -i CMakeLists.txt
  '';

  nativeBuildInputs = [ cmake rocm-cmake ];
  
  buildInputs = [ hip rocprim hipcub comgr gfortran ];

  checkInputs = [ gtest ];

  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=hipcc"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DBUILD_TEST=${if doCheck then "ON" else "OFF"}"
    "-DCMAKE_PREFIX_PATH=${rocm-cmake}/share/rocm/cmake"
    "-DAMDGPU_TARGETS=${lib.strings.concatStringsSep ";" (config.rocmTargets or [ "gfx803" "gfx900" "gfx906" ])}"
  ];

  checkPhase = ''
    # Test phase does not work. 
    #./clients/staging/rocsparse-test
  '';
}
