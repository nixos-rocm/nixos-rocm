{ stdenv, fetchFromGitHub, cmake, python, hcc-llvm }:
stdenv.mkDerivation rec {
  name = "hcc-compiler-rt";
  version = "2.4.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "compiler-rt";
    rev = "roc-${version}";
    sha256 = "1g378a8bn9jx5905wras99bkhszv95hmr9k2wqcqqw19i17g4r72";
  };
  nativeBuildInputs = [ cmake python ];
  buildInputs = [ hcc-llvm ];
}
