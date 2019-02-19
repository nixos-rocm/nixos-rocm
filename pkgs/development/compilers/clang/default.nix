{ stdenv, fetchFromGitHub, cmake, python, rocr, rocm-llvm }:
stdenv.mkDerivation rec {
  name = "clang-unwrapped";
  version = "2.1.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "clang";
    rev = "roc-${version}";
    sha256 = "0i9mfsgr95p1zid96zhc93jzyzqrzq61q8ciw3nd66saa10vwf3w";
  };
  nativeBuildInputs = [ cmake python ];
  buildInputs = [ rocm-llvm rocr ];
  hardeningDisable = ["all"];
}
