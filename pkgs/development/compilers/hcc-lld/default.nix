{ stdenv, cmake, fetchFromGitHub, libxml2, hcc-llvm }:
stdenv.mkDerivation {
  name = "hcc-lld";
  version = "2018-06-11";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "lld";
    rev = "38dff40c22de0f5ed9a88eb5311476d55e05f6a8";
    sha256 = "0cbjll23d40fvkwvg80880svv29yapsb96m5ki3digd5wljddb65";
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
