{ stdenv, fetchFromGitHub, cmake, python, hcc-llvm }:
stdenv.mkDerivation rec {
  name = "hcc-compiler-rt";
  version = "2.3.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "compiler-rt";
    rev = "roc-${version}";
    sha256 = "0knp6gj9c69ym4ghqwh624iv3nnpm2v4igz0zwl11j4mkh6b7x3m";
  };
  nativeBuildInputs = [ cmake python ];
  buildInputs = [ hcc-llvm ];
}
