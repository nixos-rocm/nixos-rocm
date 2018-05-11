{ stdenv, fetchFromGitHub, cmake, elfutils, roct }:

stdenv.mkDerivation rec {
  version = "1.8.0";
  name = "rocr-${version}";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCR-Runtime";

    rev = "36f9c49c3922634ae045340f2c3c7452a7198e62";
    sha256 = "1ra03viv7yzmqknz7xhvw9xlcymga7iczwjk3drcbac2jn3ygcgz";
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
