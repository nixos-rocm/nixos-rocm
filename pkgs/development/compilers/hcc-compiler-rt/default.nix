{ stdenv, fetchFromGitHub, cmake, python, hcc-llvm }:
stdenv.mkDerivation rec {
  name = "hcc-compiler-rt";
  version = "2.6.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "compiler-rt";
    rev = "roc-hcc-${version}";
    sha256 = "1n2snn4w090p20h2104chf00z1q77cxxjimkmw0vsvm94ajjynmq";
  };
  nativeBuildInputs = [ cmake python ];
  buildInputs = [ hcc-llvm ];
}
