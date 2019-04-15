{ stdenv, fetchFromGitHub, fetchpatch, cmake, python
, rocr, hcc-llvm, hcc-lld, rocminfo }:
stdenv.mkDerivation rec {
  name = "hcc-clang-unwrapped";
  version = "2.3.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "hcc-clang-upgrade";
    rev = "roc-${version}";
    sha256 = "0h436c314irqwpm6alanqwvl0yjycighd7ldpzcn5gk3i4z8w608";
  };
  nativeBuildInputs = [ cmake python ];
  propagatedBuildInputs = [ hcc-llvm hcc-lld ];
  buildInputs = [ rocr ];

  # The patch version is the last two digits of year + week number +
  # day in the week: date -d "2019-03-12" +%y%U%w
  cmakeFlags = [
    "-DHCC_VERSION_STRING=${version}"
    "-DHCC_VERSION_MAJOR=${stdenv.lib.versions.major version}"
    "-DHCC_VERSION_MINOR=${stdenv.lib.versions.minor version}"
    "-DHCC_VERSION_PATCH=19102"
  ];

  # Rather than let cmake extract version information from LLVM or
  # clang source control repositories, we generate the wanted
  # `VCSVersion.inc` file ourselves and remove it from the
  # depencencies of the `clangBasic` target.
  preConfigure = ''
    sed 's,\(const char\* tmp = \)std::getenv("ROCM_ROOT");,\1"${rocminfo}";,' -i ./lib/Driver/ToolChains/Hcc.cpp
    sed 's/FDecl->getName()/FDecl->getNameAsString()/' -i lib/Sema/SemaTemplateInstantiateDecl.cpp
    sed 's/  ''${version_inc}//' -i lib/Basic/CMakeLists.txt
  '';

  postConfigure = ''
    mkdir -p lib/Basic
    echo "$VCSVersion" > lib/Basic/VCSVersion.inc
  '';

  hardeningDisable = ["all"];
}
