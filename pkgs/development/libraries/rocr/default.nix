{ stdenv, fetchFromGitHub, cmake, elfutils, roct }:

stdenv.mkDerivation rec {
  version = "1.7.0";
  name = "rocr-${version}";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCR-Runtime";
    # rev = "roc-${version}";
    # sha256 = "0k71qdcrskavrk6rdd9hl2rr3p43l5lr401c1yhmhckic19bpaav";

    rev = "37157bbb3edbec37f4842f6f2f70d250fa5ddd36";
    sha256 = "0gd5w94hlqr4qq16y91siaikzyn1zgmyly44rvfmm4ns2rs8ddc3";
  };

  postUnpack = ''
    sourceRoot="$sourceRoot/src"
  '';

  # patches = [ ./gcc-7-Wformat-overflow.patch ];

  enableParallelBuilding = true;
  buildInputs = [ cmake elfutils ];
  cmakeFlags = [ "-DCMAKE_PREFIX_PATH=${roct}" ];

  fixupPhase = ''
    rm -r $out/lib $out/include
    mv $out/hsa/lib $out/hsa/include $out
  '';
}
