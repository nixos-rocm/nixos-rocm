{ stdenv, fetchFromGitHub, cmake
, llvm, lld, clang, rocr }:
stdenv.mkDerivation rec {
  name = "rocm-device-libs";
  version = "2.5.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCm-Device-Libs";
    rev = "roc-${version}";
    sha256 = "1vkk5mbdgp37sj62n49n6r6v17mgl2qqlds3k8bx2gvz39irrfxw";
  };
  nativeBuildInputs = [ cmake ];
  buildInputs = [ llvm lld clang rocr ];
  cmakeBuildType = "Release";
  cmakeFlags = [
    "-DLLVM_TARGETS_TO_BUILD='AMDGPU;X86'"
    "-DLLVM_DIR=${llvm}/lib/cmake/llvm"
  ];
  patchPhase = ''
  sed 's|set(CLANG "''${LLVM_TOOLS_BINARY_DIR}/clang''${EXE_SUFFIX}")|set(CLANG "${clang}/bin/clang")|' -i OCL.cmake
  '';
}
