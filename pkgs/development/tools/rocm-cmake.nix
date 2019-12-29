{ stdenv, fetchFromGitHub, cmake }:
stdenv.mkDerivation rec {
  name = "rocm-cmake";
  version = "3.0.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "roc-${version}";
    sha256 = "1yrz278if3ilq26v3y3pl6dr49wvssk4qaj2wsn62vph329c9paz";
  };
  nativeBuildInputs = [ cmake ];
}
