{ stdenv, fetchFromGitHub, cmake, python, hcc-llvm }:
stdenv.mkDerivation {
  name = "hcc-compiler-rt";
  version = "2018-11-20";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "compiler-rt";
    rev = "5fe32f97b2af1a96b7bee06ec57c6399bde9560b";
    sha256 = "1p95zgl28mgfv1hwyhb94aqbbxaqsl5z5vjcq7hwwg3x7d92za17";
  };
  nativeBuildInputs = [ cmake python ];
  buildInputs = [ hcc-llvm ];
}
