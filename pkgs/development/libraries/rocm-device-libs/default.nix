{ stdenv, fetchFromGitHub, cmake
, rocm-llvm, rocm-lld, rocm-clang, rocr }:
stdenv.mkDerivation rec {
  name = "rocm-device-libs";
  version = "1.9.2";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCm-Device-Libs";
    rev = "roc-${version}";
    sha256 = "127cqvgzha54pr081fkhcfcwnfb6mwwmm4i8cmvf4jdmd24wci0a";
  };
  nativeBuildInputs = [ cmake ];
  buildInputs = [ rocm-llvm rocm-lld rocm-clang rocr ];
  cmakeBuildType = "Release";
  cmakeFlags = [
    "-DLLVM_TARGETS_TO_BUILD='AMDGPU;X86'"
    "-DLLVM_DIR=${rocm-llvm}/lib/cmake/llvm"
  ];
  patchPhase = ''
  sed 's|set (CMAKE_OCL_COMPILER ''${LLVM_TOOLS_BINARY_DIR}/clang)|set (CMAKE_OCL_COMPILER ${rocm-clang}/bin/clang)|' -i OCL.cmake
  '';
}
