{ stdenv, fetchFromGitHub, cmake, elfutils, roct }:

stdenv.mkDerivation rec {
  version = "1.7.0a";
  name = "rocr-${version}";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCR-Runtime";
    # rev = "roc-${version}";
    rev = "37157bbb3edbec37f4842f6f2f70d250fa5ddd36";
    sha256 = "0gd5w94hlqr4qq16y91siaikzyn1zgmyly44rvfmm4ns2rs8ddc3";
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
