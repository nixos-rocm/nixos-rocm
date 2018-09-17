{ stdenv, fetchFromGitHub, cmake }:
stdenv.mkDerivation {
  name = "rocm-cmake";
  version = "2018-09-12";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "d82a77c9911340e7488fdea995bdfd810f0a0ecf";
    sha256 = "0wc353l0yqqz7cf1583g8pnn53mv2ldgaji41kmmf4v1g09v02qv";
  };
  nativeBuildInputs = [ cmake ];
}
