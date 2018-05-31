{ stdenv, fetchFromGitHub, cmake }:
stdenv.mkDerivation {
  name = "rocm-cmake";
  version = "2018-05-28";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "3f43e2d493f24abbab4dc189a9ab12cc3ad33baf";
    sha256 = "0j12jbgi295y37ana86dy8rsys886blr09yd95clwjkrcxv9mgir";
  };
  nativeBuildInputs = [ cmake ];
}
