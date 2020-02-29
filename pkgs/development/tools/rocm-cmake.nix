{ stdenv, fetchFromGitHub, cmake }:
stdenv.mkDerivation rec {
  name = "rocm-cmake";
  version = "3.1.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    # rev = "roc-${version}";
    rev = "1abe21258481d4cf92f5bab0ef5956636c52f735";
    sha256 = "19x881nr6naiybxwjcqh2hsmnxfawdm43g9vivr7lvvlyq62vw8h";
  };
  nativeBuildInputs = [ cmake ];
}
