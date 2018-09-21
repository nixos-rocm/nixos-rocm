{ stdenv, cmake, fetchFromGitHub, libxml2, rocm-llvm }:
stdenv.mkDerivation {
  name = "rocm-lld";
  version = "2018-09-16";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "lld";
    rev = "1676b9e6a5b7dde52ea95b1a93378260bb2ec76e";
    sha256 = "0glccxa94vlppx4l2ghm0xk2i74m9vjg0qnd4d714j99vj21nifd";
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
