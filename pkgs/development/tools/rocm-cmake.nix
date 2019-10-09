{ stdenv, fetchFromGitHub, cmake }:
stdenv.mkDerivation rec {
  name = "rocm-cmake";
  version = "2.9.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "roc-${version}";
    sha256 = "04k4ibsdqsws7r4rvgh37b6zb5xmhp6kmhzq4zy605q0spf4h0q5";
  };
  nativeBuildInputs = [ cmake ];
}
