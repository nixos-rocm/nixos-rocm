{ stdenv, fetchFromGitHub, cmake }:
stdenv.mkDerivation {
  name = "rocm-cmake";
  version = "2018-03-30";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "ec7313aa43de72729c8f66b2e53155e03aa74e20";
    sha256 = "095x40az48nz28vm2azl7ybbddmp9c2x6nz26qdcl60h8mhqhrqx";
  };
  nativeBuildInputs = [ cmake ];
}
