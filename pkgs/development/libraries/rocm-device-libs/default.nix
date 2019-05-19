{ stdenv, fetchFromGitHub, cmake
, llvm, lld, clang, rocr }:
stdenv.mkDerivation rec {
  name = "rocm-device-libs";
  version = "2.4.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCm-Device-Libs";
    rev = "roc-${version}";
    sha256 = "14n8fg35x3clpg2y97lxa3wk6iq1xg5n4dppph523hbnsyzg9wvx";
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
