{ stdenv, fetchFromGitHub, fetchpatch, cmake, python
, rocr, hcc-llvm, rocminfo }:
stdenv.mkDerivation rec {
  name = "hcc-clang-unwrapped";
  version = "7.0.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "hcc-clang-upgrade";
    rev = "e2b51bfd063e4ccd426b64290bdc1587f2bf855a";
    sha256 = "09q2rms0xy411a7df9p1a2vs1azhk9j324dk13qb76gy79hmzwls";
  };
  nativeBuildInputs = [ cmake python ];
  propagatedBuildInputs = [ hcc-llvm ];
  buildInputs = [ rocr ];

  # The patch version is the last two digits of year + week number +
  # day in the week: date -d "2018-09-06" +%y%U%w
  cmakeFlags = [
    "-DHCC_VERSION_STRING=${version}"
    "-DHCC_VERSION_MAJOR=${stdenv.lib.versions.major version}"
    "-DHCC_VERSION_MINOR=${stdenv.lib.versions.minor version}"
    "-DHCC_VERSION_PATCH=18354"
  ];

  patchPhase = ''
    sed 's,\(const char\* tmp = \)std::getenv("ROCM_ROOT");,\1"${rocminfo}";,' -i ./lib/Driver/ToolChains/Hcc.cpp
  '';

  hardeningDisable = ["all"];
}
