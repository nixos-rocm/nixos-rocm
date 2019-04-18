{stdenv, fetchFromGitHub, cmake, pkgconfig, gtest, rocm-cmake, rocr, hip

# The test suite takes a long time to build
, doCheck ? false
}:
stdenv.mkDerivation rec {
  name = "rocprim";
  version = "2.3";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocPRIM";
    rev = version;
    sha256 = "0qqsqz23ksdp3w904rn1izldzgrc2vld04wmfyp02c02dilpi2sk";
  };
  nativeBuildInputs = [ cmake rocm-cmake pkgconfig ] 
    ++ stdenv.lib.optional doCheck gtest;
  buildInputs = [ rocr hip ];
  cmakeFlags = [
    "-DHIP_PLATFORM=hcc"
    "-DCMAKE_CXX_COMPILER=hcc"
    "-DBUILD_TEST=${if doCheck then "YES" else "NO"}"
  ];
  patchPhase = ''
    sed '/find_package(hcc/d' -i cmake/VerifyCompiler.cmake
    sed -e '/find_package(Git/,/endif()/d' \
        -e '/download_project(/,/^[[:space:]]*)/d' \
        -i cmake/Dependencies.cmake
  '';
}
