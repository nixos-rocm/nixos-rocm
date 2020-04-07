{stdenv, fetchFromGitHub, cmake, pkgconfig, gtest, rocm-cmake, rocr, hip

# The test suite takes a long time to build
, doCheck ? false
}:
stdenv.mkDerivation rec {
  name = "rocprim";
  version = "3.3.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocPRIM";
    rev = "rocm-${version}";
    sha256 = "1cmh85hnv1zd7644hg07cp7v10m1f8drnc2rc8mz7640958128m6";
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
