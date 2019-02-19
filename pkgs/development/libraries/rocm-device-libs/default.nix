{ stdenv, fetchFromGitHub, cmake
, rocm-llvm, rocm-lld, rocm-clang, rocr }:
stdenv.mkDerivation rec {
  name = "rocm-device-libs";
  version = "2.1.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCm-Device-Libs";
    rev = "roc-${version}";
    sha256 = "1bqmggi241kf78cybfgzi1z2s6z82v2xkynh2gyrm1ylii1fmvh5";
  };
  nativeBuildInputs = [ cmake ];
  buildInputs = [ rocm-llvm rocm-lld rocm-clang rocr ];
  cmakeBuildType = "Release";
  cmakeFlags = [
    "-DLLVM_TARGETS_TO_BUILD='AMDGPU;X86'"
    "-DLLVM_DIR=${rocm-llvm}/lib/cmake/llvm"
  ];
  patchPhase = ''
  sed 's|set(CLANG "''${LLVM_TOOLS_BINARY_DIR}/clang''${EXE_SUFFIX}")|set(CLANG "${rocm-clang}/bin/clang")|' -i OCL.cmake
  '';
}
