{ stdenv, cmake, fetchFromGitHub, libxml2, rocm-llvm }:
stdenv.mkDerivation rec {
  name = "rocm-lld";
  version = "2.4.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "lld";
    rev = "roc-ocl-${version}";
    sha256 = "0lcjr0kknb54hgcb0vp5apkqi9226ikk1fy9y1hjn1a34n998pxy";
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
