{ stdenv, fetchFromGitHub, cmake }:
stdenv.mkDerivation rec {
  name = "rocm-cmake";
  version = "3.5.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "rocm-${version}";
    sha256 = "1x1mj1acarhin319zycms8sqm9ylw2mcdbkpqjlb8yfsgiaa99ja";
  };
  nativeBuildInputs = [ cmake ];
}
