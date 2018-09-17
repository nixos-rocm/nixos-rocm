{ stdenv, fetchFromGitHub, cmake, elfutils, roct }:

stdenv.mkDerivation rec {
  version = "1.9.0";
  name = "rocr-${version}";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCR-Runtime";
    rev = "roc-${version}";
    sha256 = "05s6j58n11v0hnafrmr24gh1199ykwvmclmny4ypcc1r0hv9jhi5";
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
