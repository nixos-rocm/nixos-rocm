{ stdenv, cmake, fetchFromGitHub, libxml2, hcc-llvm }:
stdenv.mkDerivation {
  name = "hcc-lld";
  version = "2019-01-14";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "lld";
    rev = "57d0222173fcdd1016d80ae7cedb0fbda86c148d";
    sha256 = "0v7yvhjvq8n7jdwvka2ai1czi3yp3n2wwh6lp52rl3la5jgx26l7";
  };
  nativeBuildInputs = [ cmake ];
  buildInputs = [ hcc-llvm libxml2 ];

  outputs = [ "out" "dev" ];
  enableParallelBuilding = true;

  postInstall = ''
    moveToOutput include "$dev"
    moveToOutput lib "$dev"
  '';
}
