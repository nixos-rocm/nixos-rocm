{ stdenv, cmake, fetchFromGitHub, libxml2, hcc-llvm }:
stdenv.mkDerivation {
  name = "hcc-lld";
  version = "2018-11-20";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "lld";
    rev = "fd400b956f251be58acf266641e02913cbd93b72";
    sha256 = "0w2qcbzgdfvyakhll3nbln6v0gz3j9fa0lkc0m1yh25mmp2s3y3f";
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
