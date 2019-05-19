{ stdenv, fetchFromGitHub, cmake, python, rocr, llvm
, name, version, src}:
stdenv.mkDerivation rec {
  inherit name version src;
  nativeBuildInputs = [ cmake python ];
  buildInputs = [ llvm rocr ];
  hardeningDisable = ["all"];
  cmakeFlags = [
    "-DLLVM_CMAKE_PATH=${llvm}/lib/cmake/llvm"
    "-DLLVM_MAIN_SRC_DIR=${llvm.src}"
    "-DCLANG_SOURCE_DIR=${src}"
  ];
  VCSVersion = ''
    #undef LLVM_REVISION
    #undef LLVM_REPOSITORY
    #undef CLANG_REVISION
    #undef CLANG_REPOSITORY
  '';

  # Rather than let cmake extract version information from LLVM or
  # clang source control repositories, we generate the wanted
  # `VCSVersion.inc` file ourselves and remove it from the
  # depencencies of the `clangBasic` target.
  preConfigure = ''
    sed 's/  ''${version_inc}//' -i lib/Basic/CMakeLists.txt
  '';
  postConfigure = ''
    mkdir -p lib/Basic
    echo "$VCSVersion" > lib/Basic/VCSVersion.inc
  '';
}
