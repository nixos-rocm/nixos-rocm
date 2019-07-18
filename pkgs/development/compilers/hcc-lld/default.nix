{ stdenv, cmake, fetchFromGitHub, libxml2, hcc-llvm }:
stdenv.mkDerivation rec {
  name = "hcc-lld";
  version = "2.6.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "lld";
    rev = "roc-hcc-${version}";
    sha256 = "0vxldgcwwfjsdvanpg27d827brx3d8pyfzyw2dx997q4kp763dd4";
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
