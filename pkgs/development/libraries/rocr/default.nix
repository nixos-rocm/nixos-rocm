{ stdenv, fetchFromGitHub, cmake, elfutils, roct }:

stdenv.mkDerivation rec {
  version = "1.8.2";
  name = "rocr-${version}";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCR-Runtime";

    rev = "e8c89f9d1577497345196c0e02d442a5ca7454ae";
    sha256 = "194w3y22v3cly4c1yjzrybjhiyir2dnp4vdkxccj106y3xj6rw8p";
  };

  postUnpack = ''
    sourceRoot="$sourceRoot/src"
  '';

  enableParallelBuilding = true;
  buildInputs = [ cmake elfutils ];
  cmakeFlags = [ "-DCMAKE_PREFIX_PATH=${roct}" ];

  fixupPhase = ''
    rm -r $out/lib $out/include
    mv $out/hsa/lib $out/hsa/include $out
  '';
}
