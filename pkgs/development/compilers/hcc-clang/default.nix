{ stdenv, fetchFromGitHub, fetchpatch, cmake, python
, rocr, hcc-llvm, hcc-lld, rocminfo }:
stdenv.mkDerivation rec {
  name = "hcc-clang-unwrapped";
  version = "7.0.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "hcc-clang-upgrade";
    rev = "4ed1d60af7c26e833d6d4452ba526d2daaa6ed35";
    sha256 = "0sgq9raza9k0ajyhr76bsr0bb5jch76q9ca8k3d26wh8j7fgf0c2";
  };
  nativeBuildInputs = [ cmake python ];
  propagatedBuildInputs = [ hcc-llvm hcc-lld ];
  buildInputs = [ rocr ];

  # The patch version is the last two digits of year + week number +
  # day in the week: date -d "2018-09-19" +%y%U%w
  cmakeFlags = [
    "-DHCC_VERSION_STRING=${version}"
    "-DHCC_VERSION_MAJOR=${stdenv.lib.versions.major version}"
    "-DHCC_VERSION_MINOR=${stdenv.lib.versions.minor version}"
    "-DHCC_VERSION_PATCH=18373"
  ];
  patches = [ ./flatwgs-not-null.patch ];

  preConfigure = ''
    sed 's,\(const char\* tmp = \)std::getenv("ROCM_ROOT");,\1"${rocminfo}";,' -i ./lib/Driver/ToolChains/Hcc.cpp
    sed 's/FDecl->getName()/FDecl->getNameAsString()/' -i lib/Sema/SemaTemplateInstantiateDecl.cpp
  '';

  hardeningDisable = ["all"];
}
