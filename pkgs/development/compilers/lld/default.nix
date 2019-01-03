{ stdenv, cmake, fetchFromGitHub, libxml2, rocm-llvm }:
stdenv.mkDerivation rec {
  name = "rocm-lld";
  version = "2.0.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "lld";
    rev = "roc-${version}";
    sha256 = "0w2qcbzgdfvyakhll3nbln6v0gz3j9fa0lkc0m1yh25mmp2s3y3f";
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
