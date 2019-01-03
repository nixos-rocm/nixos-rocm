{ stdenv, fetchFromGitHub, cmake, python, rocr, rocm-llvm }:
stdenv.mkDerivation rec {
  name = "clang-unwrapped";
  version = "2.0.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "clang";
    rev = "roc-${version}";
    sha256 = "1ll2hxbl2rp6vv0k8xhnb7bhaagklz0vqwnz2mr02giiww6jzx30";
  };
  nativeBuildInputs = [ cmake python ];
  buildInputs = [ rocm-llvm rocr ];
  hardeningDisable = ["all"];
}
