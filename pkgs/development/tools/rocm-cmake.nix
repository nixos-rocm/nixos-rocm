{ stdenv, fetchFromGitHub, cmake }:
stdenv.mkDerivation {
  name = "rocm-cmake";
  version = "2019-06-06";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "68fb6b3373bcecadd937d7ab0a1c3adaf6a1b13e";
    sha256 = "0hysfym5ypr9cz5s2jja1b1ga5k0fa9l8akcr4g2wsxnz2b4x3rm";
  };
  nativeBuildInputs = [ cmake ];
}
