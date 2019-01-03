{ stdenv, fetchFromGitHub, cmake, python, hcc-llvm }:
stdenv.mkDerivation {
  name = "hcc-compiler-rt";
  version = "2018-11-20";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "compiler-rt";
    rev = "638adb5bd55f84981257ee0a634cd414a9374021";
    sha256 = "0cb46hb5v4rwlpp9ijkg1dgksk72rby7jrcwmvl5w6fp81z588qn";
  };
  nativeBuildInputs = [ cmake python ];
  buildInputs = [ hcc-llvm ];
}
