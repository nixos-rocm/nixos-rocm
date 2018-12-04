{ stdenv, fetchFromGitHub, cmake }:
stdenv.mkDerivation {
  name = "rocm-cmake";
  version = "2018-09-12";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "11181f62dbb9bd551427ce87080f73d8964e0b08";
    sha256 = "00vac9w0qr53sk733prz6caz3zpj2ljsxza37g4y0jfr73wnd4bx";
  };
  nativeBuildInputs = [ cmake ];
}
