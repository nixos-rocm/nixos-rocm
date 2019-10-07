{ stdenv, fetchFromGitHub, cmake }:
stdenv.mkDerivation rec {
  name = "rocm-cmake";
  version = "2.8.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "roc-${version}";
    sha256 = "015f60gb8v3cxy4irlivbc1wxkc7c3lcwqa38wr96f1nd7x85nfd";
  };
  nativeBuildInputs = [ cmake ];
}
