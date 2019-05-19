{ stdenv, cmake, fetchFromGitHub, libxml2, llvm
, name, version, src}:
stdenv.mkDerivation rec {
  inherit name version src;
  nativeBuildInputs = [ cmake ];
  buildInputs = [ llvm libxml2 ];

  outputs = [ "out" "dev" ];
  enableParallelBuilding = true;

  postInstall = ''
    moveToOutput include "$dev"
    moveToOutput lib "$dev"
  '';
}
