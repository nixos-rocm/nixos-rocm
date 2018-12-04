{ stdenv, fetchFromGitHub, cmake, python, rocr, rocm-llvm }:
stdenv.mkDerivation rec {
  name = "clang-unwrapped";
  version = "7.0.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "clang";
    rev = "roc-1.9.2";
    sha256 = "06ph9x757rxy23wfw7lalxp5phqlj53ijbwxf7lasy9kpx2y5xq6";
  };
  nativeBuildInputs = [ cmake python ];
  buildInputs = [ rocm-llvm rocr ];
  hardeningDisable = ["all"];
}
