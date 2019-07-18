{stdenv, fetchFromGitHub, fetchpatch, cmake, rocm-cmake, hip, rocprim
, gtest, doCheck ? false }:
stdenv.mkDerivation rec {
  name = "rocthrust";
  version = "2.6.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocThrust";
    rev = version;
    sha256 = "1znrh2nq4d6083g2yyw6rz0lygpmhkxwzk0n60vk3rl7b1zm5p33";
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
    # "-DCMAKE_PREFIX_PATH=${rocm-cmake}/share/rocm/cmake"
  ];
  nativeBuildInputs = [ cmake rocm-cmake ];
  buildInputs = [ hip rocprim ] ++ stdenv.lib.optionals doCheck [ gtest ];
  
}
