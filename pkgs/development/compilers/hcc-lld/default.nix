{ stdenv, cmake, fetchFromGitHub, libxml2, hcc-llvm }:
stdenv.mkDerivation rec {
  name = "hcc-lld";
  version = "2.10.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "lld";
    rev = "roc-hcc-${version}";
    sha256 = "1rq7nklvrv5zs1a6iss3pwmwqli776pvbrxqg34idns4zm11j6jr";
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
