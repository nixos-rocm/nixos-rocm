{ stdenv, fetchFromGitHub, runCommand, cmake
, llvm, lld, clang, clang-unwrapped, rocr
, source ? null
, tagPrefix ? null
, sha256 ? null }:
stdenv.mkDerivation rec {
  name = "rocm-device-libs";
  version = "3.5.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCm-Device-Libs";
    rev = "rocm-${version}";
    sha256 = "0n160jwbh7jnqckz5bn979ll8afh2a97lf962xh9xv3cx025vnrn";
  };
  nativeBuildInputs = [ cmake ];
  buildInputs = [ llvm lld clang rocr ];
  cmakeBuildType = "Release";
  cmakeFlags = [
    "-DCMAKE_PREFIX_PATH=${llvm}/lib/cmake/llvm;${clang-unwrapped}/lib/cmake/clang"
    "-DLLVM_TARGETS_TO_BUILD='AMDGPU;X86'"
    "-DCLANG=${clang}/bin/clang"
  ];
}
