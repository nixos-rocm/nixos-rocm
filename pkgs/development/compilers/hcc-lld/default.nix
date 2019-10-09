{ stdenv, cmake, fetchFromGitHub, libxml2, hcc-llvm }:
stdenv.mkDerivation rec {
  name = "hcc-lld";
  version = "2.9.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "lld";
    rev = "roc-hcc-${version}";
    sha256 = "13lndrykz3m7fzvbkdy1wai0mc2yw3lvwz47wia5wq34gsjj5zfb";
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
