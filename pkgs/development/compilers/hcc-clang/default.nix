{ stdenv, fetchFromGitHub, fetchpatch, cmake, python
, rocr, hcc-llvm, hcc-lld, rocminfo }:
stdenv.mkDerivation rec {
  name = "hcc-clang-unwrapped";
  version = "2.10.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "hcc-clang-upgrade";
    rev = "roc-hcc-${version}";
    sha256 = "1cllbhv1w0ms54a3jza2kznrgfc34gy13vlra3liaiv21wmpc0i0";
  };
  nativeBuildInputs = [ cmake python ];
  propagatedBuildInputs = [ hcc-llvm hcc-lld ];
  buildInputs = [ rocr ];

  # The patch version is the last two digits of year + week number +
  # day in the week: date -d "2019-10-21" +%y%U%w
  cmakeFlags = [
    "-DHCC_VERSION_STRING=${version}"
    "-DHCC_VERSION_MAJOR=${stdenv.lib.versions.major version}"
    "-DHCC_VERSION_MINOR=${stdenv.lib.versions.minor version}"
    "-DHCC_VERSION_PATCH=19421"
  ];

  # Rather than let cmake extract version information from LLVM or
  # clang source control repositories, we generate the wanted
  # `VCSVersion.inc` file ourselves and remove it from the
  # depencencies of the `clangBasic` target.

  preConfigure = ''
    sed 's/  ''${version_inc}//' -i lib/Basic/CMakeLists.txt
    sed 's/\([[:space:]]*\)\(cmake_policy(SET CMP0075 NEW)\)/\1\2\n\1cmake_policy(SET CMP0077 NEW)/' -i CMakeLists.txt
    sed 's|\([[:space:]]*const Twine e = \)rocm + "/bin/rocm_agent_enumerator";|\1"${rocminfo}/bin/rocm_agent_enumerator";|' -i lib/Driver/ToolChains/Hcc.cpp
    sed 's|\([[:space:]]*std::string Linker = \)getToolChain().GetProgramPath(getShortName())|\1"${hcc-lld}/bin/ld.lld"|' -i lib/Driver/ToolChains/AMDGPU.cpp

    substituteInPlace lib/Driver/ToolChains/AMDGPU.h --replace ld.lld ${hcc-lld}/bin/ld.lld
  '';

  postConfigure = ''
    mkdir -p lib/Basic
    echo "$VCSVersion" > lib/Basic/VCSVersion.inc
  '';

  hardeningDisable = ["all"];
}
