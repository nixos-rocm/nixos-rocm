{stdenv, fetchFromGitHub, lib, config, cmake, pkgconfig
, rocm-cmake, hip, rocprim
, doCheck ? false, gtest ? null
}:

assert doCheck -> gtest != null;

stdenv.mkDerivation rec {
  name = "hipcub";
  version = "3.8.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "hipCUB";
    rev = "rocm-${version}";
    sha256 = "0l1a0lgwzad2gfpjvmix6372dksm6vjivsc9qk4lyjy6dhdlsljb";
  };

  inherit doCheck;
  
  nativeBuildInputs = [ cmake rocm-cmake pkgconfig ];
  
  buildInputs = [ hip rocprim ];

  checkInputs = [ gtest ];

  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=hipcc"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DAMDGPU_TARGETS=${lib.strings.concatStringsSep ";" (config.rocmTargets or [ "gfx803" "gfx900" "gfx906" ])}"
    "-DBUILD_TEST=${if doCheck then "YES" else "NO"}"
  ];

  patchPhase = ''
    sed -e '/find_package(Git/,/endif()/d' \
        -e '/download_project(/,/^[[:space:]]*)/d' \
        -i cmake/Dependencies.cmake
  '';

  checkPhase = ''
    ctest
  '';
  }
