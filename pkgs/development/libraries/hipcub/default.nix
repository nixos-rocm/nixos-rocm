{stdenv, fetchFromGitHub, cmake, rocm-cmake, pkgconfig, hcc, hip, rocprim}:
stdenv.mkDerivation {
  name = "hipcub";
  version = "20190507";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "hipCUB";
    rev = "b6ce7dbe9c376b869642203c42d17a0eed975971";
    sha256 = "0mr3z7d551davq77qm5ggljkch4kllcrjiypr177zd8fxlp0xjxj";
  };
  patchPhase = ''
    sed '/find_package(hcc/d' -i cmake/VerifyCompiler.cmake
    sed -e '/find_package(Git/,/endif()/d' \
        -e '/download_project(/,/^[[:space:]]*)/d' \
        -i cmake/Dependencies.cmake
  '';
  nativeBuildInputs = [ cmake rocm-cmake pkgconfig ];
  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=hcc"
    "-DHIP_PLATFORM=hcc"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"    
    "-DBUILD_TEST=NO"
  ];
  buildInputs = [ hcc hip rocprim ];
}
