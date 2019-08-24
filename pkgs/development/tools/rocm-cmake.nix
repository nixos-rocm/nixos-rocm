{ stdenv, fetchFromGitHub, cmake }:
stdenv.mkDerivation rec {
  name = "rocm-cmake";
  version = "2.7.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "roc-${version}";
    sha256 = "0pp7mdd8px52vxp2pj6nsj4cn11k58j65ffvam5j4jsafxsrgmd5";
  };
  nativeBuildInputs = [ cmake ];
}
