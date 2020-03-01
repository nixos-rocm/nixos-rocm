{ stdenv, fetchFromGitHub, cmake, python, llvm, src, namePrefix }:
stdenv.mkDerivation rec {
  name = "${namePrefix}-compiler-rt";
  version = "3.1.0";
  inherit src;
  nativeBuildInputs = [ cmake python ];
  buildInputs = [ llvm ];
}
