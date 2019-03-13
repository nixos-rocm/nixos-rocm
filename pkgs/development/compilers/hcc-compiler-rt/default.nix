{ stdenv, fetchFromGitHub, cmake, python, hcc-llvm }:
stdenv.mkDerivation {
  name = "hcc-compiler-rt";
  version = "2019-02-06";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "compiler-rt";
    rev = "15e4a1f9195d3d90828a7a122d866c69e650155c";
    sha256 = "0b4hz7aa61qs5acry678g19gy6sbka9468yviz2d76bisl61a1sj";
  };
  nativeBuildInputs = [ cmake python ];
  buildInputs = [ hcc-llvm ];
}
