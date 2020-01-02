{stdenv, fetchFromGitHub, cmake, pkgconfig, gtest, rocm-cmake, rocr, hip

# The test suite takes a long time to build
, doCheck ? false
}:
stdenv.mkDerivation rec {
  name = "rocprim";
  version = "3.0.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocPRIM";
    rev = version;
    sha256 = "1sj8j11p7andnjxxk9a82qfhcbvijdf48k4g3vlxn58h710ckb7w";
  };
  nativeBuildInputs = [ cmake rocm-cmake pkgconfig ]
    ++ stdenv.lib.optional doCheck gtest;
  buildInputs = [ rocr hip ];
  cmakeFlags = [
    # "-DHIP_PLATFORM=clang"
    "-DCMAKE_CXX_COMPILER=hipcc"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DBUILD_TEST=${if doCheck then "YES" else "NO"}"
  ];
  patchPhase = ''
    sed -e '/find_package(Git/,/endif()/d' \
        -e '/download_project(/,/^[[:space:]]*)/d' \
        -i cmake/Dependencies.cmake
    sed 's,include(cmake/VerifyCompiler.cmake),,' -i CMakeLists.txt
  '';
}
