{ stdenv, fetchFromGitHub, cmake, python, rocr, llvm
, name, version, src, clang-tools-extra_src ? null}:
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

  postUnpack = stdenv.lib.optionalString (!(isNull clang-tools-extra_src)) ''
    ln -s ${clang-tools-extra_src} $sourceRoot/tools/extra
  '';

  # Rather than let cmake extract version information from LLVM or
  # clang source control repositories, we generate the wanted
  # `VCSVersion.inc` file ourselves and remove it from the
  # depencencies of the `clangBasic` target.
  preConfigure = ''
    sed 's/  ''${version_inc}//' -i lib/Basic/CMakeLists.txt
    sed 's|sys::path::parent_path(BundlerExecutable)|StringRef("${llvm}/bin")|' -i tools/clang-offload-bundler/ClangOffloadBundler.cpp
  '';
  postConfigure = ''
    mkdir -p lib/Basic
    echo "$VCSVersion" > lib/Basic/VCSVersion.inc
  '';
}
