{ stdenv, fetchFromGitHub, cmake, python, hcc-llvm }:
stdenv.mkDerivation rec {
  name = "hcc-compiler-rt";
  version = "2.8.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "compiler-rt";
    rev = "roc-hcc-${version}";
    sha256 = "1dzgnxs9i7s5k5lzfrn0m3l5jx9pnhxc4kdwfvpp1hs6qlwy9jy9";
  };
  nativeBuildInputs = [ cmake python ];
  buildInputs = [ hcc-llvm ];
}
