{ stdenv, fetchFromGitHub, cmake
, llvm, lld, clang, rocr
, source ? null
, tagPrefix ? null
, sha256 ? null }:
# Caller *must* provide either src or both tagPrefix and sha256
assert (isNull source) -> !(isNull tagPrefix || isNull sha256);
let version = "2.7.0";
    srcTmp = if isNull source then fetchFromGitHub {
      owner = "RadeonOpenCompute";
      repo = "ROCm-Device-Libs";
      rev = "${tagPrefix}-${version}";
      inherit sha256;
    } else source;
in
stdenv.mkDerivation rec {
  name = "rocm-device-libs";
  inherit version;
  src = srcTmp;
  nativeBuildInputs = [ cmake ];
  buildInputs = [ llvm lld clang rocr ];
  cmakeBuildType = "Release";
  cmakeFlags = [
    "-DLLVM_TARGETS_TO_BUILD='AMDGPU;X86'"
    "-DLLVM_DIR=${llvm}/lib/cmake/llvm"
    "-DCLANG_OPTIONS_APPEND=-Wno-unused-command-line-argument"
  ];
  patchPhase = ''
  sed 's|set(CLANG "''${LLVM_TOOLS_BINARY_DIR}/clang''${EXE_SUFFIX}")|set(CLANG "${clang}/bin/clang")|' -i OCL.cmake
  '';
}
