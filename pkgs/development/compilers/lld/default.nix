{ stdenv, cmake, fetchFromGitHub, libxml2, rocm-llvm }:
stdenv.mkDerivation rec {
  name = "rocm-lld";
  version = "2.1.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "lld";
    rev = "roc-${version}";
    sha256 = "0v7yvhjvq8n7jdwvka2ai1czi3yp3n2wwh6lp52rl3la5jgx26l7";
  };
  nativeBuildInputs = [ cmake ];
  buildInputs = [ rocm-llvm libxml2 ];

  outputs = [ "out" "dev" ];
  enableParallelBuilding = true;

  postInstall = ''
    moveToOutput include "$dev"
    moveToOutput lib "$dev"
  '';
}
