{ stdenv, cmake, fetchFromGitHub, libxml2, rocm-llvm }:
stdenv.mkDerivation rec {
  name = "rocm-lld";
  version = "2.3.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "lld";
    rev = "roc-ocl-${version}";
    sha256 = "0dl4p7gy1cc509i6zkwfkw633zydn32y70jrw5k0skb9mrxiw225";
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
