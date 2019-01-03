{ stdenv, fetchFromGitHub, cmake }:
stdenv.mkDerivation {
  name = "rocm-cmake";
  version = "2018-12-11";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "ac45c6e269d1fd1dbd5dfc81cfe47a7452c96daf";
    sha256 = "0wnnyfl72gamvkn0s1w7wvn0afbawmkf19b52ncwjdln25lzaix6";
  };
  nativeBuildInputs = [ cmake ];
}
