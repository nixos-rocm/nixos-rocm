{ stdenv, fetchFromGitHub, cmake }:
stdenv.mkDerivation {
  name = "rocm-cmake";
  version = "2019-02-20";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "42f67408d4cbaa987baca07d6b02c975ad1c0621";
    sha256 = "1jj8rfqx20fpypx29wvviv4h6dw6j0libyjy76qc5vcc2xszycnf";
  };
  nativeBuildInputs = [ cmake ];
}
