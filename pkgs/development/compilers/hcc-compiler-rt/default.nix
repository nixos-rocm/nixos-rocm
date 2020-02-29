{ stdenv, fetchFromGitHub, cmake, python, hcc-llvm, src }:
stdenv.mkDerivation rec {
  name = "hcc-compiler-rt";
  version = "3.1.0";
  inherit src;
  nativeBuildInputs = [ cmake python ];
  buildInputs = [ hcc-llvm ];
}
