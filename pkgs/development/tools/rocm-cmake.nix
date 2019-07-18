{ stdenv, fetchFromGitHub, cmake }:
stdenv.mkDerivation {
  name = "rocm-cmake";
  version = "2019-06-28";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "56e04c087dfc092a3b5ca68849b0d4a7defd4729";
    sha256 = "1a7in9idqc4wr1x9jvnbqs3ykasjbqvby1jd5828aaz7w4zj0yd4";
  };
  nativeBuildInputs = [ cmake ];
}
