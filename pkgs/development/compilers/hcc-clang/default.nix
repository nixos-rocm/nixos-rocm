{ stdenv, fetchFromGitHub, fetchpatch, cmake, python
, rocr, hcc-llvm, hcc-lld, rocminfo }:
stdenv.mkDerivation rec {
  name = "hcc-clang-unwrapped";
  version = "2.8.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "hcc-clang-upgrade";
    rev = "roc-hcc-${version}";
    sha256 = "1w80kdqdy4h23p7sq8fbffazf4fdqjk4fj70nps5v1cdsnxnkxyv";
  };
  nativeBuildInputs = [ cmake python ];
  propagatedBuildInputs = [ hcc-llvm hcc-lld ];
  buildInputs = [ rocr ];

  # The patch version is the last two digits of year + week number +
  # day in the week: date -d "2019-08-21" +%y%U%w
  cmakeFlags = [
    "-DHCC_VERSION_STRING=${version}"
    "-DHCC_VERSION_MAJOR=${stdenv.lib.versions.major version}"
    "-DHCC_VERSION_MINOR=${stdenv.lib.versions.minor version}"
    "-DHCC_VERSION_PATCH=19333"
  ];

  # Rather than let cmake extract version information from LLVM or
  # clang source control repositories, we generate the wanted
  # `VCSVersion.inc` file ourselves and remove it from the
  # depencencies of the `clangBasic` target.

  # This version of clang mentions GFX908, which is not defined in the
  # roc-hcc-2.7.0 tag of AMD's llvm fork.
  preConfigure = ''
    sed 's/  ''${version_inc}//' -i lib/Basic/CMakeLists.txt
    sed 's/\([[:space:]]*\)\(cmake_policy(SET CMP0075 NEW)\)/\1\2\n\1cmake_policy(SET CMP0077 NEW)/' -i CMakeLists.txt
    sed 's|\([[:space:]]*const Twine e = \)rocm + "/bin/rocm_agent_enumerator";|\1"${rocminfo}/bin/rocm_agent_enumerator";|' -i lib/Driver/ToolChains/Hcc.cpp
  '';
  #    sed '/[[:space:]]*case GK_GFX908:/,/[[:space:]]*LLVM_FALLTHROUGH;/d' -i lib/Basic/Targets/AMDGPU.cpp

  postConfigure = ''
    mkdir -p lib/Basic
    echo "$VCSVersion" > lib/Basic/VCSVersion.inc
  '';

  hardeningDisable = ["all"];
}
