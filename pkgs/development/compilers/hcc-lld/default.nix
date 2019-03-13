{ stdenv, cmake, fetchFromGitHub, libxml2, hcc-llvm }:
stdenv.mkDerivation {
  name = "hcc-lld";
  version = "2019-02-06";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "lld";
    rev = "8e7027a1bf3b2a0007562d2164e0fa4c037a31d5";
    sha256 = "021irb7zhypan3nwagc9x7lk3w2wc6mj2rpmjw71azc6xyw01ggv";
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
