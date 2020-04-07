{ stdenv, fetchFromGitHub, cmake }:
stdenv.mkDerivation rec {
  name = "rocm-cmake";
  version = "3.3.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "rocm-${version}";
    sha256 = "0i920c18nmm0h6x018lckbykax8yv2i5mcslh69yqhj0lx7yjj8l";
  };
  nativeBuildInputs = [ cmake ];
}
