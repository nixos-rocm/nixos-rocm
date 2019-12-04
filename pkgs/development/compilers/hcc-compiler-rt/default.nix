{ stdenv, fetchFromGitHub, cmake, python, hcc-llvm }:
stdenv.mkDerivation rec {
  name = "hcc-compiler-rt";
  version = "2.10.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "compiler-rt";
    rev = "roc-hcc-${version}";
    sha256 = "0gp3iy3nqq76hqish9pj94a49ab5fx7yl6ygw4rx471mxwc5fmyb";
  };
  nativeBuildInputs = [ cmake python ];
  buildInputs = [ hcc-llvm ];
}
