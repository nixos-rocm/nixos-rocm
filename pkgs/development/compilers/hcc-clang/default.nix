{ stdenv, fetchFromGitHub, fetchpatch, cmake, python
, rocr, hcc-llvm, hcc-lld, rocminfo }:
stdenv.mkDerivation rec {
  name = "hcc-clang-unwrapped";
  version = "8.0.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "hcc-clang-upgrade";
    rev = "6ec3c61e09fbb60373eaf5a40021eb862363ba2c";
    sha256 = "01h0y2b66r97n6px1mn31zv7q45fs3pmpnglxqlk8643im1jsqi0";
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

  preConfigure = ''
    sed 's,\(const char\* tmp = \)std::getenv("ROCM_ROOT");,\1"${rocminfo}";,' -i ./lib/Driver/ToolChains/Hcc.cpp
    sed 's/FDecl->getName()/FDecl->getNameAsString()/' -i lib/Sema/SemaTemplateInstantiateDecl.cpp
  '';

  hardeningDisable = ["all"];
}
