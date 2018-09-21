{ stdenv, fetchFromGitHub, cmake, python, hcc-llvm }:
stdenv.mkDerivation {
  name = "hcc-compiler-rt";
  version = "2018-06-11";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "compiler-rt";
    rev = "7c1c1a65a6c1f6e8cd15c67bd6fae938eb20573a";
    sha256 = "0wb5g1s950pq39samjxnzjggyrxchk98bss06wgna9mrb6sxgphf";
  };
  nativeBuildInputs = [ cmake python ];
  buildInputs = [ hcc-llvm ];
}
