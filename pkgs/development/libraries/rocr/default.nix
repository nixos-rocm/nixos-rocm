{ stdenv, fetchFromGitHub, cmake, elfutils, roct }:

stdenv.mkDerivation rec {
  version = "1.7.2";
  name = "rocr-${version}";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCR-Runtime";

    rev = "e6f4bd6f341f40289e3e5de0c902c1a0ba0f7018";
    sha256 = "0k71qdcrskavrk6rdd9hl2rr3p43l5lr401c1yhmhckic19bpaav";
  };

  postUnpack = ''
    sourceRoot="$sourceRoot/src"
  '';

  prePatch = ''
    sed 's/sprintf(buff, "%02u", minor);/sprintf(buff, "%02u", minor%100);/' -i core/runtime/hsa.cpp
  '';

  enableParallelBuilding = true;
  buildInputs = [ cmake elfutils ];
  cmakeFlags = [ "-DCMAKE_PREFIX_PATH=${roct}" ];

  fixupPhase = ''
    rm -r $out/lib $out/include
    mv $out/hsa/lib $out/hsa/include $out
  '';
}
