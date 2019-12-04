{ stdenv, fetchFromGitHub, cmake }:
stdenv.mkDerivation rec {
  name = "rocm-cmake";
  version = "2.10.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "roc-${version}";
    sha256 = "08mmqhcjnpvhlkkg8k9j8id5bxbf0kasd9l4ywbhjbj8449mz9a0";
  };
  nativeBuildInputs = [ cmake ];
}
